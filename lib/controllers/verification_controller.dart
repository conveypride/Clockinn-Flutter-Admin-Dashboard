import 'package:get/get.dart';

class VerificationController extends GetxController {
  var isLoading = true.obs;
  var waitingUsers = <Map<String, dynamic>>[].obs;
  
  // NEW: List of sites for the dropdown
  var availableSites = <String>[].obs; 
  var selectedSite = "".obs; // Holds the admin's choice

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void fetchData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); 

    // 1. MOCK WAITING USERS
    waitingUsers.value = [
      {
        "id": "user_111",
        "name": "Lgmg Best User",
        "email": "lgmguser@gmail.com",
        "phone": "0547867377",
        "role": "Employee",
        "picurl": "https://randomuser.me/api/portraits/men/32.jpg",
        "isActive": false,
        "addedon": "2025-12-09 16:53:22",
        // This 'department' coming from the user might be wrong/blank, 
        // that's why we force the Admin to pick a real Site below.
        "department": "LGMG ACCRA OFFICE", 
      },
      {
        "id": "user_222",
        "name": "Sarah Amankwah",
        "email": "sarah.am@gmail.com",
        "phone": "0201234567",
        "role": "Employee",
        "picurl": "https://randomuser.me/api/portraits/women/44.jpg",
        "isActive": false,
        "addedon": "2025-12-10 08:15:00",
        "department": "", 
      },
    ];

    // 2. MOCK AVAILABLE SITES (In real app, fetch this from 'sites' collection)
    availableSites.value = [
      "Accra Head Office",
      "Kumasi Warehouse",
      "Tamale Outlet",
      "Takoradi Hub"
    ];
    
    // Set default selection
    if (availableSites.isNotEmpty) selectedSite.value = availableSites[0];

    isLoading.value = false;
  }

  void approveUser(String uid, String assignedSite) {
    // In Firestore, you will update 'siteId' or 'department' to this value
    waitingUsers.removeWhere((user) => user['id'] == uid);
    Get.snackbar("Approved", "User verified and assigned to: $assignedSite");
  }

  void rejectUser(String uid) {
    waitingUsers.removeWhere((user) => user['id'] == uid);
    Get.snackbar("Rejected", "User request denied");
  }
}