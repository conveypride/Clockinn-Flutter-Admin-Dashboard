import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; // Ensure this import is correct

class OfficesController extends GetxController {
  // State
  var isLoading = true.obs;
  var sites = <Map<String, dynamic>>[].obs;
  var filteredSites = <Map<String, dynamic>>[].obs; // For search functionality

  // Dependencies
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _bindSitesStream();
  }

  // ---------------------------------------------------------
  // 🔥 BIND REAL-TIME STREAM
  // ---------------------------------------------------------
   void _bindSitesStream() async {
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

      Query query = _db.collection('operationSites')
         .doc(companyId)
         .collection('sites')
         .orderBy('datejoined', descending: true);

      // 🔒 SECURITY: Restrict Query
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        // Note: orderBy might require an index with documentId, 
        // so we remove orderBy for the specific ID query or ensure index exists.
        // Queries by documentId are usually direct.
        query = _db.collection('operationSites')
           .doc(companyId)
           .collection('sites')
           .where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      query.snapshots().listen((snapshot) {
        var loadedSites = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        sites.value = loadedSites;
        filteredSites.value = List.from(loadedSites);
        isLoading.value = false;
      });

    } catch (e) {
      print("Init Error: $e");
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------
  // ⚡ INSTANT LOCAL SEARCH (No Database Calls)
  // ---------------------------------------------------------
   void filterSites(String query) {
    if (query.trim().isEmpty) {
      filteredSites.assignAll(List.from(sites)); 
    } else {
      String lowerQuery = query.toLowerCase().trim();
      var results = sites.where((site) {
        String name = (site['nameofsite'] ?? "").toString().toLowerCase();
        String location = (site['location'] ?? "").toString().toLowerCase();
        return name.contains(lowerQuery) || location.contains(lowerQuery);
      }).toList();
      filteredSites.assignAll(results);
    }
  }

  
  // ---------------------------------------------------------
  // 🗑️ DELETE SITE (SAFE)
  // ---------------------------------------------------------
  void deleteSite(String siteId) async {
// 🔒 SECURITY: Managers cannot delete sites
    final loginCtrl = Get.find<LoginController>();
    if (loginCtrl.userRole.value == "Branch Manager") {
      Get.snackbar("Access Denied", "Managers cannot delete offices.");
      return;
    }

    try {
      String companyId = "";
      
      // Try Memory
      try {
        companyId = Get.find<LoginController>().companyId.value;
      } catch (_) {}

      // Try Auth
      if (companyId.isEmpty && _auth.currentUser != null) {
         var userDoc = await _db.collection('adminusers').doc(_auth.currentUser!.uid).get();
         if(userDoc.exists) companyId = userDoc['companyId'];
      }

      if (companyId.isEmpty) {
        Get.snackbar("Error", "Session lost. Please refresh.");
        return;
      }
      
     await _db.collection('operationSites').doc(companyId).collection('sites').doc(siteId).update({'status': false});

      Get.snackbar("Success", "Office removed successfully", 
        backgroundColor: Colors.green, colorText: Colors.white);
        
    } catch (e) {
      Get.snackbar("Error", "Could not delete site");
    }
  }
}