import 'dart:io';

/// Represents a single goal or indicator within the application.
/// 
/// A goal consists of:
/// - A name: short descriptive title of the goal.
/// - A description details about what the goal is or how it’s measured.
///
/// This class supports user input creation and CSV import/export for persistence.
class Goal {
  /// The short name or title of the goal.
  String name = '';

  /// A brief description explaining the goal’s purpose or meaning.
  String description = '';

  /// Standard constructor for initializing a goal directly.
  Goal({
    required this.name,
    required this.description,
  });

  /// Named constructor that allows the user to create a goal interactively
  /// via terminal input.
  /// Prompts the user for both a name and a description.
  Goal.fromUserInput()
      : name = '',
        description = '' {
    // Ask for the goal name
    stdout.write('Enter indicator name: ');
    name = stdin.readLineSync() ?? '';

    // Ask for the goal description
    stdout.write('Enter indicator description: ');
    description = stdin.readLineSync() ?? '';
  }

  /// Populates the goal’s data fields from a row in a CSV file.
  /// Returns a list containing the parsed goal name.
  List<dynamic> fromCsvRow(List<dynamic> row) {
    name = row[1].toString();
    description = row[2].toString();
    return [name];
  }

  /// Converts the goal data into a list of strings for CSV writing.
  /// Returns a two-element list containing:
  /// `[name, description]`
  List<String> toCsvRow() {
    return [name, description];
  }
}
