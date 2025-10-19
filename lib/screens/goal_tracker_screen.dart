import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/goal.dart';
import '../core/event.dart';
import 'goal_detail_screen.dart';

class GoalTrackerScreen extends StatefulWidget {
  const GoalTrackerScreen({super.key});

  @override
  State<GoalTrackerScreen> createState() => _GoalTrackerScreenState();
}

class _GoalTrackerScreenState extends State<GoalTrackerScreen> {
  Box<Goal>? _goalsBox;
  Box<Event>? _eventsBox;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    _goalsBox = Hive.isBoxOpen('goalsBox')
        ? Hive.box<Goal>('goalsBox')
        : await Hive.openBox<Goal>('goalsBox');

    _eventsBox = Hive.isBoxOpen('eventsBox')
        ? Hive.box<Event>('eventsBox')
        : await Hive.openBox<Event>('eventsBox');

    setState(() => _loading = false);
  }

  Map<String, List<Goal>> _groupGoalsByFrequency() {
    final goals = _goalsBox!.values.toList();
    return {
      'Daily': goals,
      'Weekly': goals,
      'Monthly': goals,
    };
  }

  double _calculateProgress(List<Goal> goals, String frequency) {
    if (goals.isEmpty || _eventsBox == null) return 0.0;

    int totalEvents = 0;
    int completedEvents = 0;

    for (var goal in goals) {
      final events = _eventsBox!.values.where((e) =>
          e.linkedGoal != null &&
          e.linkedGoal!.key == goal.key &&
          _isEventInFrequency(e, frequency));

      totalEvents += events.length;
      completedEvents += events.where((e) => e.isCompleted ?? false).length;
    }

    return totalEvents == 0 ? 0.0 : completedEvents / totalEvents.toDouble();
  }

  bool _isEventInFrequency(Event e, String frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case 'Daily':
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      case 'Weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return e.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(weekEnd.add(const Duration(days: 1)));
      case 'Monthly':
        return e.date.year == now.year && e.date.month == now.month;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final groupedGoals = <String, List<Goal>>{};
    for (var entry in _groupGoalsByFrequency().entries) {
      final frequency = entry.key;
      final goals = entry.value.where((goal) {
        final usedCount = _eventsBox!.values.where((e) =>
            e.linkedGoal != null &&
            e.linkedGoal!.key == goal.key &&
            _isEventInFrequency(e, frequency)).length;
        return usedCount > 0;
      }).toList();

      if (goals.isNotEmpty) {
        groupedGoals[frequency] = goals;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Goal Tracker")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: groupedGoals.entries.map((entry) {
          final frequency = entry.key;
          final goals = entry.value;

          final progress = _calculateProgress(goals, frequency);
          final displayProgress = progress < 0.01 ? 0.01 : progress;
          final displayText = "${(progress * 100).toInt()}%";

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              title: Row(
                children: [
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
                  Text(
                    frequency,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              children: goals.map((goal) {
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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoalDetailScreen(
                          goal: goal,
                          frequency: frequency,
                        ),
                      ),
                    );
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
