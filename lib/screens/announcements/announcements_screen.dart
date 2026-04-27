import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/announcements_controller.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnnouncementsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, controller),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                if (controller.sentAnnouncements.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  itemCount: controller.sentAnnouncements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var item = controller.sentAnnouncements[index];
                    return _buildAnnouncementCard(item, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AnnouncementsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Announcements", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Broadcast messages to your team.", style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showComposeDialog(context, controller),
            icon: const Icon(Icons.send, size: 18),
            label: const Text("New Announcement"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("No announcements sent yet", style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> item, AnnouncementsController controller) {
    DateTime date = (item['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['title'] ?? "No Title", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => controller.deleteHistory(item['id']),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(item['message'] ?? "", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[800])),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.group, size: 14, color: Colors.blue[300]),
              const SizedBox(width: 5),
              Text("Sent to: ${item['target'] ?? 'All'}", style: GoogleFonts.inter(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(formattedDate, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
            ],
          )
        ],
      ),
    );
  }

  void _showComposeDialog(BuildContext context, AnnouncementsController controller) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Compose Announcement",
      content: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: msgCtrl, maxLines: 4, decoration: const InputDecoration(labelText: "Message", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            // DROP DOWN
            Obx(() {
               // Ensure value matches options
               String val = controller.selectedTarget.value;
               if (!controller.targetOptions.contains(val) && controller.targetOptions.isNotEmpty) {
                 val = controller.targetOptions.first;
               }
               return DropdownButtonFormField<String>(
                  value: val,
                  decoration: const InputDecoration(labelText: "Send To", border: OutlineInputBorder()),
                  items: controller.targetOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => controller.selectedTarget.value = v!,
               );
            }),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton.icon(
        onPressed: controller.isSending.value 
          ? null 
          : () => controller.sendAnnouncement(titleCtrl.text, msgCtrl.text),
        icon: controller.isSending.value 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Icon(Icons.send, size: 16),
        label: Text(controller.isSending.value ? "Sending..." : "Send Now"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
    );
  }
}