import 'package:clockinn_flutter_admin/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light Grey Background
      body: Center(
        child: Container(
          width: 450, // Fixed width for clean desktop look
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LOGO / TITLE ---
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Admin Portal",
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Sign in to manage your workforce",
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // --- INPUT FIELDS ---
              Text("Email Address", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextField(
                controller: controller.emailCtrl,
                decoration: InputDecoration(
                  hintText: "admin@company.com",
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              Text("Password", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Obx(() => TextField(
                controller: controller.passwordCtrl,
                obscureText: !controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: controller.togglePassword,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )),

              const SizedBox(height: 30),

              // --- LOGIN BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6), // Brand Blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Sign In", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                )),
              ),

              const SizedBox(height: 25),

              // --- FOOTER LINKS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New Manager?", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                  TextButton(
                    onPressed: () => Get.toNamed('/activate'), // Points to ActivateAccountScreen
                    child: Text("Activate Account", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              
              Center(
                child: TextButton(
                  onPressed: () => Get.toNamed('/signup'), // Link to Company Registration
                  child: Text("Register New Company", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}