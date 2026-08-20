import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

class ConnectivityStatusBanner extends StatefulWidget {
  const ConnectivityStatusBanner({super.key, this.child});

  final Widget? child;

  @override
  State<ConnectivityStatusBanner> createState() =>
      _ConnectivityStatusBannerState();
}

class _ConnectivityStatusBannerState extends State<ConnectivityStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  Worker? _onlineWorker;
  Timer? _restoredTimer;

  bool _isOffline = false;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    if (Get.isRegistered<OfflineService>()) {
      final service = Get.find<OfflineService>();
      _isOffline = !service.isOnline.value;
      if (_isOffline) {
        _controller.value = 1.0;
      }

      _onlineWorker = ever(service.isOnline, (bool isOnline) {
        if (!isOnline) {
          _restoredTimer?.cancel();
          setState(() {
            _isOffline = true;
            _showRestored = false;
          });
          _controller.forward();
        } else if (_isOffline) {
          setState(() {
            _isOffline = false;
            _showRestored = true;
          });
          _controller.forward();
          _restoredTimer?.cancel();
          _restoredTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              _controller.reverse().then((_) {
                if (mounted) {
                  setState(() => _showRestored = false);
                }
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _onlineWorker?.dispose();
    _restoredTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline && !_showRestored) {
      return widget.child ?? const IgnorePointer(child: SizedBox.shrink());
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final isRestored = _showRestored && !_isOffline;

    final bgColor = isRestored
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD84315);
    final iconData = isRestored ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final message = isRestored
        ? 'Back online. Connected.'
        : 'You are offline. Showing cached data.';

    final bannerWidget = IgnorePointer(
      ignoring: false,
      child: SizeTransition(
        sizeFactor: _expandAnimation,
        alignment: Alignment.topCenter,
        child: Material(
          elevation: 4,
          color: bgColor,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              16,
              topInset > 0 ? topInset + 4 : 8,
              16,
              8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.child == null) {
      return bannerWidget;
    }

    return Column(
      children: [
        bannerWidget,
        Expanded(child: widget.child!),
      ],
    );
  }
}

class ConnectivityStatusBannerWrapper extends ConnectivityStatusBanner {
  const ConnectivityStatusBannerWrapper({super.key, required Widget child})
      : super(child: child);
}
