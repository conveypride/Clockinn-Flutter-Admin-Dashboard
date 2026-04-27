import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/roles_controller.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RolesController());

    return Scaffold( // Wrapped in Scaffold for safety, though usually part of a layout
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha:0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Roles & Permissions",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Configure access levels for your team members.",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- CONTENT ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // RESPONSIVE LAYOUT
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1000) {
                      return _buildMobileView(controller);
                    } else {
                      return _buildDesktopMatrix(controller);
                    }
                  }
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP: PERMISSION MATRIX GRID
  // ===========================================================================
  Widget _buildDesktopMatrix(RolesController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2.5), // Permission Name Column is wider
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // HEADER ROW
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "PERMISSION",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12
                    ),
                  ),
                ),
                for (var role in controller.roles)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          role['name'] as String,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(role['color'] as int).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${role['users']} Users",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(role['color'] as int),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // DATA ROWS (Permissions)
            for (String perm in controller.allPermissions)
              TableRow(
                children: [
                  // 1. Permission Name
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Text(
                      perm,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ),

                  // 2. Checkboxes for each Role
                  for (var role in controller.roles)
                    _buildCheckboxCell(
                      controller,
                      role['name'] as String,
                      perm,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxCell(
    RolesController controller,
    String roleName,
    String perm,
  ) {
    bool isEnabled = controller.rolePermissions[roleName]?.contains(perm) ?? false;
    // Lock Super Admin permissions for safety
    bool isLocked = roleName == "Super Admin";

    return InkWell(
      onTap: isLocked
          ? null
          : () => controller.togglePermission(roleName, perm),
      child: Container(
        height: 60, // Taller touch target
        alignment: Alignment.center,
        child: isLocked
            ? const Icon(Icons.lock, size: 16, color: Colors.grey)
            : AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isEnabled ? Colors.green : Colors.grey.shade300,
                    width: 2
                  ),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: isEnabled 
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
              ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE: EXPANDABLE LIST TILES
  // ===========================================================================
  Widget _buildMobileView(RolesController controller) {
    return ListView.builder(
      itemCount: controller.roles.length,
      itemBuilder: (context, index) {
        var role = controller.roles[index];
        String roleName = role['name'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.05), blurRadius: 5)],
          ),
          child: ExpansionTile(
            title: Text(
              roleName,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${role['users']} Users assigned", style: GoogleFonts.inter(fontSize: 12)),
            leading: CircleAvatar(
              backgroundColor: Color(role['color'] as int).withValues(alpha:0.1),
              child: Icon(
                Icons.shield_outlined,
                color: Color(role['color'] as int),
                size: 20,
              ),
            ),
            children: [
              const Divider(height: 1),
              // Permission Switches
              for (String perm in controller.allPermissions)
                SwitchListTile(
                  title: Text(perm, style: GoogleFonts.inter(fontSize: 13)),
                  dense: true,
                  value: controller.rolePermissions[roleName]?.contains(perm) ?? false,
                  activeColor: Colors.green,
                  onChanged: (roleName == "Super Admin")
                      ? null // Disable toggle for Super Admin
                      : (val) => controller.togglePermission(roleName, perm),
                ),
            ],
          ),
        );
      },
    );
  }
}