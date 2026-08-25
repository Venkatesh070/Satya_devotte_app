import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a centered modal dialog pop-up floating over the application screen.
/// Matches the Google Play update card design with dynamic app name and release notes.
Future<void> showAppUpdateDialog(
  BuildContext context, {
  String? appName,
  String? appSize,
  String? contentRating,
  String? releaseNotes,
  String? storeUrl,
  bool isMandatory = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !isMandatory,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (BuildContext context) {
      return AppUpdatePopupDialog(
        appName: appName,
        appSize: appSize,
        contentRating: contentRating,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
        isMandatory: isMandatory,
      );
    },
  );
}

class AppUpdatePopupDialog extends StatefulWidget {
  final String? appName;
  final String? appSize;
  final String? contentRating;
  final String? releaseNotes;
  final String? storeUrl;
  final bool isMandatory;

  const AppUpdatePopupDialog({
    super.key,
    this.appName,
    this.appSize,
    this.contentRating,
    this.releaseNotes,
    this.storeUrl,
    this.isMandatory = false,
  });

  @override
  State<AppUpdatePopupDialog> createState() => _AppUpdatePopupDialogState();
}

class _AppUpdatePopupDialogState extends State<AppUpdatePopupDialog> {
  bool _isWhatsNewExpanded = false;
  String _resolvedAppName = '';

  @override
  void initState() {
    super.initState();
    _initDynamicAppName();
  }

  Future<void> _initDynamicAppName() async {
    if (widget.appName != null && widget.appName!.isNotEmpty) {
      setState(() {
        _resolvedAppName = widget.appName!;
      });
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _resolvedAppName = info.appName.isNotEmpty ? info.appName : 'Sathya';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvedAppName = 'Sathya';
        });
      }
    }
  }

  Future<void> _handleUpdate() async {
    final defaultUrl = Uri.parse(
      widget.storeUrl ?? 'market://details?id=com.satya_devotte_app',
    );
    final webFallback = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.satya_devotte_app',
    );

    try {
      if (await canLaunchUrl(defaultUrl)) {
        await launchUrl(defaultUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch update URL: $e');
    }
  }

  Future<void> _handleLearnMore() async {
    final webUrl = Uri.parse(
      widget.storeUrl ??
          'https://play.google.com/store/apps/details?id=com.satya_devotte_app',
    );
    try {
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch learn more URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAppName = _resolvedAppName.isNotEmpty
        ? _resolvedAppName
        : (widget.appName ?? 'Sathya');
    final displayReleaseNotes = (widget.releaseNotes != null &&
            widget.releaseNotes!.trim().isNotEmpty)
        ? widget.releaseNotes!
        : 'Bug fixes, performance enhancements, and new features included in this release.';
    final displaySize = (widget.appSize != null && widget.appSize!.trim().isNotEmpty)
        ? widget.appSize!
        : '182 MB';
    final displayRating = (widget.contentRating != null && widget.contentRating!.trim().isNotEmpty)
        ? widget.contentRating!
        : 'Rated for 3+';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Google Play header + Close 'X' button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildGooglePlayLogo(),
                        const SizedBox(width: 8),
                        const Text(
                          'Google Play',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5F6368),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isMandatory)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close',
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Title
                const Text(
                  'Update available',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'To use this app, download the latest version.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF444746),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 20),

                // App Details Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E2E5)),
                  ),
                  child: Row(
                    children: [
                      // App Icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/appLogo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFFD32F2F),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayAppName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  displaySize,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5F6368),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF747775),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    '3+',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayRating,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.info_outline,
                                  size: 13,
                                  color: Color(0xFF5F6368),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Collapsible "What's new" Section
                InkWell(
                  onTap: () {
                    setState(() {
                      _isWhatsNewExpanded = !_isWhatsNewExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "What's new",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        Icon(
                          _isWhatsNewExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF5F6368),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isWhatsNewExpanded) ...[
                  const SizedBox(height: 6),
                  Text(
                    displayReleaseNotes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444746),
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleLearnMore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B57D0),
                          side: const BorderSide(color: Color(0xFF747775)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Learn more',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B57D0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGooglePlayLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GooglePlayLogoPainter(),
      ),
    );
  }
}

class _GooglePlayLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blue triangle path
    final pathBlue = Path()
      ..moveTo(w * 0.05, h * 0.05)
      ..lineTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.05, h * 0.95)
      ..close();

    // Green triangle path
    final pathGreen = Path()
      ..moveTo(w * 0.05, h * 0.05)
      ..lineTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.55, h * 0.5)
      ..close();

    // Red triangle path
    final pathRed = Path()
      ..moveTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.72, h * 0.65)
      ..lineTo(w * 0.05, h * 0.95)
      ..close();

    // Yellow triangle path
    final pathYellow = Path()
      ..moveTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.72, h * 0.65)
      ..close();

    canvas.drawPath(pathBlue, Paint()..color = const Color(0xFF00A0FF));
    canvas.drawPath(pathGreen, Paint()..color = const Color(0xFF00E676));
    canvas.drawPath(pathRed, Paint()..color = const Color(0xFFFF3D00));
    canvas.drawPath(pathYellow, Paint()..color = const Color(0xFFFFD600));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
