import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivateAccountController extends GetxController {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void activate() async {
    if (passwordCtrl.text != confirmCtrl.text) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }
    if (passwordCtrl.text.length < 6) {
      Get.snackbar("Error", "Password too weak (min 6 chars)");
      return;
    }

    try {
      isLoading.value = true;
      String email = emailCtrl.text.trim();
      String code = codeCtrl.text.trim();

      // 1. Find Pending Invite
      var query = await _db.collection('adminusers')
          .where('email', isEqualTo: email)
          .where('activationCode', isEqualTo: code)
          .where('isActivationPending', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        Get.snackbar("Error", "Invalid Email or Activation Code");
        isLoading.value = false;
        return;
      }

      DocumentSnapshot pendingDoc = query.docs.first;
      Map<String, dynamic> pendingData = pendingDoc.data() as Map<String, dynamic>;

      // 2. Create Auth Account
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: passwordCtrl.text.trim()
      );

      String newUid = cred.user!.uid;

      // 3. Create Real Admin Doc with new UID
      // 🛠️ FIX: Added SetOptions(merge: true) to allow FieldValue.delete()
      await _db.collection('adminusers').doc(newUid).set({
        ...pendingData,
        'uid': newUid,
        'status': true,
        'isActivationPending': false,
        'activationCode': FieldValue.delete(), // This removes the code from the copied data
        'activatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); 

      // 4. Delete Temporary Pending Doc
      await pendingDoc.reference.delete();

      Get.offAllNamed('/dashboard');
      Get.snackbar("Success", "Account activated! Welcome, ${pendingData['adminname']}", 
        backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      print("Error: $e");
      Get.snackbar("Error", "Activation failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}