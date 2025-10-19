// The comments in this code were written by an AI assistant.

import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // Import Hive for local data access.
import '../core/goal.dart'; // Import the Goal data model.
import '../core/event.dart'; // Import the Event data model.
import 'goal_detail_screen.dart'; // Import the screen for detailed goal view.

/// A screen to track progress against defined goals by grouping linked events.
class GoalTrackerScreen extends StatefulWidget {
  const GoalTrackerScreen({super.key});

  @override
  // Creates the state object for this screen.
  State<GoalTrackerScreen> createState() => _GoalTrackerScreenState();
}

/// The state class for the Goal Tracker screen, handling Hive access and logic.
class _GoalTrackerScreenState extends State<GoalTrackerScreen> {
  // References to the Hive boxes for Goals and Events.
  Box<Goal>? _goalsBox;
  Box<Event>? _eventsBox;
  // Flag to manage the loading state while waiting for Hive boxes to open.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Initiate the asynchronous loading of Hive boxes.
    _loadBoxes();
  }

  /// Opens or retrieves the necessary Hive boxes and updates the loading state.
  Future<void> _loadBoxes() async {
    // Open or get the 'goalsBox'.
    _goalsBox = Hive.isBoxOpen('goalsBox')
        ? Hive.box<Goal>('goalsBox')
        : await Hive.openBox<Goal>('goalsBox');

    // Open or get the 'eventsBox'.
    _eventsBox = Hive.isBoxOpen('eventsBox')
        ? Hive.box<Event>('eventsBox')
        : await Hive.openBox<Event>('eventsBox');

    // Update UI once both boxes are ready.
    setState(() => _loading = false);
  }

  /// Groups all available goals into hardcoded frequency categories for display.
  /// NOTE: This currently puts ALL goals into ALL categories, requiring filtering later.
  Map<String, List<Goal>> _groupGoalsByFrequency() {
    final goals = _goalsBox!.values.toList();
    return {
      'Daily': goals,
      'Weekly': goals,
      'Monthly': goals,
    };
  }

  /// Calculates the overall progress percentage for a list of goals within a given frequency period.
  double _calculateProgress(List<Goal> goals, String frequency) {
    // Return 0.0 if no goals or event data is available.
    if (goals.isEmpty || _eventsBox == null) return 0.0;

    int totalEvents = 0;
    int completedEvents = 0;

    // Iterate through all goals to aggregate linked event data.
    for (var goal in goals) {
      // Filter events: must be linked to the current goal AND fall within the frequency window.
      final events = _eventsBox!.values.where((e) =>
          e.linkedGoal != null &&
          e.linkedGoal!.key == goal.key &&
          _isEventInFrequency(e, frequency));

      totalEvents += events.length;
      // Count completed events (where isCompleted is true).
      completedEvents += events.where((e) => e.isCompleted ?? false).length;
    }

    // Calculate progress: completed / total. Avoid division by zero.
    return totalEvents == 0 ? 0.0 : completedEvents / totalEvents.toDouble();
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

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while data is being fetched.
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Temporary map to hold only goal groups that actually contain events in the period.
    final groupedGoals = <String, List<Goal>>{};

    // Iterate through the hardcoded frequency groups.
    for (var entry in _groupGoalsByFrequency().entries) {
      final frequency = entry.key;
      // Filter the goals to only include those that have linked events within the current period.
      final goals = entry.value.where((goal) {
        // Count how many events are linked to this goal and fall within the frequency.
        final usedCount = _eventsBox!.values.where((e) =>
            e.linkedGoal != null &&
            e.linkedGoal!.key == goal.key &&
            _isEventInFrequency(e, frequency)).length;
        // Only include the goal if it has been used at least once in this period.
        return usedCount > 0;
      }).toList();

      // Only add the frequency group if it contains active goals.
      if (goals.isNotEmpty) {
        groupedGoals[frequency] = goals;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Goal Tracker")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        // Map the filtered groups to ExpansionTile widgets.
        children: groupedGoals.entries.map((entry) {
          final frequency = entry.key;
          final goals = entry.value;

          final progress = _calculateProgress(goals, frequency);
          // Set a minimum progress value (e.g., 0.01) to ensure the CircularProgressIndicator is visible.
          final displayProgress = progress < 0.01 ? 0.01 : progress;
          final displayText = "${(progress * 100).toInt()}%";

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            // ExpansionTile allows users to expand/collapse the list of goals in a frequency group.
            child: ExpansionTile(
              title: Row(
                children: [
                  // Circular Progress Indicator for the overall group progress.
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: displayProgress,
                          strokeWidth: 4,
                        ),
                        // Center text displaying the calculated percentage.
                        Center(
                          child: Text(
                            displayText,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // The title of the frequency group (Daily, Weekly, Monthly).
                  Text(
                    frequency,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Children are the individual Goal ListTiles.
              children: goals.map((goal) {
                // Recalculate the used count for display in the subtitle.
                final usedCount = _eventsBox!.values
                    .where((e) =>
                        e.linkedGoal != null &&
                        e.linkedGoal!.key == goal.key &&
                        _isEventInFrequency(e, frequency))
                    .length;

                return ListTile(
                  title: Text(goal.name),
                  subtitle: Text("Used: $usedCount times"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // Navigate to the detail screen when a goal is tapped.
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoalDetailScreen(
                          goal: goal,
                          frequency: frequency,
                        ),
                      ),
                    );
                    // Force a rebuild of the screen to reflect any changes made in the detail screen.
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}