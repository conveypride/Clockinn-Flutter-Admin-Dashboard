import 'dart:async'; // Required for Future.microtask
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'login_controller.dart'; 

class SettingsController extends GetxController {
  var isLoading = true.obs;

  // --- COMPANY PROFILE DATA ---
  final companyNameCtrl = TextEditingController();
  final companyEmailCtrl = TextEditingController();
  final companyPhoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  var logoUrl = "".obs; 

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    _checkAccessAndLoad();
  }

  void _checkAccessAndLoad() {
    // 🔒 SECURITY CHECK
    if (auth.userRole.value != "Super Admin") {
      // 🛠️ FIX: Use Future.microtask to avoid "setState during build" crash
      Future.microtask(() {
        Get.offAllNamed('/dashboard');
        Get.snackbar(
          "Access Denied", 
          "Only Super Admins can access Settings.", 
          backgroundColor: Colors.red, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
      });
      return;
    }
    
    fetchSettings();
  }

  void fetchSettings() async {
    isLoading.value = true;
    try {
      String cid = auth.companyId.value;
      if (cid.isEmpty) return;

      var doc = await _db.collection('companies').doc(cid).get();
      if (doc.exists) {
        var data = doc.data()!;
        
        // Profile Data
        companyNameCtrl.text = data['name'] ?? "";
        companyEmailCtrl.text = data['email'] ?? "";
        companyPhoneCtrl.text = data['phone'] ?? "";
        addressCtrl.text = data['address'] ?? "";
        logoUrl.value = data['logo'] ?? "";
      }
    } catch (e) {
      print("Error fetching settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ... (Keep pickLogo and saveSettings exactly as they are) ...
  void pickLogo() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        
        String cid = auth.companyId.value;
        Reference ref = FirebaseStorage.instance.ref().child('companyLogos/$cid/logo.jpg');
        
        Uint8List data = await image.readAsBytes();
        await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        
        String url = await ref.getDownloadURL();
        logoUrl.value = url;
        
        Get.back(); // Close Loader
      } catch (e) {
        Get.back();
        Get.snackbar("Error", "Upload failed: $e");
      }
    }
  }

  void saveSettings() async {
    isLoading.value = true;
    try {
      String cid = auth.companyId.value;
      
      await _db.collection('companies').doc(cid).set({
        // Profile Only
        'name': companyNameCtrl.text.trim(),
        'email': companyEmailCtrl.text.trim(),
        'phone': companyPhoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'logo': logoUrl.value,
      }, SetOptions(merge: true));

      Get.snackbar("Success", "Company profile saved", 
        backgroundColor: Colors.green, colorText: Colors.white);
        
    } catch (e) {
      Get.snackbar("Error", "Could not save settings: $e", 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}