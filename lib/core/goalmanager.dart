// goal_manager.dart (Rewritten to use ApiService)

import 'goal.dart';
import 'api_service.dart'; // Core dependency

/// A service class responsible for managing Goal objects via the remote API.
class GoalManager {
  final ApiService _api = ApiService();

  GoalManager._();

  /// Factory to initialize GoalManager.
  static Future<GoalManager> create() async {
    // No Hive box to open, initialization is instant.
    return GoalManager._();
  }

  //----------------------------------------------------------------------
  // Public Accessors
  //----------------------------------------------------------------------

  /// Asynchronously fetches all Goal objects from the remote API.
  Future<List<Goal>> fetchAvailableGoals() async {
    return _api.fetchGoals();
  }

  //----------------------------------------------------------------------
  // CRUD Operations
  //----------------------------------------------------------------------

  /// Add a new goal to the remote API.
  void addGoal(Goal goal) async {
    // The API service returns the created goal (with its new ID).
    // Note: Duplicate checking should ideally be done by the API/SQL database constraint.
    _api.addGoal(goal);
  }

  /// Remove a goal from the remote API using its ID.
  Future<void> removeGoal(Goal goal) async {
    if (goal.id == null) throw Exception('Cannot remove goal: ID is missing.');
    await _api.deleteGoal(goal.id!);
  }

  /// Retrieve a single goal by its name (using local filtering after fetch).
  Future<Goal?> getGoalByName(String name) async {
    final allGoals = await _api.fetchGoals();
    try {
      return allGoals.firstWhere((g) => g.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Update an existing goal on the remote API.
  Future<void> updateGoal(Goal updatedGoal) async {
    await _api.updateGoal(updatedGoal);
  }
}
