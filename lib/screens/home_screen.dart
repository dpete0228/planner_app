// calendar_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
// Core data and services.
import '../core/api_service.dart';
import '../core/event.dart';
import '../core/goal.dart';
// Import screen widgets for navigation.
import 'edit_event_screen.dart';
import 'goal_screen.dart';
import 'goal_tracker_screen.dart';
import 'package:intl/intl.dart'; // For date and time formatting utility.

/// The main screen of the application. It manages the primary navigation
/// and displays the calendar, goals, or tracker view based on the selected tab.
class HomeScreen extends StatefulWidget {
  // Use a const constructor for better performance.
  const HomeScreen({super.key});

  @override
  // Create the mutable state for this widget.
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The state class for HomeScreen, holding all mutable data and logic.
class _HomeScreenState extends State<HomeScreen> {
  // Service for all remote data operations.
  final ApiService _apiService = ApiService();
  // Local lists to hold data fetched from the API.
  List<Event> _allEvents = [];
  List<Goal> _allGoals = [];

  // Flag to indicate if the essential data is currently loading from the API.
  bool loading = true;

  // CRITICAL FIX: Explicitly specify the generic type <Event> for EventController
  // to resolve the type mismatch errors when using DayView and other screens.
  late EventController<Event> eventController;

  // State variable to control the vertical density/slot size of the DayView timeline.
  MinuteSlotSize currentSlotSize = MinuteSlotSize.minutes60;
  // Index for the currently selected tab in the BottomNavigationBar (0: Calendar, 1: Goals, 2: Tracker).
  int _currentIndex = 0;
  // The date currently focused on and displayed in the DayView.
  DateTime _currentDisplayedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize the event controller with the correct generic type.
    eventController = EventController<Event>();
    // Start the process of loading the data from the remote API.
    _loadCalendar();
  }

  // --- Data Loading and Synchronization ---

  /// Asynchronously fetches all events and goals from the API.
  Future<void> _loadCalendar() async {
    try {
      // 1. Fetch Goals and Events concurrently from the API
      final fetchedGoals = _apiService.fetchGoals();
      final fetchedEvents = _apiService.fetchEvents();

      final results = await Future.wait([fetchedGoals, fetchedEvents]);

      // 2. Update local state
      _allGoals = results[0] as List<Goal>;
      _allEvents = results[1] as List<Event>;

      // 3. Populate EventController
      _refreshEventController();

      // 4. Update UI
      setState(() => loading = false);
    } catch (e) {
      print('Error loading data from API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load data from server.")),
        );
        setState(() => loading = false);
      }
    }
  }

  /// Populates the `EventController` with `CalendarEventData` objects
  /// converted from the app's custom `Event` models.
  void _refreshEventController() {
    // Clear all existing events before refreshing.
    eventController.removeAll(
      List<CalendarEventData<Event>>.from(eventController.events),
    );

    // Create a quick lookup map for goals (SQL ID -> Goal object).
    final goalLookup = {for (var g in _allGoals) g.id: g};

    // Iterate through all custom Event objects fetched from the API.
    for (var event in _allEvents) {
      // Find the Goal object linked by the Event's linkedGoal.id.
      final linkedGoal = event.linkedGoal?.id != null
          ? goalLookup[event.linkedGoal!.id]
          : null;

      // Determine the event color. (Assumes goal.color is a stored int value)
      final bgColor = linkedGoal?.color != null
          ? Color(linkedGoal!.color) // Convert int to Color
          : Colors.blue; // Default color

      // Add a new event to the calendar display controller.
      eventController.add(
        CalendarEventData<Event>(
          // Specify the custom data type is Event
          date: event.date,
          startTime: event.date,
          endTime: event.allDay
              ? null
              : (event.endDateTime ?? event.date.add(const Duration(hours: 1))),
          title: event.name,
          description: event.description,
          color: bgColor,
          event:
              event, // CRITICAL: Attach the full Event object here for lookups!
          // Custom styles...
          titleStyle: const TextStyle(
            height: 0.5,
            color: Colors.white,
            fontSize: 20,
          ),
          descriptionStyle: const TextStyle(
            height: 1,
            color: Color.fromARGB(184, 255, 255, 255),
          ),
        ),
      );
    }
  }

  // --- Utility Methods (Unchanged) ---

  /// Toggles the `currentSlotSize` between 60 minutes, 30 minutes, and 15 minutes.
  void toggleSlotSize() {
    setState(() {
      currentSlotSize = currentSlotSize == MinuteSlotSize.minutes60
          ? MinuteSlotSize.minutes30
          : currentSlotSize == MinuteSlotSize.minutes30
          ? MinuteSlotSize.minutes15
          : MinuteSlotSize.minutes60; // Cycle back to 60 minutes.
    });
  }

  /// Returns a short label for the current slot size.
  String getSlotSizeLabel() {
    switch (currentSlotSize) {
      case MinuteSlotSize.minutes60:
        return '60m';
      case MinuteSlotSize.minutes30:
        return '30m';
      case MinuteSlotSize.minutes15:
        return '15m';
    }
  }

  /// Calculates the height of the calendar grid per minute.
  double getHeightPerMinute() {
    switch (currentSlotSize) {
      case MinuteSlotSize.minutes60:
        return 1.5;
      case MinuteSlotSize.minutes30:
        return 3.0;
      case MinuteSlotSize.minutes15:
        return 10.0;
    }
  }

  // Helper methods for grid lines.
  bool showHalfHours() => currentSlotSize != MinuteSlotSize.minutes60;
  bool showQuarterHours() => currentSlotSize == MinuteSlotSize.minutes15;

  /// Shows a date picker dialog to allow the user to jump to a specific date.
  Future<void> _pickDateFromMonthView() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentDisplayedDate,
      firstDate: DateTime(2020), // Set an appropriate start date.
      lastDate: DateTime(2100), // Set an appropriate end date.
    );

    if (selectedDate != null) {
      setState(() => _currentDisplayedDate = selectedDate);
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define the list of screen widgets corresponding to the bottom navigation tabs.
    final screens = [
      _buildCalendarView(), // Index 0: Calendar.
      const GoalScreen(), // Index 1: Goals.
      const GoalTrackerScreen(), // Index 2: Tracker.
    ];

    return Scaffold(
      body: screens[_currentIndex],
      // Bottom navigation bar for app-wide screen switching.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
        ],
      ),
      // Floating action button (FAB) for quick event creation.
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final midnight = DateTime(
                  _currentDisplayedDate.year,
                  _currentDisplayedDate.month,
                  _currentDisplayedDate.day,
                );

                // Pass null for existingEvent, and the initial date.
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventScreen(
                      eventController: eventController,
                      initialDate: midnight,
                    ),
                  ),
                );
                // Reload data to refresh the view with the new event/changes.
                _loadCalendar();
              },
            )
          : null, // Hide FAB on non-calendar tabs.
    );
  }

  /// Builds the dedicated calendar view screen, including the AppBar and DayView widget.
  Widget _buildCalendarView() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            // Calendar Icon: Tapping opens the date picker.
            GestureDetector(
              onTap: _pickDateFromMonthView,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.transparent,
                child: const Icon(Icons.calendar_today, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // "Today" button: Resets the calendar view to the current date.
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentDisplayedDate = DateTime.now();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Time Slot Size Toggle Button.
          GestureDetector(
            onTap: toggleSlotSize, // Cycles the time slot size.
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.grid_view, color: Colors.black),
                  const SizedBox(width: 4),
                  // Display the current slot size label (e.g., '60m').
                  Text(
                    getSlotSizeLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // The main calendar display widget using DayView.
      body: DayView<Event>(
        // Specify the generic type is Event
        key: ValueKey(_currentDisplayedDate),
        controller: eventController,
        heightPerMinute: getHeightPerMinute(),
        showVerticalLine: true,
        minuteSlotSize: currentSlotSize,
        showHalfHours: showHalfHours(),
        showQuarterHours: showQuarterHours(),
        initialDay: _currentDisplayedDate,
        hourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        halfHourIndicatorSettings: const HourIndicatorSettings(
          color: Colors.grey,
        ),
        quarterHourIndicatorSettings: const HourIndicatorSettings(
          color: Colors.grey,
        ),
        dateStringBuilder: (date, {secondaryDate}) =>
            DateFormat('EEEE, MMM d, yyyy').format(date),
        timeStringBuilder: (time, {secondaryDate}) =>
            DateFormat('h:mm a').format(time),
        onPageChange: (date, pageIndex) {
          setState(() => _currentDisplayedDate = date);
        },
        // Callback when the user taps an empty time slot on the calendar grid.
        onDateTap: (date) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditEventScreen(
                eventController: eventController,
                initialDate: date,
              ),
            ),
          );
          _loadCalendar();
        },
        // Callback when an existing event widget is tapped.
        onEventTap: (events, date) async {
          if (events.isNotEmpty) {
            // Get the custom Event object directly from the CalendarEventData's 'event' property
            final tappedEventData = events.first;
            final event = tappedEventData.event;

            if (event != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventScreen(
                    eventController: eventController,
                    existingEvent: event, // Pass the event object for editing.
                  ),
                ),
              );
              // Refresh data after event modification or deletion.
              _loadCalendar();
            }
          }
        },
        // Custom builder for all-day events displayed above the main timeline.
        fullDayEventBuilder: (events, date) {
          if (events.isEmpty) return const SizedBox.shrink();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: events.map((eventData) {
                // Get the custom Event object directly from the CalendarEventData
                final realEvent = eventData.event;
                final bgColor = realEvent?.linkedGoal?.color != null
                    ? Color(realEvent!.linkedGoal!.color)
                    : Colors.blue;

                return GestureDetector(
                  onTap: () {
                    if (realEvent != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(
                            eventController: eventController,
                            existingEvent: realEvent,
                          ),
                        ),
                      ).then(
                        (_) => _loadCalendar(),
                      ); // Refresh after returning.
                    }
                  },
                  // Display the event chip with goal-linked color and rounded corners.
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      eventData.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
