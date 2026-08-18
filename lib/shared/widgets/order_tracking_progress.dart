import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';

enum _TrackingStepState { complete, active, pending }

class _TrackingStepData {
  const _TrackingStepData({
    required this.title,
    required this.icon,
    required this.state,
    this.timestamp,
  });

  final String title;
  final IconData icon;
  final _TrackingStepState state;
  final DateTime? timestamp;
}

/// Vertical delivery tracking timeline (user app + CMS).
class OrderTrackingProgress extends StatelessWidget {
  const OrderTrackingProgress({
    super.key,
    required this.order,
    this.showOrderHeader = false,
    this.activeColor = AppColors.gradientEnd,
    this.activeColorLight = AppColors.gradientStart,
    this.pendingColor = const Color(0xFFD9D9D9),
    this.titleColor = AppColors.textColor,
    this.subtitleColor = AppColors.secondary,
    this.timeColor = AppColors.secondary,
  });

  final AdminOrder order;
  final bool showOrderHeader;
  final Color activeColor;
  final Color activeColorLight;
  final Color pendingColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color timeColor;

  static const _iconColumnWidth = 40.0;
  static const _iconSize = 36.0;
  static const _rowMinHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    if (!order.isDelivery) return const SizedBox.shrink();
    // Timeline only after admin books TCG (waybill) or adds manual tracking.
    if (!order.hasCourierTracking) return const SizedBox.shrink();

    final steps = _buildSteps(order);
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOrderHeader && order.orderNumber.isNotEmpty) ...[
          Text(
            'Order ID #${order.orderNumber}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            connectorSolid: steps[i].state == _TrackingStepState.complete,
            connectorDashed: steps[i].state == _TrackingStepState.active,
            activeColor: activeColor,
            activeColorLight: activeColorLight,
            pendingColor: pendingColor,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
            timeColor: timeColor,
          ),
      ],
    );
  }

  static List<_TrackingStepData> _buildSteps(AdminOrder order) {
    const titles = [
      'Order Placed',
      'Collected',
      'In Transit',
      'Out for Delivery',
      'Delivered',
    ];
    const icons = [
      Icons.check_rounded,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.delivery_dining_outlined,
      Icons.hourglass_bottom_rounded,
    ];

    final activeIndex = _resolveActiveIndex(order);
    if (activeIndex < 0) return const <_TrackingStepData>[];
    final resolvedActive = activeIndex;
    final timestamps = _resolveTimestamps(order, titles.length);

    return List<_TrackingStepData>.generate(titles.length, (i) {
      final state = i < resolvedActive
          ? _TrackingStepState.complete
          : i == resolvedActive
              ? _TrackingStepState.active
              : _TrackingStepState.pending;

      final icon = i == 4 && state != _TrackingStepState.pending
          ? Icons.check_rounded
          : icons[i];

      return _TrackingStepData(
        title: titles[i],
        icon: icon,
        state: state,
        timestamp: timestamps[i],
      );
    });
  }

  static int _resolveActiveIndex(AdminOrder order) {
    final deliveryStatus = _normalizeTcgStatus(order.delivery?.status);
    final fromDelivery = switch (deliveryStatus) {
      'delivered' => 4,
      'out-for-delivery' || 'out_for_delivery' => 3,
      'in-transit' || 'in_transit' => 2,
      'collected' => 1,
      'submitted' || 'created' || 'booked' => 0,
      _ => -1,
    };

    final fromOrder = switch (order.orderStatus) {
      OrderStatus.fulfilled || OrderStatus.delivered => 4,
      OrderStatus.outForDelivery => 3,
      OrderStatus.shipped => 2,
      _ => -1,
    };

    final baseline =
        order.delivery?.hasWaybill == true || order.hasCourierTracking ? 0 : -1;

    return [fromDelivery, fromOrder, baseline].reduce((a, b) => a > b ? a : b);
  }

  static String _normalizeTcgStatus(String? raw) {
    return (raw ?? '').toLowerCase().trim().replaceAll('_', '-');
  }

  static int _statusToStepIndex(String raw) {
    final s = raw.toLowerCase().trim().replaceAll('_', '-');
    if (s.contains('deliver')) return 4;
    if (s.contains('out-for') || s.contains('out for')) return 3;
    if (s.contains('transit')) return 2;
    if (s.contains('collect')) return 1;
    if (s.contains('submit') ||
        s.contains('creat') ||
        s.contains('book') ||
        s == 'placed') {
      return 0;
    }
    return -1;
  }

  static List<DateTime?> _resolveTimestamps(AdminOrder order, int stepCount) {
    final times = List<DateTime?>.filled(stepCount, null);
    final events = [...?order.delivery?.trackingEvents]
      ..sort((a, b) {
        final ad = a.date;
        final bd = b.date;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });

    for (final event in events) {
      final idx = _statusToStepIndex(event.status);
      final resolved =
          idx >= 0 ? idx : _statusToStepIndex(event.message);
      if (resolved < 0 || resolved >= stepCount || event.date == null) continue;
      times[resolved] ??= event.date;
    }

    void setIfEmpty(int idx, DateTime? value) {
      if (idx < 0 || idx >= stepCount || value == null) return;
      times[idx] ??= value;
    }

    setIfEmpty(0, order.delivery?.bookedAt ?? order.dispatchedAt);
    setIfEmpty(1, order.dispatchedAt);
    setIfEmpty(2, order.dispatchedAt ?? order.historyAt('SHIPPED'));
    setIfEmpty(3, order.historyAt('OUT_FOR_DELIVERY'));
    setIfEmpty(
      4,
      order.historyAt('DELIVERED') ??
          order.historyAt('FULFILLED') ??
          order.delivery?.pod?.verifiedAt,
    );

    for (var i = 1; i < stepCount; i++) {
      final prev = times[i - 1];
      final cur = times[i];
      if (prev != null && cur != null && cur.isBefore(prev)) {
        times[i] = null;
      }
    }

    return times;
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.connectorSolid,
    required this.connectorDashed,
    required this.activeColor,
    required this.activeColorLight,
    required this.pendingColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.timeColor,
  });

  final _TrackingStepData step;
  final bool isLast;
  final bool connectorSolid;
  final bool connectorDashed;
  final Color activeColor;
  final Color activeColorLight;
  final Color pendingColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color timeColor;

  bool get _isDone => step.state != _TrackingStepState.pending;

  @override
  Widget build(BuildContext context) {
    final ts = step.timestamp;
    final dateLabel = ts != null && _isDone
        ? DateFormat('d MMM, yyyy').format(ts.toLocal())
        : null;
    final timeLabel = ts != null && _isDone
        ? DateFormat('hh:mm a').format(ts.toLocal())
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: OrderTrackingProgress._iconColumnWidth,
            child: Column(
              children: [
                _TimelineIcon(
                  icon: step.icon,
                  state: step.state,
                  activeColor: activeColor,
                  activeColorLight: activeColorLight,
                  pendingColor: pendingColor,
                ),
                if (!isLast)
                  Expanded(
                    child: _VerticalConnector(
                      solid: connectorSolid,
                      dashed: connectorDashed,
                      activeColor: activeColor,
                      pendingColor: pendingColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: OrderTrackingProgress._rowMinHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _isDone ? titleColor : const Color(0xFFB0B0B0),
                      height: 1.2,
                    ),
                  ),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: subtitleColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (timeLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  color: timeColor,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({
    required this.icon,
    required this.state,
    required this.activeColor,
    required this.activeColorLight,
    required this.pendingColor,
  });

  final IconData icon;
  final _TrackingStepState state;
  final Color activeColor;
  final Color activeColorLight;
  final Color pendingColor;

  @override
  Widget build(BuildContext context) {
    final isPending = state == _TrackingStepState.pending;
    return Container(
      width: OrderTrackingProgress._iconSize,
      height: OrderTrackingProgress._iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPending ? pendingColor : null,
        gradient: isPending
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [activeColorLight, activeColor],
              ),
        boxShadow: isPending
            ? null
            : [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 20,
        color: isPending ? const Color(0xFF9E9E9E) : Colors.white,
      ),
    );
  }
}

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector({
    required this.solid,
    required this.dashed,
    required this.activeColor,
    required this.pendingColor,
  });

  final bool solid;
  final bool dashed;
  final Color activeColor;
  final Color pendingColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VerticalConnectorPainter(
        solid: solid,
        dashed: dashed,
        activeColor: activeColor,
        pendingColor: pendingColor,
      ),
      child: const SizedBox(width: 2, height: double.infinity),
    );
  }
}

class _VerticalConnectorPainter extends CustomPainter {
  _VerticalConnectorPainter({
    required this.solid,
    required this.dashed,
    required this.activeColor,
    required this.pendingColor,
  });

  final bool solid;
  final bool dashed;
  final Color activeColor;
  final Color pendingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    if (solid) {
      paint.color = activeColor;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }

    if (dashed) {
      paint.color = pendingColor;
      const dash = 5.0;
      const gap = 4.0;
      var y = 0.0;
      while (y < size.height) {
        final end = (y + dash).clamp(0.0, size.height);
        canvas.drawLine(Offset(x, y), Offset(x, end), paint);
        y += dash + gap;
      }
      return;
    }

    paint.color = pendingColor;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _VerticalConnectorPainter oldDelegate) =>
      oldDelegate.solid != solid ||
      oldDelegate.dashed != dashed ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.pendingColor != pendingColor;
}
