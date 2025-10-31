// calendar_app/lib/core/goal.dart (API-compatible version - NO HIVE)

import 'package:flutter/material.dart';

class Goal {
  // ID is now only used for the API and is nullable for new goals.
  final int? id;

  String name;
  String description;
  // This will be stored as 'completionDate' in the API JSON.
  DateTime? completionDate;
  // Store as an integer value to be sent to/from the API.
  int color;

  Goal({
    this.id,
    required this.name,
    required this.description,
    this.completionDate,
    // Store as int internally for simplicity with API calls
    required this.color,
  });

  // --- JSON Deserialization (Reading from API) ---

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      completionDate:
          json['completionDate'] != null && json['completionDate'] is String
          ? DateTime.tryParse(json['completionDate'] as String)
          : null,
      color: json['color'] as int? ?? Colors.blue.value,
    );
  }

  // --- JSON Serialization (Sending to API) ---

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'completionDate': completionDate?.toIso8601String(),
      'color': color,
    };
  }
}
