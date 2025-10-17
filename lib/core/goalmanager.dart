import 'package:hive/hive.dart';
import 'goal.dart';

class GoalManager {
  static const String boxName = 'goalsBox';
  late Box<Goal> _goalBox;

  GoalManager._();

  /// Factory to initialize GoalManager with Hive box
  static Future<GoalManager> create() async {
    final manager = GoalManager._();
    manager._goalBox = await Hive.openBox<Goal>(boxName);
    return manager;
  }

  /// All goals as a list
  List<Goal> get availableGoals => _goalBox.values.toList();

  /// Add a new goal (avoids duplicate names)
  Future<void> addGoal(Goal goal) async {
    // optional: avoid duplicates by name
    if (!availableGoals.any((g) => g.name == goal.name)) {
      await _goalBox.add(goal);
    }
  }

  /// Remove a goal by name
  Future<void> removeGoal(String name) async {
    final key = _goalBox.keys.firstWhere(
      (k) => (_goalBox.get(k)?.name == name),
      orElse: () => null,
    );
    if (key != null) await _goalBox.delete(key);
  }

  /// Get goal by name
  Goal? getGoalByName(String name) {
    try {
      return _goalBox.values.firstWhere((g) => g.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Update existing goal by old name
  Future<void> updateGoal(String oldName, Goal updatedGoal) async {
    final key = _goalBox.keys.firstWhere(
      (k) => (_goalBox.get(k)?.name == oldName),
      orElse: () => null,
    );
    if (key != null) {
      await _goalBox.put(key, updatedGoal);
    }
  }

  /// Clear all goals
  Future<void> clearAll() async => await _goalBox.clear();
}
