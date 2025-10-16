import 'dart:io';
import 'package:csv/csv.dart';
import 'event.dart';
import 'goalmanager.dart';
import 'package:path_provider/path_provider.dart';

class Calendar {
  Map<DateTime, List<Event>> events = {};
  late File file;
  late GoalManager goalManager;

  Calendar._();

  static Future<Calendar> create() async {
    Calendar calendar = Calendar._();

    // Get the app documents directory
    final dir = await getApplicationDocumentsDirectory();

    // Initialize file path
    calendar.file = File('${dir.path}/events.csv');

    // Initialize GoalManager first
    calendar.goalManager = await GoalManager.create();

    // Load events AFTER goalManager is ready
    await calendar.loadFile();
  

    return calendar;
  }

  Future<void> loadFile() async {
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('');
      events = {};
      return;
    }

    final csvString = await file.readAsString();
    if (csvString.isEmpty) return;

    final rows = const CsvToListConverter().convert(csvString);

    for (var row in rows) {
      var event = Event(date: DateTime.now(), name: '', description: '');
      event.fromCsvRow(row);

      final dateKey = DateTime(event.date.year, event.date.month, event.date.day);
      events.putIfAbsent(dateKey, () => []).add(event);
    }
  }

  Future<void> saveFile() async {
    List<List<dynamic>> rows = [];
    for (var dayEvents in events.values) {
      for (var event in dayEvents) {
        rows.add(event.toCsvRow());
      }
    }
    String csv = const ListToCsvConverter().convert(rows);

    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsString(csv);
    print("File saved.");
  }

  void addEvent() {
    stdout.write('Enter event name: ');
    var name = stdin.readLineSync() ?? '';

    stdout.write('Enter event description: ');
    var description = stdin.readLineSync() ?? '';

    DateTime? parsedDate;
    while (parsedDate == null) {
      stdout.write('Enter event date (YYYY-MM-DD HH:MM): ');
      String? input = stdin.readLineSync();
      try {
        parsedDate = DateTime.parse(input ?? '');
      } catch (e) {
        print('Invalid date format. Please try again.');
      }
    }

    final date = parsedDate!;
    final dateKey = DateTime(date.year, date.month, date.day);

    stdout.write('Do you want to link a goal to this one? (Yes/No): ');
    String? input = stdin.readLineSync();
    input = input?.trim().toLowerCase();

    var linkedGoal;

    if (input == 'yes' || input == 'y') {
      print("\nAvailable goals:");
      for (var i = 0; i < goalManager.availableGoals.length; i++) {
        print("${i + 1}) ${goalManager.availableGoals[i].name}");
      }
      print("${goalManager.availableGoals.length + 1}) Create New Goal");

      bool validChoice = false;
      while (!validChoice) {
        stdout.write("Which goal do you want? ");
        String? choiceInput = stdin.readLineSync();
        int? choice = int.tryParse(choiceInput ?? '');

        if (choice == null ||
            choice < 1 ||
            choice > goalManager.availableGoals.length + 1) {
          print("Invalid choice. Try again.");
          continue;
        }

        if (choice == goalManager.availableGoals.length + 1) {
          goalManager.createGoal();
          linkedGoal = goalManager.availableGoals.last;
        } else {
          linkedGoal = goalManager.availableGoals[choice - 1];
        }

        validChoice = true;
      }

      print('Goal linked.');
    } else {
      print('No goal linked.');
      linkedGoal = null;
    }

    Event tempEvent = Event(
      date: date,
      name: name,
      description: description,
      linkedGoal: linkedGoal,
    );

    events.putIfAbsent(dateKey, () => []).add(tempEvent);
    saveFile();
  }

  void removeEvent(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);

    if (!events.containsKey(dateKey) || events[dateKey]!.isEmpty) {
      print("No events found for that day.");
      return;
    }

    var dayEvents = events[dateKey]!;

    for (var i = 0; i < dayEvents.length; i++) {
      print('${i + 1}) ${dayEvents[i].name}');
    }

    stdout.write('Select an event to remove: ');
    String? input = stdin.readLineSync();
    int index = int.tryParse(input ?? '') ?? -1;

    if (index < 1 || index > dayEvents.length) {
      print('Invalid selection.');
      return;
    }

    dayEvents.removeAt(index - 1);

    if (dayEvents.isEmpty) events.remove(dateKey);

    saveFile();
    print("Event removed.");
  }

  void listEvents(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);

    if (!events.containsKey(dateKey) || events[dateKey]!.isEmpty) {
      print('No events found for ${dateKey.toLocal()}.');
      return;
    }

    for (var event in events[dateKey]!) {
      final goalInfo = event.linkedGoal != null
          ? ' (Goal: ${event.linkedGoal!.name})'
          : '';
      print('${event.formattedDate()}: ${event.name}$goalInfo');
    }
  }

  Event? getEventByName(String name) {
  for (var eventList in events.values) {
    for (var event in eventList) {
      if (event.name == name) {
        return event;
      }
    }
  }
  return null;
}

}
