import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShiftsController extends GetxController {
  var isLoading = true.obs;
  
  // FILTERS
  var selectedSiteId = "".obs;
  var selectedDate = DateTime.now().obs;

  // DATA LISTS
  var allShifts = <Map<String, dynamic>>[].obs;       // All shifts in DB
  var displayedShifts = <Map<String, dynamic>>[].obs; // Filtered for UI
  var availableSites = <Map<String, String>>[].obs;   // For Site Dropdown
  var eligibleEmployees = <Map<String, dynamic>>[].obs; // For "Add Shift" Dialog

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void fetchData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); 

    // 1. MOCK SITES
    availableSites.value = [
      {"id": "site_001", "name": "Accra Head Office"},
      {"id": "site_002", "name": "Kumasi Warehouse"},
    ];
    selectedSiteId.value = availableSites[0]['id']!;

    // 2. MOCK SHIFTS (Existing Roster)
    allShifts.value = [
      {
        "id": "s1",
        "siteId": "site_001",
        "userId": "u1",
        "userName": "Kofi Mensah",
        "userRole": "Security",
        "startTime": DateTime.now().add(const Duration(hours: 8)).toString(), // Today 8am
        "endTime": DateTime.now().add(const Duration(hours: 16)).toString(),  // Today 4pm
        "status": "scheduled",
        "color": 0xFF2196F3 // Blue
      },
      {
        "id": "s2",
        "siteId": "site_001",
        "userId": "u2",
        "userName": "Ama Osei",
        "userRole": "Cleaner",
        "startTime": DateTime.now().subtract(const Duration(hours: 2)).toString(), // Started 2 hours ago
        "endTime": DateTime.now().add(const Duration(hours: 6)).toString(),
        "status": "active",
        "color": 0xFF4CAF50 // Green
      }
    ];

    // 3. MOCK EMPLOYEES (Used for assigning new shifts)
    // Notice: 'John' is 'regular', so he won't appear in the Add Shift list
    var allEmployees = [
      {"id": "u1", "name": "Kofi Mensah", "siteId": "site_001", "type": "shift", "role": "Security"},
      {"id": "u2", "name": "Ama Osei", "siteId": "site_001", "type": "shift", "role": "Cleaner"},
      {"id": "u3", "name": "John Doe", "siteId": "site_001", "type": "regular", "role": "Manager"}, // REGULAR
      {"id": "u4", "name": "Yaw Boateng", "siteId": "site_002", "type": "shift", "role": "Forklift Driver"},
    ];

    // LOGIC: Filter employees for the currently selected site AND who are NOT 'regular'
    updateEligibleEmployees(allEmployees);
    
    filterShifts();
    isLoading.value = false;
  }

  void updateEligibleEmployees(List<Map<String, dynamic>> allEmps) {
    eligibleEmployees.value = allEmps.where((e) {
      return e['siteId'] == selectedSiteId.value && e['type'] != 'regular';
    }).toList();
  }

  void filterShifts() {
    // Show shifts that match the selected Site AND selected Date
    displayedShifts.value = allShifts.where((s) {
      bool siteMatch = s['siteId'] == selectedSiteId.value;
      // Simple date check (ignoring time)
      DateTime shiftDate = DateTime.parse(s['startTime']);
      bool dateMatch = shiftDate.year == selectedDate.value.year && 
                       shiftDate.month == selectedDate.value.month && 
                       shiftDate.day == selectedDate.value.day;
      return siteMatch && dateMatch;
    }).toList();
  }

  void changeSite(String newSiteId) {
    selectedSiteId.value = newSiteId;
    // In real app, re-fetch employees for this site here
    filterShifts();
  }

  void changeDate(DateTime newDate) {
    selectedDate.value = newDate;
    filterShifts();
  }

  void createShift(String userId, String userName, DateTime start, DateTime end) {
    var newShift = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "siteId": selectedSiteId.value,
      "userId": userId,
      "userName": userName,
      "userRole": "Assigned Role",
      "startTime": start.toString(),
      "endTime": end.toString(),
      "status": "scheduled",
      "color": 0xFFFF9800 // Orange
    };
    
    allShifts.add(newShift);
    filterShifts();
    Get.back();
    Get.snackbar("Success", "Shift assigned to $userName");
  }


  // ... inside ShiftsController class ...

  // UPDATED: Create shifts for MULTIPLE users at once
  void createBulkShifts(List<Map<String, dynamic>> users, DateTime start, DateTime end) {
    for (var user in users) {
      var newShift = {
        "id": DateTime.now().millisecondsSinceEpoch.toString() + user['id'], // Unique ID
        "siteId": selectedSiteId.value,
        "userId": user['id'],
        "userName": user['name'],
        "userRole": user['role'],
        "startTime": start.toString(),
        "endTime": end.toString(),
        "status": "scheduled",
        "color": 0xFFFF9800 // Orange
      };
      allShifts.add(newShift);
    }
    
    filterShifts(); // Refresh the list
    Get.back(); // Close dialog
    Get.snackbar("Success", "Assigned shift to ${users.length} employees");
  }



  void deleteShift(String id) {
    allShifts.removeWhere((s) => s['id'] == id);
    filterShifts();
  }
}