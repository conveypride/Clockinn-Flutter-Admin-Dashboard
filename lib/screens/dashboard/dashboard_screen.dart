import 'package:clockinn_flutter_admin/screens/statDetails/stat_details_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/dashboard_controller.dart'; 

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Overview",
              style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => controller.loadAdvancedStats(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          
          return RefreshIndicator(
            onRefresh: () async => controller.loadAdvancedStats(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return SizedBox(
                    height: Get.height * 0.8,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MIGRATION BUTTON (Remove later if needed)
                    TextButton(
                      onPressed: (){ controller.runAnalyticsBackfill(); }, 
                      child: const Text("Migrate Analytics Data")
                    ),
                    
                    // 1. TOP KPI GRID (Responsive)
                    _buildResponsiveKPIGrid(controller, width),

                    const SizedBox(height: 24),

                    // 2. MAIN CHART SECTION
                    _buildAttendanceChart(context, controller),

                    const SizedBox(height: 24),

                    // 3. PIE & BAR CHARTS (Responsive Row/Column)
                    if (width > 900)
                      Row(
                        children: [
                          Expanded(child: _buildPunctualityChart(controller)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildWeeklyHoursChart(controller)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildPunctualityChart(controller),
                          const SizedBox(height: 24),
                          _buildWeeklyHoursChart(controller),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // 4. SECONDARY METRICS (Productivity & Sites)
                    if (width > 900)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProductivityCard(controller)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildSiteDistributionCard(controller)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildProductivityCard(controller),
                          const SizedBox(height: 24),
                          _buildSiteDistributionCard(controller),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // 5. RECENT ACTIVITY
                    Text(
                      "Recent Activity",
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityList(controller),

                    const SizedBox(height: 40),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. RESPONSIVE KPI GRID
  // ===========================================================================
  Widget _buildResponsiveKPIGrid(DashboardController controller, double width) {
    final card1 = _buildStatCard(
      "Total Staff",
      controller.totalEmployees.value.toString(),
      "Employees registered",
      Icons.people_alt_outlined,
      Colors.blue,
      () => Get.to(() => StatDetailsScreen(
            title: "All Employees",
            themeColor: Colors.blue,
            fetchData: () => controller.getEmployeesListByType('total'),
          )),
    );

    final card2 = _buildStatCard(
      "Active Now",
      controller.activeNow.value.toString(),
      "Currently clocked in",
      Icons.verified_user_outlined,
      const Color(0xFF10B981),
      () => Get.to(() => StatDetailsScreen(
            title: "Active Employees",
            themeColor: const Color(0xFF10B981),
            fetchData: () => controller.getEmployeesListByType('active'),
          )),
    );

    final card3 = _buildStatCard(
      "Absent",
      controller.absentToday.value.toString(),
      "Not checked in today",
      Icons.person_off_outlined,
      Colors.orange,
      () => Get.to(() => StatDetailsScreen(
            title: "Absent Today",
            themeColor: Colors.orange,
            fetchData: () => controller.getEmployeesListByType('absent'),
          )),
    );

    final card4 = _buildStatCard(
      "Overtime",
      controller.overtimeCount.value.toString(),
      "Worked > 9hrs",
      Icons.timer_outlined,
      Colors.purple,
      () => Get.to(() => StatDetailsScreen(
            title: "Overtime Workers",
            themeColor: Colors.purple,
            fetchData: () => controller.getEmployeesListByType('overtime'),
          )),
    );

    if (width > 1100) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 12),
          Expanded(child: card2),
          const SizedBox(width: 12),
          Expanded(child: card3),
          const SizedBox(width: 12),
          Expanded(child: card4),
        ],
      );
    } 
    else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. MAIN ATTENDANCE CHART
  // ===========================================================================
  Widget _buildAttendanceChart(
      BuildContext context, DashboardController controller) {
    String dateRangeText =
        "${DateFormat('MMM d').format(controller.currentStartDate.value)} - ${DateFormat('MMM d').format(controller.currentEndDate.value)}";

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Attendance Trends",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                        start: controller.currentStartDate.value,
                        end: controller.currentEndDate.value),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF10B981),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    controller.updateDateRange(picked.start, picked.end);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(dateRangeText,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: controller.maxChartY.value / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[100],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        int totalDays = controller.currentEndDate.value
                            .difference(controller.currentStartDate.value)
                            .inDays;
                        int interval =
                            totalDays > 10 ? (totalDays / 5).ceil() : 1;

                        if (index >= 0 &&
                            index <= totalDays &&
                            index % interval == 0) {
                          DateTime date = controller.currentStartDate.value
                              .add(Duration(days: index));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: controller.maxChartY.value / 5,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: controller.currentEndDate.value
                    .difference(controller.currentStartDate.value)
                    .inDays
                    .toDouble(),
                minY: 0,
                maxY: controller.maxChartY.value,
                lineBarsData: [
                  LineChartBarData(
                    spots: controller.attendanceSpots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withValues(alpha:0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. PUNCTUALITY PIE CHART
  // ===========================================================================
  Widget _buildPunctualityChart(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Punctuality Breakdown",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: controller.punctualityStats['On Time'] ?? 100,
                          title:
                              '${(controller.punctualityStats['On Time'] ?? 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: controller.punctualityStats['Late'] ?? 0,
                          title:
                              '${(controller.punctualityStats['Late'] ?? 0).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(const Color(0xFF10B981), "On Time"),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.orange, "Late Arrival"),
                  ],
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  // ===========================================================================
  // 4. WEEKLY HOURS BAR CHART
  // ===========================================================================
  Widget _buildWeeklyHoursChart(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Avg Hours / Day",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.round()],
                                style: GoogleFonts.inter(
                                    color: Colors.grey, fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  double val = controller.dailyAvgHours[index] ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val > 8.0 ? Colors.green : Colors.orangeAccent,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 12,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. PRODUCTIVITY & SITES
  // ===========================================================================
  Widget _buildProductivityCard(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Productivity (Selected Period)",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildMetricRow(
              "Avg Work Hours", controller.avgWorkHours.value, Colors.blue),
          const SizedBox(height: 16),
          _buildMetricRow("Late Arrivals",
              "${controller.lateArrivals.value}", Colors.orange),
          const SizedBox(height: 16),
          _buildMetricRow("Early Leavers",
              "${controller.earlyLeavers.value}", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        Text(value,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildSiteDistributionCard(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Site Distribution",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: controller.siteDistribution.isEmpty
                ? Center(
                    child: Text("No sites active",
                        style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
                    itemCount: controller.siteDistribution.length,
                    itemBuilder: (context, index) {
                      var site = controller.siteDistribution[index];
                      double percentage = (site['count'] /
                          (controller.totalEmployees.value == 0
                              ? 1
                              : controller.totalEmployees.value));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // FIX: Defensive coding for name
                                Text(site['name']?.toString() ?? "Unknown Site",
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                Text("${site['count'] ?? 0} Users",
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[100],
                              color: Color(site['color']),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. ACTIVITY LIST
  // ===========================================================================
  Widget _buildActivityList(DashboardController controller) {
    if (controller.recentActivity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("No recent activity found.",
              style: GoogleFonts.inter(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.recentActivity.length,
      itemBuilder: (context, index) {
        var log = controller.recentActivity[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha:0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: log['color'].withValues(alpha:0.1),
              child: Icon(Icons.person, color: log['color'], size: 18),
            ),
            // FIX: Defensive coding for Name
            title: Text(log['name']?.toString() ?? "Unknown User",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            
            // FIX: Defensive coding for Site/Status
            subtitle: Text("${log['site']?.toString() ?? 'Site'} • ${log['status']?.toString() ?? 'Status'}",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            
            // FIX: Defensive coding for Time
            trailing: Text(log['time']?.toString() ?? "--:--",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
          ),
        );
      },
    );
  }
} 