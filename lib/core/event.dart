// event.dart (Replaced Hive with JSON serialization)
import 'goal.dart'; // Import the linked Goal model.
import 'api_service.dart';

/// A data model representing a calendar event, designed for API interaction.
class Event {
  // Use 'id' for the SQL primary key, which will be returned by the API.
  int? id;

  String name;
  String? description;
  DateTime date;
  DateTime? endDateTime;
  bool allDay;
  int? goalId;
  Goal? linkedGoal;
  // NOTE: This field is REQUIRED for GoalDetailScreen functionality.
  bool isCompleted;
  String? recurrenceSettings;

  Event({
    this.id,
    required this.name,
    required this.description,
    required this.date,
    this.endDateTime,
    this.allDay = false,
    this.linkedGoal,
    this.isCompleted = false, // Initialize as false
    this.recurrenceSettings = null, // initialize as false
    this.goalId,
  });

  // Factory to create an Event from a JSON map (API response).
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      endDateTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      isCompleted: json['isCompleted'] != 0,
      allDay: json['allDay'] !=1
        ? false
        : true,
      recurrenceSettings: json['recurrenceSettings'],
      goalId: json['goalId'],
      // Note: Goal linking will require fetching the goal object separately or embedding it in the API response.
      // For now, we assume the API sends back the goal ID or null.
      // The Flask API implementation determines how this link is handled.
    );
  }
  static Future<Event> fromJsonWithGoal(Map<String, dynamic> json) async {
    final apiService = ApiService();
    final event = Event.fromJson(json);
    if (event.goalId != null) {
      event.linkedGoal = await apiService.getGoalById(event.goalId!);
    }
    return event;
  }

  void updateId(Map<String, dynamic> json){
    id = json['id'] as int?;
  }
  // Method to convert the Event object to a JSON map for API POST/PUT requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'endTime': endDateTime?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,  // convert bool to int here
      'allDay': allDay,
      // For linking, send the goal's ID, not the whole object.
      'goalId': linkedGoal?.id,
      'recurrenceSettings': recurrenceSettings,
    };
  }
}
