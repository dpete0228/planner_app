import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'goal.g.dart';

@HiveType(typeId: 1) // Each class must have a unique typeId
class Goal extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  int color = 0xFF2196F3; // Store ARGB as int

  Goal({
    required this.name,
    required this.description,
    this.color = 0xFF2196F3, // Default blue
  });

  /// Helper to get Flutter Color
  Color get flutterColor => Color(color);
}
