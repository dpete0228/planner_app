import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';
import 'edit_event_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Calendar calendar;
  bool loading = true;
  late EventController eventController;

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final c = await Calendar.create();
    setState(() => calendar = c);

    eventController = EventController();

    for (var event in calendar.allEvents) {
      eventController.add(
        CalendarEventData(
          startTime: event.date,
          endTime: event.endDateTime,
          date: event.date,
          title: event.name,
          description: event.description,
        ),
      );
    }

    setState(() => loading = false);
  }

  Future<void> _refreshCalendar() async {
    setState(() => loading = true);
    await _loadCalendar();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Calendar")),
      body: DayView(
        controller: eventController,
        heightPerMinute: 1,
        showVerticalLine: true,
        onEventTap: (events, date) async {
          if (events.isNotEmpty) {
            final tappedEvent = events.first;
            final event = calendar.getEventByName(tappedEvent.title);
            if (event != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventScreen(
                    calendar: calendar,
                    eventController: eventController,
                    existingEvent: event,
                  ),
                ),
              );
              _refreshCalendar();
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
              builder: (_) => EditEventScreen(
                calendar: calendar,
                eventController: eventController,
              ),
            ),
          );
          _refreshCalendar();
        },
      ),
    );
  }
}
