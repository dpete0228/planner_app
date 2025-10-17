import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1) // Each class must have a unique typeId
class Goal extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  Goal({
    required this.name,
    required this.description,
  });

  /// Optional: convert Goal to CSV row
}
