import 'package:hive/hive.dart';
import 'event.dart';
import 'goal.dart';

class Calendar {
  static const String boxName = 'eventsBox';
  late Box<Event> eventBox;

  Calendar._();

  static Future<Calendar> create() async {
    final calendar = Calendar._();
    calendar.eventBox = await Hive.openBox<Event>(boxName);
    return calendar;
  }

  /// Add a new event, optionally linking a goal
  Future<void> addEvent({required Event event, Goal? linkedGoal}) async {
    if (linkedGoal != null) event.linkedGoal = linkedGoal;
    await eventBox.add(event);
  }

  /// Remove an event safely
  Future<void> removeEvent(Event event) async {
    final key = event.key; // HiveObject provides the key
    if (key != null) await eventBox.delete(key);
  }

  /// Update an existing event
  Future<void> updateEvent(Event event) async {
    final key = event.key;
    if (key != null) await eventBox.put(key, event);
  }

  /// Get all events
  List<Event> get allEvents => eventBox.values.toList();

  /// Events on a specific day
  List<Event> eventsOn(DateTime date) {
    return eventBox.values.where((e) =>
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    ).toList();
  }

  /// Get a single event by name
  Event? getEventByName(String name) {
    try {
      return eventBox.values.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Remove all events on a specific date
  Future<void> removeEventsOnDate(DateTime date) async {
    final keysToDelete = eventBox.keys.where((k) {
      final e = eventBox.get(k);
      return e != null &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();

    for (var key in keysToDelete) await eventBox.delete(key);
  }

  /// Clear all events
  Future<void> clearAll() async => await eventBox.clear();
}
