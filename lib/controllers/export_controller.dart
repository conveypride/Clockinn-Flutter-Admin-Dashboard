import 'dart:io';
import 'dart:js_interop';
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
  var loadingMessage = "".obs; // 🆕 For showing progress
  
  // Filters
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;
  
  var selectedSiteId = "All".obs;
  var selectedUserId = "All".obs;
  var selectedAttendanceStatus = "All".obs; // 🆕 NEW FILTER

  // Dropdown Data
  var sites = <Map<String, String>>[].obs;
  var users = <Map<String, String>>[].obs;

  // 🧠 Smart Caches
  final Map<String, String> _userNames = {};
  final Map<String, String> _siteNames = {};
  final Map<String, SiteSchedule> _siteSchedules = {};
  final Map<String, DateTime> _userVerifiedDates = {}; // 🆕 Track hire dates

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
      print("📂 Loading sites for company: $cid");
      var sitesSnap = await _db.collection('operationSites')
          .doc(cid).collection('sites').get();
      
      print("   Found ${sitesSnap.docs.length} sites");
      
      sites.assignAll(sitesSnap.docs.map((d) {
        final data = d.data(); 
        String name = data['nameofsite']?.toString() ?? "Unknown Site";
        
        print("   📍 Site: $name (${d.id})");
        _siteNames[d.id] = name; // ← Cache it
        _cacheSiteSchedule(d.id, data); 
        
        return {'id': d.id, 'name': name};
      }).toList());

      sites.insert(0, {'id': 'All', 'name': 'All Sites'});
      selectedSiteId.value = "All";
      await _loadUsersForSite("All"); 

    } else {
      selectedSiteId.value = mySite;
      print("📂 Loading single site: $mySite");
      var siteDoc = await _db.collection('operationSites')
          .doc(cid).collection('sites').doc(mySite).get();
          
      if (siteDoc.exists) {
         final data = siteDoc.data()!;
         String name = data['nameofsite']?.toString() ?? "My Site";
         
         print("   📍 Site: $name");
         _siteNames[mySite] = name;
         _cacheSiteSchedule(mySite, data);
         sites.assignAll([{'id': mySite, 'name': name}]);
      } else {
        print("   ⚠️  Site document not found: $mySite");
      }
      await _loadUsersForSite(mySite);
    }
    
    print("✅ Loaded ${sites.length} sites, cached ${_siteNames.length} site names");
  } catch (e) {
    print("❌ Error loading filters: $e");
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
    List<QueryDocumentSnapshot> allUserDocs = [];
    Map<String, String> docToSiteMap = {}; // Map docId to siteId
    
    if (siteId == "All") {
      print("🔍 Loading ALL users from all sites...");
      print("   Company ID: $cid");
      print("   Available sites: ${sites.length - 1}");
      
      // Load from each site individually
      for (var site in sites) {
        if (site['id'] == 'All') continue;
        
        String siteName = site['name']!;
        String siteIdValue = site['id']!;
        
        print("   📂 Loading from: $siteName ($siteIdValue)");
        
        try {
          var siteSnap = await _db
              .collection('users')
              .doc(cid)
              .collection('sites')
              .doc(siteIdValue)
              .collection('users')
              .where('isActive', isEqualTo: true)
              .where('isVerified', isEqualTo: true)
              .get();
          
          print("      → Found ${siteSnap.docs.length} users");
          
          // Track which site each user belongs to
          for (var doc in siteSnap.docs) {
            docToSiteMap[doc.id] = siteIdValue;
          }
          
          allUserDocs.addAll(siteSnap.docs);
          
        } catch (e) {
          print("      ⚠️  Error loading from $siteName: $e");
        }
      }
      
      print("   ✅ Total users loaded: ${allUserDocs.length}");
      
    } else {
      print("🔍 Loading users for site: $siteId");
      var siteSnap = await _db
          .collection('users')
          .doc(cid)
          .collection('sites')
          .doc(siteId)
          .collection('users')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();
      
      print("   Found ${siteSnap.docs.length} users");
      
      // Track site for all users
      for (var doc in siteSnap.docs) {
        docToSiteMap[doc.id] = siteId;
      }
      
      allUserDocs.addAll(siteSnap.docs);
    }
    
    // Process all loaded users
    for (var doc in allUserDocs) {
      final data = doc.data() as Map<String, dynamic>;
      
      String name = data['name']?.toString() ?? "Unknown User";
      
      // ✅ FIX: Get siteId from document OR from query path
      String userSiteId = data['siteId']?.toString() ?? "";
      
      // If siteId is empty in document, use the one from query path
      if (userSiteId.isEmpty && docToSiteMap.containsKey(doc.id)) {
        userSiteId = docToSiteMap[doc.id]!;
        print("   ℹ️  User ${name} missing siteId in document, using path: $userSiteId");
      }
      
      _userNames[doc.id] = name;

      // Cache verified date
      if (data['dateVerified'] != null && data['dateVerified'] != "") {
        try {
          _userVerifiedDates[doc.id] = (data['dateVerified'] as Timestamp).toDate();
        } catch (_) {}
      }
      
      // ✅ Resolve site name
      String siteName = "Unknown Site";
      if (userSiteId.isNotEmpty) {
        if (_siteNames.containsKey(userSiteId)) {
          siteName = _siteNames[userSiteId]!;
        } else {
          siteName = await _resolveSiteName(userSiteId);
        }
      }
      
      print("   👤 $name → $siteName ($userSiteId)");
      
      tempUsers.add({
        'id': doc.id, 
        'name': name, 
        'siteId': userSiteId,  // ← Now guaranteed to have a value
        'siteName': siteName,
        'role': data['role']?.toString() ?? "Employee"
      });
    }
    
    print("✅ Processed ${tempUsers.length} users");
    
    if (tempUsers.isEmpty) {
      print("⚠️  No active & verified users found");
    }
    
    // Sort and update
    tempUsers.sort((a, b) => a['name']!.compareTo(b['name']!));
    users.assignAll(tempUsers);
    users.insert(0, {'id': 'All', 'name': 'All Employees'});
    selectedUserId.value = "All";
    
    print("📊 Users list updated: ${users.length - 1} employees available\n");

  } catch (e) {
    print("❌ ERROR loading users: $e");
    users.assignAll([{'id': 'All', 'name': 'All Employees'}]);
    
    Get.snackbar(
      "Loading Error", 
      "Failed to load employees. Please check your connection.", 
      backgroundColor: Colors.orange, 
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4)
    );
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
  if (siteId.isEmpty) return "Unknown Site";
  if (_siteNames.containsKey(siteId)) return _siteNames[siteId]!;
  
  try {
    print("🔍 Resolving site name for: $siteId");
    var doc = await _db.collection('operationSites')
        .doc(auth.companyId.value)
        .collection('sites')
        .doc(siteId)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      String name = data?['nameofsite']?.toString() ?? "Unknown Site";
      print("   ✅ Found: $name");
      _siteNames[siteId] = name;
      _cacheSiteSchedule(siteId, data!);
      return name;
    } else {
      print("   ⚠️  Site document does not exist: $siteId");
    }
  } catch (e) {
    print("   ❌ Error resolving site $siteId: $e");
  }
  
  _siteNames[siteId] = "Unknown Site"; // Cache the failure to avoid repeated queries
  return "Unknown Site";
}

  // ===========================================================================
  // 📊 OPTIMIZED DATA FETCHING ENGINE (COST-EFFECTIVE)
  // ===========================================================================
  
  Future<List<Map<String, dynamic>>> _fetchAndProcessData() async {
    String cid = auth.companyId.value; 
  
  // ⚠️ CRITICAL: Ensure users are loaded before processing
  if (users.length <= 1) { 
    print("⚠️ Users not loaded yet, loading now...");
    loadingMessage.value = "Loading employee list...";
    await _loadUsersForSite(selectedSiteId.value);
    
    if (users.length <= 1) {
      throw Exception("No active employees found. Please check user setup.");
    }
  }
  
    loadingMessage.value = "Fetching attendance records...";
    
    // ============================================================
    // STEP 1: Fetch ALL attendance records for date range (ONCE)
    // Cost: ~1 read per document in range (most efficient)
    // ============================================================
    
    Query query = _db.collectionGroup('records')
        .where('companyId', isEqualTo: cid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(startDate.value.year, startDate.value.month, startDate.value.day)
        ))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(
          DateTime(endDate.value.year, endDate.value.month, endDate.value.day, 23, 59, 59)
        ));

print("selected site: ${selectedSiteId.value}");
    // Apply site filter if specific site selected
    if (selectedSiteId.value != "All") {
      query = query.where('siteId', isEqualTo: selectedSiteId.value);
    }

    var snapshot = await query.get();
    
    
    // ============================================================
    // STEP 2: Build in-memory lookup map (FREE - no reads)
    // Key: "userId_YYYY-MM-DD" → Fast O(1) lookup
    // ============================================================
    
    Map<String, Map<String, dynamic>> attendanceMap = {};
    Map<String, Set<String>> userAttendanceDates = {}; // userId → {dates}
    for (var doc in snapshot.docs) {
  var data = doc.data() as Map<String, dynamic>;

  String userId = data['userId']?.toString() ?? "";
  if (userId.isEmpty) continue;
  
  // ✅ Also check if siteId is empty in attendance records
  String recordSiteId = data['siteId']?.toString() ?? "";
  if (recordSiteId.isEmpty) {
    print("⚠️  Attendance record missing siteId for user: $userId on date: ${data['date']}");
  }
  
  // Use 'date' field (00:00:00 timestamp) for accurate day matching
  DateTime recordDate = (data['date'] as Timestamp).toDate();
  String dateKey = DateFormat('yyyy-MM-dd').format(recordDate);
  String lookupKey = "${userId}_$dateKey";
   
  // Track attendance dates per user
  userAttendanceDates.putIfAbsent(userId, () => {}).add(dateKey);
  
  // Store full record
  attendanceMap[lookupKey] = data;

      
    }
    
    loadingMessage.value = "Processing ${snapshot.docs.length} attendance records...";
    
    // ============================================================
    // STEP 3: Use CACHED users list (FREE - already loaded)
    // No additional Firestore reads needed!
    // ============================================================
     print("=== DEBUG INFO ===");
print("selectedUserId.value: ${selectedUserId.value}");
print("selectedSiteId.value: ${selectedSiteId.value}");
print("users.length: ${users.length}");
print("users list: ${users.map((u) => '${u['name']} (${u['id']})').toList()}");
print("==================");

List<String> userIdsToProcess = [];

if (selectedUserId.value != "All") {
  userIdsToProcess.add(selectedUserId.value);
} else {
  // Get all users from cached list
  for (var u in users) {
    print("Processing user: ${u['name']} - ID: ${u['id']} - SiteID: ${u['siteId']}");
    
    if (u['id'] == "All") {
      print("  → Skipped (All option)");
      continue;
    }
    
    // Filter by site if specific site selected
    bool shouldInclude = selectedSiteId.value == "All" || u['siteId'] == selectedSiteId.value;
    print("  → Should include? $shouldInclude (selectedSite: ${selectedSiteId.value}, userSite: ${u['siteId']})");
    
    if (shouldInclude) {
      userIdsToProcess.add(u['id']!);
      print("  → ✅ Added to processing list");
    }
  }
}

print("Final userIdsToProcess.length: ${userIdsToProcess.length}");
loadingMessage.value = "Calculating absences for ${userIdsToProcess.length} employees...";
    // ============================================================
    // STEP 4: Build complete records list (in memory - FREE)
    // ============================================================
    
    List<Map<String, dynamic>> processedRecords = [];
    int totalDays = endDate.value.difference(startDate.value).inDays + 1;
    for (String userId in userIdsToProcess) {
  // Get cached user info
  String userName = _userNames[userId] ?? "Unknown";
  String userSiteId = "";
  String userSiteName = "Unknown Site";
  String userRole = "Employee";
  
  // First, try to get from users list
  for (var u in users) {
    if (u['id'] == userId) {
      userSiteId = u['siteId'] ?? "";
      userRole = u['role'] ?? "Employee";
      userSiteName = u['siteName'] ?? "";
      break;
    }
  }
  
  // If siteName is empty or unknown, resolve it now
  if (userSiteId.isNotEmpty && (userSiteName.isEmpty || userSiteName == "Unknown Site")) {
    // Check cache first
    if (_siteNames.containsKey(userSiteId)) {
      userSiteName = _siteNames[userSiteId]!;
    } else {
      // Resolve from Firestore
      userSiteName = await _resolveSiteName(userSiteId);
    }
  }
  
  print("👤 Processing: $userName at $userSiteName ($userSiteId)");
  
  // Get user's hire date
  DateTime userStartDate = startDate.value;
  if (_userVerifiedDates.containsKey(userId)) {
    DateTime verifiedDate = _userVerifiedDates[userId]!;
    if (verifiedDate.isAfter(startDate.value)) {
      userStartDate = verifiedDate;
    }
  }
  
  // Get site schedule
  SiteSchedule? schedule = _siteSchedules[userSiteId];
  
  // Check each day in range
  for (int i = 0; i < totalDays; i++) {
    DateTime day = startDate.value.add(Duration(days: i));
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    String lookupKey = "${userId}_$dateKey";
    
    bool hasAttendance = attendanceMap.containsKey(lookupKey);
    
    if (hasAttendance) {
      // Present record
      var data = attendanceMap[lookupKey]!;

      // ✅ Skip records with invalid/missing timestamps
      var checkInTimeVal = data['checkInTime'];
      if (checkInTimeVal == null || checkInTimeVal == "") {
        continue;
      }

      DateTime checkIn = (checkInTimeVal as Timestamp).toDate();

      DateTime? checkOut = null;
      var checkOutTimeVal = data['checkOutTime'];
      if (checkOutTimeVal != null && checkOutTimeVal != "") {
        checkOut = (checkOutTimeVal as Timestamp).toDate();
      }
      
      double hours = 0.0;
      String durationStr = data['workingHours']?.toString() ?? "0.0";
      
      if (durationStr != "0.0" && durationStr.contains(':')) {
        try {
          var parts = durationStr.split(':');
          hours = double.parse(parts[0]) + (double.parse(parts[1]) / 60.0);
        } catch (_) {}
      } else if (checkOut != null) {
        hours = checkOut.difference(checkIn).inMinutes / 60.0;
        durationStr = hours.toStringAsFixed(1);
      }

      int lateMins = 0;
      String status = "Present";
      
      if (data['markAs']?.toString().toLowerCase().contains('late') ?? false) {
        DateTime expected = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 30);
        if (checkIn.isAfter(expected)) {
          lateMins = checkIn.difference(expected).inMinutes;
          status = "Late";
        }
      }

      processedRecords.add({
        'date': dateKey,
        'name': userName,
        'site': userSiteName,  // ← Now properly resolved
        'siteId': userSiteId,
        'userId': userId,
        'role': userRole,
        'in': DateFormat('HH:mm').format(checkIn),
        'out': checkOut != null ? DateFormat('HH:mm').format(checkOut) : "Active",
        'hoursStr': durationStr,
        'hoursVal': hours,
        'status': status,
        'late': lateMins,
        'notes': data['comments']?.toString() ?? "",
        'recordType': 'actual'
      });
      
    } else {
      // Absence record - only after verification
      if (day.isBefore(userStartDate)) continue;
      
      bool isWorkDay = true;
      bool isHoliday = false;

      if (schedule != null) {
        isWorkDay = schedule.workingDays.contains(day.weekday);
        isHoliday = schedule.holidays.any((h) => DateUtils.isSameDay(h, day));
      } else {
        isWorkDay = day.weekday >= 1 && day.weekday <= 5;
      }

      if (isWorkDay && !isHoliday) {
        processedRecords.add({
          'date': dateKey,
          'name': userName,
          'site': userSiteName,  // ← Now properly resolved
          'siteId': userSiteId,
          'userId': userId,
          'role': userRole,
          'in': "-",
          'out': "-",
          'hoursStr': "0.0",
          'hoursVal': 0.0,
          'status': "Absent",
          'late': 0,
          'notes': "No attendance record",
          'recordType': 'absence'
        });
      }
    }
  }
}
    
    // ============================================================
    // STEP 5: Apply attendance status filter (in memory - FREE)
    // ============================================================
    
    if (selectedAttendanceStatus.value != "All") {
      processedRecords = processedRecords.where((record) {
        String status = record['status'].toString();
        
        switch (selectedAttendanceStatus.value) {
          case "Present":
            return status == "Present";
          case "Absent":
            return status == "Absent";
          case "Late":
            return status == "Late";
          default:
            return true;
        }
      }).toList();
    }
    
    // ============================================================
    // STEP 6: Sort records
    // ============================================================
    
    processedRecords.sort((a, b) {
      int dateComp = a['date'].compareTo(b['date']);
      if (dateComp != 0) return dateComp;
      return a['name'].compareTo(b['name']);
    });

    loadingMessage.value = "";
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
      Get.snackbar(
        "No Data", 
        "No records found for the selected filters.", 
        backgroundColor: Colors.orange, 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP
      );
      isLoading.value = false;
      return;
    }

    loadingMessage.value = "Generating Excel file...";

    var excel = Excel.createExcel();
    Sheet sheet = excel['Attendance Report'];
    
    // Header row
    sheet.appendRow([
      "Date", "Employee Name", "Site", "Role", 
      "Check In", "Check Out", "Work Duration", 
      "Status", "Late (Mins)", "Comments"
    ].map((e) => TextCellValue(e)).toList());

    // Data rows
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
    String fileName = "Attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx";

    if (fileBytes != null) {
      if (kIsWeb) {
         // Create blob with proper MIME type
    final blob = html.Blob(
      [fileBytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    
    // Create download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.style.display = 'none';
    
    // Add to document, click, then remove
    html.document.body?.append(anchor);
    anchor.click();
    
    // Cleanup
    await Future.delayed(const Duration(milliseconds: 100));
    anchor.remove();
    html.Url.revokeObjectUrl(url);
        
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(fileBytes);
        await OpenFile.open(file.path);
      }
      
      Get.snackbar(
        "Success", 
        "Excel report downloaded successfully (${records.length} records)", 
        backgroundColor: Colors.green, 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP
      );
    }

  } catch (e) {
     print(e);
    Get.snackbar(
      "Error", 
      "Failed to generate Excel: $e", 
      backgroundColor: Colors.red, 
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP
    );
  } finally {
    isLoading.value = false;
    loadingMessage.value = "";
  }
}
  
  // ===========================================================================
  // 🔴 PDF SUMMARY GENERATION (FIXED SCORING)
  // ===========================================================================
  void generatePdfSummary() async {
    isLoading.value = true;
    try {
      List<Map<String, dynamic>> records = await _fetchAndProcessData();
      
      Map<String, UserStat> stats = {};
      Map<String, UserStat> siteStats = {}; 

      // 1. Initialize Users from cache/dropdown so everyone is included
      for (var u in users) {
        if (u['id'] == "All") continue;
        if (selectedUserId.value != "All" && u['id'] != selectedUserId.value) continue;
        
        String name = u['name'] ?? "Unknown";
        // Attempt resolve if unknown
        if (name == "Unknown" || name.contains("Unknown User")) {
           name = await _resolveUserName(u['id']!);
        }

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

      // 🧠 TRACKER: Keep track of which days we have already counted for each user
      // Format: "userId_2023-10-25"
      Set<String> processedDays = {}; 

      // 2. Process Records
      for (var rec in records) {
        String uid = rec['userId'];
        String sid = rec['siteId'];
        String dateKey = rec['date']; // "yyyy-MM-dd"
        String uniqueKey = "${uid}_$dateKey"; // Unique ID for this User+Day combo

        if (!stats.containsKey(uid)) {
           // Create stat entry if missing (e.g. user not in dropdown list)
           stats[uid] = UserStat(name: rec['name'], siteName: rec['site'], siteId: sid);
        }
        
        var s = stats[uid]!;
        s.siteId = sid; 
        s.siteName = rec['site'];

        // Init site stat if missing
        if (!siteStats.containsKey(sid)) {
           siteStats[sid] = UserStat(name: rec['site'], siteName: rec['site'], siteId: sid);
        }

        // --- 🛑 THE FIX: DEDUPLICATION LOGIC ---
        
        // Always add hours (hours are cumulative even if multiple records)
        s.totalHours += (rec['hoursVal'] as double);
        siteStats[sid]!.totalHours += (rec['hoursVal'] as double);

        // ONLY increment "Present" count if we haven't seen this day for this user yet
        if (!processedDays.contains(uniqueKey)) {
           
           if (rec['status'] != "Absent") {
             s.present++;           // User Present count
             siteStats[sid]!.present++; // Site Present count
             
             // Mark as processed so we don't count it again for this user
             processedDays.add(uniqueKey);
           }

           // Count Lateness (Only once per day ideally)
           if ((rec['late'] as int) > 0) {
             s.late++;
             siteStats[sid]!.late++;
           }
        }
      }

      // 3. Calculate Absences (Days - Present)
      int totalDaysInRange = endDate.value.difference(startDate.value).inDays + 1;
      
      stats.forEach((uid, user) {
        SiteSchedule? schedule = _siteSchedules[user.siteId];
        int expectedWorkDays = 0;
        
        for (int i = 0; i < totalDaysInRange; i++) {
          DateTime day = startDate.value.add(Duration(days: i));
          bool isWork = true;
          bool isHoliday = false;

          if (schedule != null) {
             isWork = schedule.workingDays.contains(day.weekday);
             isHoliday = schedule.holidays.any((h) => DateUtils.isSameDay(h, day));
          } else {
             isWork = day.weekday <= 5; // Default Mon-Fri
          }

          if (isWork && !isHoliday) expectedWorkDays++;
        }
        
        // Prevent negative absences if logic drifts, but clamp ensures 0 minimum
        user.absent = (expectedWorkDays - user.present).clamp(0, expectedWorkDays);
        user.totalDays = expectedWorkDays;
        
        // Aggregate to Site Stats
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
      print(e);
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
            pw.Text("Generated by ClockInngh.com", style: pw.TextStyle(font: light, fontSize: 10, color: PdfColors.grey700)),
          ]
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              "${DateFormat('MMM dd').format(startDate.value)} - ${DateFormat('MMM dd, yyyy').format(endDate.value)}", 
              style: pw.TextStyle(font: bold, fontSize: 12)
            ),
            pw.Text(
              "Scope: ${_siteNames[selectedSiteId.value] ?? 'All Sites'}", 
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)
            ),
          ]
        )
      ]
    );
  }

  pw.Widget _buildExecutiveSummary(List<UserStat> stats, pw.Font font, pw.Font bold) {
    int totalPresent = stats.fold(0, (sum, item) => sum + item.present);
    int totalAbsent = stats.fold(0, (sum, item) => sum + item.absent);
    int totalLate = stats.fold(0, (sum, item) => sum + item.late);
    int totalExpected = stats.fold(0, (sum, item) => sum + item.totalDays);
    
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
        s.totalHours.toStringAsFixed(1)
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
        double score = s.totalDays == 0 ? 0 : (s.present / s.totalDays) * 100;
        return [
          s.name, 
          s.siteName, 
          s.present, 
          s.absent, 
          s.late, 
          s.totalHours.toStringAsFixed(1),
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
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, 
        children: [
          pw.Text(
            "Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", 
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)
          ),
          pw.Text(
            "Confidential Report", 
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)
          ),
        ]
      )
    ]);
  }
}

// ===========================================================================
// HELPER CLASSES
// ===========================================================================

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

 