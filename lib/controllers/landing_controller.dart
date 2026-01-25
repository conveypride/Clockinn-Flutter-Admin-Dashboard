import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class LandingController extends GetxController {
  // Observables for inputs
  final RxInt employeeCount = 10.obs; // Default to 10 for better visual demo
  final RxBool isYearly = false.obs; 

  // --- VIDEO CONTROLLER LOGIC ---
  late VideoPlayerController demoVideoController;
  final RxBool isVideoInitialized = false.obs;

  // Constant Pricing
  final double baseRatePerEmployee = 30.0;

  @override
  void onInit() {
    super.onInit();
    _initVideo();
  }

  void _initVideo() async {
    demoVideoController = VideoPlayerController.asset('assets/img/demo-screen.mp4');
    await demoVideoController.initialize();
    await demoVideoController.setLooping(true);
    await demoVideoController.setVolume(0.0); // Mute is required for web autoplay
    await demoVideoController.play();
    isVideoInitialized.value = true;
  }

  // --- SIMPLIFIED PRICING LOGIC ---

  // 1. The total amount the user pays at checkout
  double get billingTotal {
    double monthlyTotal = employeeCount.value * baseRatePerEmployee;

    if (isYearly.value) {
      // Calculate 12 months, then apply 20% discount
      return (monthlyTotal * 12) * 0.80; 
    } else {
      return monthlyTotal;
    }
  }

  // 2. The "Price per employee" shown to the user
  double get pricePerEmployeeDisplay {
    if (isYearly.value) {
      // If paying yearly, show the effective discounted monthly rate
      // (30 * 12 * 0.8) / 12 = 24
      return baseRatePerEmployee * 0.80; 
    }
    return baseRatePerEmployee;
  }

  // 3. Plan Name (Simple one plan)
  String get planName => "All-Inclusive Plan";

  @override
  void onClose() {
    demoVideoController.dispose();
    super.onClose();
  }
}