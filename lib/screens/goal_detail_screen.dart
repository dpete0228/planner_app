// The comments in this code were written by an AI assistant.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // Import Hive for local data access.
import '../core/goal.dart'; // Import the Goal data model.
import '../core/event.dart'; // Import the Event data model.

/// A screen that displays detailed progress for a single goal within a specific time frequency.
class GoalDetailScreen extends StatefulWidget {
  // The Goal object whose progress is being tracked.
  final Goal goal;
  // The time window (Daily / Weekly / Monthly) for filtering related events.
  final String frequency; 

  const GoalDetailScreen({super.key, required this.goal, required this.frequency});

  @override
  // Creates the state object for this screen.
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

/// The state class for GoalDetailScreen, managing event fetching and progress calculation.
class _GoalDetailScreenState extends State<GoalDetailScreen> {
  // Reference to the Hive box for Events.
  Box<Event>? _eventsBox;
  // List of events linked to the goal that fall within the specified frequency.
  List<Event> _goalEvents = [];

  @override
  void initState() {
    super.initState();
    // Initiate the asynchronous loading and filtering of events.
    _loadEvents();
  }

  /// Opens the events box and filters events relevant to the current goal and frequency.
  Future<void> _loadEvents() async {
    // Open or get the 'eventsBox'.
    _eventsBox = Hive.isBoxOpen('eventsBox')
        ? Hive.box<Event>('eventsBox')
        : await Hive.openBox<Event>('eventsBox');

    // Filter events: 1. Must have a linked goal. 2. Linked goal key must match. 3. Must be in the frequency period.
    _goalEvents = _eventsBox!.values
        .where((e) =>
            e.linkedGoal != null &&
            e.linkedGoal!.key == widget.goal.key &&
            _isEventInFrequency(e, widget.frequency))
        .toList();

    // Trigger a rebuild to display the loaded events.
    setState(() {});
  }

  /// Determines if a specific event falls within the current period defined by the frequency.
  bool _isEventInFrequency(Event e, String frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case 'Daily':
        // Check if event date is today.
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      case 'Weekly':
        // Calculate the start and end of the current week.
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        // Check if event date is within the current week's range (inclusive start, exclusive end).
        return e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(weekEnd.add(const Duration(days: 1)));
      case 'Monthly':
        // Check if event date is within the current month and year.
        return e.date.year == now.year && e.date.month == now.month;
      default:
        // Default to including the event if frequency is unknown (e.g., all time).
        return true;
    }
  }

  /// Toggles the completion status of an event and persists the change to Hive.
  void _toggleComplete(Event e) {
    setState(() {
      // Toggle the completion status (default to false if null).
      e.isCompleted = !(e.isCompleted ?? false);
      // Persist the change to the Hive database. Note: `e` must be a HiveObject to call `save()`.
      e.save();
    });
  }

  /// Calculates the progress percentage (completed events / total events).
  double _calculateProgress() {
    if (_goalEvents.isEmpty) return 0.0;
    // Count events where the completion flag is true.
    final completed = _goalEvents.where((e) => e.isCompleted ?? false).length;
    // Calculate and return the ratio.
    return completed / _goalEvents.length.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    // Set a minimum visible progress for the indicator to prevent it from disappearing completely.
    final displayProgress = progress < 0.01 ? 0.01 : progress; 
    // Format the progress as a percentage string.
    final displayText = "${(progress * 100).toInt()}%";

    return Scaffold(
      appBar: AppBar(title: Text("${widget.goal.name} - ${widget.frequency}")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Centered Circular Progress Indicator for the goal's completion.
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: displayProgress,
                    strokeWidth: 8,
                  ),
                  // Display the percentage text over the indicator.
                  Center(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Display the total count of relevant events.
          Text("Total events: ${_goalEvents.length}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          // Map the filtered events to interactive CheckboxListTile widgets.
          ..._goalEvents.map((e) {
            final isDone = e.isCompleted ?? false;
            return CheckboxListTile(
              title: Text(e.name),
              // Subtitle shows the event's date and time range.
              subtitle: Text(
                  "${e.date.toLocal()}${e.endDateTime != null ? ' - ${e.endDateTime}' : ''}"),
              value: isDone,
              // Tapping toggles completion status via the private method.
              onChanged: (_) => _toggleComplete(e),
            );
          }).toList(),
        ],
      ),
    );
  }
}