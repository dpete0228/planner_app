// calendar_app/lib/screens/goal_screen.dart (Rewritten to use ApiService)

import 'package:flutter/material.dart';
import '../core/api_service.dart'; // New dependency for remote data calls
import '../core/goal.dart'; // Import the custom API-backed Goal data model.

/// A screen dedicated to managing user goals via a remote API service.
class GoalScreen extends StatefulWidget {
  // Key for the widget instance.
  const GoalScreen({super.key});

  @override
  // Create the mutable state for this widget.
  State<GoalScreen> createState() => _GoalScreenState();
}

/// The state class for GoalScreen, handling API interaction and UI logic.
class _GoalScreenState extends State<GoalScreen> {
  // API Service instance for all CRUD operations
  final ApiService _apiService = ApiService();

  // Controller for the Goal name text input.
  final TextEditingController _nameController = TextEditingController();
  // Controller for the Goal description text input.
  final TextEditingController _descController = TextEditingController();

  // Data source for the list of goals.
  List<Goal> _goals = [];
  // Flag to manage the loading state while data is retrieved from the API.
  bool _loading = true;

  // Stores the currently selected color for goal creation/editing (as an int).
  int _selectedColorValue = Colors.blue.value; // Default selected color value

  // A list of predefined colors for users to select for their goals.
  final List<Color> _predefinedColors = const [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    // Start loading goals from the API.
    _loadGoals();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Fetches all available Goal objects from the API and updates the UI state.
  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      // Fetch goals from the remote API.
      _goals = await _apiService.fetchGoals();
    } catch (e) {
      print("Error loading goals from API: $e");
      // Optionally show a user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load goals. Check API connection."),
          ),
        );
      }
    } finally {
      // Update UI once goals are loaded.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Displays a dialog to input details for a new goal and saves it via API.
  Future<void> _addGoal() async {
    // Reset input fields and color selection before dialog display.
    _nameController.clear();
    _descController.clear();
    _selectedColorValue = Colors.blue.value; // Reset to default blue value

    await showDialog(
      context: context,
      // Use StatefulBuilder to allow internal state updates (like color selection) within the dialog.
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Keep the content column compact.
            children: [
              // Text field for the goal's name.
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
              ),
              // Text field for the goal's description.
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              // Color selection chips.
              Wrap(
                spacing: 8,
                children: _predefinedColors.map((c) {
                  return GestureDetector(
                    // On tap, update the selected color value and redraw the chips via setDialogState.
                    onTap: () =>
                        setDialogState(() => _selectedColorValue = c.value),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        // Highlight the currently selected color with a border.
                        border: Border.all(
                          color: _selectedColorValue == c.value
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            // Cancel button.
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            // Add (Save) button.
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final desc = _descController.text.trim();
                // Check if name is empty.
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Goal name cannot be empty.")),
                  );
                  return;
                }

                // 1. Create the new Goal object (no ID yet)
                final newGoal = Goal(
                  name: name,
                  description: desc,
                  color: _selectedColorValue, // Use the selected int value.
                  // completionDate is null by default for new goals.
                );

                try {
                  // 2. Add the goal via API. The returned object will have the ID.
                  await _apiService.addGoal(newGoal);

                  // 3. Refresh the full list from the API to update the UI.
                  await _loadGoals();

                  Navigator.pop(context);
                } catch (e) {
                  print("Error adding goal: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Failed to add goal. Name likely duplicate.",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a dialog to edit an existing goal.
  Future<void> _editGoal(Goal existingGoal) async {
    // Populate the text controllers and selected color with the existing data.
    _nameController.text = existingGoal.name;
    _descController.text = existingGoal.description;
    _selectedColorValue = existingGoal.color;

    await showDialog(
      context: context,
      // StatefulBuilder for internal dialog state management.
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text field for goal name.
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Goal Name"),
              ),
              // Text field for goal description.
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              // Color selection chips.
              Wrap(
                spacing: 8,
                children: _predefinedColors.map((c) {
                  return GestureDetector(
                    // Update the selected color in the dialog state.
                    onTap: () =>
                        setDialogState(() => _selectedColorValue = c.value),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        // Highlight the currently selected color.
                        border: Border.all(
                          color: _selectedColorValue == c.value
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            // Cancel button.
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            // Save button.
            ElevatedButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                final newDesc = _descController.text.trim();
                // Check if name is empty.
                if (newName.isEmpty) return;

                // 1. Create the updated Goal object
                final updatedGoal = Goal(
                  id: existingGoal.id, // CRITICAL: Preserve the API ID
                  name: newName,
                  description: newDesc,
                  completionDate: existingGoal.completionDate,
                  color: _selectedColorValue,
                );

                try {
                  // 2. Update the goal via API.
                  await _apiService.updateGoal(updatedGoal);

                  // 3. Refresh the full list from the API to update the UI.
                  await _loadGoals();

                  Navigator.pop(context);
                } catch (e) {
                  print("Error updating goal: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update goal.")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  /// Deletes a goal by ID via the API.
  Future<void> _deleteGoal(int? id) async {
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Goal?"),
        content: const Text(
          "Deleting this goal will unlink it from all associated events.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm Delete
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete the goal via API. The database FOREIGN KEY will handle event unlinking.
      await _apiService.deleteGoal(id);

      // 2. Refresh the full list from the API to update the UI.
      await _loadGoals();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Goal deleted.")));
    } catch (e) {
      print("Error deleting goal: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete goal.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while data is being fetched.
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Goals"),
        actions: [
          // Icon button to add a new goal.
          IconButton(icon: const Icon(Icons.add), onPressed: _addGoal),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Expanded widget ensures the ListView takes all available vertical space.
            Expanded(
              // Builds a scrollable list of goals.
              child: _goals.isEmpty
                  ? const Center(
                      child: Text("No goals found. Tap '+' to add one."),
                    )
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (_, index) {
                        final goal = _goals[index];

                        // Display each goal as a ListTile.
                        return ListTile(
                          // Leading color indicator.
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(goal.color), // Use the goal's color.
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                          title: Text(goal.name),
                          subtitle: Text(
                            goal.description.isNotEmpty
                                ? goal.description
                                : 'No description provided.',
                          ),
                          // Trailing action buttons (Edit and Delete).
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit button.
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editGoal(goal),
                              ),
                              // Delete button.
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteGoal(goal.id), // Pass the API ID
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
