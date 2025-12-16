import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/roles_controller.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RolesController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Roles & Permissions",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Define what each role can access in the Admin Dashboard",
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
            if (Get.width < 1000) {
              return _buildMobileView(controller);
            } else {
              return _buildDesktopMatrix(controller);
            }
          }),
        ),
      ],
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2), // Permission Name Column is wider
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // HEADER ROW
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "PERMISSION",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                for (var role in controller.roles)
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          role['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(role['color'] as int).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${role['users']} Users",
                            style: TextStyle(
                              fontSize: 10,
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
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Text(
                      perm,
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
    bool isEnabled =
        controller.rolePermissions[roleName]?.contains(perm) ?? false;
    // Super Admin should usually be locked to TRUE (Safety)
    bool isLocked = roleName == "Super Admin";

    return InkWell(
      onTap: isLocked
          ? null
          : () => controller.togglePermission(roleName, perm),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: isLocked
            ? const Icon(Icons.lock, size: 16, color: Colors.grey)
            : Icon(
                isEnabled ? Icons.check_circle : Icons.circle_outlined,
                color: isEnabled ? Colors.green : Colors.grey.shade300,
                size: 20,
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Text(
              roleName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${role['users']} Users assigned"),
            leading: CircleAvatar(
              backgroundColor: Color(role['color'] as int).withOpacity(0.1),
              child: Icon(
                Icons.shield,
                color: Color(role['color'] as int),
                size: 18,
              ),
            ),
            children: [
              const Divider(height: 1),
              // Permission Switches
              for (String perm in controller.allPermissions)
                SwitchListTile(
                  title: Text(perm, style: const TextStyle(fontSize: 13)),
                  dense: true,
                  value:
                      controller.rolePermissions[roleName]?.contains(perm) ??
                      false,
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
