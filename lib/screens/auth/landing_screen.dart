import 'package:clockinn_flutter_admin/controllers/landing_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import SVG package
import 'package:video_player/video_player.dart'; // Import Video package

class LandingScreen extends GetView<LandingController> {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller if not already present
    if (!Get.isRegistered<LandingController>()) {
      Get.put(LandingController());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildNavBar(context),
      extendBodyBehindAppBar: false,
      drawer: MediaQuery.of(context).size.width < 992 ? _buildDrawer(context) : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMasthead(context),
            _buildQuoteSection(),
            _buildFeaturesSection(context),
            _buildBasicFeatureSection(context),
            _buildPricingSection(context),
            _buildCTASection(),
            _buildDownloadSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- 1. Navigation ---
  PreferredSizeWidget _buildNavBar(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 992;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text('ClockInn', style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      actions: isDesktop
          ? [
              _navLink('Features', () {}),
              _navLink('Download', () {}),
              _navLink('Pricing', () {}),
              _navLink('SignIn', () => Get.toNamed('/login')),
              _navLink('SignUp', () {}),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble, size: 18),
                label: const Text("Send Feedback"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(width: 32),
            ]
          : null,
    );
  }

  Widget _navLink(String title, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(title, style: GoogleFonts.mulish(color: Colors.black87, fontWeight: FontWeight.w600)),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Center(child: Text("ClockInn Menu"))),
          ListTile(title: const Text("Features"), onTap: () {}),
          ListTile(title: const Text("Pricing"), onTap: () {}),
          ListTile(title: const Text("Sign In"), onTap: () => Get.toNamed('/login')),
          ListTile(title: const Text("Sign Up"), onTap: () {}),
        ],
      ),
    );
  }

  // --- 2. Masthead (WITH VIDEO) ---
  Widget _buildMasthead(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 992;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFf8f9fa), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text Side
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Attendance System",
                  style: GoogleFonts.newsreader(fontSize: isMobile ? 40 : 60, fontWeight: FontWeight.bold, height: 1.1),
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                ),
                const SizedBox(height: 16),
                Text(
                  "Attendance system for your workforce!!!",
                  style: GoogleFonts.mulish(fontSize: 20, color: Colors.grey),
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    _appBadge('img/google-play-badge.png'), 
                    const SizedBox(width: 16),
                    _appBadge('img/app-store-badge.png'), 
                  ],
                ),
              ],
            ),
          ),
          if (isMobile) const SizedBox(height: 40),
          
          // Device Mockup Side (Phone with Video)
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Abstract Shapes (Gradients behind phone)
                  Transform.translate(
                    offset: const Offset(40, -40),
                    child: Container(
                      width: 400, height: 400,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
   Color(0xFF10B981),
    Color(0xFF0F172A),
  ],
),
                      ),
                    ),
                  ),
                  
                  // The Phone Frame
                  Container(
                    height: 500,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.grey.shade900, width: 12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    // Clip contents to rounded corners
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          // The Video Player
                          Obx(() {
                            if (controller.isVideoInitialized.value) {
                              return SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: controller.demoVideoController.value.size.width,
                                    height: controller.demoVideoController.value.size.height,
                                    child: VideoPlayer(controller.demoVideoController),
                                  ),
                                ),
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          }),
                          // Status bar simulation
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Container(height: 25, color: Colors.black.withValues(alpha:0.2)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Quote Section ---
  Widget _buildQuoteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
   Color(0xFF10B981),
    Color(0xFF0F172A),
  ],
),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Text(
            '"Reduce to zero late arrivals and attendance excuses. The Clockinn App serves as a bridge between managers and staff!"',
            style: GoogleFonts.newsreader(color: Colors.white, fontSize: 24, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // --- 4. Features Grid ---
  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      color: const Color(0xFFf8f9fa),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 40,
        runSpacing: 40,
        children: [
          _featureItem(Icons.phone_android, "Clock In & Out", "IOS & Android App to help you clock in & out everyday!"),
          _featureItem(Icons.face, "Face Recognition", "Integrated face recognition for accuracy!"),
          _featureItem(Icons.location_on, "Geofencing", "High accuracy radius checks!"),
          _featureItem(Icons.history, "History", "Transparent attendance history!"),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String desc) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Icon(icon, size: 50, color: const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.kanit(fontSize: 24)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.mulish(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- 5. Basic Feature (HR Empowerment WITH IMAGE) ---
  Widget _buildBasicFeatureSection(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 992;
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("A new age of HR empowerment", style: GoogleFonts.kanit(fontSize: 40, height: 1)),
                const SizedBox(height: 20),
                Text("Monitor your employees to help increase productivity. Clockinn empowers you to have full control.", style: GoogleFonts.mulish(fontSize: 18, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 40, height: 40),
          // Dashboard Image Integration
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              clipBehavior: Clip.antiAlias,
              // Uses standard Image.asset
              child: Image.asset(
                'img/dashboard.png', 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    height: 300, color: Colors.grey.shade200, 
                    child: const Center(child: Text("Dashboard.png not found in assets"))
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Pricing Calculator ---
  Widget _buildPricingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 30, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Text("Calculate Your Plan", style: GoogleFonts.kanit(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text("Simple, transparent pricing", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    // Toggles
                    Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text("Monthly"),
                              selected: !controller.isYearly.value,
                              onSelected: (val) => controller.isYearly.value = false,
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("Yearly (Save 20%)"),
                              selected: controller.isYearly.value,
                              selectedColor: Colors.green.shade100,
                              onSelected: (val) => controller.isYearly.value = true,
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              const Divider(),
              // Inputs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Number of Employees"),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.people)),
                      onChanged: (val) => controller.employeeCount.value = int.tryParse(val) ?? 1,
                      controller: TextEditingController(text: controller.employeeCount.value.toString()),
                    ),
                    const SizedBox(height: 20),
                    const Text("Number of Offices"),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                      onChanged: (val) => controller.officeCount.value = int.tryParse(val) ?? 1,
                      controller: TextEditingController(text: controller.officeCount.value.toString()),
                    ),
                    const SizedBox(height: 20),
                    // Plan Features Dynamic List
                    Obx(() => Column(
                      children: [
                        _pricingFeature(true, "Android / iOS App"),
                        _pricingFeature(true, "Face-Recognition"),
                        _pricingFeature(true, "Geo-Fencing Capability"),
                        _pricingFeature(controller.hasNotifications, "Notification Capability"),
                        _pricingFeature(controller.hasShiftSystem, "Shift Management"),
                        _pricingFeature(controller.hasPremiumSupport, "Premium Customer Support"),
                        _pricingFeature(true, "${controller.reportDays} Days Attendance Reports"),
                        _pricingFeature(true, "${controller.announcementCount} Announcements"),
                        _pricingFeature(true, "${controller.adminCount} Admin Accounts"),
                      ],
                    )),
                  ],
                ),
              ),
              // Total Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Color(0xFFf8f9fa),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Column(
                  children: [
                    Obx(() => Chip(
                      label: Text(controller.planName),
                      backgroundColor: controller.planName == 'Standard' ? Colors.green : (controller.planName == 'Professional' ? Colors.orange : Colors.blue),
                      labelStyle: const TextStyle(color: Colors.white),
                    )),
                    const SizedBox(height: 10),
                    Obx(() => Text(
                      "GHC ${controller.pricePerEmployee.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    )),
                    const Text("per employee / month", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Obx(() => Text(
                      "Total billing: GHC ${controller.billingTotal.toStringAsFixed(2)} ${controller.isYearly.value ? '/ year' : '/ month'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed('/signup'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _pricingFeature(bool enabled, String text) {
    if (!enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // --- 7. CTA ---
  Widget _buildCTASection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      // Optional: Add a background image here if available
      // decoration: BoxDecoration(
      //   image: DecorationImage(image: AssetImage('img/dashboard2.png'), fit: BoxFit.cover),
      // ),
      color: Colors.black, 
      child: Column(
        children: [
          Text("Are You An HR?\nSign-Up For Free", 
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 40)
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => Get.toNamed('/signup'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
            ),
            child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 20)),
          )
        ],
      ),
    );
  }

  // --- 8. Download & Footer ---
  Widget _buildDownloadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
   Color(0xFF10B981),
    Color(0xFF0F172A),
  ],
),
      ),
      child: Column(
        children: [
          Text("Get the app now!", style: GoogleFonts.kanit(color: Colors.white, fontSize: 32)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _appBadge('img/google-play-badge.png'),
              const SizedBox(width: 20),
              _appBadge('img/app-store-badge.png'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(30),
      child: const Center(
        child: Text(
          "© Clockinn 2026. All Rights Reserved. Developed by RTR Innovations Ltd",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }

  // Helper for App Badges using 
  Widget _appBadge(String assetPath) {
    return InkWell(
      onTap: () {
        // Add launchUrl logic here
      },
      child: Image.asset(
        assetPath,
        height: 50,
      ),
    );
  }
}