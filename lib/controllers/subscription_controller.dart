import 'package:get/get.dart';

class SubscriptionController extends GetxController {
  var isLoading = true.obs;
  
  // STATE
  var isYearly = false.obs; // Toggle for Monthly/Yearly pricing
  var currentPlanId = "basic_monthly".obs; // The plan the company currently has
  
  // DATA
  var billingHistory = <Map<String, dynamic>>[].obs;
  
  // PRICING CONFIG (You can fetch this from Firebase Remote Config later)
  final plans = [
    {
      "id": "basic",
      "name": "Starter",
      "monthlyPrice": 20,
      "yearlyPrice": 200, // Save $40
      "features": ["Up to 10 Employees", "1 Operation Site", "Basic Reporting", "Email Support"],
      "color": 0xFF2196F3 // Blue
    },
    {
      "id": "pro",
      "name": "Professional",
      "monthlyPrice": 50,
      "yearlyPrice": 500, // Save $100
      "features": ["Up to 50 Employees", "5 Operation Sites", "Advanced Analytics", "Priority Support", "Shift Management"],
      "color": 0xFFFF9800 // Orange
    },
    {
      "id": "enterprise",
      "name": "Enterprise",
      "monthlyPrice": 100,
      "yearlyPrice": 1000, // Save $200
      "features": ["Unlimited Employees", "Unlimited Sites", "Dedicated Account Manager", "API Access", "Custom Branding"],
      "color": 0xFF9C27B0 // Purple
    }
  ];

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionData();
  }

  void fetchSubscriptionData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); 

    // MOCK INVOICES
    billingHistory.value = [
      {"id": "INV-2024-001", "date": "2024-10-01", "amount": 20.00, "status": "Paid", "plan": "Starter Monthly"},
      {"id": "INV-2024-002", "date": "2024-09-01", "amount": 20.00, "status": "Paid", "plan": "Starter Monthly"},
      {"id": "INV-2024-003", "date": "2024-08-01", "amount": 20.00, "status": "Failed", "plan": "Starter Monthly"},
    ];
    
    isLoading.value = false;
  }

  void toggleBillingCycle(bool value) {
    isYearly.value = value;
  }

  void upgradePlan(String planId) {
    // Logic to initialize Stripe/Paystack payment
    Get.snackbar("Processing", "Redirecting to payment gateway...", duration: const Duration(seconds: 2));
    
    // Simulate success after delay
    Future.delayed(const Duration(seconds: 2), () {
      currentPlanId.value = "${planId}_${isYearly.value ? 'yearly' : 'monthly'}";
      Get.snackbar("Success", "Plan upgraded successfully!");
    });
  }
}