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
  Color _selectedColor = Colors.blue; // Default selected color

  final List<Color> _predefinedColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

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
    _nameController.clear();
    _descController.clear();
    _selectedColor = Colors.blue;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Goal"),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _predefinedColors.map((c) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => _selectedColor = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                final name = _nameController.text.trim();
                final desc = _descController.text.trim();
                if (name.isEmpty) return;

                if (_goalsBox.values.any((g) => g.name == name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Goal already exists")),
                  );
                  return;
                }

                await _goalsBox.add(Goal(
                  name: name,
                  description: desc,
                  color: _selectedColor.value,
                ));

                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(int index) async {
    final goal = _goalsBox.getAt(index);
    if (goal == null || _eventsBox == null) return;

    _nameController.text = goal.name;
    _descController.text = goal.description;
    _selectedColor = Color(goal.color);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _predefinedColors.map((c) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => _selectedColor = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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

                goal.name = newName;
                goal.description = newDesc;
                goal.color = _selectedColor.value;
                await goal.save();

                final linkedEvents = _eventsBox!.values.where(
                    (e) => e.linkedGoal != null && e.linkedGoal!.key == goal.key);
                for (var event in linkedEvents) {
                  event.linkedGoal = goal;
                  await event.save();
                }

                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goals = _goalsBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Goals"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGoal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: goals.length,
                itemBuilder: (_, index) {
                  final goal = goals[index];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(goal.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
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
