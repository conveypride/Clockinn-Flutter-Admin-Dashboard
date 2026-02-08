import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; 

class RolesController extends GetxController {
  var isLoading = true.obs;

  // 1. Roles Definition (No Counts)
  var roles = <Map<String, dynamic>>[
    {"name": "Super Admin", "color": 0xFF9C27B0},   
    {"name": "Branch Manager", "color": 0xFFFF9800}, 
    {"name": "Secretary", "color": 0xFFE91E63},     
    {"name": "Employee", "color": 0xFF2196F3},      
  ].obs;

  // 2. Permissions List
  final List<String> allPermissions = [
    "View Dashboard Stats",
    "Manage Operation Sites",
    "Verify New Users",
    "Manage Employees (Edit/Delete)",
    "Edit Shifts & Rosters",
    "Send Announcements",
    "View All Companies", 
    "Access Billing & Subscription",
  ];

  var rolePermissions = <String, List<dynamic>>{}.obs;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    isLoading.value = true;
    try {
      String companyId = Get.find<LoginController>().companyId.value;
      if (companyId.isEmpty) return;

      var configDoc = await _db.collection('users')
          .doc(companyId)
          .collection('config')
          .doc('roles')
          .get();

      if (configDoc.exists && configDoc.data() != null) {
        Map<String, dynamic> data = configDoc.data()!;
        Map<String, List<dynamic>> parsed = {};
        data.forEach((key, value) {
          parsed[key] = List<String>.from(value);
        });
        rolePermissions.value = parsed;
      } else {
        _applyDefaultPermissions(companyId);
      }
    } catch (e) {
      debugPrint("Error loading roles: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _applyDefaultPermissions(String companyId) async {
    // MANAGER now gets almost everything (scoped later in other controllers)
    var defaults = {
      "Super Admin": allPermissions, // Full Access
      "Branch Manager": [
        "View Dashboard Stats", 
        "Verify New Users", 
        "Manage Employees (Edit/Delete)",
        "Edit Shifts & Rosters", 
        "Send Announcements"
      ],
      "Secretary": [
        "View Dashboard Stats", "Verify New Users", "Send Announcements"
      ],
      "Employee": <String>[],
    };

    rolePermissions.value = defaults;
    
    await _db.collection('users')
        .doc(companyId)
        .collection('config')
        .doc('roles')
        .set(defaults);
  }

  void togglePermission(String role, String permission) async {
    // Lock Super Admin to prevent lockout
    if (role == "Super Admin") return; 

    List<String> currentPerms = List<String>.from(rolePermissions[role] ?? []);

    if (currentPerms.contains(permission)) {
      currentPerms.remove(permission);
    } else {
      currentPerms.add(permission);
    }
    
    rolePermissions[role] = currentPerms;
    rolePermissions.refresh();

    try {
      String companyId = Get.find<LoginController>().companyId.value;
      await _db.collection('users')
          .doc(companyId)
          .collection('config')
          .doc('roles')
          .update({ role: currentPerms });
      
      Get.snackbar("Saved", "Permissions updated");
    } catch (e) {
      Get.snackbar("Error", "Failed to save");
    }
  }
}