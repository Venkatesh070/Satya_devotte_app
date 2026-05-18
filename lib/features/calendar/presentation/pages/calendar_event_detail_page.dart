import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/calendar/data/user_calendar_event.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/widgets/calendar_ui.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';

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
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.sizeOf(sheetContext).height * 0.08,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: CalendarEventDetailPage(event: event),
          ),
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
    final dateLabel =
        date != null ? DateFormat('EEEE, MMMM do').format(date) : '';

    return Material(
      color: CalendarUi.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CalendarUi.textPrimary,
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CalendarUi.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'No additional details available.',
                    style: AppTypography.inter(
                      fontSize: 14,
                      height: 1.55,
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
      final isReminded =
          eventId.isNotEmpty && controller.isReminded(eventId);

      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: eventId.isEmpty
                    ? null
                    : () => controller.addToDeviceCalendar(event),
                icon: Icon(
                  isAdded ? Icons.check_circle_outline : Icons.event,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  isAdded ? 'Added to Calendar' : 'Add to Google Calendar',
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CalendarUi.tabSelected,
                  disabledBackgroundColor:
                      CalendarUi.tabSelected.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: isReminded ? CalendarUi.tabSelected : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: eventId.isEmpty
                  ? null
                  : () => controller.toggleReminder(event),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: isReminded
                      ? null
                      : Border.all(color: CalendarUi.cardBorder),
                ),
                child: Icon(
                  isReminded
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: isReminded ? Colors.white : CalendarUi.tabSelected,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFEADCC3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.temple_hindu,
        size: 64,
        color: Color(0xFF8C5A2A),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
