import 'package:clockinn_flutter_admin/controllers/login_controller.dart'; // Import LoginController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/manage_users_controller.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryRed = Color(0xFFEF4444);
  static const Color bgGrey = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManageUsersController());

    return Scaffold(
      backgroundColor: bgGrey,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(controller),
            const SizedBox(height: 20),
            
            // --- TABS ---
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: TabBar(
                      controller: controller.tabController,
                      labelColor: primaryBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryBlue,
                      indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
                      tabs: const [
                        Tab(text: "Employees"),
                        Tab(text: "Management Team"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        _buildEmployeesTab(controller),
                        _buildAdminsTab(controller, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ManageUsersController controller) {
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
              Text("Team Management", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Manage workforce, managers, and admins.", style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
          IconButton(
            onPressed: () {
              controller.loadEmployees(refresh: true);
              controller.loadAdmins();
            }, 
            icon: const Icon(Icons.refresh, color: primaryBlue)
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: EMPLOYEES (Standard)
  // ===========================================================================
  Widget _buildEmployeesTab(ManageUsersController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search employee...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedSiteFilter.value,
                  items: controller.availableSites.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: controller.onFilterChanged,
                ),
              )),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
            if (controller.filteredEmployees.isEmpty) return const Center(child: Text("No employees found"));

            return ListView.separated(
              itemCount: controller.filteredEmployees.length + 1,
              separatorBuilder: (_,__) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == controller.filteredEmployees.length) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: controller.hasMoreData.value 
                        ? (controller.isLoadingMore.value 
                            ? const CircularProgressIndicator()
                            : TextButton.icon(
                                onPressed: () => controller.loadEmployees(refresh: false),
                                icon: const Icon(Icons.arrow_downward, size: 16),
                                label: const Text("Load More Users"),
                              ))
                        : const Text("End of list", style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return _buildEmployeeCard(controller.filteredEmployees[index], controller, context);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> user, ManageUsersController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (user['picurl'] != null && user['picurl'] != "") ? NetworkImage(user['picurl']) : null,
          child: (user['picurl'] == null || user['picurl'] == "") ? const Icon(Icons.person) : null,
        ),
        title: Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${user['role']} • ${user['department'] ?? user['site']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: user['isActive'] == true,
              onChanged: (val) => controller.toggleStatus(user['id'], user['currentSiteId'], user['isActive']),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: "Edit User",
              onPressed: () => _showEditUserDialog(context, controller, user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: primaryRed),
              tooltip: "Delete User",
              onPressed: () => controller.deleteUser(user['id'], user['currentSiteId']),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, ManageUsersController controller, Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name']);
    String selectedRole = user['role'] ?? "Employee";
    String selectedSite = user['department'] ?? user['site'] ?? "";
    
    if (!controller.availableSites.contains(selectedSite) && controller.availableSites.isNotEmpty) {
       var realSites = controller.availableSites.where((s) => s != "All Offices").toList();
       if (realSites.isNotEmpty) selectedSite = realSites.first;
    }

    Get.defaultDialog(
      title: "Edit Employee",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              TextField(
                controller: nameCtrl, 
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Employee", child: Text("Employee")),
                  DropdownMenuItem(value: "Supervisor", child: Text("Supervisor")),
                  DropdownMenuItem(value: "Manager", child: Text("Manager")), 
                ],
                onChanged: (val) => setState(() => selectedRole = val!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedSite,
                decoration: const InputDecoration(labelText: "Office / Site", border: OutlineInputBorder()),
                items: controller.availableSites.where((s) => s != "All Offices").map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => selectedSite = val!),
              ),
            ],
          );
        }
      ),
      textConfirm: "Update",
      confirmTextColor: Colors.white,
      onConfirm: () => controller.updateUser(user['id'], user['currentSiteId'], nameCtrl.text, selectedRole, selectedSite)
    );
  }

  // ===========================================================================
  // TAB 2: MANAGEMENT TEAM (RESTRICTED)
  // ===========================================================================
  Widget _buildAdminsTab(ManageUsersController controller, BuildContext context) {
    final loginCtrl = Get.find<LoginController>();
    String myRole = loginCtrl.userRole.value; // "Super Admin" or "Branch Manager"

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showInviteAdminDialog(context, controller, myRole),
            icon: const Icon(Icons.person_add),
            label: const Text("Invite Manager / Admin"),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Obx(() {
            if (controller.admins.isEmpty) return const Center(child: Text("No managers found."));
            
            return ListView.separated(
              itemCount: controller.admins.length,
              separatorBuilder: (_,__) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                var admin = controller.admins[index];
                bool isPending = admin['isActivationPending'] == true;
                String targetRole = admin['role'];

                // 🔒 DELETE RESTRICTION: 
                // Branch Managers cannot delete other Branch Managers (peers).
                // They can only delete Secretaries.
                bool canDelete = true;
                if (myRole == "Branch Manager") {
                  if (targetRole == "Branch Manager" || targetRole == "Super Admin") {
                    canDelete = false; 
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(10),
                    border: isPending ? Border.all(color: Colors.orange.shade200) : null
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(admin['role']).withValues(alpha:0.1),
                      child: Icon(Icons.security, color: _getRoleColor(admin['role']), size: 18),
                    ),
                    title: Row(
                      children: [
                        Text(admin['adminname'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (isPending)
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text("PENDING", style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${admin['role']} • ${admin['email']}"),
                        if (admin['siteName'] != null)
                          Text("Managed Site: ${admin['siteName']}", style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                        if (isPending)
                          SelectableText("Code: ${admin['activationCode']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    trailing: canDelete 
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteAdmin(controller, admin),
                        )
                      : Tooltip(
                          message: "You cannot delete this user",
                          child: Icon(Icons.lock, color: Colors.grey.shade300, size: 20)
                        ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    if (role == "Super Admin") return Colors.purple;
    if (role == "Branch Manager") return Colors.orange;
    return Colors.pink;
  }

  // --- INVITE DIALOG (RESTRICTED) ---
  void _showInviteAdminDialog(BuildContext context, ManageUsersController controller, String myRole) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    // Default Role based on permissions
    // If I am a Manager, I can ONLY create Secretaries.
    String selectedRole = myRole == "Branch Manager" ? "Secretary" : "Branch Manager";
    String? selectedSiteId;
    
    // 🔒 RESTRICT DROPDOWN OPTIONS
    List<DropdownMenuItem<String>> roleItems = [];
    
    if (myRole == "Super Admin") {
      roleItems = const [
        DropdownMenuItem(value: "Super Admin", child: Text("Super Admin")),
        DropdownMenuItem(value: "Branch Manager", child: Text("Branch Manager")),
        DropdownMenuItem(value: "Secretary", child: Text("Secretary")),
      ];
    } else {
      // Branch Managers can ONLY add Secretaries
      roleItems = const [
        DropdownMenuItem(value: "Secretary", child: Text("Secretary")),
      ];
    }

    Get.defaultDialog(
      title: "Invite Management",
      content: StatefulBuilder(builder: (context, setState) {
        return Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
              items: roleItems, // Uses restricted list
              onChanged: (val) {
                setState(() => selectedRole = val!);
              },
            ),
            
            if (selectedRole != "Super Admin") ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Assign to Site", border: OutlineInputBorder()),
                items: controller.availableSites.where((s) => s != "All Offices").map((name) {
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (name) {
                  selectedSiteId = name; 
                },
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.blue.shade50,
              child: const Text("Note: An activation code will be generated. Share it with the user to let them set their own password.", style: TextStyle(fontSize: 12)),
            )
          ],
        );
      }),
      textConfirm: "Generate Invite",
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.inviteAdminUser(
          name: nameCtrl.text,
          email: emailCtrl.text,
          phone: phoneCtrl.text,
          role: selectedRole,
          siteId: selectedSiteId
        );
      }
    );
  }

  void _confirmDeleteAdmin(ManageUsersController controller, Map<String, dynamic> admin) {
    Get.defaultDialog(
      title: "Remove User?",
      middleText: "This will remove access for ${admin['adminname']}.",
      textConfirm: "Delete",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => controller.deleteAdmin(admin['id'], admin['isActivationPending'] == true),
    );
  }
} 