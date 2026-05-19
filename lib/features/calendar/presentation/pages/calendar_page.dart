import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/calendar/data/user_calendar_event.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_add_event_page.dart';
import 'package:satya_devotte_app/features/calendar/presentation/pages/calendar_event_detail_page.dart';
import 'package:satya_devotte_app/features/calendar/presentation/widgets/calendar_ui.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CalendarController>()) {
      Get.put(CalendarController());
    }
    final controller = Get.find<CalendarController>();

    return Scaffold(
      backgroundColor: CalendarUi.background,
      body: Column(
        children: [
          _CalendarOrangeHeader(controller: controller),
          Obx(() {
            final tab = controller.activeTab.value;
            return Material(
              color: CalendarUi.background,
              child: CalendarFilterTabs(
                labels: const ['Festivals', 'Lunar cycle', 'Events'],
                selectedIndex: tab.index,
                onSelected: (i) =>
                    controller.setActiveTab(CalendarFilterTab.values[i]),
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // Read observables here so GetX tracks them (not in child widgets).
              controller.focusedDate.value;
              controller.festivals.length;
              controller.poojas.length;
              controller.moonPhases.length;
              controller.userEvents.length;
              final tab = controller.activeTab.value;
              switch (tab) {
                case CalendarFilterTab.festivals:
                  return _FestivalsList(controller: controller);
                case CalendarFilterTab.lunarCycle:
                  return _LunarList(controller: controller);
                case CalendarFilterTab.events:
                  return _EventsList(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _CalendarOrangeHeader extends StatelessWidget {
  const _CalendarOrangeHeader({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CalendarAppHeader(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Calendar',
                        style: AppTypography.lora(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Get.to(() => const CalendarAddEventPage()),
                      icon: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Color(0XFFFFF4E0),
                        ),
                      ),
                      label: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF183EA4), Color(0xFFE35600)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'New Event',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0XFFFFF4E0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final focused = controller.focusedDate.value;
                  final selected = controller.selectedDate.value;
                  controller.festivals.length;
                  controller.poojas.length;
                  controller.moonPhases.length;
                  controller.userEvents.length;
                  return _MonthGrid(
                    controller: controller,
                    focused: focused,
                    selected: selected,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.controller,
    required this.focused,
    required this.selected,
  });

  final CalendarController controller;
  final DateTime focused;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
    final firstWeekday = DateTime(focused.year, focused.month, 1).weekday % 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                controller.focusedDate.value = DateTime(
                  focused.year,
                  focused.month - 1,
                );
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(focused),
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                controller.focusedDate.value = DateTime(
                  focused.year,
                  focused.month + 1,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ..._buildWeekRows(
          daysInMonth: daysInMonth,
          firstWeekday: firstWeekday,
          focused: focused,
          selected: selected,
        ),
      ],
    );
  }

  List<Widget> _buildWeekRows({
    required int daysInMonth,
    required int firstWeekday,
    required DateTime focused,
    required DateTime selected,
  }) {
    final dayWidgets = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const Expanded(child: SizedBox(height: 36)));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focused.year, focused.month, day);
      final events = controller.getEventsForDay(date);
      final isSelected =
          selected.year == date.year &&
          selected.month == date.month &&
          selected.day == date.day;

      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () => controller.onDateSelected(date, date),
            child: SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    '$day',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? CalendarUi.headerOrange
                          : Colors.white,
                    ),
                  ),
                  if (events.isNotEmpty && !isSelected)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final trailing = (firstWeekday + daysInMonth) % 7;
    if (trailing != 0) {
      for (var i = 0; i < 7 - trailing; i++) {
        dayWidgets.add(const Expanded(child: SizedBox(height: 36)));
      }
    }
    final rows = <Widget>[];
    for (var i = 0; i < dayWidgets.length; i += 7) {
      rows.add(Row(children: dayWidgets.sublist(i, i + 7)));
    }
    return rows;
  }
}

class _FestivalsList extends StatelessWidget {
  const _FestivalsList({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.festivalsInMonth;
    if (list.isEmpty) {
      return _empty('No festivals this month');
    }
    return ListView.separated(
      padding: CalendarUi.listScrollPadding(context),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _FestivalCard(
        festival: list[i],
        onTap: () => CalendarEventDetailPage.show(context, event: list[i]),
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.festival, required this.onTap});

  final FestivalModel festival;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = _parseDate(festival.date);
    final dateStr = date != null
        ? DateFormat('EEEE, MMMM do').format(date)
        : festival.date;

    return Material(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CalendarUi.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _FestivalImage(url: festival.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      festival.title,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CalendarUi.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: CalendarUi.subText,
                      ),
                    ),
                    if (festival.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        festival.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: CalendarUi.subText,
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

class _FestivalImage extends StatelessWidget {
  const _FestivalImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      color: const Color(0xFFEADCC3),
      child: const Icon(Icons.temple_hindu, color: Color(0xFF8C5A2A)),
    );
    if (url == null || url!.isEmpty) return ph;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => ph,
        errorWidget: (_, __, ___) => ph,
      );
    }
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ph,
    );
  }
}

class _LunarList extends StatelessWidget {
  const _LunarList({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.moonPhasesInMonth;
    if (list.isEmpty) {
      return _empty('No lunar events this month');
    }
    return ListView.separated(
      padding: CalendarUi.listScrollPadding(context),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = list[i];
        final isFull = m.type.toUpperCase().contains('FULL');
        return _LunarCard(
          title: isFull ? 'Full moon' : 'New moon',
          subtitle: isFull ? 'Purnima' : 'Amavasya',
          date: m.date,
          onTap: () => CalendarEventDetailPage.show(context, event: m),
        );
      },
    );
  }
}

class _LunarCard extends StatelessWidget {
  const _LunarCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseDate(date);
    return _CalendarEntryCard(
      title: title,
      date: parsed,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.eventsInMonth;
    if (list.isEmpty) {
      return _empty('No events this month');
    }
    return ListView.separated(
      padding: CalendarUi.listScrollPadding(context),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = list[i];
        if (e is UserCalendarEvent) {
          return _GenericEventCard(
            title: e.name,
            description: e.description,
            date: e.date,
            onTap: () => CalendarEventDetailPage.show(context, event: e),
          );
        }
        if (e is PoojaView) {
          return _GenericEventCard(
            title: e.title,
            description: e.description,
            date: _parseDate(e.date),
            onTap: () => CalendarEventDetailPage.show(context, event: e),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _GenericEventCard extends StatelessWidget {
  const _GenericEventCard({
    required this.title,
    required this.description,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String description;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CalendarEntryCard(
      title: title,
      date: date,
      subtitle: description,
      onTap: onTap,
    );
  }
}

/// Shared list row — lunar + events: gradient day/month badge, title, date, subtitle.
class _CalendarEntryCard extends StatelessWidget {
  const _CalendarEntryCard({
    required this.title,
    required this.date,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final DateTime? date;
  final String subtitle;
  final VoidCallback onTap;

  static const _dateGradient = LinearGradient(
    colors: [Color(0xFF183EA4), Color(0xFFE35600)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final day = date != null ? DateFormat('dd').format(date!) : '--';
    final month = date != null
        ? DateFormat('MMM').format(date!).toUpperCase()
        : '---';
    final dateLine = date != null
        ? DateFormat('EEEE, MMMM do').format(date!)
        : '';

    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CalendarUi.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          _dateGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        day,
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CalendarUi.textPrimary,
                        ),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          _dateGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        month,
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CalendarUi.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CalendarUi.text,
                      ),
                    ),
                    if (dateLine.isNotEmpty)
                      Text(
                        dateLine,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: CalendarUi.subText,
                        ),
                      ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: CalendarUi.subText,
                        ),
                      ),
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

Widget _empty(String message) {
  return Center(
    child: Text(
      message,
      style: AppTypography.inter(color: CalendarUi.textMuted),
    ),
  );
}

DateTime? _parseDate(String dateStr) {
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
  }
  return null;
}
