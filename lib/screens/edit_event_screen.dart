import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';

class EditEventScreen extends StatefulWidget {
  final Calendar calendar;
  final EventController eventController;
  final Event? existingEvent;
  final DateTime? initialDate;

  const EditEventScreen({
    super.key,
    required this.calendar,
    required this.eventController,
    this.existingEvent,
    this.initialDate,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  Goal? _selectedGoal;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  bool _allDay = false;

  Box<Goal>? _goalsBox;
  bool _loadingGoals = true;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    final baseDate = existing?.date ?? widget.initialDate ?? DateTime.now();

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _selectedGoal = existing?.linkedGoal;
    _selectedDate = baseDate;
    _startTime = TimeOfDay.fromDateTime(baseDate);

    // Determine if event is all-day
    _allDay = existing?.allDay ?? false;

    // Set end time automatically if not all-day
    if (!_allDay) {
      _endTime = existing?.endDateTime != null
          ? TimeOfDay.fromDateTime(existing!.endDateTime!)
          : TimeOfDay(
              hour: (_startTime.hour + ((_startTime.minute + 30) ~/ 60)) % 24,
              minute: (_startTime.minute + 30) % 60,
            );
    } else {
      _endTime = null;
    }

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
              // Name
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

              // Date
              ListTile(
                title: Text(
                  "Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}",
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

              // All-Day Checkbox
              CheckboxListTile(
                title: const Text("All Day"),
                value: _allDay,
                onChanged: (value) {
                  setState(() {
                    _allDay = value ?? false;
                    if (_allDay) {
                      _endTime = null;
                    } else {
                      _endTime ??= TimeOfDay(
                        hour: _startTime.hour,
                        minute: (_startTime.minute + 30) % 60,
                      );
                    }
                  });
                },
              ),

              // Start Time
              ListTile(
                title: Text(
                    "Start Time: ${_allDay ? '--:--' : _startTime.format(context)}"),
                trailing: const Icon(Icons.access_time),
                enabled: !_allDay,
                onTap: !_allDay
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                            _endTime = TimeOfDay(
                              hour: (picked.hour +
                                      ((_startTime.minute + 30) ~/ 60)) %
                                  24,
                              minute: (picked.minute + 30) % 60,
                            );
                          });
                        }
                      }
                    : null,
              ),

              // End Time (readonly)
              ListTile(
                title: Text(
                    "End Time: ${_allDay ? '--:--' : (_endTime ?? _startTime).format(context)}"),
                trailing: const Icon(Icons.access_time),
                enabled: !_allDay,
              ),
              const SizedBox(height: 16),

              // Linked Goal
              DropdownButtonFormField<int?>(
                value: _selectedGoal?.key as int?,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Linked Goal",
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("None"),
                  ),
                  ...goalOptions.map(
                    (goal) => DropdownMenuItem<int?>(
                      value: goal.key as int,
                      child: Text(goal.name),
                    ),
                  ),
                ],
                onChanged: (newKey) {
                  setState(() {
                    _selectedGoal =
                        newKey != null ? _goalsBox!.get(newKey) : null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Save
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

    DateTime startDateTime;
    DateTime? endDateTime;

    if (_allDay) {
      startDateTime = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      endDateTime = null;
    } else {
      startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime!.hour,
        _endTime!.minute,
      );
    }

    if (isEditing) {
      final existing = widget.existingEvent!;
      existing.name = _nameController.text;
      existing.description = _descController.text;
      existing.date = startDateTime;
      existing.endDateTime = endDateTime;
      existing.linkedGoal = _selectedGoal;
      existing.allDay = _allDay;

      final key = widget.calendar.eventBox.keys.firstWhere(
        (k) => widget.calendar.eventBox.get(k) == existing,
        orElse: () => null,
      );
      if (key != null) await widget.calendar.eventBox.put(key, existing);

      widget.eventController.removeWhere((e) => e.title == existing.name);
    } else {
      final newEvent = Event(
        name: _nameController.text,
        description: _descController.text,
        date: startDateTime,
        endDateTime: endDateTime,
        linkedGoal: _selectedGoal,
      );

      await widget.calendar.addEvent(event: newEvent);
    }

    widget.eventController.add(
      CalendarEventData(
        date: startDateTime,
        startTime: startDateTime,
        endTime: endDateTime,
        title: _nameController.text,
        description: _descController.text,
      ),
    );

    if (mounted) Navigator.pop(context, true);
  }
}
