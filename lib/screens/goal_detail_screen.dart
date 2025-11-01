// calendar_app/lib/screens/goal_detail_screen.dart (Rewritten to use ApiService)

import 'package:flutter/material.dart';
import '../core/api_service.dart'; // Import ApiService for remote data access.
import '../core/goal.dart'; // Import the API-backed Goal data model.
import '../core/event.dart'; // Import the API-backed Event data model.
import 'package:intl/intl.dart'; // For date formatting

/// A screen that displays detailed progress for a single goal within a specific time frequency.
class GoalDetailScreen extends StatefulWidget {
  // The Goal object whose progress is being tracked (from API fetch).
  final Goal goal;
  // The time window (Daily / Weekly / Monthly) for filtering related events.
  final String frequency;

  const GoalDetailScreen({
    super.key,
    required this.goal,
    required this.frequency,
  });

  @override
  // Creates the state object for this screen.
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

/// The state class for GoalDetailScreen, managing API access and progress calculation.
class _GoalDetailScreenState extends State<GoalDetailScreen> {
  // API Service instance.
  final ApiService _apiService = ApiService();

  // List of events linked to the goal that fall within the specified frequency.
  List<Event> _goalEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Initiate the asynchronous loading and filtering of events.
    _loadEvents();
  }

  /// Fetches all events from the API and filters them based on the current goal and frequency.
  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch all events from the API.
      final events = await _apiService.fetchEvents();


      // 2. Update local state
      List<Event> allEvents = events;
      
      allEvents = await Future.wait(events.map((event) async {
      if (event.goalId != null) {
        event.linkedGoal = await _apiService.getGoalById(event.goalId!);
      }
      return event;
    }));

      // 2. Filter events:
      _goalEvents = allEvents
          .where(
            (e) =>
                // Must have a linked goal ID that matches the current goal's ID
                e.goalId == widget.goal.id &&
                // Must be in the frequency period
                _isEventInFrequency(e, widget.frequency),
          )
          .toList();
    } catch (e) {
      print("Error loading events for goal detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load events.")));
      }
    } finally {
      // Trigger a rebuild to display the loaded events.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Determines if a specific event falls within the current period defined by the frequency.
  bool _isEventInFrequency(Event e, String frequency) {
    // Logic is identical to the Hive version, using Dart's DateTime.
    final now = DateTime.now();

    // Normalize date by removing time components for comparison
    DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    switch (frequency) {
      case 'Daily':
        return normalize(e.date).isAtSameMomentAs(normalize(now));
      case 'Weekly':
        final weekStart = normalize(
          now.subtract(Duration(days: now.weekday - 1)),
        );
        final weekEnd = weekStart.add(
          const Duration(days: 7),
        ); // Exclusive end (next Monday)
        return e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(weekEnd);
      case 'Monthly':
        return e.date.year == now.year && e.date.month == now.month;
      default:
        return true;
    }
  }

  /// Toggles the completion status of an event and persists the change via API.
  Future<void> _toggleComplete(Event e) async {
    // 1. Update the local model state immediately for fast feedback.
    e.isCompleted = !(e.isCompleted);

    // 2. Persist the change via API.

    try {
      await _apiService.updateEvent(e);

      // 3. Update the local state to refresh the UI (this is only needed if
      // the API update was successful and we didn't use the optimistic update).
      setState(() {});
    } catch (error) {
      print("Error updating event status via API: $error");
      // Revert local state if API failed.
      e.isCompleted = !(e.isCompleted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update event completion status."),
          ),
        );
        setState(() {}); // Force UI refresh back to old state
      }
    }
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("${widget.goal.name} - ${widget.frequency}"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _calculateProgress();
    // Set a minimum visible progress for the indicator.
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
                    // Use the goal's color for the indicator
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(widget.goal.color),
                    ),
                  ),
                  // Display the percentage text over the indicator.
                  Center(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Display the total count of relevant events.
          Text(
            "Total events in this period: **${_goalEvents.length}**",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // Map the filtered events to interactive CheckboxListTile widgets.
          if (_goalEvents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "No events linked to this goal in the selected time period.",
                ),
              ),
            )
          else
            ..._goalEvents.map((e) {
              final isDone = e.isCompleted ?? false;
              // Formatter to show Date and Time correctly
              final dateFormatter = DateFormat('MMM d, h:mm a');

              String subtitleText = dateFormatter.format(e.date.toLocal());
              if (e.endDateTime != null) {
                subtitleText +=
                    " - ${dateFormatter.format(e.endDateTime!.toLocal())}";
              }

              return CheckboxListTile(
                title: Text(
                  e.name,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                // Subtitle shows the event's date and time range.
                subtitle: Text(subtitleText),
                value: isDone,
                // Tapping toggles completion status via the API update method.
                onChanged: (newValue) => _toggleComplete(e),
              );
            }).toList(),
        ],
      ),
    );
  }
}
