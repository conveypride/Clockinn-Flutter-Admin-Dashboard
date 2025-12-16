import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SideMenuController extends GetxController {
  var activeItem = '/dashboard'.obs; // Use routes as IDs
  var hoverItem = ''.obs;

  // inside SideMenuController class
  void changeActiveItemTo(String route) {
    activeItem.value = route;
    // Check if a Drawer is open (Mobile) and close it
    if (Get.isBottomSheetOpen == true ||
        (Get.isDialogOpen == false && Get.isOverlaysOpen)) {
      // Get.back() serves to close the drawer in many GetX contexts,
      // but for standard Flutter Drawer, standard Navigator pop is safer if Get isn't tracking it.
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

    return Container(
      color: const Color(0xFF1E293B), // Dark Slate Blue
      child: Column(
        children: [
          _buildLogo(),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  menuController,
                  "Dashboard",
                  Icons.dashboard,
                  '/dashboard',
                ),
                _buildMenuItem(
                  menuController,
                  "Offices (Sites)",
                  Icons.business,
                  '/offices',
                ),
                _buildMenuItem(
                  menuController,
                  "Awaiting Verification",
                  Icons.verified_user,
                  '/verification',
                ),
                _buildMenuItem(
                  menuController,
                  "Manage Users",
                  Icons.people,
                  '/users',
                ),
                _buildMenuItem(
                  menuController,
                  "Roles",
                  Icons.admin_panel_settings,
                  '/roles',
                ),
                _buildMenuItem(
                  menuController,
                  "Shift Management",
                  Icons.calendar_month,
                  '/shifts',
                ),
                _buildMenuItem(
                  menuController,
                  "Announcements",
                  Icons.campaign,
                  '/announcements',
                ),
                const Divider(color: Colors.white10),
                _buildMenuItem(
                  menuController,
                  "Subscription",
                  Icons.credit_card,
                  '/subscription',
                ),
                _buildMenuItem(
                  menuController,
                  "Settings",
                  Icons.settings,
                  '/settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    SideMenuController controller,
    String itemName,
    IconData icon,
    String route,
  ) {
    return Obx(
      () => InkWell(
        onTap: () {
          controller.changeActiveItemTo(route);
          // Close drawer if screen is small
          if (Get.width < 800) {
            Get.back(); // Closes the Drawer
          }
        },
        onHover: (value) =>
            value ? controller.onHover(route) : controller.onHover(""),
        child: Container(
          color: controller.isActive(route) || controller.isHovering(route)
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 50,
                color: controller.isActive(route)
                    ? Colors.blueAccent
                    : Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  icon,
                  color: controller.isActive(route)
                      ? Colors.white
                      : Colors.white54,
                  size: 20,
                ),
              ),
              Text(
                itemName,
                style: GoogleFonts.inter(
                  color: controller.isActive(route)
                      ? Colors.white
                      : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.access_time_filled,
            color: Colors.blueAccent,
            size: 30,
          ),
          const SizedBox(width: 10),
          Text(
            "ClockInn",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
