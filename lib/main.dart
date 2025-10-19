import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/event.dart';
import 'core/goal.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(GoalAdapter());
  // Open boxes
  await Hive.openBox<Event>('eventsBox');
  await Hive.openBox<Goal>('goalsBox');
  
  // Uncomment below to remove events from hive.

  // final goalsBox = Hive.box<Goal>('goalsBox');
  // final eventsBox = Hive.box<Event>('eventsBox');
  // await goalsBox.clear();
  // await eventsBox.clear();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
