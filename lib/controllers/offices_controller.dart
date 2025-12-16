import 'package:get/get.dart';

class OfficesController extends GetxController {
  var isLoading = true.obs;
  var sites = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSites();
  }

  void fetchSites() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulate Network Delay
    
    // UPDATED MOCK DATA (Matches your Firestore Schema)
    sites.value = [
      {
        "id": "site_001", // Document ID
        "nameofsite": "Accra Head Office",
        "location": "Accra Head Office",
        "openingTime": "08:30",
        "closingTime": "17:00",
        "isHQ": true,
        "status": true, // Active
        "lat": "5.6339687",
        "lng": "-0.1432133",
        "radius": 300,
        "officeimage": "1749117438.jpg",
        "workingdays": ["mon", "tue", "wed", "thu", "fri"],
        "datejoined": "2025-06-05 09:57:20", // Simplified timestamp for display
      },
      {
        "id": "site_002",
        "nameofsite": "Kumasi Warehouse",
        "location": "Kumasi Central",
        "openingTime": "08:00",
        "closingTime": "18:00",
        "isHQ": false,
        "status": true,
        "lat": "6.68848",
        "lng": "-1.62443",
        "radius": 500,
        "officeimage": "",
        "workingdays": ["mon", "tue", "wed", "thu", "fri", "sat"],
        "datejoined": "2025-07-10 10:00:00",
      },
      {
        "id": "site_003",
        "nameofsite": "Tamale Outlet",
        "location": "Tamale North",
        "openingTime": "09:00",
        "closingTime": "16:00",
        "isHQ": false,
        "status": false, // Inactive
        "lat": "9.4075",
        "lng": "-0.8534",
        "radius": 200,
        "officeimage": "",
        "workingdays": ["mon", "tue", "wed"],
        "datejoined": "2025-08-01 08:30:00",
      },
    ];
    isLoading.value = false;
  }

  void deleteSite(String id) {
    sites.removeWhere((site) => site['id'] == id);
    Get.snackbar("Success", "Site deleted successfully");
  }
}