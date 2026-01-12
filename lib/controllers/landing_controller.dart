import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class LandingController extends GetxController {
  // Observables for inputs
  final RxInt employeeCount = 1.obs;
  final RxInt officeCount = 1.obs;
  final RxBool isYearly = false.obs; // Default to monthly to match HTML check

// --- VIDEO CONTROLLER LOGIC ---
  late VideoPlayerController demoVideoController;
  final RxBool isVideoInitialized = false.obs;


  // Computed properties (Getters)
  String get planName {
    if (officeCount.value <= 1) return 'Standard';
    if (officeCount.value <= 3) return 'Professional';
    return 'Premium';
  }

  // Feature flags based on Plan
  bool get hasNotifications => officeCount.value > 1; // Pro & Premium
  bool get hasShiftSystem => officeCount.value > 1;
  bool get hasPremiumSupport => officeCount.value > 3; // Premium only
  int get reportDays => officeCount.value <= 1 ? 30 : (officeCount.value <= 3 ? 60 : 120);
  String get announcementCount => officeCount.value <= 1 ? "5" : (officeCount.value <= 3 ? "15" : "Unlimited");
  String get adminCount => officeCount.value <= 1 ? "1" : (officeCount.value <= 3 ? "3" : "Unlimited");


@override
  void onInit() {
    super.onInit();
    _initVideo();
  }


  void _initVideo() async {
    // Ensure you have this file in your assets
    demoVideoController = VideoPlayerController.asset('assets/img/demo-screen.mp4');
    
    await demoVideoController.initialize();
    await demoVideoController.setLooping(true);
    await demoVideoController.setVolume(0.0); // Mute is required for web autoplay
    await demoVideoController.play();
    
    isVideoInitialized.value = true;
  }

  // Pricing Logic (Ported from your JS)
  double get yearlyBasePrice {
    int count = employeeCount.value;
    double base = 0;
    
    // Logic for Standard Plan Base Prices (Adjusted based on plan tier logic in JS)
    if (count <= 50) base = 1500;
    else if (count <= 100) base = 2000;
    else if (count <= 150) base = 2500;
    else if (count <= 200) base = 3000;
    else base = 3500;

    // Price bumps for tiers (inferred from JS logic where prices increased by 500 per tier)
    if (planName == 'Professional') base += 500;
    if (planName == 'Premium') base += 1000;

    return base;
  }

  double get billingTotal {
    if (isYearly.value) {
      return yearlyBasePrice;
    } else {
      // Monthly is Yearly / 10
      return yearlyBasePrice / 10;
    }
  }

  double get pricePerEmployee {
    double total = billingTotal;
    double perEmp = total / (employeeCount.value == 0 ? 1 : employeeCount.value);
    
    if (isYearly.value) {
      return perEmp / 12; // Show monthly breakdown
    }
    return perEmp;
  }


@override
  void onClose() {
    demoVideoController.dispose();
    super.onClose();
  }

}