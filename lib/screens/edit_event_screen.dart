// The comments in this code were written by an AI assistant.

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../core/calendar.dart'; // Custom model for Hive operations and event storage.
import '../core/event.dart'; // Custom Hive-backed Event data model.
import '../core/goal.dart'; // Custom Hive-backed Goal data model for linking.

/// A screen for creating a new calendar event or editing an existing one.
class EditEventScreen extends StatefulWidget {
  // Required: The persistent storage/calendar instance to save events to Hive.
  final Calendar calendar;
  // Required: The controller to update the CalendarView UI after save/delete.
  final EventController eventController;
  // Optional: The event object to be edited (determines 'isEditing' state).
  final Event? existingEvent;
  // Optional: The initial date to pre-select when creating a new event.
  final DateTime? initialDate;

  const EditEventScreen({
    super.key,
    required this.calendar,
    required this.eventController,
    this.existingEvent,
    this.initialDate,
  });

  @override
  // Creates the state for the event editing screen.
  State<EditEventScreen> createState() => _EditEventScreenState();
}

/// The state class managing the form, persistence, and logic for event creation/editing.
class _EditEventScreenState extends State<EditEventScreen> {
  // Global key for form validation.
  final _formKey = GlobalKey<FormState>();

  // Controllers for text inputs.
  late TextEditingController _nameController;
  late TextEditingController _descController;
  // State for the selected goal to link the event to.
  Goal? _selectedGoal;
  // State for the event's date.
  late DateTime _selectedDate;
  // State for the event's start time.
  late TimeOfDay _startTime;
  // State for the event's end time (null for all-day events).
  TimeOfDay? _endTime;
  // State to track if the event is an all-day event.
  bool _allDay = false;

  // Hive Box reference for fetching available goals.
  Box<Goal>? _goalsBox;
  // Flag to manage the loading state of the goals box.
  bool _loadingGoals = true;

  // Convenience getter: true if an existing event was passed to the widget.
  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    // Determine the base date from existing event, initial date, or now.
    final baseDate = existing?.date ?? widget.initialDate ?? DateTime.now();

    // Initialize controllers with existing data or empty strings.
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _selectedGoal = existing?.linkedGoal;
    _selectedDate = baseDate;
    _startTime = TimeOfDay.fromDateTime(baseDate);

    // Initialize all-day status.
    _allDay = existing?.allDay ?? false;

    // Initialize end time based on all-day status and existing data.
    if (!_allDay) {
      _endTime = existing?.endDateTime != null
          ? TimeOfDay.fromDateTime(existing!.endDateTime!)
          // Default to 30 minutes after start time if creating new.
          : TimeOfDay(
              // Calculate hour with carry-over for minutes.
              hour: (_startTime.hour + ((_startTime.minute + 30) ~/ 60)) % 24,
              // Calculate minute with wrap-around.
              minute: (_startTime.minute + 30) % 60,
            );
    } else {
      _endTime = null;
    }

    // Start loading goals from Hive.
    _loadGoals();
  }

  /// Opens or retrieves the Hive box for Goal objects and updates the loading state.
  Future<void> _loadGoals() async {
    // Check if the box is open, otherwise open it asynchronously.
    _goalsBox = Hive.isBoxOpen('goalsBox')
        ? Hive.box<Goal>('goalsBox')
        : await Hive.openBox<Goal>('goalsBox');

    // Update UI once goals are loaded.
    setState(() => _loadingGoals = false);
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while goals are being fetched from Hive.
    if (_loadingGoals) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // List of goals retrieved from the box for the dropdown.
    final goalOptions = _goalsBox!.values.toList();

    return Scaffold(
      appBar: AppBar(
        // Dynamic title based on edit/create mode.
        title: Text(isEditing ? "Edit Event" : "Create Event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Attach form key.
          child: ListView(
            children: [
              // Event Name Input Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Event Name",
                  border: OutlineInputBorder(),
                ),
                // Validation: field must not be empty.
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),

              // Description Input Field
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date Picker ListTile
              ListTile(
                title: Text(
                  // Display formatted date.
                  "Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  // Show date picker and update state on selection.
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
                    // Reset or set default end time when toggling all-day.
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

              // Start Time Picker ListTile
              ListTile(
                title: Text(
                    // Display start time, disabled if all-day.
                    "Start Time: ${_allDay ? '--:--' : _startTime.format(context)}"),
                trailing: const Icon(Icons.access_time),
                enabled: !_allDay,
                onTap: !_allDay
                    ? () async {
                        // Show time picker.
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                            // Recalculate end time (30 min after start, handling day wrap).
                            _endTime = TimeOfDay(
                              hour: (picked.hour +
                                      (((picked.minute + 30) ~/ 60))) %
                                  24,
                              minute: (picked.minute + 30) % 60,
                            );
                          });
                        }
                      }
                    : null,
              ),

              // End Time Display ListTile (read-only for simplicity)
              ListTile(
                title: Text(
                    // Display end time, showing start time as fallback/if all-day.
                    "End Time: ${_allDay ? '--:--' : (_endTime ?? _startTime).format(context)}"),
                trailing: const Icon(Icons.access_time),
                enabled: !_allDay,
              ),
              const SizedBox(height: 16),

              // Linked Goal Dropdown
              DropdownButtonFormField<int?>(
                // Use the Hive key as the value.
                value: _selectedGoal?.key as int?,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Linked Goal",
                  border: OutlineInputBorder(),
                ),
                items: [
                  // Option for 'None'.
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("None"),
                  ),
                  // Map goals to dropdown items using their Hive key.
                  ...goalOptions.map(
                    (goal) => DropdownMenuItem<int?>(
                      value: goal.key as int,
                      child: Text(goal.name),
                    ),
                  ),
                ],
                onChanged: (newKey) {
                  setState(() {
                    // Fetch the Goal object from the box using the key.
                    _selectedGoal =
                        newKey != null ? _goalsBox!.get(newKey) : null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Save Button (dynamic text).
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(isEditing ? "Save Changes" : "Add Event"),
                onPressed: _saveEvent,
              ),

              // Delete Button (only visible when editing).
              if (isEditing) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Event"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _deleteEvent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handles form validation, date/time construction, and saving/updating the event in Hive.
  Future<void> _saveEvent() async {
    // Validate the form fields.
    if (!_formKey.currentState!.validate()) return;

    DateTime startDateTime;
    DateTime? endDateTime;

    // Construct DateTime objects based on the _allDay flag.
    if (_allDay) {
      // All-day event starts at midnight.
      startDateTime = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      endDateTime = null;
    } else {
      // Timed event combines date and time pickers.
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

    // Logic for editing an existing event.
    if (isEditing) {
      final existing = widget.existingEvent!;
      // Update properties of the persistent Hive object.
      existing.name = _nameController.text;
      existing.description = _descController.text;
      existing.date = startDateTime;
      existing.endDateTime = endDateTime;
      existing.linkedGoal = _selectedGoal;
      existing.allDay = _allDay;

      // Find the Hive key associated with the existing object reference.
      final key = widget.calendar.eventBox.keys.firstWhere(
        (k) => widget.calendar.eventBox.get(k) == existing,
        orElse: () => null,
      );
      // Save the updated object back to Hive.
      if (key != null) await widget.calendar.eventBox.put(key, existing);

      // Remove old data from EventController to prevent duplicates/stale data.
      widget.eventController.removeWhere((e) => e.title == existing.name);
    } 
    // Logic for creating a new event.
    else {
      final newEvent = Event(
        name: _nameController.text,
        description: _descController.text,
        date: startDateTime,
        endDateTime: endDateTime,
        linkedGoal: _selectedGoal,
      );

      // Add the new event to Hive.
      await widget.calendar.addEvent(event: newEvent);
    }

    // Add the new/updated event data to the EventController for UI display.
    widget.eventController.add(
      CalendarEventData(
        date: startDateTime,
        startTime: startDateTime,
        endTime: endDateTime,
        title: _nameController.text,
        description: _descController.text,
      ),
    );

    // Close the screen upon completion.
    if (mounted) Navigator.pop(context, true);
  }

  /// Displays a confirmation dialog and deletes the event from Hive and the controller.
  Future<void> _deleteEvent() async {
    if (!isEditing) return;

    // Show confirmation dialog.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This will permanently delete the event."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm Delete
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    // If deletion is not confirmed, return.
    if (confirm != true) return;

    final existing = widget.existingEvent!;

    // Remove from Hive (Persistent Storage)
    final key = widget.calendar.eventBox.keys.firstWhere(
      (k) => widget.calendar.eventBox.get(k) == existing,
      orElse: () => null,
    );
    // Delete the event using its key.
    if (key != null) await widget.calendar.eventBox.delete(key);

    // Remove from controller so UI updates
    // Removes the event from the calendar view to instantly update the UI.
    widget.eventController.removeWhere((e) => e.title == existing.name);

    // Close the screen upon deletion.
    if (mounted) Navigator.pop(context, true);
  }
}