import 'package:clockinn_flutter_admin/controllers/setup_office_controller.dart';
import 'package:clockinn_flutter_admin/util/google_place_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class SetupOfficeScreen extends StatelessWidget {
  const SetupOfficeScreen({super.key});

  // THEME COLORS
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color accentBlue = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetupOfficeController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate-100 background
      appBar: AppBar(
        title: Text("Setup Your Office", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
                // Header Info
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha:0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_rounded, size: 40, color: primaryGreen),
                      ),
                      const SizedBox(height: 15),
                      Text("Let's Get Started", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: primaryDark)),
                      const SizedBox(height: 8),
                      Text("Configure your main office location and settings.", style: GoogleFonts.inter(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- SECTION 1: OFFICE DETAILS ---
                _buildSectionCard(
                  title: "Office Details",
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(controller.siteNameCtrl, "Office Name", "e.g. Head Office"),
                      const SizedBox(height: 20),
                      // Image Picker UI
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50
                        ),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: controller.pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryDark,
                                elevation: 0,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                              ),
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: const Text("Upload Image"),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Obx(() => Text(
                                controller.selectedImageName.value.isEmpty 
                                  ? "No file selected" 
                                  : controller.selectedImageName.value,
                                style: GoogleFonts.inter(color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              )),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 2: TIMING ---
                _buildSectionCard(
                  title: "Office Hours",
                  icon: Icons.access_time_rounded,
                  child: Row(
                    children: [
                      Expanded(child: _buildTimePicker(context, "Opening Time", controller.openTimeCtrl, Icons.wb_sunny_outlined)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTimePicker(context, "Closing Time", controller.closeTimeCtrl, Icons.nights_stay_outlined)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 3: WORKING DAYS ---
                _buildSectionCard(
                  title: "Working Days",
                  icon: Icons.calendar_today_rounded,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.daysOfWeek.map((day) {
                      return Obx(() {
                        final isSelected = controller.workingDays.contains(day);
                        return ChoiceChip(
                          label: Text(day.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) => controller.toggleDay(day),
                          selectedColor: primaryGreen,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700]
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      });
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 4: HOLIDAYS ---
                _buildSectionCard(
                  title: "Holidays",
                  icon: Icons.celebration_rounded,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha:0.3))
                        ),
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Don't forget to add public holidays. Default holidays have been pre-loaded.", 
                              style: GoogleFonts.inter(color: Colors.amber[900], fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // List of Added Holidays
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Obx(() => ListView.separated(
                          shrinkWrap: true,
                          itemCount: controller.holidays.length,
                          separatorBuilder: (_,__) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            var h = controller.holidays[index];
                            return ListTile(
                              dense: true,
                              title: Text(h['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                              subtitle: Text(h['date']!),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                onPressed: () => controller.removeHoliday(index),
                              ),
                            );
                          },
                        )),
                      ),
                      const SizedBox(height: 15),
                      // Add Holiday Inputs
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(controller.holidayNameCtrl, "Holiday Name", "e.g. Founders Day"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: controller.holidayDateCtrl,
                              readOnly: true,
                              style: GoogleFonts.inter(),
                              decoration: InputDecoration(
                                labelText: "Date",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                suffixIcon: const Icon(Icons.calendar_month, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              ),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context, 
                                  initialDate: DateTime.now(), 
                                  firstDate: DateTime(2000), 
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: const ColorScheme.light(primary: primaryGreen),
                                      ),
                                      child: child!,
                                    );
                                  }
                                );
                                if(picked != null) {
                                  controller.holidayDateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: controller.addHoliday,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.all(16)
                            ),
                            child: const Icon(Icons.add),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25), 

                // --- SECTION 5: MAP & LOCATION ---
                _buildSectionCard(
                  title: "Location & Geofence",
                  icon: Icons.map_rounded,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Autocomplete<PlaceSuggestion>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) return const Iterable<PlaceSuggestion>.empty();
                                return controller.fetchSuggestions(textEditingValue.text);
                              },
                              onSelected: (PlaceSuggestion selection) => controller.onSuggestionSelected(selection),
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: "Search Location (e.g. Accra Mall)",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.search),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 400,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final PlaceSuggestion option = options.elementAt(index);
                                          return ListTile(
                                            leading: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                                            title: Text(option.description, style: GoogleFonts.inter()),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              displayStringForOption: (PlaceSuggestion option) => option.description,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: controller.getCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            ),
                            icon: const Icon(Icons.my_location),
                            label: const Text("Use GPS"),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      // MAP
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)]
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Obx(() {
                          // Dummy read to ensure updates
                          controller.isLoading.value; 
                          return GoogleMap(
                            onMapCreated: controller.onMapCreated,
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(5.6037, -0.1870), 
                              zoom: 15,
                            ),
                            markers: controller.markers.toSet(), 
                            circles: controller.circles.toSet(),
                            mapType: MapType.normal,
                          );
                        }),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          const Icon(Icons.radar_rounded, color: primaryDark),
                          const SizedBox(width: 10),
                          Text("Clock-In Radius", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Radius Chips
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.radiusOptions.map((r) {
                            return Obx(() {
                              bool isSelected = controller.selectedRadius.value == r.toDouble();
                              return ChoiceChip(
                                label: Text("$r m"),
                                selected: isSelected,
                                onSelected: (_) => controller.updateRadius(r.toDouble()),
                                selectedColor: primaryGreen,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : primaryDark, 
                                  fontWeight: FontWeight.w600
                                ),
                                side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
                              );
                            });
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.createFirstOffice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      shadowColor: primaryGreen.withValues(alpha:0.4),
                    ),
                    child: controller.isLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text("Save & Continue to Dashboard", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
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

  // --- HELPERS ---

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryDark, size: 24),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: primaryDark)),
            ],
          ),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      onTap: () async {
        TimeOfDay? time = await showTimePicker(
          context: context, 
          initialTime: const TimeOfDay(hour: 8, minute: 30),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: primaryGreen, onSurface: primaryDark),
              ),
              child: child!,
            );
          }
        );
        if (time != null) {
          final hour = time.hour.toString().padLeft(2, '0');
          final minute = time.minute.toString().padLeft(2, '0');
          ctrl.text = "$hour:$minute";
        }
      },
    );
  }
}