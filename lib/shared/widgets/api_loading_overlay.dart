import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/api_loading_service.dart';
import 'package:satya_devotte_app/shared/pages/chakra_loader_page.dart';

/// Wraps the app navigator and shows [ChakraLoaderPage] during API calls.
class ApiLoadingOverlay extends StatelessWidget {
  const ApiLoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loadingService = Get.find<ApiLoadingService>();

    return Obx(() {
      final showLoader = loadingService.isLoading;
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
