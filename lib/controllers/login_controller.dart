import 'dart:async'; // Required for Future.microtask
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginController extends GetxController {
  // --- UI CONTROLLERS ---
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  
  // --- STATE OBSERVABLES ---
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  // --- SESSION DATA ---
  var adminName = "".obs;
  var companyId = "".obs;
  var userEmail = "".obs;
  var userRole = "".obs;        // "Super Admin" or "Branch Manager"
  var managedSiteId = "".obs;   // If Manager, restricts them to this site
  
  // GLOBAL SUBSCRIPTION STATUS
  var isSubscriptionActive = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    // Listen for Auth Changes (Auto-Login / Session Restore)
    _auth.authStateChanges().listen((User? user) {
      if (user != null && companyId.value.isEmpty) {
        _restoreSession(user.uid);
      }
    });
  }

  // ===========================================================================
  // 1. SESSION RESTORE (Handle Page Refresh)
  // ===========================================================================
  void _restoreSession(String uid) async {
    try {
      DocumentSnapshot adminDoc = await _db.collection('adminusers').doc(uid).get();
      if (adminDoc.exists) {
        var data = adminDoc.data() as Map<String, dynamic>;
        _setSessionData(data);
        
        // 🛑 Run the subscription check on page refresh
        await checkSubscriptionStatus(data['companyId'], data['role']);

        // 🚀 FIX: Navigate to Dashboard if session is valid and active
        // This was missing! It restored data but left you on the Login screen.
        if (isSubscriptionActive.value) {
           // We use microtask to prevent build errors during the redirect
           Future.microtask(() {
             // Optional: Check current route to avoid redirecting if already there
             if (Get.currentRoute == '/login' || Get.currentRoute == '/') {
               Get.offAllNamed('/dashboard');
             }
           });
        }
      }
    } catch (e) {
      print("Session Restore Failed: $e");
    }
  }

  // ===========================================================================
  // 2. CHECK SUBSCRIPTION STATUS (The Gatekeeper)
  // ===========================================================================
  Future<void> checkSubscriptionStatus(String companyId, String role) async {
    // Bypass check for lower-level roles if necessary
    if (role != "Super Admin" && role != "Branch Manager") {
      isSubscriptionActive.value = true;
      return;
    }

    try {
      DocumentSnapshot compDoc = await _db.collection('companies').doc(companyId).get();
      var compData = compDoc.data() as Map<String, dynamic>;

      Timestamp? trialEndTs = compData['trialEndsAt'];
      Timestamp? nextBillTs = compData['nextBillingDate'];
      String subStatus = compData['subscriptionStatus'] ?? 'inactive';
      bool isTrial = compData['isTrial'] ?? false;
      DateTime now = DateTime.now();

      bool allowed = false;

      // Logic: Is Trial Valid OR Subscription Valid?
      if (isTrial && trialEndTs != null && now.isBefore(trialEndTs.toDate())) {
        allowed = true; // Trial is active
      } else if (subStatus == 'Active' && nextBillTs != null && now.isBefore(nextBillTs.toDate())) {
        allowed = true; // Paid subscription is active
      }

      // Update Global State
      isSubscriptionActive.value = allowed;

      // ENFORCEMENT
      if (!allowed) {
        if (role == "Super Admin") {
           // Admin: Send to payment page
           if (Get.currentRoute != '/subscription') {
             // 🛠️ FIX: Use microtask to avoid build collisions
             Future.microtask(() => Get.offAllNamed('/subscription'));
             
             Get.snackbar("Plan Expired", "Please renew your subscription to continue.", 
               backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 5));
           }
        } else {
           // Manager: Kick out
           // 🛠️ FIX: Use microtask to avoid build collisions
           Future.microtask(() => logout());
           
           Get.snackbar("Access Denied", "Company subscription has expired. Contact Admin.", 
               backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      print("Subscription Check Error: $e");
      isSubscriptionActive.value = false; // Fail safe
    }
  }

  // ===========================================================================
  // 3. LOGIN LOGIC
  // ===========================================================================
  void login() async {
    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      Get.snackbar("Error", "Please enter email and password", 
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      
      // Authenticate
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        
        // Fetch Admin Profile
        DocumentSnapshot adminDoc = await _db.collection('adminusers').doc(uid).get();

        if (adminDoc.exists) {
          var data = adminDoc.data() as Map<String, dynamic>;
          
          if (data['status'] == false) throw "Account is disabled.";
          
          String role = data['role'] ?? 'Employee';
          if (role != "Super Admin" && role != "Branch Manager" && role != "Secretary") {
             await _auth.signOut();
             throw "Access Denied: Only Management Team allowed.";
          }

          _setSessionData(data);
          
          // 🛑 Check Subscription
          await checkSubscriptionStatus(data['companyId'], role);

          // Redirect ONLY if Subscription is Active
          if (isSubscriptionActive.value) {
            Get.offAllNamed('/dashboard');
          }
          // If inactive, checkSubscriptionStatus handles the redirect
          
        } else {
          await _auth.signOut();
          throw "Access Denied. Not an authorized admin account.";
        }
      }
    } catch (e) {
      Get.snackbar("Login Failed", e.toString(), 
        backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // 4. HELPERS & LOGOUT
  // ===========================================================================
  
  void _setSessionData(Map<String, dynamic> data) {
    adminName.value = data['adminname'] ?? "Admin";
    userEmail.value = data['email'] ?? "";
    companyId.value = data['companyId'] ?? "";
    userRole.value = data['role'] ?? "Super Admin";
    managedSiteId.value = data['siteId'] ?? ""; 
  }

  void logout() async {
    await _auth.signOut();
    
    // Reset variables
    companyId.value = "";
    adminName.value = "";
    userEmail.value = "";
    userRole.value = "";
    managedSiteId.value = "";
    isSubscriptionActive.value = false;

    // 🛠️ FIX: Use microtask to avoid "setState during build" error
    Future.microtask(() {
      Get.offAllNamed('/login');
    });
  }

  void togglePassword() => isPasswordVisible.value = !isPasswordVisible.value;
}