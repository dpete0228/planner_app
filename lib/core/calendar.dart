// The comments in this code were written by an AI assistant.

import 'package:hive/hive.dart'; // Import Hive for asynchronous, non-relational database operations.
import 'event.dart'; // Import the Event model, which includes the Hive TypeAdapter.
import 'goal.dart'; // Import the Goal model, potentially used for event linking.

/// A service class responsible for managing persistent storage operations for Event objects using Hive.
/// It utilizes the factory pattern to ensure the Hive box is open before the manager is used.
class Calendar {
  // Constant string used as the name for the Hive box dedicated to events.
  static const String boxName = 'eventsBox';
  // Late initialization for the actual Hive box instance.
  late Box<Event> eventBox;

  // Private constructor prevents direct instantiation, enforcing the factory pattern.
  Calendar._();

  /// Factory method to asynchronously create and initialize the Calendar manager.
  static Future<Calendar> create() async {
    final calendar = Calendar._();
    // Open the events box. If it's already open, Hive returns the existing instance.
    calendar.eventBox = await Hive.openBox<Event>(boxName);
    return calendar;
  }

  //--------------------------------------------------------------------------------------------------
  // CRUD Operations
  //--------------------------------------------------------------------------------------------------

  /// Add a new event, optionally linking a goal to the event object before saving.
  Future<void> addEvent({required Event event, Goal? linkedGoal}) async {
    // If a goal is provided, set the event's linkedGoal property.
    if (linkedGoal != null) event.linkedGoal = linkedGoal;
    // Use .add() for auto-incrementing integer keys (the event key will be set here).
    await eventBox.add(event);
  }

  /// Remove an event safely using the key provided by the HiveObject mixin.
  Future<void> removeEvent(Event event) async {
    // HiveObject provides the key property after it has been added to a box.
    final key = event.key;
    // Only attempt to delete if the event has a key (i.e., it exists in the box).
    if (key != null) await eventBox.delete(key);
  }

  /// Update an existing event by replacing its value in the box using its key.
  Future<void> updateEvent(Event event) async {
    final key = event.key;
    // Use .put() to save the modified event object back into the box at its existing key.
    if (key != null) await eventBox.put(key, event);
  }

  //--------------------------------------------------------------------------------------------------
  // Query Operations
  //--------------------------------------------------------------------------------------------------

  /// Getter that returns all Event objects stored in the Hive box as a list.
  List<Event> get allEvents => eventBox.values.toList();

  /// Filters and returns all events that occur on a specific day (ignoring time).
  List<Event> eventsOn(DateTime date) {
    return eventBox.values.where((e) =>
      // Compare year, month, and day for an exact date match.
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    ).toList();
  }

  /// Attempts to retrieve a single event by its name.
  Event? getEventByName(String name) {
    try {
      // Use firstWhere to find the first event whose name matches.
      return eventBox.values.firstWhere((e) => e.name == name);
    } catch (_) {
      // If firstWhere doesn't find a match, it throws a StateError, which is caught here.
      return null;
    }
  }

  //--------------------------------------------------------------------------------------------------
  // Bulk Operations
  //--------------------------------------------------------------------------------------------------

  /// Removes all events that occur on a specific date.
  Future<void> removeEventsOnDate(DateTime date) async {
    // Find all keys whose corresponding events match the specific date.
    final keysToDelete = eventBox.keys.where((k) {
      final e = eventBox.get(k);
      // Check for null and then compare date components.
      return e != null &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();

    // Iterate over the keys and delete each corresponding entry.
    for (var key in keysToDelete) await eventBox.delete(key);
  }

  /// Clear all entries from the event Hive box.
  Future<void> clearAll() async => await eventBox.clear();
}