import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/goal.dart';
import '../core/event.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  final String frequency; // Daily / Weekly / Monthly

  const GoalDetailScreen({super.key, required this.goal, required this.frequency});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  Box<Event>? _eventsBox;
  List<Event> _goalEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    _eventsBox = Hive.isBoxOpen('eventsBox')
        ? Hive.box<Event>('eventsBox')
        : await Hive.openBox<Event>('eventsBox');

    _goalEvents = _eventsBox!.values
        .where((e) =>
            e.linkedGoal != null &&
            e.linkedGoal!.key == widget.goal.key &&
            _isEventInFrequency(e, widget.frequency))
        .toList();

    setState(() {});
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

  void _toggleComplete(Event e) {
    setState(() {
      e.isCompleted = !(e.isCompleted ?? false);
      e.save();
    });
  }

  double _calculateProgress() {
    if (_goalEvents.isEmpty) return 0.0;
    final completed = _goalEvents.where((e) => e.isCompleted ?? false).length;
    return completed / _goalEvents.length.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final displayProgress = progress < 0.01 ? 0.01 : progress; // min visual 1%
    final displayText = "${(progress * 100).toInt()}%";

    return Scaffold(
      appBar: AppBar(title: Text("${widget.goal.name} - ${widget.frequency}")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          Text("Total events: ${_goalEvents.length}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ..._goalEvents.map((e) {
            final isDone = e.isCompleted ?? false;
            return CheckboxListTile(
              title: Text(e.name),
              subtitle: Text(
                  "${e.date.toLocal()}${e.endDateTime != null ? ' - ${e.endDateTime}' : ''}"),
              value: isDone,
              onChanged: (_) => _toggleComplete(e),
            );
          }).toList(),
        ],
      ),
    );
  }
}
