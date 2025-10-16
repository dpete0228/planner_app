import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';

class EditEventScreen extends StatefulWidget {
  final Calendar calendar;
  final EventController eventController;
  final Event? existingEvent;

  const EditEventScreen({
    Key? key,
    required this.calendar,
    required this.eventController,
    this.existingEvent,
  }) : super(key: key);

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  Goal? _selectedGoal;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _selectedGoal = existing?.linkedGoal;
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(existing?.date ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final goalOptions = widget.calendar.goalManager.availableGoals;

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
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => _selectedDate = pickedDate);
                  }
                },
              ),

              // Time picker
              ListTile(
                title: Text(
                  "Time: ${_selectedTime.format(context)}",
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() => _selectedTime = pickedTime);
                  }
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

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (isEditing) {
      // Edit existing event
      final existing = widget.existingEvent!;
      existing.name = _nameController.text;
      existing.description = _descController.text;
      existing.date = combinedDateTime;
      existing.linkedGoal = _selectedGoal;
    } else {
      // Create new event
      final newEvent = Event(
        name: _nameController.text,
        description: _descController.text,
        date: combinedDateTime,
        linkedGoal: _selectedGoal,
      );
      widget.calendar.events.putIfAbsent(combinedDateTime, () => []).add(newEvent);

      widget.eventController.add(
        CalendarEventData(
          date: combinedDateTime,
          title: _nameController.text,
          description: _descController.text,
        ),
      );
    }

    await widget.calendar.saveFile();

    if (mounted) {
      Navigator.pop(context, true); // return true = event saved
    }
  }
}
