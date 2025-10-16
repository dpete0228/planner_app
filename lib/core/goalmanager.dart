import 'dart:io';
import 'package:csv/csv.dart';
import 'goal.dart';
import 'package:path_provider/path_provider.dart';

class GoalManager {
  List<Goal> availableGoals = [];
  late File file;

  GoalManager._();

  static Future<GoalManager> create() async {
    GoalManager gm = GoalManager._();
    final dir = await getApplicationDocumentsDirectory();

    final path = '${dir.path}/goals.csv';
    gm.file = File(path);
    await gm.loadFile();
    return gm;
  }

  Future<void> loadFile() async {
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('');
      availableGoals = [];
      return;
    }

    final csvString = await file.readAsString();
    if (csvString.isEmpty) {
      availableGoals = [];
      return;
    }

    final rows = const CsvToListConverter().convert(csvString);

    availableGoals = rows
        .map((row) => Goal(
              name: row[0].toString(),
              description: row[1].toString(),
            ))
        .toList();
  }

  Future<void> saveFile() async {
    List<List<dynamic>> rows = availableGoals.map((goal) => goal.toCsvRow()).toList();
    String csv = const ListToCsvConverter().convert(rows);

    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsString(csv);
    print("Goals saved.");
  }

  /// Creates a new goal by prompting the user for input in the terminal.
  /// - Uses [Goal.fromUserInput()] to interactively build a new goal.
  /// - Ensures no duplicate goal names are added.
  /// - Automatically saves the updated goal list to file.
  void createGoal() {
    // Collect goal data interactively
    Goal goal = Goal.fromUserInput();

    // Avoid duplicate goals based on name
    if (!availableGoals.any((i) => i.name == goal.name)) {
      availableGoals.add(goal);
    }

    saveFile();
    print("Goal '${goal.name}' added successfully.");
  }
}
