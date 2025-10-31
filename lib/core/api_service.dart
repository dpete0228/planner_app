// api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event.dart'; // Ensure these models have fromJson/toJson methods
import 'goal.dart'; // Ensure these models have fromJson/toJson methods

class ApiService {
  // IMPORTANT: Replace this with the actual base URL of your Flask API.
  // If testing on a physical device, use your local machine's IP (e.g., http://192.168.1.10:5000).
  static const String _baseUrl = 'http://127.0.0.1:5000/api';

  final http.Client _client = http.Client();
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // =========================================================================
  // 🎯 GOAL API METHODS
  // =========================================================================

  /// Fetches all Goals from the remote database.
  Future<List<Goal>> fetchGoals() async {
    final response = await _client.get(Uri.parse('$_baseUrl/goals'));

    if (response.statusCode == 200) {
      final List<dynamic> goalJson = jsonDecode(response.body);
      return goalJson.map((json) => Goal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load goals. Status: ${response.statusCode}');
    }
  }

  /// Adds a new Goal to the remote database.
  Future<Goal> addGoal(Goal goal) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/goals/add'),
      headers: _headers,
      body: jsonEncode(goal.toJson()),
    );

    if (response.statusCode == 201) {
      // API should return the newly created goal with its assigned SQL ID.
      return Goal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to add goal. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Updates an existing Goal in the remote database (requires the Goal ID).
  Future<void> updateGoal(Goal goal) async {
    if (goal.id == null) throw Exception('Cannot update goal: ID is required.');

    final response = await _client.put(
      Uri.parse('$_baseUrl/goals/${goal.id}'),
      headers: _headers,
      body: jsonEncode(goal.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update goal. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Deletes a Goal from the remote database (requires the Goal ID).
  Future<void> deleteGoal(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/goals/$id'));

    if (response.statusCode != 204) {
      // 204 No Content is standard for successful deletion
      throw Exception('Failed to delete goal. Status: ${response.statusCode}');
    }
  }

  // =========================================================================
  // 📅 EVENT API METHODS
  // =========================================================================

  /// Fetches all Events from the remote database.
  Future<List<Event>> fetchEvents() async {
    final response = await _client.get(Uri.parse('$_baseUrl/events'));

    if (response.statusCode == 200) {
      final List<dynamic> eventJson = jsonDecode(response.body);
      // Ensure Event.fromJson can handle linked goal data or null.
      return eventJson.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events. Status: ${response.statusCode}');
    }
  }

  /// Adds a new Event to the remote database.
  Future<Event> addEvent(Event event) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/add'),
      headers: _headers,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 201) {
      // API should return the newly created event with its assigned SQL ID.
      return Event.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to add event. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Updates an existing Event in the remote database (requires the Event ID).
  Future<void> updateEvent(Event event) async {
    if (event.id == null)
      throw Exception('Cannot update event: ID is required.');

    final response = await _client.put(
      Uri.parse('$_baseUrl/events/${event.id}'),
      headers: _headers,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update event. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  /// Deletes an Event from the remote database (requires the Event ID).
  Future<void> deleteEvent(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/events/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete event. Status: ${response.statusCode}');
    }
  }
}
