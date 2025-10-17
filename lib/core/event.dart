import 'package:hive/hive.dart';
import 'goal.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  DateTime date; // Start time

  @HiveField(1)
  DateTime? endDateTime; // Optional end time

  @HiveField(2)
  String name;

  @HiveField(3)
  String description;

  @HiveField(4)
  Goal? linkedGoal;

  Event({
    required this.date,
    this.endDateTime,
    required this.name,
    required this.description,
    this.linkedGoal,
  });
}
