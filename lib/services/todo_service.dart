import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/task_model.dart';

/// 📋 TO-DO SERVICE - Task Management with Cloud Sync
class TodoService extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Box<TaskModel> _taskBox;
  List<TaskModel> _localTasks = [];

  TodoService() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize Hive for local storage
      await Hive.initFlutter();
      Hive.registerAdapter(TaskModelAdapter());
      _taskBox = await Hive.openBox<TaskModel>('tasks');

      // Load local tasks
      _loadLocalTasks();

      // Sync with Cloud
      await _syncWithCloud();

      logger.i('✅ Todo Service Initialized');
    } catch (e, stackTrace) {
      logger.e('❌ Init Error: $e', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// ➕ Add New Task
  Future<void> addTask(TaskModel task) async {
    try {
      // Add to local storage
      await _taskBox.add(task);
      _localTasks.add(task);

      // Add to Cloud
      await _saveToCloud(task);

      // Update state
      state = AsyncValue.data(_localTasks);

      logger.i('✅ Task added: ${task.title}');
    } catch (e) {
      logger.e('❌ Add Task Error: $e');
    }
  }

  /// ✏️ Update Task
  Future<void> updateTask(String taskId, TaskModel updatedTask) async {
    try {
      // Find and update locally
      final index =
          _localTasks.indexWhere((task) => task.id == taskId);

      if (index != -1) {
        _localTasks[index] = updatedTask;
        await _taskBox.putAt(index, updatedTask);
      }

      // Update in Cloud
      await _updateInCloud(taskId, updatedTask);

      state = AsyncValue.data(_localTasks);
      logger.i('✅ Task updated: $taskId');
    } catch (e) {
      logger.e('�� Update Task Error: $e');
    }
  }

  /// ❌ Delete Task
  Future<void> deleteTask(String taskId) async {
    try {
      // Remove locally
      _localTasks.removeWhere((task) => task.id == taskId);
      await _taskBox.clear();
      await _taskBox.addAll(_localTasks);

      // Remove from Cloud
      await _deleteFromCloud(taskId);

      state = AsyncValue.data(_localTasks);
      logger.i('✅ Task deleted: $taskId');
    } catch (e) {
      logger.e('❌ Delete Task Error: $e');
    }
  }

  /// ✅ Complete Task
  Future<void> completeTask(String taskId) async {
    try {
      final task = _localTasks.firstWhere((t) => t.id == taskId);
      task.isCompleted = true;
      task.completedAt = DateTime.now();

      await updateTask(taskId, task);

      // Add to statistics
      await _recordCompletion(task);

      logger.i('✅ Task completed: $taskId');
    } catch (e) {
      logger.e('❌ Complete Task Error: $e');
    }
  }

  /// 📝 Get All Tasks
  List<TaskModel> getAllTasks() {
    return _localTasks;
  }

  /// 🔍 Get Tasks by Priority
  List<TaskModel> getTasksByPriority(String priority) {
    return _localTasks
        .where((task) => task.priority == priority && !task.isCompleted)
        .toList();
  }

  /// 📅 Get Tasks by Due Date
  List<TaskModel> getTasksByDueDate(DateTime date) {
    return _localTasks
        .where((task) =>
            task.dueDate?.day == date.day &&
            task.dueDate?.month == date.month &&
            !task.isCompleted)
        .toList();
  }

  /// 🏷️ Get Tasks by Category
  List<TaskModel> getTasksByCategory(String category) {
    return _localTasks
        .where((task) => task.category == category && !task.isCompleted)
        .toList();
  }

  /// 📊 Get Statistics
  Map<String, dynamic> getStatistics() {
    final completed = _localTasks.where((t) => t.isCompleted).length;
    final pending = _localTasks.where((t) => !t.isCompleted).length;
    final highPriority =
        _localTasks.where((t) => t.priority == 'high' && !t.isCompleted).length;

    return {
      'total_tasks': _localTasks.length,
      'completed': completed,
      'pending': pending,
      'high_priority': highPriority,
      'completion_rate': _localTasks.isEmpty
          ? 0
          : (completed / _localTasks.length * 100).toStringAsFixed(2),
    };
  }

  /// 💾 Save to Cloud Firestore
  Future<void> _saveToCloud(TaskModel task) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
    } catch (e) {
      logger.e('❌ Cloud Save Error: $e');
    }
  }

  /// 🔄 Update in Cloud
  Future<void> _updateInCloud(String taskId, TaskModel task) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update(task.toMap());
    } catch (e) {
      logger.e('❌ Cloud Update Error: $e');
    }
  }

  /// 🗑️ Delete from Cloud
  Future<void> _deleteFromCloud(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      logger.e('❌ Cloud Delete Error: $e');
    }
  }

  /// 📥 Load Local Tasks
  void _loadLocalTasks() {
    _localTasks = _taskBox.values.toList();
    state = AsyncValue.data(_localTasks);
    logger.i('✅ Loaded ${_localTasks.length} local tasks');
  }

  /// 🔀 Sync with Cloud
  Future<void> _syncWithCloud() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get();

      for (var doc in snapshot.docs) {
        final task = TaskModel.fromMap(doc.data());
        if (!_localTasks.any((t) => t.id == task.id)) {
          _localTasks.add(task);
        }
      }

      await _taskBox.clear();
      await _taskBox.addAll(_localTasks);

      state = AsyncValue.data(_localTasks);
      logger.i('✅ Cloud sync complete');
    } catch (e) {
      logger.e('❌ Cloud Sync Error: $e');
    }
  }

  /// 🎮 Record Task Completion (for gamification)
  Future<void> _recordCompletion(TaskModel task) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .add({
        'task_id': task.id,
        'task_title': task.title,
        'completed_at': DateTime.now(),
        'points': _calculatePoints(task),
      });
    } catch (e) {
      logger.e('❌ Record Completion Error: $e');
    }
  }

  /// 🏆 Calculate Points for Task
  int _calculatePoints(TaskModel task) {
    int points = 10;
    if (task.priority == 'high') points += 20;
    if (task.priority == 'medium') points += 10;
    return points;
  }
}

// Provider
final todoServiceProvider =
    StateNotifierProvider<TodoService, AsyncValue<List<TaskModel>>>((ref) {
  return TodoService();
});

/// Hive Adapter for TaskModel
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    return TaskModel(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      priority: reader.readString(),
      category: reader.readString(),
      isCompleted: reader.readBool(),
      dueDate: reader.readString() == '' ? null : DateTime.parse(reader.readString()),
      createdAt: DateTime.parse(reader.readString()),
      completedAt: reader.readString() == '' ? null : DateTime.parse(reader.readString()),
      tags: reader.readList().cast<String>(),
      recurring: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.priority);
    writer.writeString(obj.category);
    writer.writeBool(obj.isCompleted);
    writer.writeString(obj.dueDate?.toString() ?? '');
    writer.writeString(obj.createdAt.toString());
    writer.writeString(obj.completedAt?.toString() ?? '');
    writer.writeList(obj.tags);
    writer.writeString(obj.recurring);
  }
}
