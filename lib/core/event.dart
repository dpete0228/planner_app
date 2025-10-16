import 'goal.dart';

/// Represents an event that can optionally be linked to a goal.
/// Each event includes a date, name, and description, and may
/// be created interactively or programmatically.
class Event {
  /// The date and time when the event occurs.
  DateTime date;
  /// A short title or name describing the event.
  String name;
  /// Additional details about what the event is or involves.
  String description;
  /// An optional [Goal] that this event is associated with.
  Goal? linkedGoal;

  /// Constructor that allows direct initialization of an event.
  Event({
    required this.date,
    required this.name,
    required this.description,
    this.linkedGoal,
  });


  /// Converts the event data into a list of strings
  /// that can easily be written to a CSV file.
  ///
  /// If the event has an associated [linkedGoal],
  /// its name and description are also included.
  List<String> toCsvRow() {
    if (linkedGoal != null) {
      return [
        date.toString(),
        name,
        description,
        linkedGoal!.name,
        linkedGoal!.description
      ];
    }

    // For events without a linked goal
    return [date.toString(), name, description];
  }

  /// Reads event data from a CSV row (a list of dynamic values)
  /// Returns a list of values representing the parsed data.
  List<dynamic> fromCsvRow(List<dynamic> row) {
    // Parse the date from the first column
    date = DateTime.parse(row[0]);

    // Assign name and description from the next columns
    name = row[1].toString();
    description = row[2];

    // If the CSV row contains at least 5 elements,
    // assume the last two are the linked goal's details
    if (row.length >= 5) {
      var goalName = row[3];
      var goalDescription = row[4];
      linkedGoal = Goal(name: goalName, description: goalDescription);

      return [
        date,
        name,
        description,
        linkedGoal!.name,
        linkedGoal!.description
      ];
    }

    // If no linked goal information is present, return basic event info
    return [date, name, description];
  }

  /// Returns a human-readable formatted string of the event's date and time.
  /// Example output: `2025-10-04 at 14:30`
  String formattedDate() {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} at '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
