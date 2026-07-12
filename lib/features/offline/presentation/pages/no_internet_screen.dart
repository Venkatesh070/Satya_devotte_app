import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3),
      body: SafeArea(
        child: Stack(
          children: [
            // Close Icon at Top Right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF4A2C10)),
                onPressed: () {
                  final offlineService = Get.find<OfflineService>();
                  if (offlineService.showNoInternetScreen.value) {
                    offlineService.showNoInternetScreen.value = false;
                  } else {
                    Get.back();
                  }
                },
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // No Internet Image / Icon with Gradient
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/no_internet.png',
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.wifi_off_rounded,
                            size: 50,
                            color: Color(0xFFFCF7EF),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A2C10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Please check your internet settings and try again to access live updates.',
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(
                      fontSize: 16,
                      color: const Color(0xFF8B5E3C),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action Button with Gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          onRetry ??
                          () => Get.find<OfflineService>().checkConnectivity(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Color(0xFFFCF7EF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
