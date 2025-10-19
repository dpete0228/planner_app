// The comments in this code were written by an AI assistant.
// This data model was originally designed for CSV storage and was reworked
// by an AI to integrate with Hive, a fast NoSQL database for Flutter.

import 'package:hive/hive.dart';
// Import the linked Goal model.
import 'goal.dart';

// Specifies the generated part file that Hive uses for adapters and type registration.
part 'event.g.dart';

/// A data model representing a calendar event, designed for persistent storage using Hive.
@HiveType(typeId: 0) // Assigns a unique type ID for Hive to recognize this object type.
class Event extends HiveObject {
  // HiveField(0): Stores the event's start date and time.
  @HiveField(0)
  DateTime date; // The required start time of the event.

  // HiveField(1): Stores the optional end date and time.
  @HiveField(1)
  DateTime? endDateTime; // Optional end time, null for open-ended or all-day events.

  // HiveField(2): Stores the name of the event.
  @HiveField(2)
  String name; // The required, descriptive name of the event.

  // HiveField(3): Stores a longer description of the event.
  @HiveField(3)
  String description; // Detailed description of the event or task.

  // HiveField(4): Stores a reference to a linked Goal object.
  @HiveField(4)
  Goal? linkedGoal; // Optional link to a Goal this event contributes to.

  // HiveField(5): Stores the completion status of the event/task.
  @HiveField(5)
  bool isCompleted = false; // Flag to track if the event/task has been finished.

  // HiveField(6): Stores whether the event is an all-day event.
  @HiveField(6)
  bool allDay = false; // Flag indicating if the event spans a full day without specific times.

  // Constructor for creating a new Event instance.
  Event({
    required this.date,
    this.endDateTime,
    required this.name,
    required this.description,
    this.linkedGoal,
  });
}