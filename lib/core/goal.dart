// The comments in this code were written by an AI assistant.
// This data model was originally designed for CSV storage and was reworked
// by an AI to integrate with Hive, a fast NoSQL database for Flutter.

import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Required for the Color class.

// Specifies the generated part file that Hive uses for adapters and type registration.
part 'goal.g.dart';

/// A data model representing a long-term goal, designed for persistent storage using Hive.
/// It tracks the goal's details and an associated color for visual identification.
@HiveType(typeId: 1) // Assigns a unique type ID (1) for this specific Hive object type.
class Goal extends HiveObject {
  
  // HiveField(0): Stores the name of the goal.
  @HiveField(0)
  String name; // The required, descriptive name of the goal.

  // HiveField(1): Stores a detailed description of the goal.
  @HiveField(1)
  String description; // Detailed description of what the goal entails.

  // HiveField(2): Stores the ARGB color value as an integer.
  @HiveField(2)
  int color = 0xFF2196F3; // The color associated with the goal (default is Flutter Blue).

  // Constructor for creating a new Goal instance.
  Goal({
    required this.name, // Requires a name.
    required this.description, // Requires a description.
    this.color = 0xFF2196F3, // Initializes with the default blue color if not provided.
  });

  /// Helper getter to convert the stored integer ARGB value into a Flutter Color object.
  Color get flutterColor => Color(color); // Allows easy access to the Color object in Flutter widgets.
}