import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/goal.dart';
import '../core/event.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late Box<Goal> _goalsBox;
  Box<Event>? _eventsBox;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
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

  Future<void> _addGoal() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) return;

    // Avoid duplicate goal names
    if (_goalsBox.values.any((g) => g.name == name)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Goal already exists")));
      return;
    }

    await _goalsBox.add(Goal(name: name, description: desc));
    _nameController.clear();
    _descController.clear();
    setState(() {});
  }

  Future<void> _deleteGoal(int index) async {
    final goal = _goalsBox.getAt(index);
    if (goal != null && _eventsBox != null) {
      final linkedEvents = _eventsBox!.values
          .where((e) => e.linkedGoal != null && e.linkedGoal!.key == goal.key);
      for (var event in linkedEvents) {
        event.linkedGoal = null;
        await event.save();
      }
      await _goalsBox.deleteAt(index);
      setState(() {});
    }
  }

  Future<void> _editGoal(int index) async {
    final goal = _goalsBox.getAt(index);
    if (goal == null || _eventsBox == null) return;

    _nameController.text = goal.name;
    _descController.text = goal.description;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Goal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Goal Name"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newDesc = _descController.text.trim();
              if (newName.isEmpty) return;

              // Update goal
              goal.name = newName;
              goal.description = newDesc;
              await goal.save();

              // Update linked events
              final linkedEvents = _eventsBox!.values
                  .where((e) => e.linkedGoal != null && e.linkedGoal!.key == goal.key);
              for (var event in linkedEvents) {
                event.linkedGoal = goal;
                await event.save();
              }

              _nameController.clear();
              _descController.clear();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goals = _goalsBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Goal
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Goal Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addGoal,
              child: const Text("Add Goal"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: goals.length,
                itemBuilder: (_, index) {
                  final goal = goals[index];
                  return ListTile(
                    title: Text(goal.name),
                    subtitle: Text(goal.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editGoal(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGoal(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
