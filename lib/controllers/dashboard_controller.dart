import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'login_controller.dart'; 

class DashboardController extends GetxController {
  var isLoading = true.obs;
  
  // --- DATE FILTER STATE ---
  var currentStartDate = DateTime.now().subtract(const Duration(days: 6)).obs;
  var currentEndDate = DateTime.now().obs;

  // 1. Workforce Stats
  var totalEmployees = 0.obs;
  var totalSites = 0.obs;
  
  // 2. Daily Status (Real-time from Today's records)
  var activeNow = 0.obs;
  var absentToday = 0.obs;
  
  // 3. Performance KPIs (Derived from Analytics)
  var lateArrivals = 0.obs;
  var earlyLeavers = 0.obs; // Note: Analytics might not track this yet, defaulting to 0
  var avgWorkHours = "0h 0m".obs;
  var overtimeCount = 0.obs; 

  // 4. Visual Data
  var attendanceSpots = <FlSpot>[].obs;
  var siteDistribution = <Map<String, dynamic>>[].obs;
  var recentActivity = <Map<String, dynamic>>[].obs;
  var maxChartY = 10.0.obs;

  // 5. NEW CHARTS DATA
  var punctualityStats = <String, double>{}.obs; // For Pie Chart
  var dailyAvgHours = <int, double>{}.obs; // For Bar Chart (0=Mon, 6=Sun)

  // 6. Drill-Down Cache (Stores IDs for quick fetching)
  Map<String, List<Map<String, dynamic>>> _drillDownCache = {};

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    loadAdvancedStats();
  }

  void updateDateRange(DateTime start, DateTime end) {
    currentStartDate.value = start;
    currentEndDate.value = end;
    loadAdvancedStats();
  }

  void loadAdvancedStats() async {
    isLoading.value = true;
    String cid = auth.companyId.value;
    
    if (cid.isEmpty) {
      isLoading.value = false;
      return;
    }

    try {
      // =======================================================================
      // 1. FETCH SITES (Needed for both Real-time & Analytics)
      // =======================================================================
      var sitesQuery = await _db.collection('users').doc(cid).collection('sites').get();
      totalSites.value = sitesQuery.docs.length;
      
      List<String> siteIds = [];
      List<Map<String, dynamic>> sitesData = [];
      int totalRegUsers = 0;

      for (var siteDoc in sitesQuery.docs) {
        siteIds.add(siteDoc.id); // Save ID for analytics loop
        var countSnap = await siteDoc.reference.collection('users').count().get();
        int count = countSnap.count ?? 0;
        totalRegUsers += count;
        
        if (count > 0) {
          sitesData.add({
            'name': siteDoc.data()['nameofsite'] ?? "Site",
            'count': count,
            'color': _getRandomColor(siteDoc.id)
          });
        }
      }
      totalEmployees.value = totalRegUsers;
      siteDistribution.assignAll(sitesData);

      // =======================================================================
      // 2. REAL-TIME DATA (Query 'records' for TODAY ONLY)
      // =======================================================================
      // We do this to get names/faces for "Active Now" and "Recent Activity"
      
      DateTime today = DateUtils.dateOnly(DateTime.now());
      var todayRecords = await _db.collectionGroup('records')
          .where('companyId', isEqualTo: cid)
          .where('date', isEqualTo: Timestamp.fromDate(today))
          .get();

      int active = 0;
      List<Map<String, dynamic>> logs = [];
      
      // Initialize Cache
      _drillDownCache = {'active': [], 'late': [], 'overtime': [], 'absent': []};

      for (var doc in todayRecords.docs) {
        var data = doc.data();
        DateTime checkIn = (data['checkInTime'] as Timestamp).toDate();
        
        Map<String, dynamic> recordObj = {
          'name': data['name'] ?? 'Unknown',
          'picurl': data['picurl'],
          'role': data['site'] ?? 'Employee',
          'time': "", 
          'id': data['userId']
        };

        // Active Count & Cache
        if (data['checkOutTime'] == null) {
          active++;
          recordObj['time'] = "In: ${DateFormat('Hm').format(checkIn)}";
          _drillDownCache['active']!.add(recordObj);
        }
        
        // Late Count (Today's drill-down only)
        DateTime expected = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 30);
        if (checkIn.isAfter(expected)) {
           var lateObj = Map<String, dynamic>.from(recordObj);
           lateObj['time'] = "Arrived: ${DateFormat('Hm').format(checkIn)}";
           _drillDownCache['late']!.add(lateObj);
        }

        // Logs
        if (logs.length < 10) {
          logs.add({
            'name': data['name'], 'site': data['site'], 'time': DateFormat('hh:mm a').format(checkIn),
            'status': data['checkOutTime'] == null ? 'Active' : 'Done',
            'color': Colors.blue
          });
        }
      }
      
      activeNow.value = active;
      absentToday.value = (totalRegUsers - todayRecords.docs.length).clamp(0, totalRegUsers);
      recentActivity.assignAll(logs);


      // =======================================================================
      // 3. HISTORICAL DATA (Query 'analytics' Collection)
      // =======================================================================
      
      // Data Buckets for Aggregation
      Map<String, Map<String, dynamic>> aggregatedDaily = {};
      
      String startStr = DateFormat('yyyy-MM-dd').format(currentStartDate.value);
      String endStr = DateFormat('yyyy-MM-dd').format(currentEndDate.value);

      // Loop through all sites and fetch their analytics for the date range
      for (String siteId in siteIds) {
        var statsSnap = await _db.collection('analytics')
            .doc(cid).collection('sites').doc(siteId).collection('daily')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
            .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
            .get();

        for (var doc in statsSnap.docs) {
          String dateKey = doc.id; // "2026-01-25"
          var d = doc.data();

          if (!aggregatedDaily.containsKey(dateKey)) {
            aggregatedDaily[dateKey] = {'total': 0, 'late': 0, 'hours': 0.0};
          }
          
          aggregatedDaily[dateKey]!['total'] += (d['totalClockIns'] as int? ?? 0);
          aggregatedDaily[dateKey]!['late'] += (d['lateCount'] as int? ?? 0);
          aggregatedDaily[dateKey]!['hours'] += (d['totalWorkingHours'] as num? ?? 0.0);
        }
      }

      // --- GENERATE CHARTS ---
      List<FlSpot> spots = [];
      int totalVisits = 0;
      int totalLate = 0;
      double grandTotalHours = 0.0;
      double maxY = 0;
      
      // Buckets for Bar Chart (Mon=0 ... Sun=6)
      Map<int, List<double>> weekdayHours = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []};

      int daysDifference = currentEndDate.value.difference(currentStartDate.value).inDays + 1;

      for (int i = 0; i < daysDifference; i++) {
        DateTime d = currentStartDate.value.add(Duration(days: i));
        String dateKey = DateFormat('yyyy-MM-dd').format(d);
        
        double count = (aggregatedDaily[dateKey]?['total'] ?? 0).toDouble();
        double hours = (aggregatedDaily[dateKey]?['hours'] ?? 0.0).toDouble();
        int late = (aggregatedDaily[dateKey]?['late'] ?? 0).toInt();

        // Line Chart Data
        totalVisits += count.toInt();
        totalLate += late;
        grandTotalHours += hours;
        
        spots.add(FlSpot(i.toDouble(), count));
        if (count > maxY) maxY = count;

        // Bar Chart Data (Weekday Avg)
        if (count > 0) {
          int weekdayIdx = d.weekday - 1; // 1=Mon -> 0
          // Average hours *per employee* for this specific day
          double dailyAvg = hours / count; 
          weekdayHours[weekdayIdx]?.add(dailyAvg);
        }
      }

      attendanceSpots.assignAll(spots);
      maxChartY.value = maxY == 0 ? 10.0 : maxY * 1.25;

      // Pie Chart
      if (totalVisits > 0) {
        double onTime = (totalVisits - totalLate).toDouble();
        punctualityStats.value = {
          'On Time': (onTime / totalVisits) * 100,
          'Late': (totalLate / totalVisits) * 100,
        };
      } else {
        punctualityStats.value = {'On Time': 100, 'Late': 0};
      }

      // Bar Chart
      Map<int, double> finalBarMap = {};
      weekdayHours.forEach((day, averages) {
         if (averages.isEmpty) {
           finalBarMap[day] = 0.0;
         } else {
           double sum = averages.reduce((a, b) => a + b);
           finalBarMap[day] = sum / averages.length;
         }
      });
      dailyAvgHours.assignAll(finalBarMap);
      
      // Metrics
      lateArrivals.value = totalLate;
      if (totalVisits > 0) {
        double avg = grandTotalHours / totalVisits;
        int h = avg.floor();
        int m = ((avg - h) * 60).round();
        avgWorkHours.value = "${h}h ${m}m";
      } else {
        avgWorkHours.value = "0h 0m";
      }

    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // 4. ADMIN TOOL: BACKFILL SCRIPT
  // ===========================================================================
  // Run this ONCE to calculate history & working hours for existing data
  Future<void> runAnalyticsBackfill() async {
    String cid = auth.companyId.value;
    if (cid.isEmpty) return;
    
    isLoading.value = true;
    Get.snackbar("Backfill Started", "Calculating history... This may take time.", 
      duration: const Duration(seconds: 5), backgroundColor: Colors.blue, colorText: Colors.white);

    try {
      var sitesSnap = await _db.collection('users').doc(cid).collection('sites').get();
      int totalWrites = 0;

      for (var siteDoc in sitesSnap.docs) {
        String siteId = siteDoc.id;
        
        // Get all records for this site
        var historySnap = await _db.collectionGroup('records')
            .where('companyId', isEqualTo: cid)
            .where('siteId', isEqualTo: siteId)
            .get();

        // Aggregate in Memory
        Map<String, Map<String, dynamic>> dailyStats = {};

        for (var doc in historySnap.docs) {
          var data = doc.data();
          if (data['checkInTime'] == null) continue;

          DateTime date = (data['checkInTime'] as Timestamp).toDate();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);

          if (!dailyStats.containsKey(dateKey)) {
            dailyStats[dateKey] = {'total': 0, 'late': 0, 'hours': 0.0};
          }

          dailyStats[dateKey]!['total'] += 1;

          // Late Check
          String markAs = (data['markAs'] ?? "").toString().toLowerCase();
          if (markAs.contains('late')) {
            dailyStats[dateKey]!['late'] += 1;
          }

          // Hours Calc
          if (data['workingHours'] != null) {
             dailyStats[dateKey]!['hours'] += _parseDuration(data['workingHours'].toString());
          }
        }

        // Write to Analytics
        WriteBatch batch = _db.batch();
        int batchCount = 0;

        dailyStats.forEach((dateKey, stats) {
          DocumentReference ref = _db.collection('analytics')
              .doc(cid).collection('sites').doc(siteId).collection('daily').doc(dateKey);
          
          batch.set(ref, {
            'totalClockIns': stats['total'],
            'lateCount': stats['late'],
            'totalWorkingHours': stats['hours'], // Added for Bar Chart
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          batchCount++;
          if (batchCount >= 450) {
            batch.commit();
            batch = _db.batch();
            batchCount = 0;
          }
        });

        if (batchCount > 0) await batch.commit();
        totalWrites += dailyStats.length;
      }

      Get.snackbar("Success", "Updated $totalWrites days of history.", 
        backgroundColor: Colors.green, colorText: Colors.white);
      
      loadAdvancedStats(); // Refresh charts

    } catch (e) {
      debugPrint("Backfill Error: $e");
      Get.snackbar("Error", "Migration Failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Helpers ---
  Future<List<Map<String, dynamic>>> getEmployeesListByType(String type) async {
    if (_drillDownCache.containsKey(type) && _drillDownCache[type]!.isNotEmpty) {
      return _drillDownCache[type]!;
    }
    // Absent list logic needs to query users vs active IDs (same as before)
    if (type == 'absent' || type == 'total') {
      String cid = auth.companyId.value;
      List<Map<String, dynamic>> result = [];
      var sitesSnap = await _db.collection('users').doc(cid).collection('sites').get();
      DateTime today = DateUtils.dateOnly(DateTime.now());
      var attendanceSnap = await _db.collectionGroup('records')
          .where('companyId', isEqualTo: cid).where('date', isEqualTo: Timestamp.fromDate(today)).get();
      List<String> activeIds = attendanceSnap.docs.map((d) => d['userId'] as String).toList();

      for (var site in sitesSnap.docs) {
        var usersSnap = await site.reference.collection('users').get();
        for (var u in usersSnap.docs) {
          bool isAbsent = !activeIds.contains(u.id);
          if (type == 'total' || (type == 'absent' && isAbsent)) {
             result.add({
                'name': u['name'],
                'picurl': u['picurl'] ?? u['choosenprofilepic'],
                'role': u['role'] ?? 'Employee',
                'detail': u['department'] ?? 'General',
             });
          }
        }
      }
      return result;
    }
    return []; 
  }

  double _parseDuration(String duration) {
    if (duration.isEmpty || duration == "0:0") return 0.0;
    try {
      var parts = duration.split(':');
      return double.parse(parts[0]) + (double.parse(parts[1]) / 60.0);
    } catch (e) { return 0.0; }
  }

  int _getRandomColor(String seed) {
    return 0xFF000000 + (seed.hashCode & 0xFFFFFF);
  }
}