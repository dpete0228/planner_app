// event.dart (Replaced Hive with JSON serialization)
import 'goal.dart'; // Import the linked Goal model.

/// A data model representing a calendar event, designed for API interaction.
class Event {
  // Use 'id' for the SQL primary key, which will be returned by the API.
  final int? id;

  String name;
  String description;
  DateTime date;
  DateTime? endDateTime;
  bool allDay;
  Goal? linkedGoal;
  // NOTE: This field is REQUIRED for GoalDetailScreen functionality.
  bool? isCompleted;

  Event({
    this.id,
    required this.name,
    required this.description,
    required this.date,
    this.endDateTime,
    this.allDay = false,
    this.linkedGoal,
    this.isCompleted = false, // Initialize as false
  });

  // Factory to create an Event from a JSON map (API response).
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      allDay: json['allDay'] ?? false,
      // Note: Goal linking will require fetching the goal object separately or embedding it in the API response.
      // For now, we assume the API sends back the goal ID or null.
      // The Flask API implementation determines how this link is handled.
    );
  }

  // Method to convert the Event object to a JSON map for API POST/PUT requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'allDay': allDay,
      // For linking, send the goal's ID, not the whole object.
      'linked_goal_id': linkedGoal?.id,
    };
  }
}
