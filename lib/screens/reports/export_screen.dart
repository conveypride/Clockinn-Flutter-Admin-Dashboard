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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Export Reports",
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: 32),

                // Filters Card
                _buildFiltersCard(controller, isSuperAdmin),
                const SizedBox(height: 24),

                // Action Buttons
                Obx(() => _buildActionButtons(controller)),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER SECTION
  // =========================================================================
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Analytics",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Generate comprehensive reports with advanced filtering",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FILTERS CARD
  // =========================================================================
  Widget _buildFiltersCard(ExportController controller, bool isSuperAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Report Filters",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Filters Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DATE RANGE
                _buildFilterLabel("Date Range", Icons.calendar_today),
                const SizedBox(height: 12),
                Obx(() => _buildDateRangePicker(controller)),
                const SizedBox(height: 24),

                // 2. SITE SELECTION (Super Admin only)
                if (isSuperAdmin) ...[
                  _buildFilterLabel("Office Location", Icons.business),
                  const SizedBox(height: 12),
                  Obx(() => _buildSiteDropdown(controller)),
                  const SizedBox(height: 24),
                ],

                // 3. EMPLOYEE SELECTION
                _buildFilterLabel("Employee", Icons.person_outline),
                const SizedBox(height: 12),
                Obx(() => _buildEmployeeDropdown(controller)),
                const SizedBox(height: 24),

                // 4. ATTENDANCE STATUS FILTER
                _buildFilterLabel("Attendance Status", Icons.assignment_turned_in_outlined),
                const SizedBox(height: 12),
                Obx(() => _buildStatusDropdown(controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FILTER COMPONENTS
  // =========================================================================
  
  Widget _buildFilterLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(ExportController controller) {
    return InkWell(
      onTap: () async {
        DateTimeRange? picked = await showDateRangePicker(
          context: Get.context!,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: DateTimeRange(
            start: controller.startDate.value,
            end: controller.endDate.value,
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF0EA5E9),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.startDate.value = picked.start;
          controller.endDate.value = picked.end;
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.date_range,
                size: 20,
                color: Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Period",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${DateFormat('MMM dd, yyyy').format(controller.startDate.value)} - ${DateFormat('MMM dd, yyyy').format(controller.endDate.value)}",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteDropdown(ExportController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: controller.sites.any((s) => s['id'] == controller.selectedSiteId.value)
              ? controller.selectedSiteId.value
              : null,
          icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          dropdownColor: Colors.white,
          items: controller.sites.map((site) {
            return DropdownMenuItem(
              value: site['id'],
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: site['id'] == 'All'
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      site['name']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => controller.onSiteChanged(val),
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown(ExportController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: controller.users.any((u) => u['id'] == controller.selectedUserId.value)
              ? controller.selectedUserId.value
              : "All",
          icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          dropdownColor: Colors.white,
          items: controller.users.map((user) {
            return DropdownMenuItem(
              value: user['id'],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: user['id'] == 'All'
                        ? const Color(0xFF0EA5E9).withValues(alpha:0.1)
                        : const Color(0xFF8B5CF6).withValues(alpha:0.1),
                    child: Text(
                      user['name']![0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user['id'] == 'All'
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user['name']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => controller.selectedUserId.value = val!,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(ExportController controller) {
    final statusOptions = [
      {'value': 'All', 'label': 'All Records', 'icon': Icons.list_alt, 'color': const Color(0xFF64748B)},
      {'value': 'Present', 'label': 'Present Only', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF10B981)},
      {'value': 'Absent', 'label': 'Absent Only', 'icon': Icons.cancel_outlined, 'color': const Color(0xFFEF4444)},
      {'value': 'Late', 'label': 'Late Only', 'icon': Icons.access_time, 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: controller.selectedAttendanceStatus.value,
          icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          dropdownColor: Colors.white,
          items: statusOptions.map((option) {
            return DropdownMenuItem(
              value: option['value'] as String,
              child: Row(
                children: [
                  Icon(
                    option['icon'] as IconData,
                    size: 20,
                    color: option['color'] as Color,
                  ),
                  const SizedBox(width: 12),
                  Text(option['label'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => controller.selectedAttendanceStatus.value = val!,
        ),
      ),
    );
  }

  // =========================================================================
  // ACTION BUTTONS
  // =========================================================================
  
  Widget _buildActionButtons(ExportController controller) {
    if (controller.isLoading.value) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha:0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF0EA5E9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              controller.loadingMessage.value.isEmpty
                  ? "Processing..."
                  : controller.loadingMessage.value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0EA5E9).withValues(alpha:0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF0EA5E9),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Choose your export format below",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF0369A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Excel Button
        _buildExportButton(
          onPressed: controller.generateAttendanceReport,
          label: "Download Excel Report",
          subtitle: "Detailed records with all data points",
          icon: Icons.table_chart,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          shadowColor: const Color(0xFF10B981),
        ),
        
        const SizedBox(height: 16),
        
        // PDF Button
        _buildExportButton(
          onPressed: controller.generatePdfSummary,
          label: "Download PDF Summary",
          subtitle: "Executive summary with analytics",
          icon: Icons.picture_as_pdf,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          shadowColor: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required VoidCallback onPressed,
    required String label,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withValues(alpha:0.8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}