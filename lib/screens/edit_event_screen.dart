import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:hive/hive.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';

class EditEventScreen extends StatefulWidget {
  final Calendar calendar;
  final EventController eventController;
  final Event? existingEvent;

  const EditEventScreen({
    super.key,
    required this.calendar,
    required this.eventController,
    this.existingEvent,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  Goal? _selectedGoal;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime; // optional end time

  Box<Goal>? _goalsBox;
  bool _loadingGoals = true;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _selectedGoal = existing?.linkedGoal;
    _selectedDate = existing?.date ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(existing?.date ?? DateTime.now());
    _endTime = existing?.endDateTime != null
        ? TimeOfDay.fromDateTime(existing!.endDateTime!)
        : null;

    _loadGoals();
  }

  Future<void> _loadGoals() async {
    _goalsBox = Hive.isBoxOpen('goalsBox')
        ? Hive.box<Goal>('goalsBox')
        : await Hive.openBox<Goal>('goalsBox');

    setState(() => _loadingGoals = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingGoals) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goalOptions = _goalsBox!.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Event" : "Create Event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Event name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Event Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date picker
              ListTile(
                title: Text(
                  "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),

              // Start time picker
              ListTile(
                title: Text("Start Time: ${_startTime.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),

              // Optional end time picker
              ListTile(
                title: Text(
                    "End Time: ${(_endTime ?? _startTime).format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? _startTime,
                  );
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),

              const SizedBox(height: 16),

              // Goal selection
              DropdownButtonFormField<Goal?>(
                value: _selectedGoal,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Linked Goal",
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Goal?>(
                    value: null,
                    child: Text("None"),
                  ),
                  ...goalOptions.map(
                    (goal) => DropdownMenuItem<Goal?>(
                      value: goal,
                      child: Text(goal.name),
                    ),
                  ),
                ],
                onChanged: (newValue) {
                  setState(() => _selectedGoal = newValue);
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(isEditing ? "Save Changes" : "Add Event"),
                onPressed: _saveEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      (_endTime ?? _startTime).hour,
      (_endTime ?? _startTime).minute,
    );

    if (isEditing) {
      final existing = widget.existingEvent!;
      existing.name = _nameController.text;
      existing.description = _descController.text;
      existing.date = startDateTime;
      existing.endDateTime = endDateTime;
      existing.linkedGoal = _selectedGoal;

      final key = widget.calendar.eventBox.keys.firstWhere(
        (k) => widget.calendar.eventBox.get(k) == existing,
        orElse: () => null,
      );
      if (key != null) {
        await widget.calendar.eventBox.put(key, existing);
      }
    } else {
      final newEvent = Event(
        name: _nameController.text,
        description: _descController.text,
        date: startDateTime,
        endDateTime: endDateTime,
        linkedGoal: _selectedGoal,
      );

      await widget.calendar.addEvent(event: newEvent);
      widget.eventController.add(
        CalendarEventData(
          date: startDateTime,
          endDate: endDateTime,
          title: _nameController.text,
          description: _descController.text,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }
}
