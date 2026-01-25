import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class StatDetailsScreen extends StatelessWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function() fetchData;
  final Color themeColor;

  const StatDetailsScreen({
    super.key,
    required this.title,
    required this.fetchData,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No employees found", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: themeColor.withOpacity(0.1),
                  backgroundImage: (user['picurl'] != null && user['picurl'].isNotEmpty)
                      ? NetworkImage(user['picurl'])
                      : null,
                  child: (user['picurl'] == null || user['picurl'].isEmpty)
                      ? Text(
                          (user['name'] ?? "U")[0].toUpperCase(),
                          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(
                  user['name'] ?? "Unknown",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  user['detail'] ?? user['role'] ?? "Employee",
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: user['time'] != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user['time'],
                          style: GoogleFonts.inter(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}