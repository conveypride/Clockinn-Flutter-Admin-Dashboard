import 'package:clockinn_flutter_admin/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SideMenuController extends GetxController {
  var activeItem = '/dashboard'.obs; 
  var hoverItem = ''.obs;

  void changeActiveItemTo(String route) {
    activeItem.value = route;
    if (Get.isBottomSheetOpen == true || (Get.isDialogOpen == false && Get.isOverlaysOpen)) {
      Navigator.of(Get.context!).pop();
    }
    Get.toNamed(route);
  }

  void onHover(String route) {
    if (!isActive(route)) hoverItem.value = route;
  }

  bool isActive(String route) => activeItem.value == route;
  bool isHovering(String route) => hoverItem.value == route;
}

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final SideMenuController menuController = Get.put(SideMenuController());
    final LoginController auth = Get.find<LoginController>();

    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          _buildLogo(),
          const Divider(color: Colors.white10),
          Expanded(
            child: Obx(() { // Reactive to role changes
              bool isSuperAdmin = auth.userRole.value == "Super Admin";
              
              return ListView(
                children: [
                  _buildMenuItem(menuController, "Dashboard", Icons.dashboard, '/dashboard'),
                  _buildMenuItem(menuController, "Offices (Sites)", Icons.business, '/offices'),
                  _buildMenuItem(menuController, "Awaiting Verification", Icons.verified_user, '/verification'),
                  _buildMenuItem(menuController, "Manage Users", Icons.people, '/users'),
                  _buildMenuItem(menuController, "Reports & Export", Icons.file_download, '/export'),
                  
                  // 🔒 RESTRICTED: ROLES (Super Admin Only)
                  if (isSuperAdmin)
                    _buildMenuItem(menuController, "Roles", Icons.admin_panel_settings, '/roles'),
                  
                  _buildMenuItem(menuController, "Shift Management", Icons.calendar_month, '/shifts'),
                  _buildMenuItem(menuController, "Announcements", Icons.campaign, '/announcements'),
                  
                  const Divider(color: Colors.white10),
                  
                  // 🔒 RESTRICTED: SUBSCRIPTION & SETTINGS (Super Admin Only)
                  if (isSuperAdmin) ...[
                    _buildMenuItem(menuController, "Subscription", Icons.credit_card, '/subscription'),
                    _buildMenuItem(menuController, "Settings", Icons.settings, '/settings'),
                  ],
                ],
              );
            }),
          ),
          
          // LOGOUT
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: InkWell(
              onTap: () => auth.logout(),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text("Logout", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(SideMenuController controller, String itemName, IconData icon, String route) {
    return Obx(() => InkWell(
      onTap: () {
        controller.changeActiveItemTo(route);
        if (Get.width < 800) Get.back();
      },
      onHover: (value) => value ? controller.onHover(route) : controller.onHover(""),
      child: Container(
        color: controller.isActive(route) || controller.isHovering(route)
            ? Colors.blueAccent.withValues(alpha:0.2)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 50,
              color: controller.isActive(route) ? Colors.blueAccent : Colors.transparent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(icon, color: controller.isActive(route) ? Colors.white : Colors.white54, size: 20),
            ),
            Text(itemName, style: GoogleFonts.inter(color: controller.isActive(route) ? Colors.white : Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    ));
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_filled, color: Colors.blueAccent, size: 30),
          const SizedBox(width: 10),
          Text("ClockInn", style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}