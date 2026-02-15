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

  // --- PRICING CONFIGURATION (YEARLY BASE) ---
  // The pricing provided is per YEAR based on tiers
  double get _baseYearlyCost {
    int count = employeeCount.value;
    if (count <= 50) return 1500.0;
    if (count <= 100) return 2000.0;
    if (count <= 150) return 2500.0;
    if (count <= 200) return 3000.0;
    return 3500.0; // 201+ employees
  }

  // --- COMPUTED VALUES ---

  // 1. Calculate the cost for the *selected* plan
  double get currentPlanCost {
    if (isYearly.value) {
      // Yearly Payment: 5% Off the base yearly price
      return _baseYearlyCost * 0.95; 
    }
    
    // Monthly Payment: Yearly Price divided by 12
    return _baseYearlyCost / 12;
  }

  // 2. Calculate savings (Difference between paying monthly for a year vs paying yearly once)
  // (Monthly * 12) vs (Yearly Discounted)
  double get yearlySavings {
    double totalIfMonthly = (_baseYearlyCost / 12) * 12; // effectively _baseYearlyCost
    double totalIfYearly = _baseYearlyCost * 0.95;
    return totalIfMonthly - totalIfYearly;
  }

  // 3. Helper for UI display text
  String get currentTierName {
    int count = employeeCount.value;
    if (count <= 50) return "Starter (1-50 Emps)";
    if (count <= 100) return "Growth (51-100 Emps)";
    if (count <= 150) return "Business (101-150 Emps)";
    if (count <= 200) return "Enterprise (151-200 Emps)";
    return "Unlimited (201+ Emps)";
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
    // Arrears are calculated at the UNDISCOUNTED monthly rate
    double monthlyRate = _baseYearlyCost / 12;
    return monthlyRate * monthsOverdue;
  }

  double get totalDueNow {
    return arrearsCost + currentPlanCost;
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
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
        bool isUpgrade = isYearly.value; 
        
        return Column(
          children: [
            Text(currentTierName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Switching to: ${isUpgrade ? 'Yearly (5% Off)' : 'Monthly'}"),
            
            if (isUpgrade)
               Padding(
                 padding: const EdgeInsets.only(top: 5.0),
                 child: Text("You save GHC ${NumberFormat("#,##0").format(yearlySavings)}/year", 
                   style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
               ),
            
            const SizedBox(height: 15),

            if (hasArrears) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Past Due ($monthsOverdue mos):", style: const TextStyle(color: Colors.red)),
                  Text("GHC ${NumberFormat("#,##0").format(arrearsCost)}", style: const TextStyle(color: Colors.red)),
                ],
              ),
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total To Pay:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  "GHC ${NumberFormat("#,##0.00").format(totalDueNow)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                ),
              ],
            ),
          ],
        );
      }),
      textConfirm: "Pay & Update",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
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

  void _activateSubscription() async {
    try {
      String cid = auth.companyId.value;
      DateTime now = DateTime.now();
      
      DateTime startDate = nextBillingDate.value.isAfter(now) 
          ? nextBillingDate.value 
          : now;

      DateTime newExpiry = startDate.add(Duration(days: isYearly.value ? 365 : 30));

      await _db.collection('companies').doc(cid).update({
        'isTrial': false,
        'subscriptionStatus': 'Active',
        'isYearly': isYearly.value,
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