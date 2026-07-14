import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/api_loading_service.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';

/// Wraps the app navigator and shows [ChakraLoaderPage] during API calls.
class ApiLoadingOverlay extends StatelessWidget {
  const ApiLoadingOverlay({super.key, required this.child});

  final Widget child;

  static const Set<String> _skipLoaderRoutes = {
    '',
    '/',
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.userDonationConfirming,
    AppRoutes.poojaKitPayment,
    AppRoutes.search,
  };

  @override
  Widget build(BuildContext context) {
    final loadingService = Get.find<ApiLoadingService>();

    return Obx(() {
      final currentRoute = Get.currentRoute;
      final showLoader =
          loadingService.isLoading && !_skipLoaderRoutes.contains(currentRoute);

      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (showLoader) const ChakraLoaderPage(asOverlay: true),
        ],
      );
    });
  }
}
