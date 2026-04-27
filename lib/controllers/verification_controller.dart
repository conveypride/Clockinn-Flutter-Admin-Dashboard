import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; 

class VerificationController extends GetxController {
  var isLoading = true.obs;
  var waitingUsers = <Map<String, dynamic>>[].obs;
  
  var availableSites = <String>[].obs; 
  List<Map<String, String>> _siteMap = []; 
  var selectedSite = "".obs; 

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void fetchData() async {
    isLoading.value = true;
    try {
      final loginCtrl = Get.find<LoginController>();
      String companyId = loginCtrl.companyId.value;
      String mySiteId = loginCtrl.managedSiteId.value;
      String myRole = loginCtrl.userRole.value;

      if (companyId.isEmpty) {
        isLoading.value = false;
        return;
      }

      // -------------------------------------------------------------
      // 1. FETCH SITES (Restricted)
      // -------------------------------------------------------------
      Query sitesQuery = _db.collection('operationSites')
          .doc(companyId)
          .collection('sites')
          .where('status', isEqualTo: true);
 print("Seeing profile for myrole: $myRole and companyId $companyId");
      // 🔒 SECURITY: If Manager, restrict to their site
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        sitesQuery = sitesQuery.where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      var sitesSnap = await sitesQuery.get();

      _siteMap = sitesSnap.docs.map((doc) => {
        'id': doc.id,
        'name': doc['nameofsite'].toString()
      }).toList();

      availableSites.value = _siteMap.map((s) => s['name']!).toList();
      if (availableSites.isNotEmpty) selectedSite.value = availableSites.first;

      // -------------------------------------------------------------
      // 2. FETCH USERS (Restricted Join)
      // -------------------------------------------------------------
      try {
        Query usersQuery = _db.collection('allusers')
            .where('companyId', isEqualTo: companyId)
            .where('isActive', isEqualTo: false); // Unverified Only

        // 🔒 SECURITY: Restrict to site
        if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
          usersQuery = usersQuery.where('siteId', isEqualTo: mySiteId);
        }

        var pointersSnap = await usersQuery.get();
        print("Found ${pointersSnap.docs.length} unverified users matching criteria.");
        List<Map<String, dynamic>> fullUserList = [];

        for (var doc in pointersSnap.docs) {
          var pointerData = doc.data() as Map<String, dynamic>;
          String uid = doc.id;
          String siteId = pointerData['siteId'] ?? "";
 
          // Double check for client-side safety
          if (myRole == "Branch Manager" && siteId != mySiteId) continue;
          if (siteId.isEmpty) continue;

          try {
            print("Fetching profile for UID: $uid at Site: $siteId, and companyId $companyId");
            var profileDoc = await _db.collection('users')
                .doc(companyId)
                .collection('sites')
                .doc(siteId)
                .collection('users')
                .doc(uid)
                .get();

            if (profileDoc.exists) {
              fullUserList.add({
                ...profileDoc.data()!,
                ...pointerData,
                'id': uid,
                'currentSiteId': siteId
              });
            }
          } catch (_) {}
        }

        waitingUsers.value = fullUserList;

      } catch (e) {
        debugPrint("Error fetching users: $e");
      }

    } catch (e) {
      debugPrint("General Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------
  // ✅ APPROVE USER
  // ---------------------------------------------------------
  Future<void> approveUser(String uid, String assignedSiteName) async {
    try {
      String companyId = Get.find<LoginController>().companyId.value;

      // 1. Find New Site ID from Dropdown Name
      var siteObj = _siteMap.firstWhere(
        (element) => element['name'] == assignedSiteName, 
        orElse: () => {'id': ''}
      );
      String newSiteId = siteObj['id']!;

      if (newSiteId.isEmpty) {
        Get.snackbar("Error", "Invalid site selected");
        return;
      }

      // 2. Find Current Info from Local List
      var localUser = waitingUsers.firstWhere((u) => u['id'] == uid);
      String currentSiteId = localUser['currentSiteId'];

      if (currentSiteId.isEmpty) {
         Get.snackbar("Error", "Could not locate user data.");
         return;
      }

      // 3. Case A: Site NOT Changed (Simple Update)
      if (newSiteId == currentSiteId) {
        // Update Nested Doc
        await _db.collection('users')
            .doc(companyId)
            .collection('sites')
            .doc(currentSiteId)
            .collection('users')
            .doc(uid)
            .update({
              'isActive': true,
              'isVerified': true, 
              'dateVerified': FieldValue.serverTimestamp(),
            });

        // Update AllUsers Doc
        await _db.collection('allusers').doc(uid).update({
          'isActive': true, 
          'isVerified': true // Optional, consistency
        });
      } 
      // 4. Case B: Site CHANGED (Move Document)
      else {
        // A. Read Old Nested Doc
        DocumentReference oldRef = _db.collection('users')
            .doc(companyId)
            .collection('sites')
            .doc(currentSiteId)
            .collection('users')
            .doc(uid);

        DocumentSnapshot oldDoc = await oldRef.get();
        if (!oldDoc.exists) throw "User detailed profile not found";
        Map<String, dynamic> userData = oldDoc.data() as Map<String, dynamic>;

        // B. Update Data fields
        userData['isActive'] = true;
        userData['isVerified'] = true;
        userData['siteId'] = newSiteId;
        userData['site'] = assignedSiteName; 
        userData['department'] = assignedSiteName; 
        userData['dateVerified'] = FieldValue.serverTimestamp();

        // C. Write to NEW Nested Location
        await _db.collection('users')
            .doc(companyId)
            .collection('sites')
            .doc(newSiteId)
            .collection('users')
            .doc(uid)
            .set(userData);

        // D. Update AllUsers Pointer
        await _db.collection('allusers').doc(uid).update({
          'siteId': newSiteId, 
          'isActive': true, 
          'isVerified': true
        });

        // E. Delete Old Nested Doc
        await oldRef.delete();
      }

      // 5. Cleanup UI
      waitingUsers.removeWhere((user) => user['id'] == uid);
      Get.back();
      Get.snackbar("Approved", "$assignedSiteName assigned successfully!", 
        backgroundColor: const Color(0xFF10B981), colorText: const Color(0xFFFFFFFF));

    } catch (e) {
      Get.snackbar("Error", "Approval failed: $e",
        backgroundColor: const Color(0xFFFF5252), colorText: const Color(0xFFFFFFFF));
    }
  }

 // ---------------------------------------------------------
  // ❌ REJECT USER (Delete from Auth + Firestore)
  // ---------------------------------------------------------
  Future<void> rejectUser(String uid) async {
    try {
      isLoading.value = true; // Show loading indicator
      
      // 1. CALL CLOUD FUNCTION TO DELETE FROM AUTH
      // This deletes the login credentials (email/pass)
      try {
        await FirebaseFunctions.instance
            .httpsCallable('deleteUserAccount') // Must match the function name exactly
            .call({'uid': uid});
      } catch (e) {
        print("Cloud Function Error: $e");
        // We continue execution even if Auth delete fails, 
        // to ensure we at least clean up the Firestore data.
      }

      // 2. DELETE FROM FIRESTORE (Your existing logic)
      String companyId = Get.find<LoginController>().companyId.value;
      
      var localUser = waitingUsers.firstWhereOrNull((u) => u['id'] == uid);
      
      if (localUser != null) {
        String currentSiteId = localUser['currentSiteId'] ?? "";

        // Delete Nested Profile
        if (currentSiteId.isNotEmpty) {
          await _db.collection('users')
              .doc(companyId)
              .collection('sites')
              .doc(currentSiteId)
              .collection('users')
              .doc(uid)
              .delete();
        }

        // Delete AllUsers Pointer
        await _db.collection('allusers').doc(uid).delete();
        
        // Remove from local list
        waitingUsers.removeWhere((user) => user['id'] == uid);
      }

      Get.snackbar("Rejected", "User account and data removed permanently",
          backgroundColor: Colors.red, colorText: Colors.white);
          
    } catch (e) {
      Get.snackbar("Error", "Could not reject user: $e");
    } finally {
      isLoading.value = false;
    }
  }
}