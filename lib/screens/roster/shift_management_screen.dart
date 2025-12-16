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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddShiftDialog(context, controller),
        label: const Text("Assign Shift"),
        icon: const Icon(Icons.add_task),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // --- 1. FILTER BAR (Site & Date) ---
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
                  "Shift Management",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // FILTERS ROW
                Row(
                  children: [
                    // SITE DROPDOWN
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Obx(
                          () => DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.selectedSiteId.value,
                              items: controller.availableSites.map((site) {
                                return DropdownMenuItem(
                                  value: site['id'],
                                  child: Text(site['name']!),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) controller.changeSite(val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // DATE PICKER BUTTON
                    Expanded(
                      flex: 1,
                      child: Obx(
                        () => OutlinedButton.icon(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: controller.selectedDate.value,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) controller.changeDate(picked);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat(
                              'EEE, MMM d',
                            ).format(controller.selectedDate.value),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. SHIFT LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value)
                return const Center(child: CircularProgressIndicator());

              if (controller.displayedShifts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No shifts scheduled for this day.",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.displayedShifts.length,
                itemBuilder: (context, index) {
                  return _buildShiftCard(
                    controller.displayedShifts[index],
                    controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(
    Map<String, dynamic> shift,
    ShiftsController controller,
  ) {
    DateTime start = DateTime.parse(shift['startTime']);
    DateTime end = DateTime.parse(shift['endTime']);
    String timeStr =
        "${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}";
    int duration = end.difference(start).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Color(shift['color']), width: 5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          // TIME COLUMN
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('h:mm a').format(start),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(end),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 20),

          // INFO COLUMN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift['userName'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shift['userRole'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$duration Hrs",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ACTIONS
          IconButton(
            onPressed: () => controller.deleteShift(shift['id']),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // --- ADD SHIFT DIALOG ---
  void _showAddShiftDialog(BuildContext context, ShiftsController controller) {
    
    // Local State for selections
    var selectedUsers = <Map<String, dynamic>>[].obs;
    var startTime = const TimeOfDay(hour: 8, minute: 0).obs;
    var endTime = const TimeOfDay(hour: 17, minute: 0).obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500, // Wider for better visibility
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bulk Shift Assignment", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Select all employees for this shift:", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 15),

              // 1. MULTI-SELECT USER LIST
              Container(
                height: 200, // Fixed height scrollable area
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  if (controller.eligibleEmployees.isEmpty) {
                    return const Center(child: Text("No eligible shift workers found.", style: TextStyle(color: Colors.grey)));
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.eligibleEmployees.length,
                    itemBuilder: (context, index) {
                      var emp = controller.eligibleEmployees[index];
                      return Obx(() {
                        bool isSelected = selectedUsers.contains(emp);
                        return CheckboxListTile(
                          title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(emp['role'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          value: isSelected,
                          activeColor: Colors.blueAccent,
                          onChanged: (val) {
                            if (val == true) {
                              selectedUsers.add(emp);
                            } else {
                              selectedUsers.remove(emp);
                            }
                          },
                        );
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 10),
              // Selection Counter
              Obx(() => Text(
                "${selectedUsers.length} employees selected", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)
              )),

              const SizedBox(height: 20),

              // 2. TIME PICKERS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Start Time", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Obx(() => OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: startTime.value);
                            if (time != null) startTime.value = time;
                          },
                          child: Text(startTime.value.format(context)),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("End Time", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Obx(() => OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: endTime.value);
                            if (time != null) endTime.value = time;
                          },
                          child: Text(endTime.value.format(context)),
                        )),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 3. ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(), 
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                  ),
                  const SizedBox(width: 10),
                  Obx(() => ElevatedButton(
                    onPressed: selectedUsers.isEmpty ? null : () {
                      // Logic to calculate DateTimes
                      DateTime date = controller.selectedDate.value;
                      DateTime startDt = DateTime(date.year, date.month, date.day, startTime.value.hour, startTime.value.minute);
                      DateTime endDt = DateTime(date.year, date.month, date.day, endTime.value.hour, endTime.value.minute);
                      
                      // Overnight logic
                      if (endDt.isBefore(startDt)) {
                        endDt = endDt.add(const Duration(days: 1));
                      }

                      controller.createBulkShifts(selectedUsers, startDt, endDt);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                    ),
                    child: Text("Assign to ${selectedUsers.length} Users", style: const TextStyle(color: Colors.white)),
                  )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
