import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/subscription_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Subscription & Billing", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Tiered pricing based on your team size.", style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 30),

            // Main Loading Check
            Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 900;
                  
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildCurrentPlanCard(controller),
                              const SizedBox(height: 20),
                              _buildBillingCalculator(controller),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          flex: 1,
                          child: _buildPaymentSummary(controller),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildCurrentPlanCard(controller),
                        const SizedBox(height: 20),
                        _buildBillingCalculator(controller),
                        const SizedBox(height: 30),
                        _buildPaymentSummary(controller),
                      ],
                    );
                  }
                }
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCurrentPlanCard(SubscriptionController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha:0.1)),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.verified, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentTierName, // Shows "Starter", "Growth", etc.
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  "Next billing: ${DateFormat('MMM d, yyyy').format(controller.nextBillingDate.value)}",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
            child: Text(controller.status.value.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildBillingCalculator(SubscriptionController controller) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Billing Configuration", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // BILLING CYCLE TOGGLE
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildToggleOption("Monthly", !controller.isYearly.value, () => controller.toggleBillingCycle(false))),
                Expanded(child: _buildToggleOption("Yearly (Save 5%)", controller.isYearly.value, () => controller.toggleBillingCycle(true))),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active Employees", style: GoogleFonts.inter(color: Colors.grey[600])),
              Text("${controller.employeeCount.value}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Current Tier", style: GoogleFonts.inter(color: Colors.grey[600])),
              Text(controller.currentTierName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4)] : [],
        ),
        child: Center(
          child: Text(text, 
            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blueAccent : Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(SubscriptionController controller) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Navy
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Summary", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildSummaryRow("Plan Cost", "GHC ${NumberFormat("#,##0.00").format(controller.currentPlanCost)}"),
          _buildSummaryRow("Cycle", controller.isYearly.value ? "Yearly" : "Monthly"),
          
          if (controller.monthsOverdue > 0) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha:0.5))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 5),
                        Text("Past Due: ${controller.monthsOverdue} Months", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Arrears Cost", style: TextStyle(color: Colors.white70)),
                        Text("GHC ${NumberFormat("#,##0").format(controller.arrearsCost)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              )
          ],

          const Divider(color: Colors.white12, height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Due", style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
              Flexible(
                child: Text(
                  "GHC ${NumberFormat("#,##0.00").format(controller.totalDueNow)}",
                  style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          if (controller.isYearly.value) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Center(
                child: Text(
                  "You save GHC ${NumberFormat("#,##0").format(controller.yearlySavings)}!",
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: controller.updateSubscription,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Update Subscription", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}