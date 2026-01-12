import 'package:clockinn_flutter_admin/controllers/login_controller.dart';
import 'package:clockinn_flutter_admin/firebase_options.dart';
import 'package:clockinn_flutter_admin/screens/announcements/announcements_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/landing_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/login_screen.dart';
import 'package:clockinn_flutter_admin/screens/offices/offices_screen.dart';
import 'package:clockinn_flutter_admin/screens/roles/roles_screen.dart';
import 'package:clockinn_flutter_admin/screens/roster/shift_management_screen.dart';
import 'package:clockinn_flutter_admin/screens/settings/settings_screen.dart';
import 'package:clockinn_flutter_admin/screens/subscription/subscription_screen.dart';
import 'package:clockinn_flutter_admin/screens/users/awaiting_verification_screen.dart';
import 'package:clockinn_flutter_admin/screens/users/manage_users_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'layout/base_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdminApp());
}
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClockInn Admin',
      theme: ThemeData(useMaterial3: true, primaryColor: const Color(0xFF2d2ed4),),
      initialBinding: AdminBinding(), 
      // Define Routes (Like web.php)
      initialRoute: '/',
      getPages: [
        // Landing Page Route
        GetPage(
          name: '/', 
          page: () => const LandingScreen(),
        ),
        GetPage(name: '/login', page: () => const LoginScreen()), 
        GetPage(
          name: '/dashboard',
          page: () => const BaseLayout(child: DashboardScreen()),
        ),
        GetPage(
          name: '/offices',
          page: () => const BaseLayout(child: OfficesScreen()),
        ),
        GetPage(
          name: '/verification',
          page: () => const BaseLayout(child: AwaitingVerificationScreen()),
        ),
        GetPage(
          name: '/users',
          page: () => const BaseLayout(child: ManageUsersScreen()),
        ),
        GetPage(
          name: '/roles',
          page: () => const BaseLayout(child: RolesScreen()),
        ),
        GetPage(name: '/announcements', page: () => const BaseLayout(child: AnnouncementsScreen())),
        GetPage(name: '/shifts', page: () => const BaseLayout(child: ShiftManagementScreen())),
        GetPage(name: '/subscription', page: () => const BaseLayout(child: SubscriptionScreen())),
        GetPage(name: '/settings', page: () => const BaseLayout(child: SettingsScreen())),
      ],
    );
  }


  
}

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LoginController(), permanent: true);
  }
}
