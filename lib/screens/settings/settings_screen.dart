import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Column(
      children: [
        // --- HEADER ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Settings", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              // TABS
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
                  ),
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: "Company Profile"),
                    Tab(text: "Attendance Rules"),
                    Tab(text: "Notifications"),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- TAB CONTENT ---
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(controller),
                  _buildRulesTab(controller),
                  _buildNotificationsTab(controller),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: COMPANY PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab(SettingsController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Company Details", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Uploader
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: NetworkImage(controller.logoUrl.value), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: controller.pickLogo,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text("Change Logo"),
                  )
                ],
              ),
              const SizedBox(width: 30),
              
              // Form Fields
              Expanded(
                child: Column(
                  children: [
                    _buildTextField("Company Name", controller.companyNameCtrl),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Email Address", controller.companyEmailCtrl)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField("Phone Number", controller.companyPhoneCtrl)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField("Headquarters Address", controller.addressCtrl),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: controller.saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ATTENDANCE RULES
  // ---------------------------------------------------------------------------
  Widget _buildRulesTab(SettingsController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Attendance Policies", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Define how the system calculates lateness and site boundaries.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 30),

          // Late Tolerance Slider
          Text("Late Tolerance: ${controller.lateToleranceMinutes.value.toInt()} minutes", style: const TextStyle(fontWeight: FontWeight.w500)),
          Slider(
            value: controller.lateToleranceMinutes.value,
            min: 0,
            max: 60,
            divisions: 12,
            label: "${controller.lateToleranceMinutes.value.toInt()} min",
            activeColor: Colors.orange,
            onChanged: (val) => controller.lateToleranceMinutes.value = val,
          ),
          const Text("Employees arriving after this time will be marked as 'Late'.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          
          const Divider(height: 40),

          // Geofence Slider
          Text("Default Geofence Radius: ${controller.defaultGeofenceRadius.value.toInt()} meters", style: const TextStyle(fontWeight: FontWeight.w500)),
          Slider(
            value: controller.defaultGeofenceRadius.value,
            min: 50,
            max: 1000,
            divisions: 19,
            activeColor: Colors.purple,
            label: "${controller.defaultGeofenceRadius.value.toInt()} m",
            onChanged: (val) => controller.defaultGeofenceRadius.value = val,
          ),
          const Text("The default allowable distance from a site for mobile clock-ins.", style: TextStyle(fontSize: 12, color: Colors.grey)),

          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: controller.saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
              child: const Text("Update Policies", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: NOTIFICATIONS
  // ---------------------------------------------------------------------------
  Widget _buildNotificationsTab(SettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Email Alerts", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        SwitchListTile(
          title: const Text("New User Registration"),
          subtitle: const Text("Receive an email when a new employee signs up and needs verification."),
          value: controller.alertOnNewUser.value,
          activeColor: Colors.green,
          onChanged: (val) => controller.alertOnNewUser.value = val,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text("Late Arrival Alerts"),
          subtitle: const Text("Get notified if a Manager or Key Staff member is late."),
          value: controller.alertOnLateArrival.value,
          activeColor: Colors.green,
          onChanged: (val) => controller.alertOnLateArrival.value = val,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text("Weekly Attendance Report"),
          subtitle: const Text("Receive a summary PDF of all attendance every Monday morning."),
          value: controller.weeklyReportEmail.value,
          activeColor: Colors.green,
          onChanged: (val) => controller.weeklyReportEmail.value = val,
        ),
        
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: controller.saveSettings,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
            child: const Text("Save Preferences", style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    );
  }

  // Helper for Text Fields
  Widget _buildTextField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}