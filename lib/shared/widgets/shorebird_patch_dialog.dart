import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

enum ShorebirdPatchDialogPhase { downloading, ready }

/// Blocking sheet for Shorebird patch download / apply.
class ShorebirdPatchDialog extends StatelessWidget {
  final ShorebirdPatchDialogPhase phase;
  final VoidCallback? onCloseAndApply;
  final VoidCallback? onDismiss;

  /// Same fill as home [Scaffold] background.
  static const Color homeBackground = Color(0xFFF2EBDC);

  const ShorebirdPatchDialog({
    super.key,
    required this.phase,
    this.onCloseAndApply,
    this.onDismiss,
  });

  bool get _isDownloading => phase == ShorebirdPatchDialogPhase.downloading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: homeBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gradientEnd.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gradientStart.withValues(alpha: 0.08),
                  ),
                ),
              ),
              if (!_isDownloading && onDismiss != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textColor.withValues(alpha: 0.45),
                    ),
                    tooltip: 'Dismiss',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.gradientStart.withValues(alpha: 0.95),
                            AppColors.gradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gradientEnd.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isDownloading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.system_update_alt_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _isDownloading ? 'Updating Sathya' : 'Update ready',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isDownloading
                          ? 'Downloading a quick improvement for a smoother experience.'
                          : 'Close the app, then open Sathya again to finish applying the update.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textColor.withValues(alpha: 0.72),
                      ),
                    ),
                    if (!_isDownloading) ...[
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.gradientStart,
                                AppColors.gradientEnd,
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: onCloseAndApply,
                              child: Center(
                                child: Text(
                                  'Close app to apply',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      Text(
                        'Please keep the app open…',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
