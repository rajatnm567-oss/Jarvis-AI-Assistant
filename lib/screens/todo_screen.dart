import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/todo_service.dart';

/// 📋 TODO SCREEN - Task Management & List View
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String _selectedFilter = 'all'; // all, pending, completed
  String _selectedCategory = 'All';
  late TextEditingController _taskController;
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  /// ➕ Add New Task Dialog
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('➕ Add New Task'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedPriority,
                dropdownColor: Colors.grey[800],
                items: ['high', 'medium', 'low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(
                            priority.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedPriority = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedCategory,
                dropdownColor: Colors.grey[800],
                items: ['Work', 'Personal', 'Shopping', 'Health', 'Learning']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addTask();
              Navigator.pop(context);
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  /// ➕ Add Task Function
  void _addTask() async {
    if (_taskController.text.isEmpty) return;

    final task = TaskModel(
      title: _taskController.text,
      priority: _selectedPriority,
      category: _selectedCategory,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );

    final todoService = ref.read(todoServiceProvider.notifier);
    await todoService.addTask(task);

    _taskController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Task added successfully!')),
    );
  }

  /// 🗑️ Delete Task
  void _deleteTask(String taskId) async {
    final todoService = ref.read(todoServiceProvider.notifier);
    await todoService.deleteTask(taskId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Task deleted!')),
    );
  }

  /// ✅ Complete Task
  void _completeTask(String taskId) async {
    final todoService = ref.read(todoServiceProvider.notifier);
    await todoService.completeTask(taskId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Task completed!')),
    );
  }

  /// 🔍 Filter Tasks
  List<TaskModel> _getFilteredTasks(List<TaskModel> tasks) {
    var filtered = tasks;

    // Filter by status
    if (_selectedFilter == 'pending') {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    } else if (_selectedFilter == 'completed') {
      filtered = filtered.where((t) => t.isCompleted).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Sort by priority
    filtered.sort((a, b) {
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 My Tasks'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // 🔍 Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending', 'pending'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 'completed'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Work'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Personal'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Shopping'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 📋 Task List
            Expanded(
              child: todoState.when(
                data: (tasks) {
                  final filtered = _getFilteredTasks(tasks);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found!',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return _buildTaskCard(task);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  /// 🏷️ Build Filter Chip
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.blue[600],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[300],
      ),
    );
  }

  /// 🎨 Build Category Chip
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = category);
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.orange[600],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[300],
      ),
    );
  }

  /// 📌 Build Task Card
  Widget _buildTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.left(
          color: Color(int.parse(
            task.priorityColor.replaceFirst('#', '0xff'),
          )),
          width: 4,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _completeTask(task.id),
          activeColor: Colors.blue[600],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${task.categoryEmoji} ${task.category}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  task.priorityEmoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            if (task.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '📅 Due: ${task.formattedDueDate}',
                  style: TextStyle(
                    color: task.isOverdue ? Colors.red[400] : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteTask(task.id),
        ),
      ),
    );
  }

  /// 📊 Show Statistics Dialog
  void _showStatsDialog() {
    final todoService = ref.read(todoServiceProvider.notifier);
    final stats = todoService.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Task Statistics'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Tasks', '${stats['total_tasks']}'),
            _buildStatRow('✅ Completed', '${stats['completed']}'),
            _buildStatRow('⏳ Pending', '${stats['pending']}'),
            _buildStatRow('🔴 High Priority', '${stats['high_priority']}'),
            _buildStatRow(
              '📈 Completion Rate',
              '${stats['completion_rate']}%',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 📊 Build Stat Row
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue[300],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
