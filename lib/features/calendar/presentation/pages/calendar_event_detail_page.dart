import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/calendar/data/user_calendar_event.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/widgets/calendar_ui.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

/// Figma calendar event detail — bottom sheet with "Add to Google Calendar".
class CalendarEventDetailPage extends StatelessWidget {
  const CalendarEventDetailPage({super.key, required this.event});

  final dynamic event;

  static Future<void> show(BuildContext context, {required dynamic event}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.sizeOf(sheetContext).height * 0.08,
          ),
          child: CalendarEventDetailPage(event: event),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _title(event);
    final description = _description(event);
    final date = _date(event);
    final imageUrl = _imageUrl(event);
    final dateLabel = date != null
        ? (date.hour != 0 || date.minute != 0
            ? '${DateFormat('EEEE, MMMM dd').format(date)} at ${DateFormat('HH:mm').format(date)}'
            : DateFormat('EEEE, MMMM dd').format(date))
        : '';

    return Material(
      color: CalendarUi.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CalendarUi.cardBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: CalendarUi.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: _HeroImage(url: imageUrl),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTypography.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: CalendarUi.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  RichTextDisplay(
                    description.isNotEmpty ? description : null,
                    style: AppTypography.inter(
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _EventDetailActions(event: event),
            ),
          ),
        ],
      ),
    );
  }

  static String _title(dynamic e) {
    if (e is FestivalModel) return e.title;
    if (e is PoojaView) return e.title;
    if (e is UserCalendarEvent) return e.name;
    if (e is MoonPhaseModel) {
      final t = e.type.toUpperCase();
      if (t.contains('FULL')) return 'Full moon';
      if (t.contains('NEW')) return 'New moon';
      return e.type.replaceAll('_', ' ');
    }
    return 'Event';
  }

  static String _description(dynamic e) {
    if (e is FestivalModel) return e.description;
    if (e is PoojaView) return e.description;
    if (e is UserCalendarEvent) return e.description;
    if (e is MoonPhaseModel) {
      return e.type.toUpperCase().contains('FULL')
          ? 'Purnima — full moon.'
          : 'Amavasya — new moon.';
    }
    return '';
  }

  static DateTime? _date(dynamic e) {
    if (e is FestivalModel) return _parse(e.date);
    if (e is PoojaView) return _parse(e.date);
    if (e is UserCalendarEvent) return e.date;
    if (e is MoonPhaseModel) return _parse(e.date);
    return null;
  }

  static DateTime? _parse(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        final p = s.split('-');
        if (p.length == 3) {
          return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      } catch (_) {}
    }
    return null;
  }

  static String? _imageUrl(dynamic e) {
    if (e is FestivalModel) return e.imageUrl;
    if (e is PoojaView) return e.heroImage;
    return null;
  }
}

class _EventDetailActions extends StatelessWidget {
  const _EventDetailActions({required this.event});

  final dynamic event;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalendarController>();

    return Obx(() {
      controller.addedToCalendarIds.length;
      controller.remindedEventIds.length;
      final eventId = controller.eventIdFor(event);
      final isAdded =
          eventId.isNotEmpty && controller.isAddedToCalendar(eventId);
      final isReminded = eventId.isNotEmpty && controller.isReminded(eventId);

      final canAct = eventId.isNotEmpty;

      final isUserEvent = event is UserCalendarEvent;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _GradientActionButton(
                  height: 48,
                  borderRadius: 20,
                  enabled: canAct,
                  onTap: canAct
                      ? () => controller.addToDeviceCalendar(event)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdded ? Icons.check_circle_outline : Icons.event,
                        color: Color(0xFFFCF7EF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isAdded
                              ? 'Added to Calendar'
                              : 'Add to Google Calendar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFCF7EF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: isReminded ? kCalendarActionGradient[0] : Color(0xFFFCF7EF),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: canAct ? () => controller.toggleReminder(event) : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: isReminded
                          ? null
                          : Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 0.66,
                            ),
                    ),
                    child: Icon(
                      isReminded
                          ? Icons.notifications_active
                          : Icons.notifications_outlined,
                      color: isReminded
                          ? Color(0xFFFCF7EF)
                          : kCalendarActionGradient[0],
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isUserEvent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        'Remove Event',
                        style: AppTypography.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CalendarUi.textPrimary,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to remove this event?',
                        style: AppTypography.inter(
                          fontSize: 14,
                          color: CalendarUi.textPrimary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'Cancel',
                            style: AppTypography.inter(
                              fontSize: 14,
                              color: CalendarUi.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Remove',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB10F1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).then((confirmed) {
                    if (confirmed == true) {
                      final userEvent = event as UserCalendarEvent;
                      controller.removeUserEvent(userEvent.id);
                      if (context.mounted) Navigator.of(context).pop();
                      ToastUtil.showInfo('${userEvent.name} removed');
                    }
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFB10F1A),
                ),
                label: Text(
                  'Remove Event',
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB10F1A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB10F1A), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Figma gradient CTA — #183EA4 → #E35600.
class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.height = 48,
    this.borderRadius = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: enabled
                  ? kCalendarActionGradient
                  : [
                      kCalendarActionGradient[0].withValues(alpha: 0.45),
                      kCalendarActionGradient[1].withValues(alpha: 0.45),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(
      'assets/images/default_img.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
    if (url == null || url!.isEmpty) return placeholder;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
