import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/subscription_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & TOGGLE ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Subscription Plan", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("Manage your billing and plan preferences", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                    // BILLING CYCLE TOGGLE
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(50)),
                      child: Obx(() => Row(
                        children: [
                          _buildToggleOption(controller, "Monthly", false),
                          _buildToggleOption(controller, "Yearly (-20%)", true),
                        ],
                      )),
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- PRICING CARDS ---
          Obx(() {
            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
            
            // Responsive Grid
            double width = MediaQuery.of(context).size.width;
            int crossAxisCount = width > 1100 ? 3 : width > 700 ? 2 : 1;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: width > 1100 ? 0.8 : 1.2, // Adjust card height
              ),
              itemCount: controller.plans.length,
              itemBuilder: (context, index) {
                return _buildPlanCard(controller.plans[index], controller);
              },
            );
          }),

          const SizedBox(height: 40),

          // --- BILLING HISTORY ---
          Text("Billing History", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Obx(() => DataTable(
              horizontalMargin: 0,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("Invoice ID", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Download", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: controller.billingHistory.map((inv) {
                return DataRow(cells: [
                  DataCell(Text(inv['id'], style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(inv['date'])),
                  DataCell(Text("\$${inv['amount'].toStringAsFixed(2)}")),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: inv['status'] == "Paid" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(inv['status'], style: TextStyle(fontSize: 11, color: inv['status'] == "Paid" ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    )
                  ),
                  DataCell(IconButton(icon: const Icon(Icons.download, size: 18, color: Colors.grey), onPressed: (){})),
                ]);
              }).toList(),
            )),
          )
        ],
      ),
    );
  }

  // --- WIDGET: Pricing Card ---
  Widget _buildPlanCard(Map<String, dynamic> plan, SubscriptionController controller) {
    bool isYearly = controller.isYearly.value;
    int price = isYearly ? plan['yearlyPrice'] as int : plan['monthlyPrice'] as int;
    String period = isYearly ? "/year" : "/mo";
    
    // Check if this is the active plan
    String checkId = "${plan['id']}_${isYearly ? 'yearly' : 'monthly'}";
    bool isCurrent = controller.currentPlanId.value.contains(plan['id'] as String); // Simple check

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isCurrent ? Border.all(color: Color(plan['color'] as int), width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent) 
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Color(plan['color'] as int).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text("CURRENT PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(plan['color'] as int))),
            ),
            
          Text(plan['name'] as String, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$$price", style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
              Text(period, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // Features List
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: (plan['features'] as List<String>).map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Color(plan['color'] as int)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: isCurrent ? null : () => controller.upgradePlan(plan['id'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey.shade300 : Color(plan['color'] as int),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              child: Text(
                isCurrent ? "Active" : "Upgrade", 
                style: TextStyle(color: isCurrent ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: Toggle Button ---
  Widget _buildToggleOption(SubscriptionController controller, String text, bool isYearlyOption) {
    bool isActive = controller.isYearly.value == isYearlyOption;
    return GestureDetector(
      onTap: () => controller.toggleBillingCycle(isYearlyOption),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
        ),
        child: Text(
          text, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isActive ? Colors.black : Colors.grey,
            fontSize: 13
          )
        ),
      ),
    );
  }
}