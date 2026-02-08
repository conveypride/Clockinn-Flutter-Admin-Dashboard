import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // --- HEADER ---
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
                    Text("Company Settings", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Manage your company profile and branding.", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                Obx(() => controller.isLoading.value 
                  ? const SizedBox()
                  : ElevatedButton.icon(
                      onPressed: controller.saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      icon: const Icon(Icons.save, size: 18, color: Colors.white),
                      label: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    )
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- CONTENT ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                return _buildProfileForm(controller);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(SettingsController controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Logo Section
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: controller.logoUrl.value.isNotEmpty
                          ? DecorationImage(image: NetworkImage(controller.logoUrl.value), fit: BoxFit.cover)
                          : null,
                    ),
                    child: controller.logoUrl.value.isEmpty 
                        ? const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: controller.pickLogo,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text("Upload Logo"),
                  )
                ],
              ),
              const SizedBox(width: 40),
              
              // 2. Form Fields
              Expanded(
                child: Column(
                  children: [
                    _buildTextField("Company Name", controller.companyNameCtrl, Icons.business),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Email Address", controller.companyEmailCtrl, Icons.email)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTextField("Phone Number", controller.companyPhoneCtrl, Icons.phone)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Headquarters Address", controller.addressCtrl, Icons.location_on),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            hintText: "Enter $label",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueAccent)),
            filled: true, 
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}