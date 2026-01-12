import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  // GLOBAL SESSION DATA
  var adminName = "".obs;
  var companyId = "".obs;
  var isSuperAdmin = false.obs;
  var companyStatus = "active".obs; // active, inactive, expired

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void login() async {
    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;

    try {
      isLoading.value = true;

      // 1. AUTHENTICATE
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // 2. FETCH ADMIN PROFILE (Optimized: Direct Doc Get)
        DocumentSnapshot adminDoc = await _db.collection('adminusers').doc(uid).get();

        if (adminDoc.exists) {
          Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
          
          if (data['status'] == false) throw "Account disabled.";

          // Store Session Data
          adminName.value = data['adminname'] ?? "Admin";
          companyId.value = data['companyId'] ?? "";
          isSuperAdmin.value = data['isSuperAdmin'] ?? false;

          // 3. CHECK SUBSCRIPTION STATUS (Crucial Step)
          // We fetch the COMPANY document to see if they have paid
          DocumentSnapshot companyDoc = await _db.collection('companies').doc(companyId.value).get();
          
          if (companyDoc.exists) {
            String status = companyDoc['companyscription'] ?? 'inactive';
            companyStatus.value = status;

            if (status != 'active') {
              // SUBSCRIPTION EXPIRED / INACTIVE
              Get.offAllNamed('/subscription'); // FORCE REDIRECT TO PAYMENT
              Get.snackbar(
                "Subscription Expired", 
                "Please renew your subscription to access the dashboard.", 
                backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 5)
              );
            } else {
              // ACTIVE SUBSCRIPTION
              Get.offAllNamed('/dashboard');
              Get.snackbar("Welcome", "Logged in successfully");
            }
          } else {
            throw "Company record not found.";
          }
        } else {
          await _auth.signOut();
          throw "Access Denied. Not an Admin account.";
        }
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }


  void logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  void togglePassword() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}