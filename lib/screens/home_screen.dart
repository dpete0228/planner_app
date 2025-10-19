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
  int _currentIndex = 0;
  DateTime _currentDisplayedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    eventController = EventController();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    calendar = await Calendar.create();
    _refreshEventController();
    setState(() => loading = false);
  }

  void _refreshEventController() {
    eventController.removeAll(List<CalendarEventData>.from(eventController.events));

    for (var event in calendar.allEvents) {
      final bgColor = event.linkedGoal?.color != null
          ? Color(event.linkedGoal!.color)
          : Colors.blue;

      eventController.add(
        CalendarEventData(
          date: event.date,
          startTime: event.date,
          endTime: event.allDay ? null : (event.endDateTime ?? event.date.add(const Duration(hours: 1))),
          title: event.name,
          description: event.description,
          color: bgColor,
          titleStyle: const TextStyle(
            height: 0.5,
            color: Colors.white,
            fontSize: 20,
          ),
          descriptionStyle: const TextStyle(
            height: 1,
            color: Color.fromARGB(184, 255, 255, 255),
          ),
        ),
      );
    }
  }

  void toggleSlotSize() {
    setState(() {
      currentSlotSize = currentSlotSize == MinuteSlotSize.minutes60
          ? MinuteSlotSize.minutes30
          : currentSlotSize == MinuteSlotSize.minutes30
              ? MinuteSlotSize.minutes15
              : MinuteSlotSize.minutes60;
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
    }
  }

  double getHeightPerMinute() {
    switch (currentSlotSize) {
      case MinuteSlotSize.minutes60:
        return 1.5;
      case MinuteSlotSize.minutes30:
        return 3.0;
      case MinuteSlotSize.minutes15:
        return 10.0;
    }
  }

  bool showHalfHours() => currentSlotSize != MinuteSlotSize.minutes60;
  bool showQuarterHours() => currentSlotSize == MinuteSlotSize.minutes15;

  Future<void> _pickDateFromMonthView() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentDisplayedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() => _currentDisplayedDate = selectedDate);
    }
  }

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
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            // Calendar Icon with larger invisible touch area
            GestureDetector(
              onTap: _pickDateFromMonthView,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.transparent,
                child: const Icon(Icons.calendar_today, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Today button
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentDisplayedDate = DateTime.now();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Slot size toggle icon with larger touch area
          GestureDetector(
            onTap: toggleSlotSize,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.grid_view, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    getSlotSizeLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: DayView<Object?>(
        key: ValueKey(_currentDisplayedDate), // rebuild when date changes
        controller: eventController,
        heightPerMinute: getHeightPerMinute(),
        showVerticalLine: true,
        minuteSlotSize: currentSlotSize,
        showHalfHours: showHalfHours(),
        showQuarterHours: showQuarterHours(),
        initialDay: _currentDisplayedDate,
        hourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        halfHourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        quarterHourIndicatorSettings: const HourIndicatorSettings(color: Colors.grey),
        dateStringBuilder: (date, {secondaryDate}) => DateFormat('EEEE, MMM d, yyyy').format(date),
        timeStringBuilder: (time, {secondaryDate}) => DateFormat('h:mm a').format(time),
        onPageChange: (date, pageIndex) {
          setState(() => _currentDisplayedDate = date);
        },
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
        fullDayEventBuilder: (events, date) {
          if (events.isEmpty) return const SizedBox.shrink();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: events.map((event) {
                final realEvent = calendar.getEventByName(event.title);
                final bgColor = realEvent?.linkedGoal?.color != null
                    ? Color(realEvent!.linkedGoal!.color)
                    : Colors.blue;

                return GestureDetector(
                  onTap: () {
                    if (realEvent != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(
                            calendar: calendar,
                            eventController: eventController,
                            existingEvent: realEvent,
                          ),
                        ),
                      ).then((_) => _loadCalendar());
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.title,
                      style: const TextStyle(color: Colors.white),
                    ),
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
