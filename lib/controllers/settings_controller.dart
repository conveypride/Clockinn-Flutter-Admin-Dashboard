import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  var isLoading = true.obs;

  // --- TAB 1: COMPANY PROFILE ---
  final companyNameCtrl = TextEditingController();
  final companyEmailCtrl = TextEditingController();
  final companyPhoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  var logoUrl = "https://via.placeholder.com/150".obs; // Default placeholder

  // --- TAB 2: ATTENDANCE RULES ---
  var lateToleranceMinutes = 15.0.obs; // Mark late after 15 mins
  var defaultGeofenceRadius = 200.0.obs; // Default site radius in meters
  var workWeekStartsOn = "Monday".obs;

  // --- TAB 3: NOTIFICATIONS ---
  var alertOnLateArrival = true.obs;
  var alertOnNewUser = true.obs;
  var weeklyReportEmail = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  void fetchSettings() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulate Network

    // MOCK DATA (Fetch from 'companies' collection)
    companyNameCtrl.text = "LGMG Global";
    companyEmailCtrl.text = "admin@lgmg.com";
    companyPhoneCtrl.text = "0541234567";
    addressCtrl.text = "123 Independence Ave, Accra";
    
    // Simulate existing preferences
    lateToleranceMinutes.value = 10;
    alertOnNewUser.value = true;

    isLoading.value = false;
  }

  void pickLogo() {
    // In real app, use image_picker_web to select and upload to Storage
    Get.snackbar("Image Picker", "Opening file dialog...");
  }

  void saveSettings() async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    await Future.delayed(const Duration(seconds: 1)); // Simulate Save
    Get.back(); // Close Loader
    Get.snackbar("Success", "Settings saved successfully", backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
  }
}