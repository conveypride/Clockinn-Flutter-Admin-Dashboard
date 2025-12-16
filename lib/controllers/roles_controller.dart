import 'package:get/get.dart';

class RolesController extends GetxController {
  var isLoading = true.obs;

  // The predefined Roles in your system
  var roles = [
    {"name": "Super Admin", "users": 1, "color": 0xFF9C27B0}, // Purple
    {"name": "Branch Manager", "users": 5, "color": 0xFFFF9800}, // Orange
    {"name": "Secretary", "users": 3, "color": 0xFFE91E63}, // Pink
    {"name": "Employee", "users": 120, "color": 0xFF2196F3}, // Blue
  ].obs;

  // The List of System Permissions
  final List<String> allPermissions = [
    "View Dashboard Stats",
    "Manage Operation Sites",
    "Verify New Users",
    "Manage Employees (Edit/Delete)",
    "Edit Shifts & Rosters",
    "Send Announcements",
    "View All Companies", // Super Admin only
    "Access Billing & Subscription",
  ];

  // The "Matrix" - Which role has which permission
  // Key: Role Name, Value: List of enabled permissions
  var rolePermissions = <String, List<String>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPermissions();
  }

  void loadPermissions() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    // MOCK DATA: Initial Setup
    rolePermissions.value = {
      "Super Admin": [
        "View Dashboard Stats",
        "Manage Operation Sites",
        "Verify New Users",
        "Manage Employees (Edit/Delete)",
        "Edit Shifts & Rosters",
        "Send Announcements",
        "View All Companies",
        "Access Billing & Subscription",
      ],
      "Branch Manager": [
        "View Dashboard Stats",
        "Verify New Users",
        "Manage Employees (Edit/Delete)",
        "Edit Shifts & Rosters",
        "Send Announcements",
      ],
      "Secretary": [
        "View Dashboard Stats",
        "Verify New Users",
        "Send Announcements",
      ],
      "Employee": [
        // Usually employees have no admin permissions
      ],
    };

    isLoading.value = false;
  }

  void togglePermission(String role, String permission) {
    // 1. Create a copy of the list to trigger reactivity
    List<String> currentPerms = List.from(rolePermissions[role] ?? []);

    if (currentPerms.contains(permission)) {
      currentPerms.remove(permission);
    } else {
      currentPerms.add(permission);
    }

    // 2. Update the map
    rolePermissions[role] = currentPerms;

    // 3. (Real App) Here you would update Firestore Security Rules or a 'roles' collection
    Get.snackbar(
      "Updated",
      "$role permission changed",
      duration: const Duration(seconds: 1),
    );
  }
}
