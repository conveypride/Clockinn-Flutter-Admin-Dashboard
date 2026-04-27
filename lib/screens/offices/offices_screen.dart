import 'package:clockinn_flutter_admin/controllers/login_controller.dart'; // Import this
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/offices_controller.dart';
import 'edit_office_screen.dart'; 

class OfficesScreen extends StatelessWidget {
  OfficesScreen({super.key});

  static const Color bgGrey = Color(0xFFF1F5F9);
  static const Color textDark = Color(0xFF1E293B);
  static const Color primaryGreen = Color(0xFF10B981);

  final TextEditingController searchInputCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OfficesController());

    return Scaffold(
      backgroundColor: bgGrey,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(controller),
            const SizedBox(height: 30),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }
                if (controller.filteredSites.isEmpty) {
                  return _buildEmptyState();
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return _buildDesktopGrid(controller);
                    } else {
                      return _buildMobileList(controller);
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OfficesController controller) {
    final loginCtrl = Get.find<LoginController>(); // Get Login Controller
    bool canAddOffice = loginCtrl.userRole.value == "Super Admin"; // Check permission

    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 600;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Office Locations", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                    Text("Manage your operating sites and geofences.", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              // 🔒 RESTRICTED: ADD BUTTON (Desktop)
              if (!isMobile && canAddOffice)
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/setup-office'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add Office"),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Search & Add Section
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: searchInputCtrl,
                    onChanged: controller.filterSites,
                    decoration: InputDecoration(
                      hintText: "Search offices...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          searchInputCtrl.clear();
                          controller.filterSites("");
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              
              // 🔒 RESTRICTED: ADD BUTTON (Mobile)
              if (isMobile && canAddOffice) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed('/setup-office'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      elevation: 2,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.add, size: 24),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      );
    });
  }

  
  // Paste the rest of your original file here to ensure no functionality is lost.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No offices found", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(OfficesController controller) {
     final loginCtrl = Get.find<LoginController>(); // Get Login Controller
  bool canAddOffice = loginCtrl.userRole.value == "Super Admin"; // Check permission
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: controller.filteredSites.length,
      itemBuilder: (context, index) => _buildOfficeCard(controller.filteredSites[index],canAddOffice, controller, isMobile: false),
    );
  }

  Widget _buildMobileList(OfficesController controller) {
      final loginCtrl = Get.find<LoginController>(); // Get Login Controller
  bool canAddOffice = loginCtrl.userRole.value == "Super Admin"; // Check permission

    return ListView.separated(
      itemCount: controller.filteredSites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildOfficeCard(controller.filteredSites[index],canAddOffice, controller, isMobile: true),
    );
  }

  Widget _buildOfficeCard(Map<String, dynamic> site, bool canAddOffice, OfficesController controller, {required bool isMobile}) {
    bool isHQ = site['isHQ'] == true;
    bool isActive = site['status'] == true;
    String imageUrl = site['officeimage'] ?? "";

    Widget contentBody = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  site['nameofsite'] ?? "Unknown",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    Get.to(() => EditOfficeScreen(siteData: site, siteId: site['id']));
                  } else if (value == 'delete') {
                    _confirmDelete(controller, site['id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text("Edit")])),
                    if (canAddOffice)
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  site['location'] ?? "No address",
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (!isMobile) const Spacer() else const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(Icons.radar, "${site['radius']}m"),
              _buildMiniStat(Icons.schedule, "${site['openingTime']}-${site['closingTime']}"),
              _buildMiniStat(Icons.work, "${(site['workingdays'] as List?)?.length ?? 0} Days"),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: textDark, child: const Icon(Icons.business, color: Colors.white24)))
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(child: Icon(Icons.business, color: Colors.white24, size: 40)),
                      ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (isHQ)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(6)),
                          child: const Text("HQ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(6)),
                        child: Text(isActive ? "Active" : "Inactive", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          if (isMobile) contentBody else Expanded(child: contentBody),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _confirmDelete(OfficesController controller, String id) {
    Get.defaultDialog(
      title: "Delete Office?",
      middleText: "This action cannot be undone.",
      textConfirm: "Delete",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteSite(id);
        Get.back();
      },
      textCancel: "Cancel",
    );
  }
}