import 'package:clockinn_flutter_admin/controllers/signup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 900, // Wide card for Web
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                // LEFT SIDE: Branding / Visuals
                Expanded(
                  child: Container(
                    height: 650,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // ClockInn Green
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.watch_later_outlined, size: 60, color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          "Join ClockInn Today.",
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Manage your workforce attendance, geolocation, and payroll efficiently from one dashboard.",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "© 2026 ClockInn Global",
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT SIDE: Signup Form
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Admin Account",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text("Already have an account? ", style: GoogleFonts.inter(color: Colors.grey)),
                            InkWell(
                              onTap: () => Get.offNamed('/login'),
                              child: Text("Sign In", 
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981), 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Form Fields
                        _buildTextField("Full Name", controller.nameCtrl, Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildTextField("Company Name", controller.companyNameCtrl, Icons.business_outlined),
                        const SizedBox(height: 20),
                        _buildTextField("Email Address", controller.emailCtrl, Icons.email_outlined),
                        const SizedBox(height: 20),
                        _buildTextField("Phone Number", controller.phoneCtrl, Icons.phone_outlined),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        Obx(() => TextField(
                          controller: controller.passwordCtrl,
                          obscureText: !controller.isPasswordVisible.value,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(controller.isPasswordVisible.value 
                                ? Icons.visibility 
                                : Icons.visibility_off),
                              onPressed: controller.togglePassword,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),

                        const SizedBox(height: 40),

                        // Submit Button
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : controller.signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : Text(
                                    "Get Started",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }
}