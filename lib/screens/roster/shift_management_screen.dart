import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controllers/shifts_controller.dart';

class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShiftsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(controller),
            const SizedBox(height: 10),
            
            // --- WEEK NAVIGATION ---
            _buildWeekControls(controller),
            const SizedBox(height: 10),

            // --- ROSTER MATRIX ---
            Expanded(
              child: _buildRosterMatrix(controller),
            ),
          ],
        ),
      ),
    );
  }

  // --- SAFE COLOR EXTRACTOR HELPER ---
  int _getColor(dynamic colorData) {
    if (colorData == null) return 0xFF2196F3; // Default Blue
    if (colorData is int) return colorData;
    if (colorData is double) return colorData.toInt();
    // Fallback try parse
    return int.tryParse(colorData.toString()) ?? 0xFF2196F3;
  }

  Widget _buildHeader(ShiftsController controller) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text("Weekly Roster", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          
          // Site Dropdown
          Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedSiteId.value.isEmpty ? null : controller.selectedSiteId.value,
              hint: const Text("Select Site"),
              items: controller.availableSites.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']!))).toList(),
              onChanged: (val) => controller.changeSite(val!),
            ),
          )),
          const SizedBox(width: 20),
          
          // Copy Button
          ElevatedButton.icon(
            onPressed: controller.copyPreviousWeek,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Copy Previous Week"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekControls(ShiftsController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: controller.prevWeek, icon: const Icon(Icons.arrow_back_ios, size: 16)),
        Obx(() {
          DateTime start = controller.currentWeekStartDate.value;
          DateTime end = start.add(const Duration(days: 6));
          return Text(
            "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          );
        }),
        IconButton(onPressed: controller.nextWeek, icon: const Icon(Icons.arrow_forward_ios, size: 16)),
      ],
    );
  }

  Widget _buildRosterMatrix(ShiftsController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.siteEmployees.isEmpty) return const Center(child: Text("No employees found in this site."));

      DateTime startOfWeek = controller.currentWeekStartDate.value;
      List<DateTime> weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            // HEADER
            Container(
              color: Colors.grey[100],
              height: 50,
              child: Row(
                children: [
                  const SizedBox(width: 150, child: Center(child: Text("Employee", style: TextStyle(fontWeight: FontWeight.bold)))), 
                  ...weekDays.map((d) => Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('EEE').format(d), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('d').format(d), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
            
            // BODY
            Expanded(
              child: ListView.separated(
                itemCount: controller.siteEmployees.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  var emp = controller.siteEmployees[index];
                  return SizedBox(
                    height: 70, 
                    child: Row(
                      children: [
                        // Name Column
                        Container(
                          width: 150,
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emp['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text(emp['role'] ?? 'Staff', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        // Day Cells
                        ...weekDays.map((date) {
                          var shifts = controller.weeklyShifts.where((s) {
                            DateTime sDate = DateTime.parse(s['startTime']);
                            return s['userId'] == emp['id'] && 
                                   sDate.year == date.year && 
                                   sDate.month == date.month && 
                                   sDate.day == date.day;
                          }).toList();

                          return Expanded(
                            child: InkWell(
                              onTap: () => _showShiftDialog(context, controller, emp, date, existingShift: shifts.isNotEmpty ? shifts.first : null),
                              child: Container(
                                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
                                child: shifts.isEmpty 
                                  ? const Center(child: Icon(Icons.add, size: 14, color: Colors.grey)) 
                                  : _buildShiftChip(shifts.first), // Pass safe color logic here
                              ),
                            ),
                          );
                        })
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShiftChip(Map<String, dynamic> shift) {
    DateTime start = DateTime.parse(shift['startTime']);
    DateTime end = DateTime.parse(shift['endTime']);
    
    // 🛠️ FIX: Safe Color Casting
    int colorVal = _getColor(shift['color']);

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Color(colorVal).withValues(alpha:0.2), // Light background
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: Color(colorVal), width: 3)), // Solid border
      ),
      child: Center(
        child: Text(
          "${DateFormat('HH:mm').format(start)}\n${DateFormat('HH:mm').format(end)}",
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- ADD / EDIT DIALOG ---
  void _showShiftDialog(BuildContext context, ShiftsController controller, Map<String, dynamic> user, DateTime date, {Map<String, dynamic>? existingShift}) {
    var startTime = const TimeOfDay(hour: 9, minute: 0).obs;
    var endTime = const TimeOfDay(hour: 17, minute: 0).obs;
    var selectedColor = 0xFF2196F3.obs;
    var repeatWeeks = 1.obs;

    if (existingShift != null) {
      DateTime s = DateTime.parse(existingShift['startTime']);
      DateTime e = DateTime.parse(existingShift['endTime']);
      startTime.value = TimeOfDay(hour: s.hour, minute: s.minute);
      endTime.value = TimeOfDay(hour: e.hour, minute: e.minute);
      
      // 🛠️ FIX: Safe Load Existing Color
      selectedColor.value = _getColor(existingShift['color']);
    }

    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(DateFormat('EEEE, MMM d').format(date), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                if (existingShift != null)
                  IconButton(
                    onPressed: () {
                      Get.defaultDialog(
                        title: "Delete Shift?",
                        middleText: "Are you sure you want to remove this shift?",
                        textConfirm: "Delete",
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.red,
                        onConfirm: () => controller.deleteShift(existingShift['id']),
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Delete Shift",
                  )
              ],
            ),
            const Divider(height: 30),

            // TEMPLATES
            const Text("Quick Templates", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              children: controller.shiftTemplates.map((t) {
                // 🛠️ FIX: Visual feedback for selected template
                bool isSelected = selectedColor.value == t['color'];
                return ActionChip(
                  avatar: isSelected ? const Icon(Icons.check, size: 14) : null,
                  label: Text(t['name'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  backgroundColor: Color(t['color'] as int).withValues(alpha:isSelected ? 0.4 : 0.1),
                  side: isSelected ? BorderSide(color: Color(t['color'] as int), width: 2) : null,
                  onPressed: () {
                    var s = (t['start'] as String).split(":");
                    var e = (t['end'] as String).split(":");
                    startTime.value = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
                    endTime.value = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
                    selectedColor.value = t['color'] as int;
                  },
                );
              }).toList(),
            )),
            const SizedBox(height: 20),

            // TIME PICKERS
            Row(
              children: [
                Expanded(
                  child: Obx(() => OutlinedButton.icon(
                    onPressed: () async {
                      var t = await showTimePicker(context: Get.context!, initialTime: startTime.value);
                      if (t != null) startTime.value = t;
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(startTime.value.format(Get.context!)),
                  )),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(() => OutlinedButton.icon(
                    onPressed: () async {
                      var t = await showTimePicker(context: Get.context!, initialTime: endTime.value);
                      if (t != null) endTime.value = t;
                    },
                    icon: const Icon(Icons.access_time_filled),
                    label: Text(endTime.value.format(Get.context!)),
                  )),
                ),
              ],
            ),

            const SizedBox(height: 20),
            if (existingShift == null) ...[
              Obx(() => Row(
                children: [
                  Checkbox(
                    value: repeatWeeks.value > 1, 
                    onChanged: (val) => repeatWeeks.value = val! ? 4 : 1
                  ),
                  const Text("Repeat for next 4 weeks"),
                ],
              )),
            ],

            const SizedBox(height: 20),
            
            // 🛠️ FIX: Button Color = Selected Shift Color
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: () {
                  controller.assignShift(
                    userId: user['id'],
                    userName: user['name'] ?? "Unknown",
                    userRole: user['role'] ?? 'Staff',
                    date: date,
                    start: startTime.value,
                    end: endTime.value,
                    weeksToRepeat: repeatWeeks.value,
                    color: selectedColor.value,
                  );
                },
                // Use selected color for button background
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(selectedColor.value), 
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                child: Text(
                  existingShift == null ? "Assign Shift" : "Update Shift", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              )),
            )
          ],
        ),
      ),
    ));
  }
}