// calendar_app/lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import the main screen of the application.

/// The entry point of the application. It is no longer asynchronous.
void main() {
  // Ensures that Flutter is initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const HomeScreen(),
    );
  }
}
