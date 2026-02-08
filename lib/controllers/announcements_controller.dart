import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; 

class AnnouncementsController extends GetxController {
  var isLoading = true.obs;
  var isSending = false.obs;
  
  // History
  var sentAnnouncements = <Map<String, dynamic>>[].obs;
  
  // Dropdown Logic
  var targetOptions = <String>["All Employees"].obs;
  var selectedTarget = "All Employees".obs;
  
  // Internal Map for Name -> ID
  List<Map<String, String>> _siteMap = [];

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadSites();
    fetchSentHistory();
  }

  // 1. LOAD SITES (RESTRICTED)
  void _loadSites() async {
    try {
      final loginCtrl = Get.find<LoginController>();
      String cid = loginCtrl.companyId.value;
      String myRole = loginCtrl.userRole.value;
      String mySiteId = loginCtrl.managedSiteId.value;

      if (cid.isEmpty) return;

      Query query = _db.collection('operationSites')
          .doc(cid)
          .collection('sites')
          .where('status', isEqualTo: true);

      // 🔒 SECURITY: Manager only fetches their own site
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        query = query.where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      var snap = await query.get();

      _siteMap = snap.docs.map((d) => {
        'id': d.id,
        'name': d['nameofsite'].toString()
      }).toList();

      List<String> names = _siteMap.map((s) => s['name']!).toList();

      // 🔒 SECURITY: Dropdown Options
      if (myRole == "Branch Manager") {
        // Manager can ONLY see their site in dropdown
        targetOptions.assignAll(names);
        if (names.isNotEmpty) selectedTarget.value = names.first;
      } else {
        // Super Admin sees All + Specific Sites
        targetOptions.assignAll(["All Employees", ...names]);
      }
      
    } catch (e) {
      print("Error loading sites: $e");
    }
  }

  // 2. FETCH HISTORY
  void fetchSentHistory() async {
    try {
      isLoading.value = true;
      String cid = Get.find<LoginController>().companyId.value;
      if (cid.isEmpty) return;

      var snap = await _db.collection('companies')
          .doc(cid)
          .collection('sent_announcements')
          .orderBy('date', descending: true)
          .get();

      sentAnnouncements.value = snap.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Optional: Filter history client-side if you want Managers to only see their own sent items
      // For now, we allow them to see history to stay informed of company-wide announcements.

    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 3. SEND ANNOUNCEMENT (RESTRICTED)
  Future<void> sendAnnouncement(String title, String message) async {
    if (title.isEmpty || message.isEmpty) {
      Get.snackbar("Error", "Title and Message are required");
      return;
    }

    try {
      isSending.value = true;
      final loginCtrl = Get.find<LoginController>();
      String cid = loginCtrl.companyId.value;
      String senderName = loginCtrl.adminName.value;
      String myRole = loginCtrl.userRole.value;
      String mySiteId = loginCtrl.managedSiteId.value;

      // A. Create Payload
      Map<String, dynamic> payload = {
        'title': title,
        'message': message,
        'date': FieldValue.serverTimestamp(),
        'sender': senderName,
        'markAs': 'unread',
        'type': 'general',
      };

      // B. Identify Recipients
      List<String> recipientIds = [];
      String? targetSiteId; // To store in history for reference

      if (selectedTarget.value == "All Employees") {
        // 🔒 SECURITY CHECK
        if (myRole == "Branch Manager") {
           Get.snackbar("Access Denied", "Managers cannot send to All Employees.");
           isSending.value = false;
           return;
        }

        // Fetch ALL
        var usersSnap = await _db.collection('allusers')
            .where('companyId', isEqualTo: cid)
            .where('isActive', isEqualTo: true)
            .get();
        recipientIds = usersSnap.docs.map((d) => d.id).toList();
      } 
      else {
        // Specific Site Selected
        targetSiteId = _siteMap.firstWhereOrNull((s) => s['name'] == selectedTarget.value)?['id'];
        
        // 🔒 SECURITY CHECK
        if (myRole == "Branch Manager" && targetSiteId != mySiteId) {
           Get.snackbar("Access Denied", "You can only send to your managed site.");
           isSending.value = false;
           return;
        }

        if (targetSiteId != null) {
          var usersSnap = await _db.collection('allusers')
              .where('companyId', isEqualTo: cid)
              .where('siteId', isEqualTo: targetSiteId)
              .where('isActive', isEqualTo: true)
              .get();
          recipientIds = usersSnap.docs.map((d) => d.id).toList();
        }
      }

      if (recipientIds.isEmpty) {
        Get.snackbar("Warning", "No active users found in selected target.");
        isSending.value = false;
        return;
      }

      // C. Save to "Sent Items"
      await _db.collection('companies').doc(cid).collection('sent_announcements').add({
        ...payload,
        'target': selectedTarget.value,
        'targetSiteId': targetSiteId ?? "all", // Store ID for future filtering
        'recipientCount': recipientIds.length,
      });

      // D. Fan-out (Batching)
      int chunkSize = 450; 
      for (var i = 0; i < recipientIds.length; i += chunkSize) {
        WriteBatch batch = _db.batch();
        var end = (i + chunkSize < recipientIds.length) ? i + chunkSize : recipientIds.length;
        var sublist = recipientIds.sublist(i, end);

        for (var uid in sublist) {
          DocumentReference userRef = _db.collection('announcements')
              .doc(cid).collection(uid).doc();
          batch.set(userRef, payload);
        }
        await batch.commit();
      }

      Get.back();
      Get.snackbar("Success", "Sent to ${recipientIds.length} employees!", 
        backgroundColor: Colors.green, colorText: Colors.white);
      
      fetchSentHistory(); 

    } catch (e) {
      Get.snackbar("Error", "Failed to send: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteHistory(String docId) async {
    try {
      String cid = Get.find<LoginController>().companyId.value;
      await _db.collection('companies').doc(cid).collection('sent_announcements').doc(docId).delete();
      sentAnnouncements.removeWhere((a) => a['id'] == docId);
    } catch (e) {
      Get.snackbar("Error", "Could not delete");
    }
  }
}