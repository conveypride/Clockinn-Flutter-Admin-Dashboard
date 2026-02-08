import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<LoginController>();

    // 1. If not logged in, force Login
    if (authController.companyId.value.isEmpty) {
      return const RouteSettings(name: '/login');
    }

    // 2. If logged in but Subscription is EXPIRED
    if (!authController.isSubscriptionActive.value) {
      // If they are trying to go anywhere EXCEPT subscription, block them
      if (route != '/subscription') {
         return const RouteSettings(name: '/subscription');
      }
    }

    return null; // Allow access
  }
}