import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/pujas/presentation/models/pooja_view_model.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class CalendarController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  final RxList<FestivalModel> festivals = <FestivalModel>[].obs;
  final RxList<PoojaView> poojas = <PoojaView>[].obs;
  final RxList<MoonPhaseModel> moonPhases = <MoonPhaseModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<DateTime> focusedDate = DateTime.now().obs;

  final RxSet<String> remindedEventIds = <String>{}.obs;
  final RxSet<String> addedToCalendarIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadReminders();
    _loadCalendarStatus();
    fetchData();

    // Re-fetch data whenever the focused month/year changes
    ever(focusedDate, (_) => fetchData());
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

  Future<void> toggleReminder(dynamic event) async {
    String id = '';
    String title = '';
    String type = '';
    DateTime? date;

    if (event is FestivalModel) {
      id = event.id;
      title = event.title;
      type = 'festival';
      date = _parseDate(event.date);
    } else if (event is PoojaView) {
      id = event.title; // Using title as ID if no ID
      title = event.title;
      type = 'pooja';
      date = _parseDate(event.date);
    }

    if (id.isEmpty || date == null) return;

    debugPrint(
      'CalendarController: Toggling reminder for $title, id: $id, date: $date',
    );

    if (remindedEventIds.contains(id)) {
      remindedEventIds.remove(id);
      await _notificationService.unsubscribeFromEventNotification(id);
      Get.snackbar(
        'Reminder Removed',
        'You will no longer receive notifications for $title',
      );
    } else {
      remindedEventIds.add(id);
      try {
        debugPrint(
          'CalendarController: Requesting notification subscription for $title',
        );
        await _notificationService.subscribeToEventNotification(
          id,
          title,
          type,
          date,
        );
      } catch (e) {
        debugPrint('CalendarController: Failed to subscribe: $e');
        remindedEventIds.remove(id);
        Get.snackbar('Error', 'Failed to set reminder. Please try again.');
      }
    }
    await _saveReminders();
  }

  Future<void> addToDeviceCalendar(dynamic event) async {
    String id = '';
    String title = '';
    String desc = '';
    DateTime? date;

    if (event is FestivalModel) {
      id = event.id;
      title = event.title;
      desc = event.description;
      date = _parseDate(event.date);
    } else if (event is PoojaView) {
      id = event.title;
      title = event.title;
      desc = event.description;
      date = _parseDate(event.date);
    }

    if (date == null || id.isEmpty) return;

    if (addedToCalendarIds.contains(id)) {
      addedToCalendarIds.remove(id);
      await _saveCalendarStatus();
      Get.snackbar(
        'Calendar Status',
        'Event marked as removed from your plans',
      );
      return;
    }

    final ev = Event(
      title: title,
      description: desc,
      location: 'Sathya App',
      startDate: date,
      endDate: date.add(const Duration(hours: 1)),
      allDay: true,
    );

    final success = await Add2Calendar.addEvent2Cal(ev);
    if (success) {
      addedToCalendarIds.add(id);
      await _saveCalendarStatus();
    }
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
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          // Assuming DD-MM-YYYY
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

    return events;
  }
}
