import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

/// Header / toolbar bell matching CMS notification mock (cream tile + orange dot).
class CmsActivityBellButton extends StatefulWidget {
  const CmsActivityBellButton({
    super.key,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.borderRadius = 10,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  State<CmsActivityBellButton> createState() => _CmsActivityBellButtonState();
}

class _CmsActivityBellButtonState extends State<CmsActivityBellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  int _lastPulseTick = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _maybePulse(int tick) {
    if (tick != _lastPulseTick) {
      _lastPulseTick = tick;
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CmsAdminNotificationsController>()) {
      return _CmsNotificationBellShell(
        onTap: widget.onTap,
        size: widget.size,
        iconSize: widget.iconSize,
        borderRadius: widget.borderRadius,
        count: 0,
        badgeScale: const AlwaysStoppedAnimation<double>(1),
      );
    }

    final ctrl = Get.find<CmsAdminNotificationsController>();
    return Obx(() {
      final count = ctrl.unreadCount.value;
      _maybePulse(ctrl.badgePulseTick.value);
      return _CmsNotificationBellShell(
        onTap: widget.onTap,
        size: widget.size,
        iconSize: widget.iconSize,
        borderRadius: widget.borderRadius,
        count: count,
        badgeScale: _pulseScale,
      );
    });
  }
}

/// Compact orange count pill for the sidebar **Activity** row.
class CmsActivitySidebarBadge extends StatelessWidget {
  const CmsActivitySidebarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CmsAdminNotificationsController>()) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final count = Get.find<CmsAdminNotificationsController>().unreadCount.value;
      if (count <= 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _CmsNotificationCountBadge(count: count, diameter: 16, fontSize: 9),
      );
    });
  }
}

class _CmsNotificationBellShell extends StatelessWidget {
  const _CmsNotificationBellShell({
    required this.onTap,
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    required this.count,
    required this.badgeScale,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double borderRadius;
  final int count;
  final Animation<double> badgeScale;

  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        hoverColor: CmsColors.orange.withValues(alpha: 0.08),
        splashColor: CmsColors.orange.withValues(alpha: 0.14),
        child: SizedBox(
          width: size + (showBadge ? 4 : 0),
          height: size + (showBadge ? 4 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: CmsColors.bg,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: CmsColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: iconSize,
                  color: const Color(0xFF5C5C5C),
                ),
              ),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: AnimatedBuilder(
                    animation: badgeScale,
                    builder: (context, child) => Transform.scale(
                      scale: badgeScale.value,
                      child: child,
                    ),
                    child: _CmsNotificationCountBadge(count: count),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CmsNotificationCountBadge extends StatelessWidget {
  const _CmsNotificationCountBadge({
    required this.count,
    this.diameter = 18,
    this.fontSize = 10,
  });

  final int count;
  final double diameter;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CmsColors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
