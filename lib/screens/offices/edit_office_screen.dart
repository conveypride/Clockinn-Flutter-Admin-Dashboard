import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/edit_office_controller.dart';

class EditOfficeScreen extends StatelessWidget {
  final Map<String, dynamic> siteData;
  final String siteId;

  const EditOfficeScreen({super.key, required this.siteData, required this.siteId});

  static const Color primaryDark = Color(0xFF1E293B);
  static const Color primaryGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    // Initialize controller with data
    final controller = Get.put(EditOfficeController(siteData: siteData, siteId: siteId), tag: siteId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("Edit Office", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: IDENTITY ---
                _buildSectionCard(
                  title: "Office Identity",
                  icon: Icons.business,
                  child: Column(
                    children: [
                      _buildTextField(controller.siteNameCtrl, "Office Name", "e.g. Head Office"),
                      // --- NEW: HQ SWITCH ---
      Container(
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withValues(alpha:0.1)),
        ),
        child: Obx(() => SwitchListTile(
          title: Text("Set as Head Office (HQ)", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.purple)),
          subtitle: controller.isHQ.value 
            ? const Text("This is your main office.") 
            : const Text("Enable to make this your main office. (Will replace current HQ)"),
          value: controller.isHQ.value,
          activeColor: Colors.purple,
          onChanged: (val) {
            controller.isHQ.value = val;
          },
        )),
      ),
                      const SizedBox(height: 20),
                      
                      // IMAGE PREVIEW AREA
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50
                        ),
                        child: Row(
                          children: [
                            // Current or New Image Preview
                            Obx(() {
                              if (controller.selectedImageName.isNotEmpty) {
                                return const Icon(Icons.image, size: 50, color: Colors.blue); // Placeholder for local file
                              } else if (controller.currentImageUrl.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(controller.currentImageUrl.value, width: 50, height: 50, fit: BoxFit.cover),
                                );
                              } else {
                                return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                              }
                            }),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() => Text(
                                    controller.selectedImageName.isNotEmpty 
                                      ? "New: ${controller.selectedImageName.value}"
                                      : "Current Image",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  )),
                                  const SizedBox(height: 5),
                                  ElevatedButton.icon(
                                    onPressed: controller.pickImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryDark,
                                      elevation: 0,
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    icon: const Icon(Icons.upload_file, size: 16),
                                    label: const Text("Change Image"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 2: MAP & LOCATION ---
              _buildSectionCard(
  title: "Location",
  icon: Icons.map,
  child: Column(
    children: [
      // 1. AUTOCOMPLETE SEARCH FIELD
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.searchCtrl,
            onChanged: controller.onSearchChanged, // ⚡ Triggers search
            decoration: InputDecoration(
              labelText: "Search Address",
              hintText: "Type to search...",
              border: const OutlineInputBorder(),
              suffixIcon: Obx(() => controller.isSearching.value 
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search)),
            ),
          ),
          
          // 2. SUGGESTIONS LIST (Shows only when there are suggestions)
          Obx(() {
            if (controller.suggestions.isEmpty) return const SizedBox.shrink();
            
            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.suggestions.length,
                itemBuilder: (context, index) {
                  final place = controller.suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    title: Text(place.description),
                    onTap: () => controller.selectSuggestion(place), // ⚡ Moves Map
                  );
                },
              ),
            );
          }),
        ],
      ),
      
      const SizedBox(height: 15),
                      
                      // Map Container
                      Container(
                        height: 350,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Obx(() => GoogleMap(
                          onMapCreated: controller.onMapCreated,
                          // Important: Start at the existing location!
                          initialCameraPosition: CameraPosition(
                            target: LatLng(double.parse(controller.latCtrl.text), double.parse(controller.lngCtrl.text)),
                            zoom: 15,
                          ),
                          markers: controller.markers.toSet(),
                          circles: controller.circles.toSet(),
                          mapType: MapType.normal,
                        )),
                      ),
                      const SizedBox(height: 20),
                      // Radius Chips
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: controller.radiusOptions.map((r) {
                            return Obx(() {
                              bool isSelected = controller.selectedRadius.value == r.toDouble();
                              return ChoiceChip(
                                label: Text("$r m"),
                                selected: isSelected,
                                onSelected: (_) => controller.updateRadius(r.toDouble()),
                                selectedColor: primaryGreen,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : primaryDark),
                              );
                            });
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 3: HOURS & DAYS ---
                _buildSectionCard(
                  title: "Schedule",
                  icon: Icons.access_time,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTimePicker(context, "Opens", controller.openTimeCtrl)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTimePicker(context, "Closes", controller.closeTimeCtrl)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.daysOfWeek.map((day) {
                            return Obx(() {
                              final isSelected = controller.workingDays.contains(day);
                              return FilterChip(
                                label: Text(day.toUpperCase()),
                                selected: isSelected,
                                onSelected: (_) => controller.toggleDay(day),
                                selectedColor: primaryGreen,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                checkmarkColor: Colors.white,
                              );
                            });
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // UPDATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.updateOffice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: controller.isLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Save Changes", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  )),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPERS (Simplified for brevity) ---
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: primaryDark), const SizedBox(width: 10), Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.access_time)),
      onTap: () async {
        TimeOfDay? t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
        if (t != null) ctrl.text = "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}";
      },
    );
  }
}