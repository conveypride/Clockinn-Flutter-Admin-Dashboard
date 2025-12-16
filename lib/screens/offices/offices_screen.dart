import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/offices_controller.dart';

class OfficesScreen extends StatelessWidget {
  const OfficesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OfficesController());

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
          child: LayoutBuilder(builder: (context, constraints) {
            bool isSmall = constraints.maxWidth < 600;
            return Flex(
              direction: isSmall ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Operation Sites", 
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                if(isSmall) const SizedBox(height: 15),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: isSmall ? 200 : 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search sites...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: () => Get.snackbar("Action", "Add Site Dialog"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text("Add New", style: TextStyle(color: Colors.white)),
                    ),
                  ],
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

            if (Get.width < 900) {
              return ListView.builder(
                itemCount: controller.sites.length,
                itemBuilder: (context, index) => _buildMobileCard(controller.sites[index], controller),
              );
            } else {
              return _buildDesktopTable(controller);
            }
          }),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(OfficesController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: DataTable(
          horizontalMargin: 0,
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(label: Text("Site Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Location", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Radius", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Working Hours", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: controller.sites.map((site) {
            bool isActive = site['status'] == true;
            bool isHQ = site['isHQ'] == true;

            return DataRow(cells: [
              // 1. Site Name (With HQ Badge)
              DataCell(Row(
                children: [
                  Text(site['nameofsite'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (isHQ)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade100)),
                      child: const Text("HQ", style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                    )
                ],
              )),
              
              // 2. Location
              DataCell(Text(site['location'])),
              
              // 3. Radius
              DataCell(Text("${site['radius']}m")),

              // 4. Hours
              DataCell(Text("${site['openingTime']} - ${site['closingTime']}")),

              // 5. Status
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? "Active" : "Inactive",
                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ),

              // 6. Actions
              DataCell(Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => controller.deleteSite(site['id'])),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> site, OfficesController controller) {
    bool isActive = site['status'] == true;
    bool isHQ = site['isHQ'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(site['nameofsite'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  if(isHQ)
                     Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                      child: const Text("HQ", style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isActive ? "Active" : "Inactive", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 5),
          Text(site['location'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
          
          const Divider(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const Text("Radius", style: TextStyle(fontSize: 11, color: Colors.grey)),
                 Text("${site['radius']}m", style: const TextStyle(fontWeight: FontWeight.w500)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const Text("Hours", style: TextStyle(fontSize: 11, color: Colors.grey)),
                 Text("${site['openingTime']} - ${site['closingTime']}", style: const TextStyle(fontWeight: FontWeight.w500)),
              ]),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.deleteSite(site['id'])),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}