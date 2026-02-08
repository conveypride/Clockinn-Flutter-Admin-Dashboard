import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import 'login_controller.dart';

class ExportController extends GetxController {
  var isLoading = false.obs;
  
  // Filters
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;
  
  var selectedSiteId = "All".obs;
  var selectedUserId = "All".obs;

  // Dropdown Data
  var sites = <Map<String, String>>[].obs;
  var users = <Map<String, String>>[].obs;

  // 🧠 Smart Caches
  final Map<String, String> _userNames = {};
  final Map<String, String> _siteNames = {};
  final Map<String, SiteSchedule> _siteSchedules = {};

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    _loadFilters();
  }

  // ===========================================================================
  // 1. INITIAL SETUP & FILTERS
  // ===========================================================================
  void _loadFilters() async {
    String cid = auth.companyId.value;
    String myRole = auth.userRole.value;
    String mySite = auth.managedSiteId.value;

    try {
      if (myRole == "Super Admin") {
        var sitesSnap = await _db.collection('operationSites')
            .doc(cid).collection('sites').get();
        
        sites.assignAll(sitesSnap.docs.map((d) {
          final data = d.data(); 
          String name = data['nameofsite']?.toString() ?? "Unknown Site";
          _siteNames[d.id] = name;
          _cacheSiteSchedule(d.id, data); 
          return {'id': d.id, 'name': name};
        }).toList());

        sites.insert(0, {'id': 'All', 'name': 'All Sites'});
        selectedSiteId.value = "All";
        await _loadUsersForSite("All"); 

      } else {
        selectedSiteId.value = mySite;
        var siteDoc = await _db.collection('operationSites')
            .doc(cid).collection('sites').doc(mySite).get();
            
        if (siteDoc.exists) {
           final data = siteDoc.data()!;
           String name = data['nameofsite']?.toString() ?? "My Site";
           _siteNames[mySite] = name;
           _cacheSiteSchedule(mySite, data);
           sites.assignAll([{'id': mySite, 'name': name}]);
        }
        await _loadUsersForSite(mySite);
      }
    } catch (e) {
      print("Error loading filters: $e");
    }
  }

  void _cacheSiteSchedule(String siteId, Map<String, dynamic> data) {
    List<int> workingDays = [1, 2, 3, 4, 5];
    if (data['workingdays'] != null) {
      List<String> days = List<String>.from(data['workingdays']);
      workingDays = days.map((d) => _dayStringToInt(d)).where((i) => i != 0).toList();
    }

    List<DateTime> holidays = [];
    if (data['holidaylist'] != null) {
      for (var h in data['holidaylist']) {
        if (h is Map && h.isNotEmpty) {
          try {
            holidays.add(DateTime.parse(h.values.first.toString()));
          } catch (_) {}
        }
      }
    }
    _siteSchedules[siteId] = SiteSchedule(workingDays: workingDays, holidays: holidays);
  }

  int _dayStringToInt(String day) {
    switch(day.toLowerCase().substring(0,3)) {
      case 'mon': return 1; case 'tue': return 2; case 'wed': return 3;
      case 'thu': return 4; case 'fri': return 5; case 'sat': return 6; case 'sun': return 7;
      default: return 0;
    }
  }

  void onSiteChanged(String? newSiteId) {
    if (newSiteId != null) {
      selectedSiteId.value = newSiteId;
      _loadUsersForSite(newSiteId);
    }
  }

  Future<void> _loadUsersForSite(String siteId) async {
    String cid = auth.companyId.value;
    List<Map<String, String>> tempUsers = [];

    try {
      QuerySnapshot snap;
      if (siteId == "All") {
        snap = await _db.collectionGroup('users').where('companyId', isEqualTo: cid).get();
      } else {
        snap = await _db.collection('users').doc(cid).collection('sites').doc(siteId).collection('users').get();
      }
      
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String name = data['name']?.toString() ?? "Unknown User";
        _userNames[doc.id] = name;
        
        String userSite = data['siteId']?.toString() ?? "";
        if (!_siteNames.containsKey(userSite) && userSite.isNotEmpty) {
           _resolveSiteName(userSite); 
        }
        
        tempUsers.add({'id': doc.id, 'name': name, 'siteId': userSite});
      }
      
      tempUsers.sort((a, b) => a['name']!.compareTo(b['name']!));
      users.assignAll(tempUsers);
      users.insert(0, {'id': 'All', 'name': 'All Employees'});
      selectedUserId.value = "All"; 

    } catch (e) {
      print("Error loading users: $e");
      users.assignAll([{'id': 'All', 'name': 'All Employees'}]);
    }
  }

  // ===========================================================================
  // ⚡ SMART LOOKUP HELPERS
  // ===========================================================================
  
  Future<String> _resolveUserName(String userId) async {
    if (_userNames.containsKey(userId)) return _userNames[userId]!;
    try {
      var ptr = await _db.collection('allusers').doc(userId).get();
      if (ptr.exists) {
        var profile = await _db.collection('users')
            .doc(auth.companyId.value).collection('sites').doc(ptr['siteId'])
            .collection('users').doc(userId).get();
        if (profile.exists) {
          String name = profile['name'] ?? "Unknown";
          _userNames[userId] = name;
          return name;
        }
      }
    } catch (_) {}
    return "Unknown User";
  }

  Future<String> _resolveSiteName(String siteId) async {
    if (_siteNames.containsKey(siteId)) return _siteNames[siteId]!;
    try {
      var doc = await _db.collection('operationSites')
          .doc(auth.companyId.value).collection('sites').doc(siteId).get();
      if (doc.exists) {
        String name = doc['nameofsite'] ?? "Unknown Site";
        _siteNames[siteId] = name;
        _cacheSiteSchedule(siteId, doc.data()!); 
        return name;
      }
    } catch (_) {}
    return "Unknown Site";
  }

  // ===========================================================================
  // 📊 DATA FETCHING ENGINE
  // ===========================================================================
  
  Future<List<Map<String, dynamic>>> _fetchAndProcessData() async {
    String cid = auth.companyId.value;
    
    Query query = _db.collectionGroup('records')
        .where('companyId', isEqualTo: cid)
        .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.value))
        .where('checkInTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate.value.add(const Duration(days: 1))));

    if (selectedSiteId.value != "All") {
      query = query.where('siteId', isEqualTo: selectedSiteId.value);
    }
    if (selectedUserId.value != "All") {
      query = query.where('userId', isEqualTo: selectedUserId.value);
    }

    var snapshot = await query.get();
    List<Map<String, dynamic>> processedRecords = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['checkInTime'] == null) continue;

      String userId = data['userId']?.toString() ?? "";
      String siteId = data['siteId']?.toString() ?? "";

      String empName = await _resolveUserName(userId);
      String siteName = await _resolveSiteName(siteId);

      DateTime checkIn = (data['checkInTime'] as Timestamp).toDate();
      DateTime? checkOut = data['checkOutTime'] != null ? (data['checkOutTime'] as Timestamp).toDate() : null;
      
      double hours = 0.0;
      String durationStr = data['workingHours']?.toString() ?? "0.0";
      if (durationStr != "0.0") {
         try {
           var parts = durationStr.split(':');
           hours = double.parse(parts[0]) + (double.parse(parts[1]) / 60.0);
         } catch (_) {}
      } else if (checkOut != null) {
         hours = checkOut.difference(checkIn).inMinutes / 60.0;
         durationStr = hours.toStringAsFixed(1);
      }

      int lateMins = 0;
      if (data['markAs'].toString().toLowerCase().contains('late')) {
         DateTime expected = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 30);
         if (checkIn.isAfter(expected)) lateMins = checkIn.difference(expected).inMinutes;
      }

      processedRecords.add({
        'date': DateFormat('yyyy-MM-dd').format(checkIn),
        'name': empName,
        'site': siteName,
        'siteId': siteId,
        'userId': userId,
        'role': data['role'] ?? "Employee",
        'in': DateFormat('HH:mm').format(checkIn),
        'out': checkOut != null ? DateFormat('HH:mm').format(checkOut) : "Active",
        'hoursStr': durationStr,
        'hoursVal': hours,
        'status': data['status'] ?? "Present",
        'late': lateMins,
        'notes': data['comments'] ?? ""
      });
    }
    
    processedRecords.sort((a, b) {
      int dateComp = a['date'].compareTo(b['date']);
      if (dateComp != 0) return dateComp;
      return a['name'].compareTo(b['name']);
    });

    return processedRecords;
  }

  // ===========================================================================
  // 🟢 EXCEL GENERATION
  // ===========================================================================
  void generateAttendanceReport() async {
    isLoading.value = true;
    try {
      List<Map<String, dynamic>> records = await _fetchAndProcessData();

      if (records.isEmpty) {
        Get.snackbar("No Data", "No records found for selection.", backgroundColor: Colors.orange, colorText: Colors.white);
        isLoading.value = false;
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel['Attendance Report'];
      
      sheet.appendRow([
        "Date", "Employee Name", "Site", "Role", 
        "Check In", "Check Out", "Work Duration", 
        "Status", "Late (Mins)", "Comments"
      ].map((e) => TextCellValue(e)).toList());

      for (var row in records) {
        sheet.appendRow([
          TextCellValue(row['date']),
          TextCellValue(row['name']),
          TextCellValue(row['site']),
          TextCellValue(row['role']),
          TextCellValue(row['in']),
          TextCellValue(row['out']),
          TextCellValue(row['hoursStr']),
          TextCellValue(row['status']),
          IntCellValue(row['late']),
          TextCellValue(row['notes'])
        ]);
      }

      excel.delete('Sheet1');
      var fileBytes = excel.save();
      String fileName = "Attendance_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";

      if (fileBytes != null) {
        if (kIsWeb) {
          final blob = html.Blob([fileBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)..setAttribute("download", fileName)..click();
          html.Url.revokeObjectUrl(url);
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(fileBytes);
          await OpenFile.open(file.path);
        }
        Get.snackbar("Success", "Excel Downloaded", backgroundColor: Colors.green, colorText: Colors.white);
      }

    } catch (e) {
      Get.snackbar("Error", "Excel Generation Failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // 🔴 PDF SUMMARY GENERATION (UPDATED)
  // ===========================================================================
  void generatePdfSummary() async {
    isLoading.value = true;
    try {
      // 1. Fetch & Prepare Data
      List<Map<String, dynamic>> records = await _fetchAndProcessData();
      
      Map<String, UserStat> stats = {};
      Map<String, UserStat> siteStats = {}; // To aggregate by Site

      // Pre-fill stats for ALL selected users
      for (var u in users) {
        if (u['id'] == "All") continue;
        if (selectedUserId.value != "All" && u['id'] != selectedUserId.value) continue;
        
        // 🚀 LAST CHECK: Try to resolve name if unknown
        String name = u['name']!;
        if (name == "Unknown" || name.contains("Unknown User")) {
           name = await _resolveUserName(u['id']!);
        }

        // Get Site Name for Display
        String uSiteId = u['siteId'] ?? "";
        String uSiteName = "Unknown Site";
        if (uSiteId.isNotEmpty) {
           uSiteName = await _resolveSiteName(uSiteId);
        }

        stats[u['id']!] = UserStat(
          name: name, 
          siteName: uSiteName,
          siteId: uSiteId
        );
      }

      // Process Actual Records
      for (var rec in records) {
        String uid = rec['userId'];
        String sid = rec['siteId'];
        String sName = rec['site'];

        if (!stats.containsKey(uid)) {
           stats[uid] = UserStat(name: rec['name'], siteName: sName, siteId: sid);
        }
        
        // Update User Stat
        var s = stats[uid]!;
        s.siteId = sid; 
        s.siteName = sName;
        s.present++;
        s.totalHours += (rec['hoursVal'] as double);
        if ((rec['late'] as int) > 0) s.late++;

        // Update Site Aggregate Stat
        if (!siteStats.containsKey(sid)) {
           siteStats[sid] = UserStat(name: sName, siteName: sName, siteId: sid);
        }
        siteStats[sid]!.present++;
        siteStats[sid]!.late += ((rec['late'] as int) > 0 ? 1 : 0);
        siteStats[sid]!.totalHours += (rec['hoursVal'] as double);
      }

      // 3. Calculate Absences (Days - Present)
      int totalDaysInRange = endDate.value.difference(startDate.value).inDays + 1;
      
      stats.forEach((uid, user) {
        SiteSchedule? schedule = _siteSchedules[user.siteId];
        int expectedWorkDays = 0;
        
        for (int i = 0; i < totalDaysInRange; i++) {
          DateTime day = startDate.value.add(Duration(days: i));
          bool isWorkDay = true;
          bool isHoliday = false;

          if (schedule != null) {
             isWorkDay = schedule.workingDays.contains(day.weekday);
             isHoliday = schedule.holidays.any((h) => DateUtils.isSameDay(h, day));
          } else {
             isWorkDay = day.weekday <= 5;
          }

          if (isWorkDay && !isHoliday) expectedWorkDays++;
        }
        
        user.absent = (expectedWorkDays - user.present).clamp(0, expectedWorkDays);
        user.totalDays = expectedWorkDays;
        
        // Add expected days to site stats for aggregation
        if (siteStats.containsKey(user.siteId)) {
           siteStats[user.siteId]!.totalDays += expectedWorkDays;
           siteStats[user.siteId]!.absent += user.absent;
        }
      });

      // 4. Build PDF
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.interRegular();
      final bold = await PdfGoogleFonts.interBold();
      final light = await PdfGoogleFonts.interLight();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPdfHeader(font, bold, light),
          pw.SizedBox(height: 20),
          _buildExecutiveSummary(stats.values.toList(), font, bold),
          pw.SizedBox(height: 20),
          
          if (selectedSiteId.value == "All") ...[
             pw.Text("Site Performance Breakdown", style: pw.TextStyle(font: bold, fontSize: 14)),
             pw.SizedBox(height: 10),
             _buildSitePerformanceTable(siteStats.values.toList(), font, bold),
             pw.SizedBox(height: 30),
          ],

          pw.Text("Detailed Employee Report", style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 10),
          _buildDetailedTable(stats.values.toList(), font, bold),
          pw.SizedBox(height: 20),
          _buildPdfFooter(font),
        ]
      ));

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Attendance_Summary.pdf');

    } catch (e) {
      Get.snackbar("Error", "PDF Failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- PDF WIDGETS ---

  pw.Widget _buildPdfHeader(pw.Font font, pw.Font bold, pw.Font light) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("ATTENDANCE REPORT", style: pw.TextStyle(font: bold, fontSize: 20, color: PdfColors.blue900)),
            pw.Text("Generated by ClockInn", style: pw.TextStyle(font: light, fontSize: 10, color: PdfColors.grey700)),
          ]
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("${DateFormat('MMM dd').format(startDate.value)} - ${DateFormat('MMM dd, yyyy').format(endDate.value)}", style: pw.TextStyle(font: bold, fontSize: 12)),
            pw.Text("Scope: ${_siteNames[selectedSiteId.value] ?? 'All Sites'}", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
          ]
        )
      ]
    );
  }

  pw.Widget _buildExecutiveSummary(List<UserStat> stats, pw.Font font, pw.Font bold) {
    int totalPresent = stats.fold(0, (sum, item) => sum + item.present);
    int totalAbsent = stats.fold(0, (sum, item) => sum + item.absent);
    int totalLate = stats.fold(0, (sum, item) => sum + item.late);
    int totalExpected = totalPresent + totalAbsent;
    
    double rate = totalExpected == 0 ? 0 : (totalPresent / totalExpected) * 100;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300)
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfStatItem("Avg. Attendance", "${rate.toStringAsFixed(1)}%", PdfColors.blue, font, bold),
          _pdfStatItem("Total Present", "$totalPresent", PdfColors.green, font, bold),
          _pdfStatItem("Total Absent", "$totalAbsent", PdfColors.red, font, bold),
          _pdfStatItem("Late Arrivals", "$totalLate", PdfColors.orange, font, bold),
        ]
      )
    );
  }

  pw.Widget _pdfStatItem(String label, String value, PdfColor color, pw.Font font, pw.Font bold) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 18, color: color)),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
      ]
    );
  }

  pw.Widget _buildSitePerformanceTable(List<UserStat> sites, pw.Font font, pw.Font bold) {
    return pw.Table.fromTextArray(
      headers: ['Site Name', 'Present', 'Absent', 'Late', 'Total Hours'],
      data: sites.map((s) => [
        s.siteName, 
        s.present, 
        s.absent, 
        s.late, 
        "${s.totalHours.toStringAsFixed(1)}"
      ]).toList(),
      headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: PdfColors.grey300),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    );
  }

  pw.Widget _buildDetailedTable(List<UserStat> stats, pw.Font font, pw.Font bold) {
    return pw.Table.fromTextArray(
      headers: ['Employee', 'Site', 'Present', 'Absent', 'Late', 'Hrs', 'Score'],
      data: stats.map((s) {
        // Simple Score: (Present / Total Days) * 100
        double score = s.totalDays == 0 ? 0 : (s.present / s.totalDays) * 100;
        return [
          s.name, 
          s.siteName, 
          s.present, 
          s.absent, 
          s.late, 
          "${s.totalHours.toStringAsFixed(1)}",
          "${score.toStringAsFixed(0)}%"
        ];
      }).toList(),
      headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: PdfColors.grey300),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    );
  }

  pw.Widget _buildPdfFooter(pw.Font font) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
        pw.Text("Confidential Report", style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
      ])
    ]);
  }
}

// --- HELPER CLASSES ---
class SiteSchedule {
  final List<int> workingDays;
  final List<DateTime> holidays;
  SiteSchedule({required this.workingDays, required this.holidays});
}

class UserStat {
  final String name;
  String siteName;
  String siteId;
  int present = 0;
  int absent = 0;
  int late = 0;
  int totalDays = 0;
  double totalHours = 0.0;
  UserStat({required this.name, required this.siteName, required this.siteId});
}