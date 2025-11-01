// calendar.dart (Rewritten to use ApiService)

import 'event.dart'; // Now includes JSON methods
import 'goal.dart'; // Now includes JSON methods
import 'api_service.dart'; // New dependency for HTTP calls

/// A service class responsible for managing Event objects via the remote API.
class Calendar {
  // Use a singleton instance of the ApiService to perform network operations.
  final ApiService _api = ApiService();

  // The factory pattern is kept for consistent initialization,
  // but it no longer needs to open a Hive box.
  Calendar._();

  static Future<Calendar> create() async {
    // Initialization logic is now simple, as there's no local storage setup.
    return Calendar._();
  }

  //----------------------------------------------------------------------
  // CRUD Operations
  //----------------------------------------------------------------------

  /// Adds a new event to the remote API.
  Future<void> addEvent({required Event event, Goal? linkedGoal}) async {
    // Assign goal and let the Event.toJson() handle sending the linked_goal_id.
    if (linkedGoal != null) event.linkedGoal = linkedGoal;

    // The API service returns the created event (with its new ID).
    await _api.addEvent(event);
  }

  /// Removes an event from the remote API by its ID.
  Future<void> removeEvent(Event event) async {
    if (event.id == null)
      throw Exception('Cannot remove event: ID is missing.');
    await _api.deleteEvent(event.id!);
  }

  /// Updates an existing event on the remote API.
  Future<void> updateEvent(Event event) async {
    // The API service handles finding the event by ID and updating it.
    await _api.updateEvent(event);
  }

  //----------------------------------------------------------------------
  // Query Operations
  //----------------------------------------------------------------------

  /// Fetches all events from the remote API asynchronously.
  Future<List<Event>> fetchAllEvents() async {
    return _api.fetchEvents();
  }

  /// Filters events locally after fetching all of them.
  /// For large datasets, this filtering should be moved to the API call.
  Future<List<Event>> eventsOn(DateTime date) async {
    final allEvents = await _api.fetchEvents();

    return allEvents
        .where(
          (e) =>
              // Compare year, month, and day for an exact date match.
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
        )
        .toList();
  }

  /// Attempts to retrieve a single event by its name (local filtering).
  Future<Event?> getEventByName(String name) async {
    final allEvents = await _api.fetchEvents();
    try {
      return allEvents.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  // NOTE: Bulk operations like removeEventsOnDate and clearAll
  // need to be re-implemented either by the API or by repeated API calls.
  // For now, we'll keep the function signatures minimal as per the API's focus.
}
