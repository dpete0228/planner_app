// The comments in this code were written by an AI assistant.

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
// Import the custom core data models for the application's logic.
import '../core/calendar.dart';
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
  // The application's core calendar data model, initialized late because it's loaded asynchronously.
  late Calendar calendar;
  // Flag to indicate if the essential calendar data is currently loading from storage.
  bool loading = true;
  // Controller from the calendar_view package to manage events displayed on the calendar grid.
  late EventController eventController;
  // State variable to control the vertical density/slot size of the DayView timeline.
  MinuteSlotSize currentSlotSize = MinuteSlotSize.minutes60;
  // Index for the currently selected tab in the BottomNavigationBar (0: Calendar, 1: Goals, 2: Tracker).
  int _currentIndex = 0;
  // The date currently focused on and displayed in the DayView.
  DateTime _currentDisplayedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize the event controller upon widget creation.
    eventController = EventController();
    // Start the process of loading the calendar data from persistent storage.
    _loadCalendar();
  }

  /// Asynchronously initializes or loads the application's calendar data.
  Future<void> _loadCalendar() async {
    // Await the creation or loading of the Calendar model instance, which handles persistence.
    calendar = await Calendar.create();
    // Refresh the EventController to display the newly loaded events.
    _refreshEventController();
    // Update the UI to show that loading is complete and render the main content.
    setState(() => loading = false);
  }

  /// Populates the `EventController` with `CalendarEventData` objects
  /// converted from the app's custom `Event` models.
  void _refreshEventController() {
    // Clear all existing events from the controller to avoid duplicates before adding new data.
    // This is necessary for a full data refresh.
    eventController.removeAll(List<CalendarEventData>.from(eventController.events));

    // Iterate through all custom Event objects in the Calendar model.
    for (var event in calendar.allEvents) {
      // Determine the event color. Prioritize the linked goal's color,
      // converting the integer color value to a Flutter Color object.
      final bgColor = event.linkedGoal?.color != null
          ? Color(event.linkedGoal!.color)
          : Colors.blue; // Default to a standard blue if no goal/color is linked.

      // Add a new event to the calendar display controller.
      eventController.add(
        CalendarEventData(
          date: event.date,
          // Start time is derived from the custom event's date property.
          startTime: event.date,
          // Calculate end time: null for all-day events (they show in the header),
          // otherwise use the stored end time, defaulting to one hour if missing.
          endTime: event.allDay ? null : (event.endDateTime ?? event.date.add(const Duration(hours: 1))),
          title: event.name, // The event's name serves as the CalendarEventData title.
          description: event.description,
          color: bgColor,
          // Custom style for the event title displayed on the calendar.
          titleStyle: const TextStyle(
            height: 0.5,
            color: Colors.white,
            fontSize: 20,
          ),
          // Custom style for the event description, using a slightly transparent white.
          descriptionStyle: const TextStyle(
            height: 1,
            color: Color.fromARGB(184, 255, 255, 255),
          ),
        ),
      );
    }
  }

  /// Toggles the `currentSlotSize` between 60 minutes, 30 minutes, and 15 minutes,
  /// updating the calendar grid density.
  void toggleSlotSize() {
    setState(() {
      currentSlotSize = currentSlotSize == MinuteSlotSize.minutes60
          ? MinuteSlotSize.minutes30
          : currentSlotSize == MinuteSlotSize.minutes30
              ? MinuteSlotSize.minutes15
              : MinuteSlotSize.minutes60; // Cycle back to 60 minutes.
    });
  }

  /// Returns a short label for the current slot size for display in the AppBar.
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

  /// Calculates the height of the calendar grid per minute, effectively controlling the vertical zoom level.
  double getHeightPerMinute() {
    switch (currentSlotSize) {
      // 60m slots use a lower height per minute, making the view more compact.
      case MinuteSlotSize.minutes60:
        return 1.5;
      // 30m slots use a medium height.
      case MinuteSlotSize.minutes30:
        return 3.0;
      // 15m slots use the highest height, making the view the most expanded.
      case MinuteSlotSize.minutes15:
        return 10.0;
    }
  }

  // Helper to determine if half-hour lines should be visible in the DayView.
  bool showHalfHours() => currentSlotSize != MinuteSlotSize.minutes60;
  // Helper to determine if quarter-hour lines should be visible.
  bool showQuarterHours() => currentSlotSize == MinuteSlotSize.minutes15;

  /// Shows a date picker dialog to allow the user to jump to a specific date.
  Future<void> _pickDateFromMonthView() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentDisplayedDate,
      firstDate: DateTime(2020), // Set an appropriate start date.
      lastDate: DateTime(2100), // Set an appropriate end date.
    );

    // If a date was selected (not null), update the displayed date and rebuild.
    if (selectedDate != null) {
      setState(() => _currentDisplayedDate = selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the data is still loading, show a simple loading screen.
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Define the list of screen widgets corresponding to the bottom navigation tabs.
    final screens = [
      _buildCalendarView(), // Index 0: Calendar.
      const GoalScreen(), // Index 1: Goals.
      const GoalTrackerScreen(), // Index 2: Tracker.
    ];

    return Scaffold(
      // The currently active screen based on the bottom navigation index.
      body: screens[_currentIndex],
      // Bottom navigation bar for app-wide screen switching.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Update state to switch the displayed screen.
          setState(() => _currentIndex = index);
        },
        // Navigation items with icons and labels.
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
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
                // Determine the midnight time of the currently displayed day for initial event date.
                final midnight = DateTime(
                  _currentDisplayedDate.year,
                  _currentDisplayedDate.month,
                  _currentDisplayedDate.day,
                );

                // Navigate to the event creation/edit screen.
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventScreen(
                      calendar: calendar,
                      eventController: eventController,
                      initialDate: midnight, // Pass the initial date for the new event.
                    ),
                  ),
                );
                // Reload calendar data to refresh the view with the new event/changes.
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
        // Use a Row in the title area to hold navigational actions.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            // Calendar Icon: Tapping opens the date picker.
            GestureDetector(
              onTap: _pickDateFromMonthView,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.transparent, // Ensures a larger, transparent tap target.
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent, // Styled as a primary action button.
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              color: Colors.transparent, // Enlarges the tap area.
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
      body: DayView<Object?>(
        // A unique key forces the DayView to completely rebuild when the date changes, which is crucial for DayView's page view logic.
        key: ValueKey(_currentDisplayedDate),
        controller: eventController,
        heightPerMinute: getHeightPerMinute(), // Set vertical scaling.
        showVerticalLine: true, // Show the current time indicator line.
        minuteSlotSize: currentSlotSize, // Set the primary time grid interval.
        showHalfHours: showHalfHours(), // Show half-hour indicators if applicable.
        showQuarterHours: showQuarterHours(), // Show quarter-hour indicators if applicable.
        initialDay: _currentDisplayedDate, // The day to display when the widget is built.
        // Custom color for the main time indicators.
        hourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        halfHourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        quarterHourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        // Custom formatters for the view's date and time labels.
        dateStringBuilder: (date, {secondaryDate}) => DateFormat('EEEE, MMM d, yyyy').format(date),
        timeStringBuilder: (time, {secondaryDate}) => DateFormat('h:mm a').format(time),
        // Callback when the user swipes to view a different day.
        onPageChange: (date, pageIndex) {
          setState(() => _currentDisplayedDate = date);
        },
        // Callback when the user taps an empty time slot on the calendar grid.
        onDateTap: (date) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditEventScreen(
                calendar: calendar,
                eventController: eventController,
                initialDate: date, // Pass the tapped time to pre-fill the new event time.
              ),
            ),
          );
          // Refresh data after returning from the event creation screen.
          _loadCalendar();
        },
        // Callback when an existing event widget is tapped.
        onEventTap: (events, date) async {
          if (events.isNotEmpty) {
            final tappedEvent = events.first;
            // Lookup the custom Event object using the title (event name) for the full model data.
            final event = calendar.getEventByName(tappedEvent.title);
            if (event != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventScreen(
                    calendar: calendar,
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
          // If no all-day events exist for the day, show an empty box.
          if (events.isEmpty) return const SizedBox.shrink();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // Map each calendar event to a clickable chip widget.
              children: events.map((event) {
                // Get the custom Event object to retrieve the linked goal's color.
                final realEvent = calendar.getEventByName(event.title);
                final bgColor = realEvent?.linkedGoal?.color != null
                    ? Color(realEvent!.linkedGoal!.color)
                    : Colors.blue;

                return GestureDetector(
                  // Tap handler for the all-day event chip to open the edit screen.
                  onTap: () {
                    if (realEvent != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(
                            calendar: calendar,
                            eventController: eventController,
                            existingEvent: realEvent,
                          ),
                        ),
                      ).then((_) => _loadCalendar()); // Refresh after returning.
                    }
                  },
                  // Display the event chip with goal-linked color and rounded corners.
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.title,
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