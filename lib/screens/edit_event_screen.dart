// calendar_app/lib/screens/edit_event_screen.dart (Rewritten to use ApiService)

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart'; // New dependency for remote data calls
import '../core/event.dart'; // Custom API-backed Event data model.
import '../core/goal.dart'; // Custom API-backed Goal data model for linking.

/// A screen for creating a new calendar event or editing an existing one,
/// managing data via a remote API service.
class EditEventScreen extends StatefulWidget {
  // Required: The controller to update the CalendarView UI after save/delete.
  final EventController eventController;
  // Optional: The event object to be edited (determines 'isEditing' state).
  final Event? existingEvent;
  // Optional: The initial date to pre-select when creating a new event.
  final DateTime? initialDate;

  const EditEventScreen({
    super.key,
    // Removed: required this.calendar,
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
  // API Service instance for all CRUD operations
  final ApiService _apiService = ApiService();

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

  // Data Source variables
  List<Goal> _goalOptions = [];
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
    // The existingEvent already holds the full Goal object from the API fetch.
    _selectedGoal = existing?.linkedGoal;

    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
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

    // Start loading goals from the API.
    _loadGoals();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Fetches available Goal objects from the API and updates the loading state.
  Future<void> _loadGoals() async {
    try {
      // Fetch goals from the remote API.
      _goalOptions = await _apiService.fetchGoals();

      // Ensure the selected goal (if one exists) is the one we loaded from the API list.
      if (_selectedGoal != null) {
        _selectedGoal = _goalOptions.firstWhere(
          (g) => g.id == _selectedGoal!.id,
          orElse: () =>
              null!, // If not found (e.g., goal was deleted), set to null.
        );
      }
    } catch (e) {
      print("Error loading goals from API: $e");
    } finally {
      // Update UI once goals are loaded.
      if (mounted) setState(() => _loadingGoals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while goals are being fetched from the API.
    if (_loadingGoals) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

              // Start Time Picker ListTile
              ListTile(
                title: Text(
                  "Start Time: ${_allDay ? '--:--' : _startTime.format(context)}",
                ),
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
                            // Recalculate end time (30 min after start, handling day wrap).
                            _endTime = TimeOfDay(
                              hour:
                                  (picked.hour +
                                      (((picked.minute + 30) ~/ 60))) %
                                  24,
                              minute: (picked.minute + 30) % 60,
                            );
                          });
                        }
                      }
                    : null,
              ),

              // End Time Picker ListTile (Now a tap target for time adjustment)
              ListTile(
                title: Text(
                  "End Time: ${_allDay ? '--:--' : (_endTime ?? _startTime).format(context)}",
                ),
                trailing: const Icon(Icons.access_time),
                enabled: !_allDay,
                onTap: !_allDay
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? _startTime,
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Linked Goal Dropdown
              DropdownButtonFormField<int?>(
                // Use the Goal ID as the value.
                value: _selectedGoal?.id,
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
                  // Map goals to dropdown items using their API ID.
                  ..._goalOptions.map(
                    (goal) => DropdownMenuItem<int?>(
                      value: goal.id,
                      child: Text(goal.name),
                      // Use the goal's color for the text if desired, or a color swatch icon.
                    ),
                  ),
                ],
                onChanged: (newId) {
                  setState(() {
                    // Find the Goal object from the local list using the ID.
                    _selectedGoal = newId != null
                        ? _goalOptions.firstWhere((g) => g.id == newId)
                        : null;
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _deleteEvent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handles form validation, date/time construction, and saving/updating the event via API.
  Future<void> _saveEvent() async {
    // Validate the form fields.
    if (!_formKey.currentState!.validate()) return;

    DateTime startDateTime;
    DateTime? endDateTime;

    // 1. Construct DateTime objects
    if (_allDay) {
      startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
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
      // Handle cross-day event logic (end time before start time means it crosses midnight)
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
    }

    // 2. Create the Event model instance for API
    final eventToSave = Event(
      // CRITICAL: Include the ID only if editing.
      id: widget.existingEvent?.id,
      name: _nameController.text,
      description: _descController.text,
      date: startDateTime,
      endDateTime: endDateTime,
      linkedGoal: _selectedGoal, // The Goal object is passed
      allDay: _allDay,
    );

    Event finalEvent;

    // 3. Perform CRUD Operation via API
    if (isEditing) {
      await _apiService.updateEvent(eventToSave);
      finalEvent = eventToSave;
    } else {
      // API returns the newly created event with its assigned ID
      finalEvent = await _apiService.addEvent(eventToSave);
    }

    // 4. Update the Calendar Controller for UI refresh

    // Clear old event data from the controller if we updated an event.
    // We use the ID attached to the CalendarEventData's 'event' property.
    widget.eventController.removeWhere(
      (e) => (e.event as Event?)?.id == widget.existingEvent?.id,
    );

    // Add the final, up-to-date event data to the controller.
    widget.eventController.add(
      CalendarEventData<Event>(
        date: finalEvent.date,
        startTime: finalEvent.date,
        endTime: finalEvent.endDateTime,
        title: finalEvent.name,
        description: finalEvent.description,
        // CRITICAL: Attach the full Event model to the CalendarEventData
        event: finalEvent,
        // Use the Goal's color if linked, otherwise default to blue.
        color: finalEvent.linkedGoal?.color != null
            ? Color(finalEvent.linkedGoal!.color)
            : Colors.blue,
      ),
    );

    // Close the screen upon completion.
    if (mounted) Navigator.pop(context, true);
  }

  /// Displays a confirmation dialog and deletes the event via API.
  Future<void> _deleteEvent() async {
    if (!isEditing || widget.existingEvent?.id == null) return;

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

    if (confirm != true) return;

    final existingId = widget.existingEvent!.id!;

    // 1. Remove from remote API
    await _apiService.deleteEvent(existingId);

    // 2. Remove from controller so UI updates
    widget.eventController.removeWhere(
      (e) => (e.event as Event?)?.id == existingId,
    );

    // 3. Close the screen upon deletion.
    if (mounted) Navigator.pop(context, true);
  }
}
