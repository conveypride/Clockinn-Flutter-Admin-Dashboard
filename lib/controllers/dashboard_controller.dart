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
  
  // 2. Daily Status
  var activeNow = 0.obs;
  var absentToday = 0.obs;
  
  // 3. Performance KPIs
  var lateArrivals = 0.obs;
  var earlyLeavers = 0.obs; 
  var avgWorkHours = "0.0 hrs".obs;
  var overtimeCount = 0.obs; 

  // 4. Visual Data
  var attendanceSpots = <FlSpot>[].obs;
  var siteDistribution = <Map<String, dynamic>>[].obs;
  var recentActivity = <Map<String, dynamic>>[].obs;
  var maxChartY = 10.0.obs;

  // 5. Charts Data
  var punctualityStats = <String, double>{}.obs; 
  var punctualityTooltips = <String, String>{}.obs; 
  var dailyAvgHours = <int, double>{}.obs; 

  // 6. Drill-Down Cache
  Map<String, List<Map<String, dynamic>>> _drillDownCache = {};

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override 
  void onInit() {
    super.onInit();
    if (auth.companyId.value.isNotEmpty) {
      loadAdvancedStats();
    }
    ever(auth.companyId, (String id) {
      if (id.isNotEmpty) loadAdvancedStats();
    });
  }

  void updateDateRange(DateTime start, DateTime end) {
    currentStartDate.value = start;
    currentEndDate.value = end;
    loadAdvancedStats();
  }

  void loadAdvancedStats() async {
    isLoading.value = true;
    String cid = auth.companyId.value;
    
    // Safety check for LoginController readiness
    String myRole = "Super Admin";
    String mySiteId = "";
    try {
       myRole = auth.userRole.value;
       mySiteId = auth.managedSiteId.value;
    } catch (_) {}
    
    if (cid.isEmpty) {
      isLoading.value = false;
      return;
    }

    try {
      // =======================================================================
      // 1. FETCH SITES (Restricted for Managers)
      // =======================================================================
      Query sitesQuery = _db.collection('users').doc(cid).collection('sites');

      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        sitesQuery = sitesQuery.where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      var sitesSnap = await sitesQuery.get();
      totalSites.value = sitesSnap.docs.length;
      
      List<String> siteIds = [];
      List<Map<String, dynamic>> sitesData = [];
      int totalRegUsers = 0;

      for (var siteDoc in sitesSnap.docs) {
        siteIds.add(siteDoc.id); 
        var countSnap = await siteDoc.reference.collection('users').count().get();
        int count = countSnap.count ?? 0;
        totalRegUsers += count;
        
        if (count > 0) {
          // 🛠️ FIX IS HERE: Safe Casting
          var data = siteDoc.data() as Map<String, dynamic>; 
          
          sitesData.add({
            'name': data['nameofsite'] ?? "Site", // Now safe to access
            'count': count,
            'color': _getRandomColor(siteDoc.id)
          });
        }
      }
      totalEmployees.value = totalRegUsers;
      siteDistribution.assignAll(sitesData);

      // =======================================================================
      // 2. REAL-TIME DATA 
      // =======================================================================
      
      DateTime today = DateUtils.dateOnly(DateTime.now());
      Query recordQuery = _db.collectionGroup('records')
          .where('companyId', isEqualTo: cid)
          .where('date', isEqualTo: Timestamp.fromDate(today));

      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        recordQuery = recordQuery.where('siteId', isEqualTo: mySiteId);
      }

      var todayRecords = await recordQuery.get();

      int active = 0;
      List<Map<String, dynamic>> logs = [];
      _drillDownCache = {'active': [], 'late': [], 'overtime': [], 'absent': []};

      for (var doc in todayRecords.docs) {
        var data = doc.data() as Map<String, dynamic>; // Safe cast
        DateTime checkIn = (data['checkInTime'] as Timestamp).toDate();
        
        Map<String, dynamic> recordObj = {
          'name': data['name'] ?? 'Unknown',
          'picurl': data['picurl'] ?? '', 
          'role': data['site'] ?? 'Employee',
          'time': "", 
          'id': data['userId']
        };

        if (data['checkOutTime'] == null) {
          active++;
          recordObj['time'] = "In: ${DateFormat('Hm').format(checkIn)}";
          _drillDownCache['active']!.add(recordObj);
        }
        
        DateTime expected = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 30);
        if (checkIn.isAfter(expected)) {
           var lateObj = Map<String, dynamic>.from(recordObj);
           lateObj['time'] = "Arrived: ${DateFormat('Hm').format(checkIn)}";
           _drillDownCache['late']!.add(lateObj);
        }

        if (logs.length < 10) {
          logs.add({
            'name': data['name'] ?? "Unknown User", 
            'site': data['site'] ?? "Unknown Site", 
            'picurl': data['picurl'] ?? "", 
            'time': DateFormat('hh:mm a').format(checkIn),
            'status': data['checkOutTime'] == null ? 'Active' : 'Done',
            'color': Colors.blue 
          });
        }
      }
      
      activeNow.value = active;
      absentToday.value = (totalRegUsers - todayRecords.docs.length).clamp(0, totalRegUsers);
      recentActivity.assignAll(logs);

      // =======================================================================
      // 3. HISTORICAL DATA 
      // =======================================================================
      
      Map<String, Map<String, dynamic>> aggregatedDaily = {};
      String startStr = DateFormat('yyyy-MM-dd').format(currentStartDate.value);
      String endStr = DateFormat('yyyy-MM-dd').format(currentEndDate.value);

      for (String siteId in siteIds) {
        var statsSnap = await _db.collection('analytics')
            .doc(cid).collection('sites').doc(siteId).collection('daily')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
            .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
            .get();

        for (var doc in statsSnap.docs) {
          String dateKey = doc.id; 
          var d = doc.data(); // usually strictly typed in analytics, but can cast if needed

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
      
      Map<int, List<double>> weekdayHours = {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []};

      int daysDifference = currentEndDate.value.difference(currentStartDate.value).inDays + 1;

      for (int i = 0; i < daysDifference; i++) {
        DateTime d = currentStartDate.value.add(Duration(days: i));
        String dateKey = DateFormat('yyyy-MM-dd').format(d);
        
        double count = (aggregatedDaily[dateKey]?['total'] ?? 0).toDouble();
        double hours = (aggregatedDaily[dateKey]?['hours'] ?? 0.0).toDouble();
        int late = (aggregatedDaily[dateKey]?['late'] ?? 0).toInt();

        totalVisits += count.toInt();
        totalLate += late;
        grandTotalHours += hours;
        
        spots.add(FlSpot(i.toDouble(), count));
        if (count > maxY) maxY = count;

        if (count > 0) {
          int weekdayIdx = d.weekday - 1; 
          double dailyAvg = hours / count; 
          weekdayHours[weekdayIdx]?.add(dailyAvg);
        }
      }

      attendanceSpots.assignAll(spots);
      maxChartY.value = maxY == 0 ? 10.0 : maxY * 1.25;

      // --- PIE CHART ---
      if (totalVisits > 0) {
        int onTimeCount = totalVisits - totalLate;
        double onTimePct = (onTimeCount / totalVisits) * 100;
        double latePct = (totalLate / totalVisits) * 100;

        punctualityStats.value = {
          'On Time': onTimePct,
          'Late': latePct,
        };
        
        punctualityTooltips.value = {
          'On Time': "$onTimeCount people (${onTimePct.toStringAsFixed(1)}%)",
          'Late': "$totalLate people (${latePct.toStringAsFixed(1)}%)"
        };
      } else {
        punctualityStats.value = {'On Time': 100, 'Late': 0};
        punctualityTooltips.value = {'On Time': "0 people (0%)", 'Late': "0 people (0%)"};
      }

      // --- BAR CHART ---
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
      
      lateArrivals.value = totalLate;
      if (totalVisits > 0) {
        double avg = grandTotalHours / totalVisits;
        avgWorkHours.value = "${avg.toStringAsFixed(1)} hrs";
      } else {
        avgWorkHours.value = "0.0 hrs";
      }

    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- HELPERS ---
  Future<void> runAnalyticsBackfill() async {
    String cid = auth.companyId.value;
    if (cid.isEmpty) return;
    
    isLoading.value = true;
    Get.snackbar("Backfill Started", "Calculating history...", backgroundColor: Colors.blue, colorText: Colors.white);

    try {
      var sitesSnap = await _db.collection('users').doc(cid).collection('sites').get();
      int totalWrites = 0;

      for (var siteDoc in sitesSnap.docs) {
        String siteId = siteDoc.id;
        var historySnap = await _db.collectionGroup('records')
            .where('companyId', isEqualTo: cid)
            .where('siteId', isEqualTo: siteId)
            .get();

        Map<String, Map<String, dynamic>> dailyStats = {};

        for (var doc in historySnap.docs) {
          var data = doc.data(); // Can cast if needed
          if (data['checkInTime'] == null) continue;

          DateTime date = (data['checkInTime'] as Timestamp).toDate();
          String dateKey = DateFormat('yyyy-MM-dd').format(date);

          if (!dailyStats.containsKey(dateKey)) {
            dailyStats[dateKey] = {'total': 0, 'late': 0, 'hours': 0.0};
          }

          dailyStats[dateKey]!['total'] += 1;
          String markAs = (data['markAs'] ?? "").toString().toLowerCase();
          if (markAs.contains('late')) dailyStats[dateKey]!['late'] += 1;
          if (data['workingHours'] != null) {
             dailyStats[dateKey]!['hours'] += _parseDuration(data['workingHours'].toString());
          }
        }

        WriteBatch batch = _db.batch();
        int batchCount = 0;

        dailyStats.forEach((dateKey, stats) {
          DocumentReference ref = _db.collection('analytics')
              .doc(cid).collection('sites').doc(siteId).collection('daily').doc(dateKey);
          
          batch.set(ref, {
            'totalClockIns': stats['total'],
            'lateCount': stats['late'],
            'totalWorkingHours': stats['hours'],
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

      Get.snackbar("Success", "Updated $totalWrites days of history.", backgroundColor: Colors.green, colorText: Colors.white);
      loadAdvancedStats(); 

    } catch (e) {
      Get.snackbar("Error", "Migration Failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

   Future<List<Map<String, dynamic>>> getEmployeesListByType(String type) async {
    // 1. Check Cache first (for Active, Late, Overtime)
    if (_drillDownCache.containsKey(type) && _drillDownCache[type]!.isNotEmpty) {
      return _drillDownCache[type]!;
    }

    // 2. Handle 'Total' and 'Absent' lookups
    if (type == 'absent' || type == 'total') {
      String cid = auth.companyId.value;
      String myRole = auth.userRole.value;       // <--- Get Role
      String mySiteId = auth.managedSiteId.value; // <--- Get Site ID

      List<Map<String, dynamic>> result = [];
      
      // 🛑 FIX: Apply Filter to Sites Query
      Query sitesQuery = _db.collection('users').doc(cid).collection('sites');
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        sitesQuery = sitesQuery.where(FieldPath.documentId, isEqualTo: mySiteId);
      }
      var sitesSnap = await sitesQuery.get();

      // Get today's attendance to determine who is absent
      DateTime today = DateUtils.dateOnly(DateTime.now());
      
      // 🛑 FIX: Apply Filter to Attendance Query too
      Query recordQuery = _db.collectionGroup('records')
          .where('companyId', isEqualTo: cid)
          .where('date', isEqualTo: Timestamp.fromDate(today));
          
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        recordQuery = recordQuery.where('siteId', isEqualTo: mySiteId);
      }
      var attendanceSnap = await recordQuery.get();
      
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