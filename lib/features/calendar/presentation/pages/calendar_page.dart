import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/rituals/presentation/models/pooja_view_model.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CalendarController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBDC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CalendarView(),
                    const SizedBox(height: 24),
                    _UpcomingFestivals(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Festival\nCalendar',
            style: AppTypography.lora(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1E08),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B1E08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFEAD9BC)),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalendarController>();

    return Obx(() {
      final focusedDate = controller.focusedDate.value;
      final daysInMonth = _getDaysInMonth(focusedDate.year, focusedDate.month);
      final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
      final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMonthSelector(focusedDate, controller),
            const SizedBox(height: 16),
            _buildWeekdayHeaders(),
            const SizedBox(height: 8),
            _buildDaysGrid(
              daysInMonth,
              firstWeekday,
              focusedDate,
              controller,
              context,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMonthSelector(DateTime date, CalendarController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            controller.focusedDate.value = DateTime(date.year, date.month - 1);
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(date),
          style: AppTypography.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1E08),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            controller.focusedDate.value = DateTime(date.year, date.month + 1);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDaysGrid(
    int daysInMonth,
    int firstWeekday,
    DateTime focusedDate,
    CalendarController controller,
    BuildContext context,
  ) {
    final List<Widget> dayWidgets = [];

    // Empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const Expanded(child: SizedBox()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedDate.year, focusedDate.month, day);
      final events = controller.getEventsForDay(date);
      final isSelected =
          controller.selectedDate.value.year == date.year &&
          controller.selectedDate.value.month == date.month &&
          controller.selectedDate.value.day == date.day;
      final isToday =
          DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;

      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              controller.onDateSelected(date, date);
              if (events.isNotEmpty) {
                _showEventBottomSheet(context, events);
              }
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B1E08)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFF3B1E08), width: 1)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? const Color(0xFF3B1E08) : Colors.black),
                    ),
                  ),
                  if (events.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.map((e) {
                          Color dotColor = const Color(0xFFE0884A);
                          if (e is MoonPhaseModel) {
                            dotColor = Colors.grey;
                          }
                          return Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : dotColor,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      if ((firstWeekday + day) % 7 == 0 || day == daysInMonth) {
        // End of week, add remaining empty cells if it's the last day
        if (day == daysInMonth) {
          int remaining = 7 - ((firstWeekday + day) % 7);
          if (remaining < 7) {
            for (int i = 0; i < remaining; i++) {
              dayWidgets.add(const Expanded(child: SizedBox()));
            }
          }
        }
      }
    }

    // Chunk into rows of 7
    final List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(Row(children: dayWidgets.sublist(i, i + 7)));
    }

    return Column(children: rows);
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _showEventBottomSheet(BuildContext context, List<dynamic> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventBottomSheet(events: events),
    );
  }
}

class _EventBottomSheet extends StatelessWidget {
  final List<dynamic> events;

  const _EventBottomSheet({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Events on this day',
            style: AppTypography.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1E08),
            ),
          ),
          const SizedBox(height: 16),
          ...events.map((e) {
            if (e is FestivalModel) {
              return _buildEventItem(
                title: e.title,
                description: e.description,
                icon: Icons.celebration,
                color: const Color(0xFFE0884A),
                bgColor: const Color(0xFFFFF1DD),
              );
            } else if (e is PoojaView) {
              return _buildEventItem(
                title: e.title,
                description: e.description,
                icon: Icons.temple_hindu,
                color: const Color(0xFF3B1E08),
                bgColor: const Color(0xFFF2EBDC),
              );
            } else if (e is MoonPhaseModel) {
              return _buildEventItem(
                title: e.type.replaceAll('_', ' '),
                description: e.type == 'FULL_MOON' ? 'Purnima' : 'Amavasya',
                icon: e.type == 'FULL_MOON'
                    ? Icons.brightness_high
                    : Icons.brightness_2,
                color: Colors.blueGrey,
                bgColor: Colors.blueGrey.withOpacity(0.1),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingFestivals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CalendarController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Upcoming Festivals & Rituals',
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B1E08),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = controller.upcomingEvents;
          if (events.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming events'),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _EventCard(event: events[index]);
            },
          );
        }),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final dynamic event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    String title = '';
    String dateStr = '';

    if (event is FestivalModel) {
      title = (event as FestivalModel).title;
      dateStr = (event as FestivalModel).date;
    } else if (event is PoojaView) {
      title = (event as PoojaView).title;
      dateStr = (event as PoojaView).date;
    } else if (event is MoonPhaseModel) {
      final m = event as MoonPhaseModel;
      title = m.type.replaceAll('_', ' ');
      dateStr = m.date;
    }

    final date = _parseDate(dateStr);
    final daysToGo = _calculateDaysToGo(dateStr);

    final day = date != null ? DateFormat('dd').format(date) : '--';
    final month = date != null
        ? DateFormat('MMM').format(date).toUpperCase()
        : '---';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EBDC),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                Text(
                  month,
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? '${DateFormat('EEEE').format(date)}, ${DateFormat('MMMM dd').format(date)}'
                      : 'Unknown Date',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysToGo Days To Go',
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE0884A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDaysToGo(String dateStr) {
    final date = _parseDate(dateStr);
    if (date == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
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
}
