import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/manage_users_controller.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManageUsersController());

    return Column(
      children: [
        // --- HEADER & SEARCH ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
          ),
          child: LayoutBuilder(builder: (context, constraints) {
             bool isSmall = constraints.maxWidth < 600;
             return Flex(
              direction: isSmall ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Manage Users", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("View active employees, change roles, or manage access", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                if(isSmall) const SizedBox(height: 15),
                
                // Search Field
                SizedBox(
                  width: isSmall ? double.infinity : 300,
                  child: TextField(
                    onChanged: (val) => controller.filterUsers(val),
                    decoration: InputDecoration(
                      hintText: "Search by name or email...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
             );
          }),
        ),

        const SizedBox(height: 20),

        // --- DATA LIST ---
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.displayedUsers.isEmpty) {
              return Center(child: Text("No users found.", style: GoogleFonts.inter(color: Colors.grey)));
            }

            // RESPONSIVE SWITCH
            if (Get.width < 900) {
              return ListView.builder(
                itemCount: controller.displayedUsers.length,
                itemBuilder: (context, index) => _buildMobileCard(controller.displayedUsers[index], controller),
              );
            } else {
              return _buildDesktopTable(controller);
            }
          }),
        ),
      ],
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(ManageUsersController controller) {
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
            DataColumn(label: Text("User", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Role", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Site / Dept", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Contact", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: controller.displayedUsers.map((user) {
            return DataRow(cells: [
              // 1. User (Avatar + Name + Email)
              DataCell(Row(
                children: [
                   CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: (user['picurl'] != "") ? NetworkImage(user['picurl']) : null,
                    child: (user['picurl'] == "") ? Text(user['name'][0], style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(user['email'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  )
                ],
              )),
              
              // 2. Role (Colored Badge)
              DataCell(_buildRoleBadge(user['role'])),

              // 3. Site
              DataCell(Text(user['department'])),

              // 4. Contact
              DataCell(Text(user['phone'])),

              // 5. Status Toggle
              DataCell(
                InkWell(
                  onTap: () => controller.toggleUserStatus(user['id'], user['isActive']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user['isActive'] ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user['isActive'] ? "Active" : "Suspended",
                      style: TextStyle(color: user['isActive'] ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ),

              // 6. Actions (Edit / Delete)
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), 
                    onPressed: () => _showEditUserDialog(controller, user)
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), 
                    onPressed: () => controller.deleteUser(user['id'])
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // --- MOBILE CARD ---
  Widget _buildMobileCard(Map<String, dynamic> user, ManageUsersController controller) {
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
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: (user['picurl'] != "") ? NetworkImage(user['picurl']) : null,
                child: (user['picurl'] == "") ? Text(user['name'][0]) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(user['email'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              // Status Badge
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user['isActive'] ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(user['isActive'] ? "Active" : "Suspended", style: TextStyle(color: user['isActive'] ? Colors.green : Colors.red, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const Text("Role", style: TextStyle(fontSize: 11, color: Colors.grey)),
                 const SizedBox(height: 2),
                 _buildRoleBadge(user['role']),
               ]),
               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const Text("Site", style: TextStyle(fontSize: 11, color: Colors.grey)),
                 const SizedBox(height: 2),
                 Text(user['department'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
               ]),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _showEditUserDialog(controller, user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit Profile"),
              ),
              TextButton.icon(
                onPressed: () => controller.toggleUserStatus(user['id'], user['isActive']),
                icon: Icon(user['isActive'] ? Icons.block : Icons.check_circle, size: 16, color: user['isActive'] ? Colors.orange : Colors.green),
                label: Text(user['isActive'] ? "Suspend" : "Activate", style: TextStyle(color: user['isActive'] ? Colors.orange : Colors.green)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Role Badge ---
  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case "Super Admin": color = Colors.purple; break;
      case "Branch Manager": color = Colors.orange; break;
      case "Secretary": color = Colors.pink; break;
      default: color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.05)
      ),
      child: Text(role, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // --- DIALOG: Edit User ---
  void _showEditUserDialog(ManageUsersController controller, Map<String, dynamic> user) {
    // Local state for the dialog inputs
    var selectedRole = user['role'].toString().obs;
    var selectedSite = user['department'].toString().obs;

    Get.defaultDialog(
      title: "Edit User Profile",
      contentPadding: const EdgeInsets.all(20),
      radius: 8,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Editing: ${user['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          const Text("Assign Role:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.availableRoles.contains(selectedRole.value) ? selectedRole.value : controller.availableRoles[0],
                items: controller.availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => selectedRole.value = val!,
              ),
            ),
          )),
          
          const SizedBox(height: 15),
          
          const Text("Assign Site / Department:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.availableSites.contains(selectedSite.value) ? selectedSite.value : controller.availableSites[0],
                items: controller.availableSites.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => selectedSite.value = val!,
              ),
            ),
          )),
        ],
      ),
      textConfirm: "Save Changes",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.updateUser(user['id'], selectedRole.value, selectedSite.value);
      }
    );
  }
}