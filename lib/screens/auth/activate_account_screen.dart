import 'package:clockinn_flutter_admin/controllers/activate_account_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 


class ActivateAccountScreen extends StatelessWidget {
  const ActivateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ActivateAccountController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView( // <--- 1. ADDED SCROLL VIEW
          padding: const EdgeInsets.all(20), // Prevents card touching edges on small screens
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open_rounded, size: 50, color: Color(0xFF10B981)),
                const SizedBox(height: 20),
                Text("Activate Account", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Enter the code provided by your administrator to set up your password.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                TextField(
                  controller: controller.emailCtrl,
                  decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller.codeCtrl,
                  decoration: const InputDecoration(labelText: "Activation Code (6-Digits)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                Obx(() => TextField(
                  controller: controller.passwordCtrl,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: "Create Password", 
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => controller.isPasswordVisible.toggle(),
                    )
                  ),
                )),
                const SizedBox(height: 15),
                TextField(
                  controller: controller.confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.activate,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                    child: controller.isLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Activate & Login"),
                  )),
                ),
                const SizedBox(height: 15),
                TextButton(onPressed: () => Get.toNamed('/login'), child: const Text("Back to Login"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}