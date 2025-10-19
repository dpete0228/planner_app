// The comments in this code were written by an AI assistant.

import 'package:hive/hive.dart'; // Import Hive for asynchronous, non-relational database operations.
import 'goal.dart'; // Import the Goal model, which includes the Hive TypeAdapter.

/// A service class responsible for managing persistent storage operations for Goal objects using Hive.
/// It uses a factory pattern to ensure the Hive box is open before the manager is used.
class GoalManager {
  // Constant string used as the name for the Hive box dedicated to goals.
  static const String boxName = 'goalsBox';
  // Late initialization for the actual Hive box instance.
  late Box<Goal> _goalBox;

  // Private constructor prevents direct instantiation, enforcing the factory pattern.
  GoalManager._();

  /// Factory to initialize GoalManager with Hive box.
  /// This asynchronous method ensures the required Hive box is open before returning the instance.
  static Future<GoalManager> create() async {
    final manager = GoalManager._();
    // Open the goals box. If it's already open, Hive returns the existing instance.
    manager._goalBox = await Hive.openBox<Goal>(boxName);
    return manager;
  }

  //--------------------------------------------------------------------------------------------------
  // Public Accessors
  //--------------------------------------------------------------------------------------------------

  /// Getter that returns all Goal objects stored in the Hive box as a list.
  List<Goal> get availableGoals => _goalBox.values.toList();

  //--------------------------------------------------------------------------------------------------
  // CRUD Operations
  //--------------------------------------------------------------------------------------------------

  /// Add a new goal to the Hive box.
  /// Uses a check to prevent adding goals with duplicate names.
  Future<void> addGoal(Goal goal) async {
    // Check if any existing goal has the same name.
    if (!availableGoals.any((g) => g.name == goal.name)) {
      // Use .add() for auto-incrementing integer keys.
      await _goalBox.add(goal);
    }
  }

  /// Remove a goal from the Hive box by its unique name.
  Future<void> removeGoal(String name) async {
    // Find the internal Hive key (int) of the goal that matches the given name.
    final key = _goalBox.keys.firstWhere(
      (k) => (_goalBox.get(k)?.name == name),
      // If no matching goal is found, orElse returns null.
      orElse: () => null,
    );
    // If a key is found, delete the entry associated with that key.
    if (key != null) await _goalBox.delete(key);
  }

  /// Retrieve a single goal by its name.
  Goal? getGoalByName(String name) {
    try {
      // Use firstWhere to find the goal with the matching name.
      return _goalBox.values.firstWhere((g) => g.name == name);
    } catch (_) {
      // If firstWhere doesn't find a match, it throws a StateError, which is caught here.
      return null;
    }
  }

  /// Update an existing goal by finding it with its old name and replacing it with the new object.
  Future<void> updateGoal(String oldName, Goal updatedGoal) async {
    // Find the internal Hive key of the goal to be updated.
    final key = _goalBox.keys.firstWhere(
      (k) => (_goalBox.get(k)?.name == oldName),
      orElse: () => null,
    );
    // If the existing goal is found (key is not null), use .put() to replace the value at that key.
    if (key != null) {
      await _goalBox.put(key, updatedGoal);
    }
  }

  /// Clear all entries from the goal Hive box.
  Future<void> clearAll() async => await _goalBox.clear();
}