import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; 

class ManageUsersController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  // --- STATE ---
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasMoreData = true.obs;
  
  // DATA LISTS
  var employees = <Map<String, dynamic>>[].obs;      
  var admins = <Map<String, dynamic>>[].obs; 
  var filteredEmployees = <Map<String, dynamic>>[].obs; 
  
  // PAGINATION
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;

  // FILTERS
  var selectedSiteFilter = "All Offices".obs;
  var searchQuery = "".obs;

  // DROPDOWN DATA
  var availableSites = <String>["All Offices"].obs;
  List<Map<String, String>> _siteMap = []; // Internal ID map

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _fetchSites();
    loadEmployees(refresh: true);
    loadAdmins();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------
  // 1. FETCH SITES (Restricted)
  // ---------------------------------------------------------
  void _fetchSites() async {
    try {
      final loginCtrl = Get.find<LoginController>();
      String companyId = loginCtrl.companyId.value;
      String mySiteId = loginCtrl.managedSiteId.value;
      String myRole = loginCtrl.userRole.value;

      if (companyId.isEmpty) return;

      Query query = _db.collection('operationSites')
          .doc(companyId)
          .collection('sites')
          .where('status', isEqualTo: true);

      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        query = query.where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      var sitesSnap = await query.get();

      _siteMap = sitesSnap.docs.map((doc) => {
        'id': doc.id,
        'name': doc['nameofsite'].toString()
      }).toList();

      if (myRole == "Branch Manager") {
        availableSites.assignAll(_siteMap.map((s) => s['name']!));
        if (availableSites.isNotEmpty) selectedSiteFilter.value = availableSites.first;
      } else {
        availableSites.assignAll(["All Offices", ..._siteMap.map((s) => s['name']!)]);
      }
    } catch (e) {
      debugPrint("Error fetching sites: $e");
    }
  }

  // ---------------------------------------------------------
  // 2. FETCH EMPLOYEES (Pagination + Filtering)
  // ---------------------------------------------------------
  void loadEmployees({bool refresh = false}) async {
    if (refresh) {
      isLoading.value = true;
      _lastDocument = null;
      hasMoreData.value = true;
      employees.clear();
    } else {
      if (!hasMoreData.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final loginCtrl = Get.find<LoginController>();
      String companyId = loginCtrl.companyId.value;
      String mySiteId = loginCtrl.managedSiteId.value;
      String myRole = loginCtrl.userRole.value;

      // Query Pointer Collection
      Query query = _db.collection('allusers')
          .where('companyId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .limit(_pageSize);

      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        query = query.where('siteId', isEqualTo: mySiteId);
      }
      
      if (_lastDocument != null) query = query.startAfterDocument(_lastDocument!);

      var pointersSnap = await query.get();
      
      if (pointersSnap.docs.length < _pageSize) {
        hasMoreData.value = false;
      }
      
      if (pointersSnap.docs.isNotEmpty) {
        _lastDocument = pointersSnap.docs.last;
      } else if (!refresh) {
        hasMoreData.value = false;
      }

      List<Map<String, dynamic>> newBatch = [];

      // Join with Profile Data
      for (var doc in pointersSnap.docs) {
        var pointer = doc.data() as Map<String, dynamic>;
        String uid = doc.id;
        String siteId = pointer['siteId'] ?? "";
        
        if (myRole == "Branch Manager" && siteId != mySiteId) continue;
        if (siteId.isEmpty) continue;

        try {
          var profileDoc = await _db.collection('users')
              .doc(companyId)
              .collection('sites')
              .doc(siteId)
              .collection('users')
              .doc(uid)
              .get();

          if (profileDoc.exists) {
            newBatch.add({
              ...profileDoc.data()!, 
              ...pointer, 
              'id': uid, 
              'currentSiteId': siteId
            });
          }
        } catch (_) {}
      }

      if (refresh) {
        employees.assignAll(newBatch);
      } else {
        employees.addAll(newBatch);
      }
      
      _applyFilters();

    } catch (e) {
      debugPrint("Error employees: $e");
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ---------------------------------------------------------
  // 3. FETCH ADMINS
  // ---------------------------------------------------------
  void loadAdmins() async {
    try {
      final loginCtrl = Get.find<LoginController>();
      String companyId = loginCtrl.companyId.value;
      String myRole = loginCtrl.userRole.value;
      String mySiteId = loginCtrl.managedSiteId.value;

      Query query = _db.collection('adminusers')
          .where('companyId', isEqualTo: companyId);

      if (myRole == "Branch Manager") {
        query = query.where('siteId', isEqualTo: mySiteId);
      }

      var snap = await query.get();
      var loadedAdmins = snap.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['siteId'] != null) {
          var s = _siteMap.firstWhereOrNull((s) => s['id'] == data['siteId']);
          data['siteName'] = s?['name'] ?? "All Sites";
        } else {
          data['siteName'] = "All Sites";
        }
        return data;
      }).toList();

      if (myRole == "Branch Manager") {
        loadedAdmins.removeWhere((a) => a['role'] == "Super Admin");
      }

      admins.assignAll(loadedAdmins);

    } catch (e) {
      debugPrint("Error loading admins: $e");
    }
  }

  // ---------------------------------------------------------
  // 4. MANAGEMENT ACTIONS (Update / Invite / Delete)
  // ---------------------------------------------------------
  
  // A. UPDATE EMPLOYEE (Handles Office Moves)
  Future<void> updateUser(String uid, String currentSiteId, String newName, String newRole, String newSiteName) async {
    try {
      isLoading.value = true;
      Get.back(); // Close Dialog

      String companyId = Get.find<LoginController>().companyId.value;

      // Resolve New Site ID
      var siteObj = _siteMap.firstWhere(
        (s) => s['name'] == newSiteName, 
        orElse: () => {'id': ''}
      );
      String newSiteId = siteObj['id']!;

      if (newSiteId.isEmpty) throw "Invalid Office Selected";

      // CASE 1: Moving Offices
      if (newSiteId != currentSiteId) {
        var oldRef = _db.collection('users').doc(companyId).collection('sites').doc(currentSiteId).collection('users').doc(uid);
        var oldDoc = await oldRef.get();
        
        if(oldDoc.exists) {
          var userData = oldDoc.data()!;
          userData['name'] = newName;
          userData['role'] = newRole;
          userData['siteId'] = newSiteId;
          userData['site'] = newSiteName;
          userData['department'] = newSiteName;

          // Write New
          await _db.collection('users')
              .doc(companyId).collection('sites').doc(newSiteId).collection('users').doc(uid)
              .set(userData);

          // Update Pointer
          await _db.collection('allusers').doc(uid).update({'siteId': newSiteId});

          // Delete Old
          await oldRef.delete();
        }
      } 
      // CASE 2: Same Office
      else {
        await _db.collection('users')
            .doc(companyId).collection('sites').doc(currentSiteId).collection('users').doc(uid)
            .update({'name': newName, 'role': newRole});
      }

      Get.snackbar("Success", "User profile updated", backgroundColor: Colors.green, colorText: Colors.white);
      loadEmployees(refresh: true);

    } catch (e) {
      Get.snackbar("Error", "Update failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // B. INVITE ADMIN
  Future<void> inviteAdminUser({
    required String name,
    required String email,
    required String role,
    required String phone,
    String? siteId,
  }) async {
    try {
      isLoading.value = true;
      String companyId = Get.find<LoginController>().companyId.value;
      String activationCode = (100000 + Random().nextInt(900000)).toString();

      // Resolve Site ID if siteId passed is actually a name (UI quirk)
      String finalSiteId = siteId ?? "";
      if (siteId != null && siteId.isNotEmpty) {
         var found = _siteMap.firstWhereOrNull((s) => s['name'] == siteId || s['id'] == siteId);
         if(found != null) finalSiteId = found['id']!;
      }

      DocumentReference ref = _db.collection('adminusers').doc();
      
      await ref.set({
        'tempId': ref.id,
        'companyId': companyId,
        'adminname': name,
        'email': email.trim(),
        'admincontact': phone,
        'role': role,
        'siteId': finalSiteId,
        'isSuperAdmin': role == "Super Admin",
        'status': false,
        'isActivationPending': true,
        'activationCode': activationCode,
        'dateinvited': FieldValue.serverTimestamp(),
      });

      Get.back();
      
      Get.defaultDialog(
        title: "Invitation Created",
        content: Column(
          children: [
            const Text("Share this Activation Code with the user:", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SelectableText(
              activationCode, 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5, color: Colors.blue)
            ),
            const SizedBox(height: 20),
            const Text("They will need this code and their email to activate their account.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        textConfirm: "Done",
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );

      loadAdmins(); 

    } catch (e) {
      Get.snackbar("Error", "Invite failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // C. DELETE ADMIN
  Future<void> deleteAdmin(String uid, bool isPending) async {
    try {
      if (isPending) {
        await _db.collection('adminusers').doc(uid).delete();
      } else {
        await FirebaseFunctions.instance.httpsCallable('deleteUserAccount').call({'uid': uid});
        await _db.collection('adminusers').doc(uid).delete();
      }
      
      admins.removeWhere((a) => a['id'] == uid);
      Get.snackbar("Deleted", "User removed.");
    } catch (e) {
      Get.snackbar("Error", "Could not delete: $e");
    }
  }

  // D. DELETE EMPLOYEE
  Future<void> deleteUser(String uid, String siteId) async {
     try {
       String cid = Get.find<LoginController>().companyId.value;
       await FirebaseFunctions.instance.httpsCallable('deleteUserAccount').call({'uid': uid});
       
       await _db.collection('users').doc(cid).collection('sites').doc(siteId).collection('users').doc(uid).delete();
       await _db.collection('allusers').doc(uid).delete();
       
       employees.removeWhere((e) => e['id'] == uid);
       _applyFilters();
       Get.snackbar("Success", "Employee deleted");
     } catch(e) { Get.snackbar("Error", "Failed: $e"); }
  } 
  
  // E. TOGGLE STATUS
  Future<void> toggleStatus(String uid, String siteId, bool currentStatus) async {
     try {
       String cid = Get.find<LoginController>().companyId.value;
       await _db.collection('users').doc(cid).collection('sites').doc(siteId).collection('users').doc(uid).update({'isActive': !currentStatus});
       await _db.collection('allusers').doc(uid).update({'isActive': !currentStatus});
       
       var index = employees.indexWhere((e) => e['id'] == uid);
       if(index != -1) employees[index]['isActive'] = !currentStatus;
       _applyFilters();
     } catch(e) { Get.snackbar("Error", "Failed"); }
  }

  // ---------------------------------------------------------
  // 5. HELPER: FILTERING
  // ---------------------------------------------------------
  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(employees);
    if (selectedSiteFilter.value != "All Offices") {
      temp = temp.where((u) => u['department'] == selectedSiteFilter.value || u['site'] == selectedSiteFilter.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      String q = searchQuery.value.toLowerCase();
      temp = temp.where((u) => u['name'].toString().toLowerCase().contains(q)).toList();
    }
    filteredEmployees.assignAll(temp);
  }

  void onSearchChanged(String val) { searchQuery.value = val; _applyFilters(); }
  void onFilterChanged(String? val) { if (val != null) { selectedSiteFilter.value = val; _applyFilters(); } }
}