import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add intl dependency to pubspec.yaml for date formatting

class AnnouncementsController extends GetxController {
  var isLoading = true.obs;
  var announcements = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  void fetchAnnouncements() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); 

    // MOCK DATA: Matches your Schema
    announcements.value = [
      {
        "id": "ann_01",
        "adminId": "QhC3A55fqjdqxvwyd6Eqkt0E6cp1",
        "title": "Monday Announcement",
        "body": "Please come to work early; it's very important. We have a general meeting at 8:00 AM sharp.",
        "username": "Alex Liu",
        "usertype": "Super-Admin",
        "markAs": "unread",
        "date": "2025-10-25 20:35:16", // Stored as String/Timestamp
      },
      {
        "id": "ann_02",
        "adminId": "admin_456",
        "title": "Holiday Notice",
        "body": "The office will be closed this Friday for the National Holiday. Enjoy your long weekend!",
        "username": "Sarah Smith",
        "usertype": "Secretary",
        "markAs": "read",
        "date": "2025-10-20 09:15:00",
      }
    ];
    isLoading.value = false;
  }

  void postAnnouncement(String title, String body) {
    // Simulate Posting to Firestore
    var newPost = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "adminId": "CURRENT_USER_ID", // In real app, get from Auth
      "title": title,
      "body": body,
      "username": "Admin User", // In real app, get from Profile
      "usertype": "Super-Admin",
      "markAs": "unread",
      "date": DateTime.now().toString(),
    };

    announcements.insert(0, newPost); // Add to top of list
    Get.back(); // Close dialog
    Get.snackbar("Success", "Announcement posted successfully");
  }

  void deleteAnnouncement(String id) {
    announcements.removeWhere((ann) => ann['id'] == id);
    Get.snackbar("Deleted", "Announcement removed");
  }
}