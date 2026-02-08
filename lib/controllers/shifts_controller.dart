import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart'; 

class ShiftsController extends GetxController {
  var isLoading = true.obs;
  
  // --- STATE ---
  var currentWeekStartDate = _getStartOfWeek(DateTime.now()).obs;
  var selectedSiteId = "".obs;
  var availableSites = <Map<String, String>>[].obs;
  
  // DATA
  var siteEmployees = <Map<String, dynamic>>[].obs; 
  var weeklyShifts = <Map<String, dynamic>>[].obs; 

  // TEMPLATES
  final shiftTemplates = [
    {"name": "Morning", "start": "06:00", "end": "14:00", "color": 0xFF4CAF50},
    {"name": "Afternoon", "start": "14:00", "end": "22:00", "color": 0xFFFF9800},
    {"name": "Night", "start": "22:00", "end": "06:00", "color": 0xFF9C27B0},
    {"name": "Full Day", "start": "08:00", "end": "17:00", "color": 0xFF2196F3},
  ];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LoginController auth = Get.find<LoginController>();

  @override
  void onInit() {
    super.onInit();
    if (auth.companyId.value.isNotEmpty) {
      _fetchSites();
    }
    ever(auth.companyId, (String id) {
      if (id.isNotEmpty) _fetchSites();
    });
  }

  // ---------------------------------------------------------------------------
  // 🛠️ FIX 1: STRIP TIME FROM DATES
  // ---------------------------------------------------------------------------
  static DateTime _getStartOfWeek(DateTime date) {
    // 1. Calculate Monday
    var monday = date.subtract(Duration(days: date.weekday - 1));
    // 2. Return Midnight (00:00:00) to ensure full day coverage
    return DateTime(monday.year, monday.month, monday.day);
  }

  // 1. FETCH SITES 
  void _fetchSites() async {
    isLoading.value = true;
    try {
      String cid = auth.companyId.value;
      if (cid.isEmpty) { isLoading.value = false; return; }

      String mySiteId = auth.managedSiteId.value;
      String myRole = auth.userRole.value;

      Query query = _db.collection('operationSites')
          .doc(cid)
          .collection('sites')
          .where('status', isEqualTo: true);
      
      if (myRole == "Branch Manager" && mySiteId.isNotEmpty) {
        query = query.where(FieldPath.documentId, isEqualTo: mySiteId);
      }

      var snap = await query.get();
      availableSites.value = snap.docs.map((d) => {
        "id": d.id,
        "name": d['nameofsite'].toString()
      }).toList();

      if (availableSites.isNotEmpty) {
        if (selectedSiteId.value.isEmpty || !availableSites.any((s) => s['id'] == selectedSiteId.value)) {
          selectedSiteId.value = availableSites.first['id']!;
        }
        loadRosterData();
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      print("Error fetching sites: $e");
      isLoading.value = false;
    }
  }

  // 2. LOAD ROSTER 
  void loadRosterData() async {
    if (selectedSiteId.value.isEmpty) return;
    
    isLoading.value = true;
    String cid = auth.companyId.value;
    if (cid.isEmpty) return;

    try {
      // A. Get Employees
      var usersSnap = await _db.collection('users')
          .doc(cid)
          .collection('sites')
          .doc(selectedSiteId.value)
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      siteEmployees.value = usersSnap.docs.map((d) {
        var data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      // -----------------------------------------------------------------------
      // 🛠️ FIX 2: ENSURE QUERY COVERS FULL DAYS
      // -----------------------------------------------------------------------
      // Start: Monday 00:00:00
      DateTime start = currentWeekStartDate.value; 
      // End: Next Monday 00:00:00 (Greater than Sunday 23:59)
      DateTime end = start.add(const Duration(days: 7)); 

      var shiftsSnap = await _db.collection('users')
          .doc(cid)
          .collection('sites')
          .doc(selectedSiteId.value)
          .collection('shifts')
          .where('startTime', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('startTime', isLessThan: end.toIso8601String())
          .get();

      weeklyShifts.value = shiftsSnap.docs.map((d) {
        var data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

    } catch (e) {
      Get.snackbar("Error", "Could not load roster: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 3. CREATE SHIFT
  Future<void> assignShift({
    required String userId,
    required String userName,
    required String userRole,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int weeksToRepeat,
    required int color,
  }) async {
    try {
      String cid = auth.companyId.value;
      WriteBatch batch = _db.batch();
      CollectionReference shiftsRef = _db.collection('users')
          .doc(cid)
          .collection('sites')
          .doc(selectedSiteId.value)
          .collection('shifts');

      for (int i = 0; i < weeksToRepeat; i++) {
        // Ensure we are adding days to the BASE date (Midnight)
        DateTime shiftDay = DateTime(date.year, date.month, date.day).add(Duration(days: i * 7));
        
        DateTime startDt = DateTime(shiftDay.year, shiftDay.month, shiftDay.day, start.hour, start.minute);
        DateTime endDt = DateTime(shiftDay.year, shiftDay.month, shiftDay.day, end.hour, end.minute);
        
        if (endDt.isBefore(startDt)) endDt = endDt.add(const Duration(days: 1));

        String docId = shiftsRef.doc().id;
        batch.set(shiftsRef.doc(docId), {
          "userId": userId,
          "userName": userName,
          "userRole": userRole,
          "startTime": startDt.toIso8601String(),
          "endTime": endDt.toIso8601String(),
          "color": color, // Save as INT (e.g. 4283215696)
          "status": "scheduled",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      loadRosterData();
      Get.back();
      Get.snackbar("Success", "Shift assigned successfully", 
          backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", "Assignment failed: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // 4. DELETE SHIFT
  Future<void> deleteShift(String shiftId) async {
    try {
      Get.back(); // Close dialog
      isLoading.value = true;
      String cid = auth.companyId.value;
      
      await _db.collection('users')
          .doc(cid)
          .collection('sites')
          .doc(selectedSiteId.value)
          .collection('shifts')
          .doc(shiftId)
          .delete();
      
      // Refresh strictly from DB
      loadRosterData(); 
      Get.snackbar("Deleted", "Shift removed.", backgroundColor: Colors.grey, colorText: Colors.white);

    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not delete: $e");
    }
  }

  // 5. COPY PREVIOUS WEEK
  Future<void> copyPreviousWeek() async {
    isLoading.value = true;
    try {
      String cid = auth.companyId.value;
      CollectionReference shiftsRef = _db.collection('users')
          .doc(cid)
          .collection('sites')
          .doc(selectedSiteId.value)
          .collection('shifts');

      DateTime prevStart = currentWeekStartDate.value.subtract(const Duration(days: 7));
      DateTime prevEnd = currentWeekStartDate.value;

      var prevSnap = await shiftsRef
          .where('startTime', isGreaterThanOrEqualTo: prevStart.toIso8601String())
          .where('startTime', isLessThan: prevEnd.toIso8601String())
          .get();

      if (prevSnap.docs.isEmpty) {
        Get.snackbar("Info", "No shifts found in previous week.");
        isLoading.value = false;
        return;
      }

      WriteBatch batch = _db.batch();
      int count = 0;

      for (var doc in prevSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime oldStart = DateTime.parse(data['startTime']);
        DateTime oldEnd = DateTime.parse(data['endTime']);
        
        DateTime newStart = oldStart.add(const Duration(days: 7));
        DateTime newEnd = oldEnd.add(const Duration(days: 7));

        var newRef = shiftsRef.doc();
        batch.set(newRef, {
          ...data,
          "startTime": newStart.toIso8601String(),
          "endTime": newEnd.toIso8601String(),
          "createdAt": FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      loadRosterData();
      Get.snackbar("Success", "Copied $count shifts!", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      Get.snackbar("Error", "Copy failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // CONTROLS
  void nextWeek() {
    currentWeekStartDate.value = currentWeekStartDate.value.add(const Duration(days: 7));
    loadRosterData();
  }

  void prevWeek() {
    currentWeekStartDate.value = currentWeekStartDate.value.subtract(const Duration(days: 7));
    loadRosterData();
  }

  void changeSite(String id) {
    selectedSiteId.value = id;
    loadRosterData();
  }
}