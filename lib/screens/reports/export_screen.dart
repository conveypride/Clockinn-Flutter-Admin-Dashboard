import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/export_controller.dart';
import '../../controllers/login_controller.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExportController());
    final auth = Get.find<LoginController>();
    bool isSuperAdmin = auth.userRole.value == "Super Admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("Export Reports", style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Generate Payroll & Attendance Reports", style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[700])),
                const SizedBox(height: 30),

                // 1. DATE RANGE
                _buildSectionLabel("Select Date Range"),
                const SizedBox(height: 10),
                Obx(() => InkWell(
                  onTap: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: DateTimeRange(start: controller.startDate.value, end: controller.endDate.value),
                      builder: (context, child) {
                        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF10B981))), child: child!);
                      },
                    );
                    if (picked != null) {
                      controller.startDate.value = picked.start;
                      controller.endDate.value = picked.end;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${DateFormat('MMM dd, yyyy').format(controller.startDate.value)}  -  ${DateFormat('MMM dd, yyyy').format(controller.endDate.value)}", style: GoogleFonts.inter(fontSize: 15)),
                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 24),

                // 2. SITE SELECTION
                if (isSuperAdmin) ...[
                  _buildSectionLabel("Filter by Office"),
                  const SizedBox(height: 10),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: controller.sites.any((s) => s['id'] == controller.selectedSiteId.value) ? controller.selectedSiteId.value : null,
                        items: controller.sites.map((site) => DropdownMenuItem(value: site['id'], child: Text(site['name']!))).toList(),
                        onChanged: (val) => controller.onSiteChanged(val),
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],

                // 3. USER SELECTION
                _buildSectionLabel("Filter by Employee"),
                const SizedBox(height: 10),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.users.any((u) => u['id'] == controller.selectedUserId.value) ? controller.selectedUserId.value : "All",
                      items: controller.users.map((user) => DropdownMenuItem(value: user['id'], child: Text(user['name']!))).toList(),
                      onChanged: (val) => controller.selectedUserId.value = val!,
                    ),
                  ),
                )),

                const SizedBox(height: 40),

                // 4. ACTION BUTTONS
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      // EXCEL BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: controller.generateAttendanceReport, // Calls the Excel function
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.table_view),
                          label: const Text("Download Excel Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // PDF BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: controller.generatePdfSummary, // Calls the NEW PDF function
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444), // Red for PDF
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Download PDF Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87));
  }
}