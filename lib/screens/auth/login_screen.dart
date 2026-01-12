import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 900;

    return Scaffold(
      body: Row(
        children: [
          // --- LEFT SIDE (Branding - Desktop Only) ---
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF1E293B), // Dark Slate Blue
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_filled, size: 100, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text("ClockInn Admin", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text("Manage your workforce efficiently.", style: GoogleFonts.inter(color: Colors.white70)),
                  ],
                ),
              ),
            ),

          // --- RIGHT SIDE (Login Form) ---
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mobile Logo (Only show if desktop sidebar is hidden)
                    if (!isDesktop) ...[
                      const Center(child: Icon(Icons.access_time_filled, size: 60, color: Colors.blueAccent)),
                      const SizedBox(height: 20),
                      Center(child: Text("ClockInn Admin", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 40),
                    ],

                    Text("Welcome Back", style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Please enter your details to sign in.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 40),

                    // EMAIL
                    const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller.emailCtrl,
                      decoration: InputDecoration(
                        hintText: "admin@company.com",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD
                    const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Obx(() => TextField(
                      controller: controller.passwordCtrl,
                      obscureText: !controller.isPasswordVisible.value,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                          onPressed: controller.togglePassword,
                        ),
                      ),
                    )),

                    const SizedBox(height: 30),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isLoading.value 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      )),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {}, // Add Forgot Password logic later
                        child: const Text("Forgot password?", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}