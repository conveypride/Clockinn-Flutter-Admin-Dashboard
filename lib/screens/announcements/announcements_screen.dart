import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/announcements_controller.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnnouncementsController());

    return Scaffold(
      // Scaffold required here for FloatingActionButton
      backgroundColor:
          Colors.transparent, // Keep transparent to show BaseLayout bg
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComposeDialog(controller),
        label: const Text("Compose"),
        icon: const Icon(Icons.edit),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Announcements",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Broadcast messages to all company employees",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- FEED LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.announcements.isEmpty) {
                return Center(
                  child: Text(
                    "No announcements yet.",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              return Center(
                child: Container(
                  // Constrain width on Desktop for better readability (like Facebook/Twitter feed)
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                    itemCount: controller.announcements.length,
                    itemBuilder: (context, index) {
                      final ann = controller.announcements[index];
                      return _buildAnnouncementCard(ann, controller);
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Map<String, dynamic> ann,
    AnnouncementsController controller,
  ) {
    // Format Date
    String dateStr = ann['date'].toString();
    try {
      DateTime dt = DateTime.parse(dateStr);
      dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (e) {
      dateStr = "Just now";
    }

    // Role Color Logic
    Color roleColor = Colors.blue;
    if (ann['usertype'] == "Super-Admin") roleColor = Colors.purple;
    if (ann['usertype'] == "Secretary") roleColor = Colors.pink;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Text(
                      ann['username'][0],
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ann['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ann['usertype'],
                              style: TextStyle(
                                fontSize: 10,
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => controller.deleteAnnouncement(ann['id']),
                tooltip: "Delete Announcement",
              ),
            ],
          ),

          const Divider(height: 30),

          // 2. Content
          Text(
            ann['title'],
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            ann['body'],
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          // 3. Status Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 5),
              Text(
                "Marked as ${ann['markAs']}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- COMPOSE DIALOG ---
  void _showComposeDialog(AnnouncementsController controller) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    Get.defaultDialog(
      title: "New Announcement",
      contentPadding: const EdgeInsets.all(20),
      radius: 10,
      content: SizedBox(
        width: 400, // Fixed width for desktop
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
                hintText: "e.g., Weekly Meeting",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
                hintText: "Type your message here...",
              ),
            ),
          ],
        ),
      ),
      textConfirm: "Post Message",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blueAccent,
      onConfirm: () {
        if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
          controller.postAnnouncement(titleCtrl.text, bodyCtrl.text);
        } else {
          Get.snackbar(
            "Error",
            "Please fill in all fields",
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );
        }
      },
    );
  }
}
