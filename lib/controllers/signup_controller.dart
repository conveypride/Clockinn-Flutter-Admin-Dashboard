import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupController extends GetxController {
  // UI Controllers
  final nameCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // State
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 🔑 LOGIC: GENERATE SHORT COMPANY ID
  // ===========================================================================
  String _generateCompanyId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 1, 0 to avoid confusion
    Random rnd = Random();
    
    // Generate a 6-character code (e.g., "TXM-492")
    String code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    
    // Insert a dash for readability (Optional, removes it if you prefer plain text)
    return "${code.substring(0, 3)}-${code.substring(3, 6)}";
  }

  // ===========================================================================
  // 🚀 ACTION: SIGN UP
  // ===========================================================================
  void signup() async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;

      // 1. GENERATE UNIQUE COMPANY ID (Collision Check)
      String newCompanyId = "";
      bool isUnique = false;
      
      // Loop until we find a unique ID (Usually happens on 1st try)
      while (!isUnique) {
        newCompanyId = _generateCompanyId();
        final docSnap = await _db.collection('companies').doc(newCompanyId).get();
        if (!docSnap.exists) isUnique = true;
      }

      // 2. CREATE AUTH USER
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        
        // Calculate Trial (30 Days)
        DateTime now = DateTime.now();
        DateTime trialEndDate = now.add(const Duration(days: 30));

        // 3. CREATE COMPANY DOCUMENT (Using Short ID)
        await _db.collection('companies').doc(newCompanyId).set({
          'companyId': newCompanyId, // Redundant but useful for queries
          'name': companyNameCtrl.text.trim(),
          'companyscription': 'active', // Active during trial
          'isTrial': true,
          'trialEndsAt': Timestamp.fromDate(trialEndDate),
          'billing_cycle': 'monthly',
          'companyType': 'private',
          'amount': '0',
          'companySize': 1, 
          'hasExceededNumOfEmployees': false, // Critical for mobile checks
          'countOperationSites': 0, // Forces setup flow
          'locationVerificationEnabled': true,
          'department': ['none'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. CREATE ADMIN USER PROFILE
        await _db.collection('adminusers').doc(uid).set({
          'uid': uid,
          'adminname': nameCtrl.text.trim(),
          'admincontact': phoneCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'companyname': companyNameCtrl.text.trim(),
          'companyId': newCompanyId, // Links Admin to the Company
          'isSuperAdmin': true,
          'status': true,
          'role': 'Super Admin',
          'datejoined': FieldValue.serverTimestamp(),
        });

        // 5. SUCCESS & REDIRECT
        Get.offAllNamed('/setup-office'); 
        
        Get.snackbar(
          "Account Created", 
          "Your Company ID is: $newCompanyId. Please set up your first office.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.TOP,
        );
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Signup Failed", e.message ?? "An error occurred", 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "System error: $e", 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (nameCtrl.text.isEmpty || 
        companyNameCtrl.text.isEmpty || 
        phoneCtrl.text.isEmpty || 
        emailCtrl.text.isEmpty || 
        passwordCtrl.text.isEmpty) {
      Get.snackbar("Missing Fields", "Please fill in all fields.", 
        backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }
    if (passwordCtrl.text.length < 6) {
      Get.snackbar("Weak Password", "Password must be at least 6 characters.", 
        backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }
    return true;
  }

  void togglePassword() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}