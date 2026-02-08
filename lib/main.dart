import 'package:clockinn_flutter_admin/controllers/login_controller.dart';
import 'package:clockinn_flutter_admin/firebase_options.dart';
import 'package:clockinn_flutter_admin/middleware/auth_middleware.dart';
import 'package:clockinn_flutter_admin/screens/announcements/announcements_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/activate_account_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/landing_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/login_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/setup_office_screen.dart';
import 'package:clockinn_flutter_admin/screens/auth/signup_screen.dart';
import 'package:clockinn_flutter_admin/screens/offices/offices_screen.dart';
import 'package:clockinn_flutter_admin/screens/reports/export_screen.dart';
import 'package:clockinn_flutter_admin/screens/roles/roles_screen.dart';
import 'package:clockinn_flutter_admin/screens/roster/shift_management_screen.dart';
import 'package:clockinn_flutter_admin/screens/settings/settings_screen.dart';
import 'package:clockinn_flutter_admin/screens/subscription/payment_success_screen.dart';
import 'package:clockinn_flutter_admin/screens/subscription/subscription_screen.dart';
import 'package:clockinn_flutter_admin/screens/users/awaiting_verification_screen.dart';
import 'package:clockinn_flutter_admin/screens/users/manage_users_screen.dart';
import 'package:clockinn_flutter_admin/util/web_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'layout/base_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load Maps API only on Web
  if (kIsWeb) {
    await loadGoogleMaps();
  }
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
          name: '/signup', 
          page: () => const SignupScreen(),
        ),
        GetPage(
          name: '/setup-office',
          page: () => const  SetupOfficeScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const BaseLayout(child: DashboardScreen()),
          middlewares: [AuthMiddleware()],
        ),
GetPage(name: '/activate', page: () => const ActivateAccountScreen()),
        
        GetPage(
          name: '/offices',
          page: () =>  BaseLayout(child: OfficesScreen()),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/verification',
          page: () => const BaseLayout(child: AwaitingVerificationScreen()),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/users',
          page: () => const BaseLayout(child: ManageUsersScreen()),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/roles',
          page: () => const BaseLayout(child: RolesScreen()),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
    name: '/payment-success',
    page: () => const PaymentSuccessScreen(),
    transition: Transition.fadeIn, 
  ),
        GetPage(name: '/announcements', page: () => const BaseLayout(child: AnnouncementsScreen()),middlewares: [AuthMiddleware()],),
        GetPage(name: '/shifts', page: () => const BaseLayout(child: ShiftManagementScreen()), middlewares: [AuthMiddleware()],),
        GetPage(name: '/export', page: () => const BaseLayout(child: ExportScreen()), middlewares: [AuthMiddleware()],),
        GetPage(name: '/subscription', page: () => SubscriptionScreen()),
        GetPage(name: '/settings', page: () => const BaseLayout(child: SettingsScreen()),middlewares: [AuthMiddleware()],),
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
