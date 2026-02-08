import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_controller.dart'; 

class SubscriptionController extends GetxController {
  var isLoading = true.obs;
  
  // --- STATE ---
  var employeeCount = 0.obs; 
  var isYearly = false.obs; 
  var nextBillingDate = DateTime.now().add(const Duration(days: 30)).obs;
  var status = "Active".obs; 

  // --- PRICING ---
  final double baseRatePerEmployee = 30.00;
  final double discountRate = 0.80; // 20% Off

  // --- COMPUTED VALUES ---
  double get pricePerUserDisplay {
    if (isYearly.value) {
      return baseRatePerEmployee * discountRate;
    }
    return baseRatePerEmployee;
  }

  double get standardPlanCost {
    double monthlyTotal = employeeCount.value * baseRatePerEmployee;
    if (isYearly.value) {
      return (monthlyTotal * 12) * discountRate;
    }
    return monthlyTotal;
  }

  double get yearlySavings {
    double regularYearly = (employeeCount.value * baseRatePerEmployee) * 12;
    double discountedYearly = regularYearly * discountRate;
    return regularYearly - discountedYearly;
  }

  // --- ARREARS LOGIC ---
  int get monthsOverdue {
    DateTime now = DateTime.now();
    if (nextBillingDate.value.isAfter(now)) return 0; // Not overdue

    int daysLate = now.difference(nextBillingDate.value).inDays;
    if (daysLate <= 0) return 0;
    return (daysLate / 30).ceil();
  }

  double get arrearsCost {
    if (monthsOverdue == 0) return 0.0;
    return (employeeCount.value * baseRatePerEmployee) * monthsOverdue;
  }

  double get totalDueNow {
    return arrearsCost + standardPlanCost;
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
  // 🛠️ FIX: Wait for the build to finish before checking access/navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessAndLoad();
    });
  }

  void _checkAccessAndLoad() {
    if (auth.userRole.value != "Super Admin") {
      Get.offAllNamed('/dashboard');
      Get.snackbar("Access Denied", "Only Super Admins can manage billing.");
      return;
    }
    fetchSubscriptionData();
  }

  void fetchSubscriptionData() async {
    isLoading.value = true;
    try {
      String cid = auth.companyId.value;
      if (cid.isEmpty) return;

      var doc = await _db.collection('companies').doc(cid).get();
      if (doc.exists) {
        var data = doc.data()!;
        // Load their PREFERRED cycle, but user can change it in UI
        isYearly.value = data['isYearly'] ?? false; 
        status.value = data['subscriptionStatus'] ?? "Active";
        
        if (data['nextBillingDate'] != null) {
          nextBillingDate.value = (data['nextBillingDate'] as Timestamp).toDate();
        }
      }

      var empSnap = await _db.collection('allusers')
          .where('companyId', isEqualTo: cid)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      
      employeeCount.value = empSnap.count ?? 1;
      
    } catch (e) {
      print("Error subscription: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // UI calls this when toggling the switch
  void toggleBillingCycle(bool value) {
    isYearly.value = value;
  }

  void updateSubscription() async {
    if (employeeCount.value <= 0) {
      Get.snackbar("Error", "You need at least 1 employee to subscribe.");
      return;
    }

    Get.defaultDialog(
      title: "Confirm Update",
      content: Obx(() {
        bool hasArrears = monthsOverdue > 0;
        bool isUpgrade = isYearly.value; // If they selected Yearly
        
        return Column(
          children: [
            Text("Switching to: ${isUpgrade ? 'Yearly (Best Value)' : 'Monthly'}"),
            if (isUpgrade)
               Text("You save GHC ${NumberFormat("#,##0").format(yearlySavings)}/year", style: const TextStyle(color: Colors.green, fontSize: 12)),
            
            const SizedBox(height: 15),

            if (hasArrears) ...[
              Text("Past Due: $monthsOverdue Months", style: const TextStyle(color: Colors.red)),
              const Divider(),
            ],

            const Text("Total To Pay Now:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "GHC ${NumberFormat("#,##0.00").format(totalDueNow)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue),
            ),
          ],
        );
      }),
      textConfirm: "Pay & Update",
      textCancel: "Cancel",
      onConfirm: () async {
        Get.back(); 
        _initiatePaystack();
      }
    );
  }

  void _initiatePaystack() async {
    isLoading.value = true;
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('initializePaystack');
      final result = await callable.call({
        'email': auth.userEmail.value,
        'amount': (totalDueNow * 100).toInt(), 
      });

      String url = result.data['url'];
      String reference = result.data['reference'];

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _showVerificationDialog(reference);
      }
    } catch (e) {
      Get.snackbar("Error", "Payment Init Failed: $e");
      isLoading.value = false;
    }
  }

  void _showVerificationDialog(String reference) {
    Get.defaultDialog(
      title: "Verifying Payment",
      content: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 15),
          Text("Please complete payment in the browser..."),
        ],
      ),
      barrierDismissible: false,
    );

    _pollPaymentStatus(reference);
  }

  void _pollPaymentStatus(String reference) async {
    int attempts = 0;
    bool success = false;

    while (attempts < 10 && !success) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('verifyPaystackPayment')
            .call({'reference': reference});  
        success = result.data['success'] == true;
      } catch (e) {
        print("Polling error: $e");
      }
      if (success) break;
      attempts++;
    }

    Get.back(); 

    if (success) {
      _activateSubscription();
    } else {
      Get.snackbar("Payment Pending", "Could not verify yet. It will update shortly if successful.", 
        backgroundColor: Colors.orange, colorText: Colors.white);
      isLoading.value = false;
    }
  }

  // 🛑 SMART ACTIVATION LOGIC
  void _activateSubscription() async {
    try {
      String cid = auth.companyId.value;
      DateTime now = DateTime.now();
      
      // Determine Start Date:
      // If they are expired/late: Start from NOW.
      // If they are active and renewing early: Start from their FUTURE billing date.
      DateTime startDate = nextBillingDate.value.isAfter(now) 
          ? nextBillingDate.value 
          : now;

      // Add the new duration (30 days or 365 days)
      DateTime newExpiry = startDate.add(Duration(days: isYearly.value ? 365 : 30));

      await _db.collection('companies').doc(cid).update({
        'isTrial': false,
        'subscriptionStatus': 'Active',
        'isYearly': isYearly.value, // Saves their new preference
        'nextBillingDate': newExpiry,
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'lastPaymentAmount': totalDueNow,
      });

      nextBillingDate.value = newExpiry;
      status.value = 'Active';
      isLoading.value = false;

      Get.snackbar("Success", "Subscription Updated!", 
        backgroundColor: Colors.green, colorText: Colors.white);
        
    } catch (e) {
      Get.snackbar("Error", "Database update failed: $e");
      isLoading.value = false;
    }
  }
}