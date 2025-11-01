// calendar_app/lib/screens/goal_tracker_screen.dart (Rewritten to use ApiService)

import 'package:flutter/material.dart';
import '../core/api_service.dart'; // New dependency for remote data calls
import '../core/goal.dart'; // Import the API-backed Goal data model.
import '../core/event.dart'; // Import the API-backed Event data model.
// NOTE: Assuming goal_detail_screen.dart is also updated or can handle API models
import 'goal_detail_screen.dart';

/// A screen to track progress against defined goals by grouping linked events
/// fetched from a remote API.
class GoalTrackerScreen extends StatefulWidget {
  const GoalTrackerScreen({super.key});

  @override
  // Creates the state object for this screen.
  State<GoalTrackerScreen> createState() => _GoalTrackerScreenState();
}

/// The state class for the Goal Tracker screen, handling API access and logic.
class _GoalTrackerScreenState extends State<GoalTrackerScreen> {
  // API Service instance for fetching data
  final ApiService _apiService = ApiService();

  // Data sources from the API
  List<Goal> _goals = [];
  List<Event> _events = [];

  // Flag to manage the loading state while waiting for API calls to complete.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Initiate the asynchronous loading of data from the API.
    _loadData();
  }

  /// Fetches the list of goals and events from the API and updates the state.
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Fetch data from the remote API.
      final fetchedEvents = _apiService.fetchEvents();
      final fetchedGoals = _apiService.fetchGoals();

      final results = await Future.wait([fetchedGoals, fetchedEvents]);

      // 2. Update local state
      _goals = results[0] as List<Goal>;
      List<Event> events = results[1] as List<Event>;
      
      _events = await Future.wait(events.map((event) async {
      if (event.goalId != null) {
        event.linkedGoal = await _apiService.getGoalById(event.goalId!);
      }
      return event;
    }));
    } catch (e) {
      print("Error loading data from API: $e");
      // Optionally show a user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load goals/events. Check API connection."),
          ),
        );
      }
    } finally {
      // Update UI once all data is ready.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Groups all available goals into hardcoded frequency categories for display.
  /// This function now works on the internal API-fetched list `_goals`.
  Map<String, List<Goal>> _groupGoalsByFrequency() {
    // Uses a copy of the goals list.
    final goals = List<Goal>.from(_goals);
    // The grouping structure remains hardcoded by frequency categories.
    return {'Daily': goals, 'Weekly': goals, 'Monthly': goals};
  }

  /// Calculates the overall progress percentage for a list of goals within a given frequency period.
  /// This function now uses the internal API-fetched list `_events`.
  double _calculateProgress(List<Goal> goals, String frequency) {
    // Return 0.0 if no goals are available.
    if (goals.isEmpty) return 0.0;

    int totalEvents = 0;
    int completedEvents = 0;

    // Iterate through all goals to aggregate linked event data.
    for (var goal in goals) {
      // Filter events: must be linked to the current goal's ID
      // AND fall within the frequency window.
      final events = _events.where(
        (e) =>
            e.goalId == goal.id && // Use the API ID for linking
            _isEventInFrequency(e, frequency),
      );

      totalEvents += events.length;

      completedEvents += events
          .where((e) => e.isCompleted==true).length;
    }

    // Calculate progress: completed / total. Avoid division by zero.
    return totalEvents == 0 ? 0.0 : completedEvents / totalEvents.toDouble();
  }

  /// Determines if a specific event falls within the current period defined by the frequency.
  bool _isEventInFrequency(Event e, String frequency) {
    // Logic remains the same as it relies on Dart's DateTime features.
    final now = DateTime.now();

    // Normalize date by removing time components for comparison
    DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    switch (frequency) {
      case 'Daily':
        // Check if event date is today.
        return normalize(e.date).isAtSameMomentAs(normalize(now));
      case 'Weekly':
        // Calculate the start and end of the current week (assuming Monday start).
        // Find the Monday of the current week.
        final weekStart = normalize(
          now.subtract(Duration(days: now.weekday - 1)),
        );
        final weekEnd = weekStart.add(
          const Duration(days: 7),
        ); // Exclusive end (next Monday)

        // Check if event date is within the current week's range.
        return e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(weekEnd);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupedGoals = <String, List<Goal>>{};

    // Iterate through the hardcoded frequency groups.
    for (var entry in _groupGoalsByFrequency().entries) {
      final frequency = entry.key;

      // Filter the goals to only include those that have linked events within the current period.
      

      final goals = entry.value.where((goal) {
        // Count how many events are linked to this goal's API ID and fall within the frequency.  
        final usedCount = _events
            .where(
              (e) =>
                  e.goalId == goal.id && // Use API ID
                  _isEventInFrequency(e, frequency),
            ).length;
        final allEventsForGoal = _events.where((e) => e.goalId == goal.id);
        final allCompleted = allEventsForGoal.isNotEmpty && allEventsForGoal.every((e) => e.isCompleted);


        // Only include the goal if it has been used at least once in this period.
        return usedCount > 0 || allCompleted;
      }).toList();

      // Only add the frequency group if it contains active goals.
      if (goals.isNotEmpty) {
        groupedGoals[frequency] = goals;
      }
    }

    // Display a message if no goals have been used in any period.
    if (groupedGoals.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Goal Tracker")),
        body: const Center(
          child: Text(
            "No linked events found in the current Daily, Weekly, or Monthly periods.",
          ),
        ),
      );
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Children are the individual Goal ListTiles.
              children: goals.map((goal) {
                // Recalculate the used count for display in the subtitle.
                final usedCount = _events
                    .where(
                      (e) =>
                          e.goalId == goal.id && // Use API ID
                          _isEventInFrequency(e, frequency),
                    )
                    .length;

                return ListTile(
                  title: Text(goal.name),
                  subtitle: Text("Used: $usedCount times"),
                  trailing: Icon(Icons.chevron_right, color: Color(goal.color)),
                  onTap: () async {
                    // Navigate to the detail screen when a goal is tapped.
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GoalDetailScreen(goal: goal, frequency: frequency),
                      ),
                    );
                    // Force a reload of all data to reflect any changes made in the detail screen.
                    _loadData();
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
