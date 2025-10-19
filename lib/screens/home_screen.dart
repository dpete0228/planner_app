import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../core/calendar.dart';
import '../core/event.dart';
import '../core/goal.dart';
import 'edit_event_screen.dart';
import 'goal_screen.dart';
import 'goal_tracker_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Calendar calendar;
  bool loading = true;
  late EventController eventController;
  MinuteSlotSize currentSlotSize = MinuteSlotSize.minutes60;
  int _currentIndex = 0; // 0 = Calendar, 1 = Goals, 2 = Goal Tracker

  // Track the currently displayed date in DayView
  DateTime _currentDisplayedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    eventController = EventController();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final c = await Calendar.create();
    calendar = c;
    _refreshEventController();
    setState(() => loading = false);
  }

  void _refreshEventController() {
    if (eventController.events.isNotEmpty) {
      eventController.removeAll(
        List<CalendarEventData>.from(eventController.events),
      );
    }

    for (var event in calendar.allEvents) {
      eventController.add(
        CalendarEventData(
          date: event.date,
          startTime: event.date,
          endTime: event.endDateTime ?? event.date.add(const Duration(hours: 1)),
          title: event.name,
          description: event.description,
          // Flag all-day events if endDateTime is null
          // allDay: event.endDateTime == null,
        ),
      );
    }
  }

  void toggleSlotSize() {
    setState(() {
      if (currentSlotSize == MinuteSlotSize.minutes60) {
        currentSlotSize = MinuteSlotSize.minutes30;
      } else if (currentSlotSize == MinuteSlotSize.minutes30) {
        currentSlotSize = MinuteSlotSize.minutes15;
      } else {
        currentSlotSize = MinuteSlotSize.minutes60;
      }
    });
  }

  String getSlotSizeLabel() {
    switch (currentSlotSize) {
      case MinuteSlotSize.minutes60:
        return '60m';
      case MinuteSlotSize.minutes30:
        return '30m';
      case MinuteSlotSize.minutes15:
        return '15m';
      default:
        return '';
    }
  }

  double getHeightPerMinute() {
    switch (currentSlotSize) {
      case MinuteSlotSize.minutes60:
        return 2.5;
      case MinuteSlotSize.minutes30:
        return 5.0;
      case MinuteSlotSize.minutes15:
        return 10.0;
      default:
        return 2.0;
    }
  }

  bool showHalfHours() => currentSlotSize != MinuteSlotSize.minutes60;
  bool showQuarterHours() => currentSlotSize == MinuteSlotSize.minutes15;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      _buildCalendarView(),
      const GoalScreen(),
      const GoalTrackerScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final midnight = DateTime(
                  _currentDisplayedDate.year,
                  _currentDisplayedDate.month,
                  _currentDisplayedDate.day,
                  0,
                  0,
                );

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventScreen(
                      calendar: calendar,
                      eventController: eventController,
                      initialDate: midnight,
                    ),
                  ),
                );
                _loadCalendar();
              },
            )
          : null,
    );
  }

  Widget _buildCalendarView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Calendar"),
        actions: [
          GestureDetector(
            onTap: toggleSlotSize,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.grid_view, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    getSlotSizeLabel(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: DayView<Object?>(
        key: ValueKey(currentSlotSize),
        controller: eventController,
        heightPerMinute: getHeightPerMinute(),
        showVerticalLine: true,
        minuteSlotSize: currentSlotSize,
        showHalfHours: showHalfHours(),
        showQuarterHours: showQuarterHours(),
        hourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        halfHourIndicatorSettings:
            const HourIndicatorSettings(color: Colors.grey),
        quarterHourIndicatorSettings:
            const HourIndicatorSettings(color: Colors.grey),
        dateStringBuilder: (date, {secondaryDate}) =>
            DateFormat('EEEE, MMM d, yyyy').format(date),
        timeStringBuilder: (time, {secondaryDate}) =>
            DateFormat('h:mm a').format(time),

        /// Track currently displayed date
        onPageChange: (date, pageIndex) {
          setState(() {
            _currentDisplayedDate = date;
          });
        },

        /// Tap empty timeslot
        onDateTap: (date) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditEventScreen(
                calendar: calendar,
                eventController: eventController,
                initialDate: date,
              ),
            ),
          );
          _loadCalendar();
        },

        /// Tap existing event
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
              _loadCalendar();
            }
          }
        },

        /// Full-day events show at the top row
        fullDayEventBuilder: (events, date) {
          if (events.isEmpty) return const SizedBox.shrink();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: events.map((event) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
