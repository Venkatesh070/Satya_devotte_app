import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

enum ToastType { success, error, info }

class ToastUtil {
  static OverlayEntry? _currentEntry;

  static String _cleanMessage(String msg) {
    var cleaned = msg
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
    return cleaned
        .replaceAll('"', '')
        .replaceAll('\u201C', '')
        .replaceAll('\u201D', '')
        .trim();
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    final context = Get.overlayContext ?? Get.context;
    if (context != null) {
      _showToast(
        context: context,
        title: title,
        message: _cleanMessage(message),
        type: ToastType.success,
      );
    }
  }

  static void showError(String message, {String title = 'Error'}) {
    final context = Get.overlayContext ?? Get.context;
    if (context != null) {
      var cleanTitle = title;
      final cleanMsg = _cleanMessage(message);
      if (cleanTitle == 'Error') {
        if (cleanMsg.toLowerCase().contains('out of stock')) {
          cleanTitle = 'Out of Stock';
        } else if (cleanMsg.toLowerCase().contains('stock') ||
            cleanMsg.toLowerCase().contains('inventory') ||
            cleanMsg.toLowerCase().contains('can be built')) {
          cleanTitle = 'Stock Limit';
        }
      }
      _showToast(
        context: context,
        title: cleanTitle,
        message: cleanMsg,
        type: ToastType.error,
      );
    }
  }

  static void showInfo(String message, {String title = 'Info'}) {
    final context = Get.overlayContext ?? Get.context;
    if (context != null) {
      _showToast(
        context: context,
        title: title,
        message: _cleanMessage(message),
        type: ToastType.info,
      );
    }
  }

  static void show(String title, String message) {
    final context = Get.overlayContext ?? Get.context;
    if (context != null) {
      _showToast(
        context: context,
        title: title,
        message: _cleanMessage(message),
        type: ToastType.info,
      );
    }
  }

  static void _showToast({
    required BuildContext context,
    required String title,
    required String message,
    required ToastType type,
  }) {
    // Dismiss any existing toast first
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AnimatedToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _AnimatedToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _AnimatedToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<_AnimatedToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF2E7D32);
      case ToastType.error:
        return const Color(0xFFD32F2F);
      case ToastType.info:
        return const Color(0xFFE65100);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final double maxToastWidth = isTablet ? 450 : screenWidth - 32;

    return Positioned(
      top: topPadding > 0 ? topPadding + 10 : (kIsWeb ? 16 : 40),
      left: (screenWidth - maxToastWidth) / 2,
      width: maxToastWidth,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _dismiss,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < 0) {
              _dismiss();
            }
          },
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF7EF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon,
                        color: _accentColor,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title.isNotEmpty)
                            Text(
                              widget.title,
                              style: AppTypography.lora(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                          if (widget.title.isNotEmpty &&
                              widget.message.isNotEmpty)
                            const SizedBox(height: 3),
                          if (widget.message.isNotEmpty)
                            Text(
                              widget.message,
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF424242),
                                height: 1.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
