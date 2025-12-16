import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/verification_controller.dart';

class AwaitingVerificationScreen extends StatelessWidget {
  const AwaitingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(VerificationController());

    return Column(
      children: [
        // --- 1. HEADER SECTION ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Awaiting Verification", 
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Review new registrations and assign them to an Operation Site", 
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                ],
              ),
              // Refresh Button
              IconButton(
                onPressed: controller.fetchData, 
                icon: const Icon(Icons.refresh, color: Colors.blue),
                tooltip: "Refresh List",
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- 2. USER LIST SECTION ---
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.waitingUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 60, color: Colors.green.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text("All caught up!", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("No users waiting for verification.", style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              );
            }

            // RESPONSIVE SWITCH: Table for Desktop (>900px), Cards for Mobile
            if (Get.width < 900) {
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: controller.waitingUsers.length,
                itemBuilder: (context, index) => _buildMobileCard(controller.waitingUsers[index], controller),
              );
            } else {
              return _buildDesktopTable(controller);
            }
          }),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET: DESKTOP TABLE
  // ===========================================================================
  Widget _buildDesktopTable(VerificationController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: DataTable(
          horizontalMargin: 0,
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 70,
          columns: const [
            DataColumn(label: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Name / Email", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Requested Dept", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Registered On", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: controller.waitingUsers.map((user) {
            return DataRow(cells: [
              // 1. Profile Pic (Click to View)
              DataCell(
                GestureDetector(
                  onTap: () => _showImageDialog(user['picurl']),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (user['picurl'] != null && user['picurl'] != "") 
                        ? NetworkImage(user['picurl']) 
                        : null,
                    child: (user['picurl'] == null || user['picurl'] == "") 
                        ? const Icon(Icons.person, color: Colors.grey) 
                        : null,
                  ),
                )
              ),
              // 2. Name & Email
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(user['email'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )),
              // 3. Phone
              DataCell(Text(user['phone'] ?? "N/A")),
              // 4. Requested Department (From App)
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(user['department'] != "" ? user['department'] : "None", 
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                )
              ),
              // 5. Date
              DataCell(Text(user['addedon'].toString().split(' at ')[0])), // Extracts just the date part
              // 6. Actions
              DataCell(Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showApproveDialog(controller, user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                    ),
                    child: const Text("Approve", style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => controller.rejectUser(user['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, 
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                    ),
                    child: const Text("Reject", style: TextStyle(fontSize: 12)),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: MOBILE CARD VIEW
  // ===========================================================================
  Widget _buildMobileCard(Map<String, dynamic> user, VerificationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showImageDialog(user['picurl']),
                child: CircleAvatar(
                  radius: 25, 
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (user['picurl'] != null && user['picurl'] != "") 
                      ? NetworkImage(user['picurl']) 
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user['email'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(user['phone'] ?? "N/A", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text("Req: ${user['department'] != "" ? user['department'] : "None"}", 
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 10)),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showApproveDialog(controller, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                  ),
                  child: const Text("Approve", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.rejectUser(user['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, 
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                  ),
                  child: const Text("Reject"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER: SELFIE ZOOM DIALOG
  // ===========================================================================
  void _showImageDialog(String? url) {
    if (url == null || url.isEmpty) return;
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              onPressed: () => Get.back(),
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.close, color: Colors.black),
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER: APPROVAL & ASSIGNMENT DIALOG
  // ===========================================================================
  void _showApproveDialog(VerificationController controller, Map<String, dynamic> user) {
    // 1. Ensure selection defaults to the first available site
    if (controller.availableSites.isNotEmpty) {
      controller.selectedSite.value = controller.availableSites.first;
    }

    Get.defaultDialog(
      title: "Approve & Assign Site",
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
      contentPadding: const EdgeInsets.all(20),
      radius: 12,
      content: Column(
        children: [
          // Information Text
          const Text(
            "Select the Operation Site for this employee:", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14)
          ),
          const SizedBox(height: 20),
          
          // DROPDOWN MENU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.selectedSite.value,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                items: controller.availableSites.map((String site) {
                  return DropdownMenuItem<String>(
                    value: site,
                    child: Text(site, style: GoogleFonts.inter(fontSize: 15)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) controller.selectedSite.value = newValue;
                },
              ),
            )),
          ),
          
          const SizedBox(height: 15),
          
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "This grants clock-in access to this specific location.", 
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      textConfirm: "Confirm & Verify",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () {
        controller.approveUser(user['id'], controller.selectedSite.value);
        Get.back(); // Close Dialog
      }
    );
  }
}