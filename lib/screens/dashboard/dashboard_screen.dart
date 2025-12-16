import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Welcome Message
            _buildHeader(),
            const SizedBox(height: 24),

            // Stat Cards with Gradient
            LayoutBuilder(
              builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                int columns = availableWidth > 1100 ? 6 : availableWidth > 650 ? 4 : 1;
                double aspectRatio = availableWidth > 1100 ? 1.5 : availableWidth > 650 ? 1.4 : 2.2;

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  childAspectRatio: aspectRatio,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAnimatedStatCard(
                      "Total Employees",
                      "124",
                      Icons.people_rounded,
                      const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                      "+12% from last month",
                      0,
                    ),
                    _buildAnimatedStatCard(
                      "On-Site Now",
                      "85",
                      Icons.check_circle_rounded,
                      const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
                      "68% attendance rate",
                      1,
                    ),
                    _buildAnimatedStatCard(
                      "Late Arrivals",
                      "12",
                      Icons.warning_rounded,
                      const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
                      "-3 from yesterday",
                      2,
                    ),
                    _buildAnimatedStatCard(
                      "Total Sites",
                      "6",
                      Icons.location_on_rounded,
                      const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                      "All operational",
                      3,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // Charts Row
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 900;
                return isWideScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildAttendanceChart()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSiteDistributionChart()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildAttendanceChart(),
                          const SizedBox(height: 20),
                          _buildSiteDistributionChart(),
                        ],
                      );
              },
            ),

            const SizedBox(height: 30),

            // Recent Activity and Quick Stats
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 900;
                return isWideScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildRecentActivity(width)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildQuickStats()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRecentActivity(width),
                          const SizedBox(height: 20),
                          _buildQuickStats(),
                        ],
                      );
              },
            ),

            const SizedBox(height: 30),

            // Peak Hours Chart
            _buildPeakHoursChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, Admin! 👋",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Here's what's happening with your team today",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    String subtitle,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                "Attendance Trend",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildChartLegend(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt() % 7],
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 95),
                      const FlSpot(1, 88),
                      const FlSpot(2, 92),
                      const FlSpot(3, 85),
                      const FlSpot(4, 90),
                      const FlSpot(5, 78),
                      const FlSpot(6, 80),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withOpacity(0.3),
                          const Color(0xFF764ba2).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildChartLegend() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF667eea),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "Attendance %",
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSiteDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: 40,
                    title: '40%',
                    color: const Color(0xFF667eea),
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: '25%',
                    color: const Color(0xFF11998e),
                    radius: 45,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: '20%',
                    color: const Color(0xFFf5576c),
                    radius: 45,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: '15%',
                    color: const Color(0xFF4facfe),
                    radius: 45,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSiteLegend(),
        ],
      ),
    );
  }

  Widget _buildSiteLegend() {
    return Column(
      children: [
        _buildLegendItem("Accra HQ", const Color(0xFF667eea), "50 employees"),
        _buildLegendItem("Kumasi Branch", const Color(0xFF11998e), "31 employees"),
        _buildLegendItem("Takoradi Office", const Color(0xFFf5576c), "25 employees"),
        _buildLegendItem("Tema Site", const Color(0xFF4facfe), "18 employees"),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                "Recent Clock-Ins",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: width > 800 ? 600 : width),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                horizontalMargin: 0,
                columnSpacing: 24,
                columns: [
                  DataColumn(
                    label: Text("Employee", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text("Site", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text("Time", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text("Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: [
                  _buildDataRow("John Doe", "Accra HQ", "07:55 AM", "On Time"),
                  _buildDataRow("Sarah Smith", "Kumasi Branch", "08:15 AM", "Late"),
                  _buildDataRow("Michael K.", "Accra HQ", "08:00 AM", "On Time"),
                  _buildDataRow("Emma Wilson", "Tema Site", "07:50 AM", "On Time"),
                  _buildDataRow("David Brown", "Takoradi Office", "08:20 AM", "Late"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String col1, String col2, String col3, String col4) {
    return DataRow(cells: [
      DataCell(
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF667eea).withOpacity(0.2),
              child: Text(
                col1[0],
                style: GoogleFonts.inter(
                  color: const Color(0xFF667eea),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(col1, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      DataCell(Text(col2, style: GoogleFonts.inter())),
      DataCell(Text(col3, style: GoogleFonts.inter())),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: col4 == "Late" ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: col4 == "Late" ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Text(
            col4,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: col4 == "Late" ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Stats",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildQuickStatItem(Icons.trending_up, "Avg. Attendance", "87%", Colors.green),
          _buildQuickStatItem(Icons.access_time, "Avg. Check-in Time", "08:12 AM", Colors.blue),
          _buildQuickStatItem(Icons.schedule, "Late Rate", "9.7%", Colors.orange),
          _buildQuickStatItem(Icons.event_available, "On Leave Today", "8", Colors.purple),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Peak Check-in Hours",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const hours = ['6AM', '7AM', '8AM', '9AM', '10AM', '11AM'];
                        return Text(
                          hours[value.toInt() % 6],
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, 5, const Color(0xFF667eea)),
                  _buildBarGroup(1, 25, const Color(0xFF667eea)),
                  _buildBarGroup(2, 45, const Color(0xFF11998e)),
                  _buildBarGroup(3, 20, const Color(0xFF667eea)),
                  _buildBarGroup(4, 10, const Color(0xFF667eea)),
                  _buildBarGroup(5, 3, const Color(0xFF667eea)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Helper to get screen width
//     final width = MediaQuery.of(context).size.width;

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Dashboard Overview",
//               style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 20),

//           // 1. RESPONSIVE STAT CARDS
//           // Use LayoutBuilder to decide how many columns
//           LayoutBuilder(
//             builder: (context, constraints) {
//               // Determine width available for cards
//               double availableWidth = constraints.maxWidth;
              
//               // Define columns based on width
//               // > 1100px: 4 columns (Desktop)
//               // > 850px:  2 columns (Tablet)
//               // < 850px:  1 column (Mobile)
//               int columns = availableWidth > 1100 ? 4 : availableWidth > 650 ? 4 : 1;
              
//               // Calculate aspect ratio to keep cards looking good
//               double aspectRatio = availableWidth > 1100 ? 1.4 : availableWidth > 650 ? 1.6 : 2.5;

//               return GridView.count(
//                 crossAxisCount: columns,
//                 crossAxisSpacing: 20,
//                 mainAxisSpacing: 20,
//                 shrinkWrap: true, // Vital for nesting in ScrollView
//                 childAspectRatio: aspectRatio,
//                 physics: const NeverScrollableScrollPhysics(), // Scroll parent instead
//                 children: [
//                   _buildStatCard("Total Employees", "124", Icons.people, Colors.blue),
//                   _buildStatCard("On-Site Now", "85", Icons.check_circle, Colors.green),
//                   _buildStatCard("Late Arrivals", "12", Icons.warning, Colors.orange),
//                   _buildStatCard("Total Sites", "6", Icons.location_on, Colors.purple),
//                 ],
//               );
//             },
//           ),

//           const SizedBox(height: 30),

//           // 2. RECENT ACTIVITY TABLE (Scrollable horizontally on mobile)
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//                 color: Colors.white, borderRadius: BorderRadius.circular(10)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Recent Clock-Ins",
//                     style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 15),
                
//                 // ADD SingleChildScrollView for horizontal scrolling
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(minWidth: width > 800 ? 600 : width),
//                     child: DataTable(
//                       horizontalMargin: 0,
//                       columnSpacing: 20,
//                       columns: const [
//                          DataColumn(label: Text("Employee", style: TextStyle(fontWeight: FontWeight.bold))),
//                          DataColumn(label: Text("Site", style: TextStyle(fontWeight: FontWeight.bold))),
//                          DataColumn(label: Text("Time", style: TextStyle(fontWeight: FontWeight.bold))),
//                          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
//                       ],
//                       rows: [
//                          _buildDataRow("John Doe", "Accra HQ", "07:55 AM", "On Time"),
//                          _buildDataRow("Sarah Smith", "Kumasi Branch", "08:15 AM", "Late"),
//                          _buildDataRow("Michael K.", "Accra HQ", "08:00 AM", "On Time"),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   // Updated Stat Card for GridView
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Flexible(child: Text(title, style: GoogleFonts.inter(color: Colors.grey), overflow: TextOverflow.ellipsis)),
//               Icon(icon, color: color.withOpacity(0.7)),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(value,
//               style: GoogleFonts.inter(
//                   fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
//         ],
//       ),
//     );
//   }

//   // Using DataTable Rows instead of manual TableRow for better alignment
//   DataRow _buildDataRow(String col1, String col2, String col3, String col4) {
//     return DataRow(cells: [
//       DataCell(Text(col1)),
//       DataCell(Text(col2)),
//       DataCell(Text(col3)),
//       DataCell(
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           decoration: BoxDecoration(
//             color: col4 == "Late" ? Colors.red.shade100 : Colors.green.shade100,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Text(col4,
//               style: TextStyle(
//                   fontSize: 12,
//                   color: col4 == "Late" ? Colors.red : Colors.green)),
//         ),
//       ),
//     ]);
//   }
// }