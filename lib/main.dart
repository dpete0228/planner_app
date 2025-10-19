// The comments in this code were written by an AI assistant.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for persistent local storage in Flutter.
import 'core/event.dart'; // Import the Event model (which contains the Hive TypeAdapter).
import 'core/goal.dart'; // Import the Goal model (which contains the Hive TypeAdapter).
import 'screens/home_screen.dart'; // Import the main screen of the application.

/// The entry point of the application. It is asynchronous because it initializes Hive.
void main() async {
  // Ensures that Flutter is initialized before running the app or any plugin initialization.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive's local database storage for Flutter projects.
  await Hive.initFlutter();

  // Register the TypeAdapters for custom objects (Event and Goal) so Hive knows how to read/write them.
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(GoalAdapter());
  
  // Open the specific data "boxes" (tables) in Hive for persistent storage.
  await Hive.openBox<Event>('eventsBox');
  await Hive.openBox<Goal>('goalsBox');
  
  // Uncomment below to remove events from hive.
  // This section is commented out but provides a utility to clear all data in the boxes.

  // final goalsBox = Hive.box<Goal>('goalsBox');
  // final eventsBox = Hive.box<Event>('eventsBox');
  // await goalsBox.clear();
  // await eventsBox.clear();

  // Run the main Flutter application widget.
  runApp(const MyApp());
}

/// The root widget of the application, defining the overall look and feel.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up the fundamental building blocks (routing, themes, etc.).
    return MaterialApp(
      title: 'Calendar App',
      // Define the application's primary color theme.
      theme: ThemeData(primarySwatch: Colors.blue),
      // Set the initial screen the user sees.
      home: HomeScreen(),
    );
  }
}