import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/calendar/data/user_calendar_event.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/core/services/calendar_sync_service.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarFilterTab { festivals, lunarCycle, events }

class MoonPhaseModel {
  final String date;
  final String type; // FULL_MOON | NEW_MOON

  MoonPhaseModel({required this.date, required this.type});

  factory MoonPhaseModel.fromJson(Map<String, dynamic> json) {
    return MoonPhaseModel(
      date: (json['date'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
    );
  }
}

class _CalendarEventFields {
  const _CalendarEventFields({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.reminderType,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String reminderType;
}

class CalendarController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  final RxList<FestivalModel> festivals = <FestivalModel>[].obs;
  final RxList<PoojaView> poojas = <PoojaView>[].obs;
  final RxList<MoonPhaseModel> moonPhases = <MoonPhaseModel>[].obs;
  final RxList<UserCalendarEvent> userEvents = <UserCalendarEvent>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<DateTime> focusedDate = DateTime.now().obs;
  final Rx<CalendarFilterTab> activeTab = CalendarFilterTab.festivals.obs;

  static const _userEventsKey = 'user_calendar_events';

  final RxSet<String> remindedEventIds = <String>{}.obs;
  final RxSet<String> addedToCalendarIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadReminders();
    _loadCalendarStatus();
    _loadUserEvents();
    fetchData();

    // Re-fetch data whenever the focused month/year changes
    ever(focusedDate, (_) => fetchData());
  }

  void setActiveTab(CalendarFilterTab tab) => activeTab.value = tab;

  Future<void> _loadUserEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userEventsKey);
    userEvents.assignAll(UserCalendarEvent.listFromPrefs(raw));
  }

  Future<void> addUserEvent({
    required String name,
    required String description,
    required DateTime date,
  }) async {
    final event = UserCalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      date: DateTime(date.year, date.month, date.day),
    );
    userEvents.add(event);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEventsKey, UserCalendarEvent.encodeList(userEvents));
  }

  bool _isInFocusedMonth(DateTime date) {
    return date.year == focusedDate.value.year &&
        date.month == focusedDate.value.month;
  }

  List<FestivalModel> get festivalsInMonth {
    return festivals.where((f) {
      final d = _parseDate(f.date);
      return d != null && _isInFocusedMonth(d);
    }).toList()
      ..sort((a, b) {
        final da = _parseDate(a.date) ?? DateTime(2100);
        final db = _parseDate(b.date) ?? DateTime(2100);
        return da.compareTo(db);
      });
  }

  List<MoonPhaseModel> get moonPhasesInMonth {
    return moonPhases.where((m) {
      final d = _parseDate(m.date);
      return d != null && _isInFocusedMonth(d);
    }).toList()
      ..sort((a, b) {
        final da = _parseDate(a.date) ?? DateTime(2100);
        final db = _parseDate(b.date) ?? DateTime(2100);
        return da.compareTo(db);
      });
  }

  List<dynamic> get eventsInMonth {
    final list = <dynamic>[];
    list.addAll(
      poojas.where((p) {
        final d = _parseDate(p.date);
        return d != null && _isInFocusedMonth(d);
      }),
    );
    list.addAll(
      userEvents.where((e) => _isInFocusedMonth(e.date)),
    );
    list.sort((a, b) {
      final da = a is PoojaView
          ? _parseDate(a.date)
          : a is UserCalendarEvent
              ? a.date
              : null;
      final db = b is PoojaView
          ? _parseDate(b.date)
          : b is UserCalendarEvent
              ? b.date
              : null;
      return (da ?? DateTime(2100)).compareTo(db ?? DateTime(2100));
    });
    return list;
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('reminded_events') ?? [];
    remindedEventIds.assignAll(list);
  }

  Future<void> _loadCalendarStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('added_to_calendar') ?? [];
    addedToCalendarIds.assignAll(list);
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminded_events', remindedEventIds.toList());
  }

  Future<void> _saveCalendarStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('added_to_calendar', addedToCalendarIds.toList());
  }

  bool isReminded(String id) => remindedEventIds.contains(id);
  bool isAddedToCalendar(String id) => addedToCalendarIds.contains(id);

  String eventIdFor(dynamic event) => _fieldsFor(event)?.id ?? '';

  Future<void> toggleReminder(dynamic event) async {
    final fields = _fieldsFor(event);
    if (fields == null) {
      Get.snackbar(
        'Reminder unavailable',
        'This event does not have a valid date.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final id = fields.id;
    debugPrint(
      'CalendarController: Toggling reminder for ${fields.title}, id: $id',
    );

    if (remindedEventIds.contains(id)) {
      remindedEventIds.remove(id);
      remindedEventIds.refresh();
      await _notificationService.unsubscribeFromEventNotification(id);
      Get.snackbar(
        'Reminder removed',
        'You will no longer receive notifications for ${fields.title}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      remindedEventIds.add(id);
      remindedEventIds.refresh();
      try {
        await _notificationService.subscribeToEventNotification(
          id,
          fields.title,
          fields.reminderType,
          fields.date,
        );
      } catch (e) {
        debugPrint('CalendarController: Failed to subscribe: $e');
        remindedEventIds.remove(id);
        remindedEventIds.refresh();
        Get.snackbar(
          'Error',
          'Failed to set reminder. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
    await _saveReminders();
  }

  Future<void> addToDeviceCalendar(dynamic event) async {
    final fields = _fieldsFor(event);
    if (fields == null) {
      Get.snackbar(
        'Unable to add',
        'This event does not have a valid date.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (addedToCalendarIds.contains(fields.id)) {
      addedToCalendarIds.remove(fields.id);
      addedToCalendarIds.refresh();
      await _saveCalendarStatus();
      Get.snackbar(
        'Calendar',
        'Removed from your saved calendar list',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final start = fields.date;
      final end = DateTime(start.year, start.month, start.day)
          .add(const Duration(days: 1));
      final success = await addEventToCalendar(
        title: fields.title,
        description: fields.description,
        startDate: start,
        endDate: end,
      );
      if (success) {
        addedToCalendarIds.add(fields.id);
        addedToCalendarIds.refresh();
        await _saveCalendarStatus();
        Get.snackbar(
          'Calendar',
          'Confirm save in your calendar app',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Calendar',
          'Could not open your calendar app. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('CalendarController: addToDeviceCalendar failed: $e');
      Get.snackbar(
        'Calendar',
        'Could not add this event. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  _CalendarEventFields? _fieldsFor(dynamic event) {
    if (event is FestivalModel) {
      final date = _parseDate(event.date);
      if (date == null || event.id.isEmpty) return null;
      return _CalendarEventFields(
        id: event.id,
        title: event.title,
        description: event.description,
        date: DateTime(date.year, date.month, date.day),
        reminderType: 'festival',
      );
    }
    if (event is PoojaView) {
      final date = _parseDate(event.date);
      if (date == null || event.title.isEmpty) return null;
      return _CalendarEventFields(
        id: 'pooja_${event.title}_${event.date}',
        title: event.title,
        description: event.description,
        date: DateTime(date.year, date.month, date.day),
        reminderType: 'pooja',
      );
    }
    if (event is UserCalendarEvent) {
      return _CalendarEventFields(
        id: event.id,
        title: event.name,
        description: event.description,
        date: DateTime(event.date.year, event.date.month, event.date.day),
        reminderType: 'user_event',
      );
    }
    if (event is MoonPhaseModel) {
      final date = _parseDate(event.date);
      if (date == null) return null;
      final isFull = event.type.toUpperCase().contains('FULL');
      return _CalendarEventFields(
        id: 'moon_${event.type}_${event.date}',
        title: isFull ? 'Full moon' : 'New moon',
        description: isFull
            ? 'Purnima — full moon.'
            : 'Amavasya — new moon.',
        date: DateTime(date.year, date.month, date.day),
        reminderType: 'moon',
      );
    }
    return null;
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      // Fetch month-specific data for the Calendar Grid
      final queryParams = {
        'month': focusedDate.value.month,
        'year': focusedDate.value.year,
      };

      final response = await _apiClient.dio.get(
        ApiEndpoints.calendar,
        queryParameters: queryParams,
        options: Options(headers: {'timezone': DateTime.now().timeZoneName}),
      );

      final payload = response.data;
      if (payload is Map && payload['success'] == true) {
        final data = payload['data'];
        if (data is Map) {
          final rawFestivals = _extractList(data['festivals']);
          final rawPoojas = _extractList(data['poojas']);
          final rawMoonPhases = _extractList(data['moonPhases']);

          // Use assignAll to ensure we ONLY show what the calendar API returns
          festivals.assignAll(
            rawFestivals.map((e) => FestivalModel.fromJson(e)).toList(),
          );
          poojas.assignAll(rawPoojas.map((e) => PoojaView(e)).toList());
          moonPhases.assignAll(
            rawMoonPhases.map((e) => MoonPhaseModel.fromJson(e)).toList(),
          );

          debugPrint(
            'CalendarController: Fetched ${festivals.length} festivals, ${poojas.length} poojas, and ${moonPhases.length} moon phases for ${focusedDate.value.month}/${focusedDate.value.year}',
          );
        }
      }
    } catch (e) {
      debugPrint('Global error fetching calendar data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Removing _fetchFallbacks as it is no longer used

  List<dynamic> _extractList(dynamic body) {
    debugPrint('CalendarController: Extracting list from body: $body');
    if (body == null) return const [];
    if (body is List) return body;
    if (body is Map) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map) {
        for (final k in ['festivals', 'poojas', 'items', 'results', 'data']) {
          final v = d[k];
          if (v is List) {
            debugPrint('CalendarController: Found list in data[\'$k\']');
            return v;
          }
        }
      }
      for (final k in ['festivals', 'poojas', 'items', 'results', 'data']) {
        final v = body[k];
        if (v is List) {
          debugPrint('CalendarController: Found list in body[\'$k\']');
          return v;
        }
      }
    }
    debugPrint('CalendarController: No list found in body');
    return const [];
  }

  List<dynamic> get upcomingEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final events = <dynamic>[];

    events.addAll(
      festivals.where((f) {
        final fDate = _parseDate(f.date);
        return fDate != null && !fDate.isBefore(today);
      }),
    );

    events.addAll(
      poojas.where((p) {
        final pDate = _parseDate(p.date);
        return pDate != null && !pDate.isBefore(today);
      }),
    );

    events.addAll(
      moonPhases.where((m) {
        final mDate = _parseDate(m.date);
        return mDate != null && !mDate.isBefore(today);
      }),
    );

    events.sort((a, b) {
      final dateA =
          _parseDate(
            a is FestivalModel
                ? a.date
                : a is PoojaView
                ? a.date
                : (a as MoonPhaseModel).date,
          ) ??
          DateTime(2100);
      final dateB =
          _parseDate(
            b is FestivalModel
                ? b.date
                : b is PoojaView
                ? b.date
                : (b as MoonPhaseModel).date,
          ) ??
          DateTime(2100);
      return dateA.compareTo(dateB);
    });

    return events;
  }

  DateTime? _parseDate(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;
    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      try {
        final parts = trimmed.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
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

  void onDateSelected(DateTime selected, DateTime focused) {
    selectedDate.value = selected;
    focusedDate.value = focused;
  }

  List<dynamic> getEventsForDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final events = <dynamic>[];

    events.addAll(
      festivals.where((f) {
        final fDate = _parseDate(f.date);
        return fDate != null &&
            fDate.year == dayOnly.year &&
            fDate.month == dayOnly.month &&
            fDate.day == dayOnly.day;
      }),
    );

    events.addAll(
      poojas.where((p) {
        final pDate = _parseDate(p.date);
        return pDate != null &&
            pDate.year == dayOnly.year &&
            pDate.month == dayOnly.month &&
            pDate.day == dayOnly.day;
      }),
    );

    events.addAll(
      moonPhases.where((m) {
        final mDate = _parseDate(m.date);
        return mDate != null &&
            mDate.year == dayOnly.year &&
            mDate.month == dayOnly.month &&
            mDate.day == dayOnly.day;
      }),
    );

    events.addAll(
      userEvents.where((e) =>
          e.date.year == dayOnly.year &&
          e.date.month == dayOnly.month &&
          e.date.day == dayOnly.day),
    );

    events.sort((a, b) {
      final da = _eventSortDate(a);
      final db = _eventSortDate(b);
      return (da ?? DateTime(2100)).compareTo(db ?? DateTime(2100));
    });

    return events;
  }

  DateTime? _eventSortDate(dynamic event) {
    if (event is FestivalModel) return _parseDate(event.date);
    if (event is PoojaView) return _parseDate(event.date);
    if (event is UserCalendarEvent) return event.date;
    if (event is MoonPhaseModel) return _parseDate(event.date);
    return null;
  }
}
