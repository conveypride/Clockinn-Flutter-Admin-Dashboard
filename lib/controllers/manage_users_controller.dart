import 'package:get/get.dart';

class ManageUsersController extends GetxController {
  var isLoading = true.obs;
  var allUsers = <Map<String, dynamic>>[].obs; // The full dataset
  var displayedUsers = <Map<String, dynamic>>[].obs; // The filtered dataset for UI

  // Dropdown Data for Edit Dialog
  var availableRoles = ["Super Admin", "Branch Manager", "Employee", "Secretary"];
  var availableSites = ["Accra Head Office", "Kumasi Warehouse", "Tamale Outlet", "Takoradi Hub"];

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulate Network

    // MOCK DATA: Active Users
    var mockData = [
      {
        "id": "u1",
        "name": "John Doe",
        "email": "john.doe@clockinn.com",
        "phone": "0541112222",
        "role": "Super Admin",
        "department": "Accra Head Office",
        "isActive": true,
        "picurl": "https://randomuser.me/api/portraits/men/1.jpg",
        "employeeType": "regular"
      },
      {
        "id": "u2",
        "name": "Jane Smith",
        "email": "jane.smith@clockinn.com",
        "phone": "0209998888",
        "role": "Branch Manager",
        "department": "Kumasi Warehouse",
        "isActive": true,
        "picurl": "https://randomuser.me/api/portraits/women/2.jpg",
        "employeeType": "regular"
      },
      {
        "id": "u3",
        "name": "Kofi Mensah",
        "email": "kofi.m@clockinn.com",
        "phone": "0557776666",
        "role": "Employee",
        "department": "Accra Head Office",
        "isActive": true,
        "picurl": "", // No Image
        "employeeType": "contract"
      },
      {
        "id": "u4",
        "name": "Ama Osei",
        "email": "ama.osei@clockinn.com",
        "phone": "0245554444",
        "role": "Employee",
        "department": "Tamale Outlet",
        "isActive": false, // Suspended User
        "picurl": "https://randomuser.me/api/portraits/women/5.jpg",
        "employeeType": "regular"
      },
    ];

    allUsers.value = mockData;
    displayedUsers.value = mockData; // Initially show everyone
    isLoading.value = false;
  }

  // --- ACTIONS ---

  void filterUsers(String query) {
    if (query.isEmpty) {
      displayedUsers.value = allUsers;
    } else {
      displayedUsers.value = allUsers.where((user) {
        return user['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
               user['email'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  void updateUser(String uid, String newRole, String newSite) {
    // Logic to update Firestore
    int index = allUsers.indexWhere((u) => u['id'] == uid);
    if (index != -1) {
      var updatedUser = Map<String, dynamic>.from(allUsers[index]);
      updatedUser['role'] = newRole;
      updatedUser['department'] = newSite;
      
      allUsers[index] = updatedUser;
      filterUsers(""); // Refresh list
    }
    Get.back(); // Close Dialog
    Get.snackbar("Success", "User profile updated successfully");
  }

  void toggleUserStatus(String uid, bool currentStatus) {
    // Logic to suspend/activate user
    int index = allUsers.indexWhere((u) => u['id'] == uid);
    if (index != -1) {
      var updatedUser = Map<String, dynamic>.from(allUsers[index]);
      updatedUser['isActive'] = !currentStatus;
      allUsers[index] = updatedUser;
      filterUsers("");
    }
    Get.snackbar("Status Updated", "User is now ${!currentStatus ? 'Active' : 'Inactive'}");
  }
  
  void deleteUser(String uid) {
    allUsers.removeWhere((u) => u['id'] == uid);
    filterUsers("");
    Get.snackbar("Deleted", "User removed from system");
  }
}