import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';
import 'edit_event_screen.dart'; // <-- Make sure you create this file next

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Calendar calendar;
  bool loading = true;
  final EventController eventController = EventController();

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final c = await Calendar.create();
    setState(() {
      calendar = c;
      loading = false;
    });

    // Load events into controller
    calendar.events.forEach((date, events) {
      for (var event in events) {
        eventController.add(
          CalendarEventData(
            date: event.date,
            title: event.name,
            description: event.description,
          ),
        );
      }
    });
  }

  // When returning from the EventScreen, reload the events
  Future<void> _refreshCalendar() async {
    setState(() {
      loading = true;
    });
    await _loadCalendar();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Calendar")),
      body: DayView(
        controller: eventController,
        heightPerMinute: 1,
        showVerticalLine: true,
        onEventTap: (events, date) {
          if (events.isNotEmpty) {
            final tappedEvent = events.first;
            final event = calendar.getEventByName(tappedEvent.title);
            if (event != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventScreen(
                    calendar: calendar,
                    eventController: eventController,
                  ),
                ),
              ).then((_) => _refreshCalendar());
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditEventScreen(calendar: calendar, eventController: eventController),
            ),
          );
          _refreshCalendar();
        },
      ),
    );
  }
}
