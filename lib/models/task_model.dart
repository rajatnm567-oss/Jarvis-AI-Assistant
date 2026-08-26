import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

/// 📋 TASK MODEL - Data Structure for To-Do Items
@HiveType(typeId: 0)
class TaskModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String priority; // high, medium, low

  @HiveField(4)
  final String category;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String recurring; // none, daily, weekly, monthly

  @HiveField(11)
  final String voiceCommand; // Original voice command

  @HiveField(12)
  int completionPoints;

  TaskModel({
    String? id,
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.category = 'General',
    this.isCompleted = false,
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
    this.tags = const [],
    this.recurring = 'none',
    this.voiceCommand = '',
    this.completionPoints = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'recurring': recurring,
      'voiceCommand': voiceCommand,
      'completionPoints': completionPoints,
    };
  }

  /// Create from Map (from Firebase)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      recurring: map['recurring'] ?? 'none',
      voiceCommand: map['voiceCommand'] ?? '',
      completionPoints: map['completionPoints'] ?? 0,
    );
  }

  /// Copy with modifications
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? category,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
    String? recurring,
    String? voiceCommand,
    int? completionPoints,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      recurring: recurring ?? this.recurring,
      voiceCommand: voiceCommand ?? this.voiceCommand,
      completionPoints: completionPoints ?? this.completionPoints,
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Get days until due
  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Get formatted due date
  String? get formattedDueDate {
    if (dueDate == null) return null;
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }

  /// Get priority color (for UI)
  String get priorityColor {
    switch (priority) {
      case 'high':
        return '#FF6B6B'; // Red
      case 'medium':
        return '#FFA500'; // Orange
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Gray
    }
  }

  /// Get priority emoji
  String get priorityEmoji {
    switch (priority) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  /// Get category emoji
  String get categoryEmoji {
    switch (category) {
      case 'Work':
        return '💼';
      case 'Personal':
        return '👤';
      case 'Health':
        return '🏥';
      case 'Shopping':
        return '🛒';
      case 'Learning':
        return '📚';
      case 'Finance':
        return '💰';
      case 'Home':
        return '🏠';
      default:
        return '📌';
    }
  }

  /// Status badge for UI
  String get statusBadge {
    if (isCompleted) return '✅ Completed';
    if (isOverdue) return '⏰ Overdue';
    if (daysUntilDue != null && daysUntilDue! <= 1) return '⚠️ Due Soon';
    return '📌 Pending';
  }

  @override
  String toString() => 'TaskModel(id: $id, title: $title, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Category Model
class TaskCategory {
  final String name;
  final String emoji;
  final String color;

  const TaskCategory({
    required this.name,
    required this.emoji,
    required this.color,
  });
}

/// Priority Model
class TaskPriority {
  final String level;
  final int points;
  final String emoji;
  final String color;

  const TaskPriority({
    required this.level,
    required this.points,
    required this.emoji,
    required this.color,
  });
}

/// Predefined Categories
const List<TaskCategory> predefinedCategories = [
  TaskCategory(name: 'Work', emoji: '💼', color: '#2196F3'),
  TaskCategory(name: 'Personal', emoji: '👤', color: '#9C27B0'),
  TaskCategory(name: 'Health', emoji: '🏥', color: '#F44336'),
  TaskCategory(name: 'Shopping', emoji: '🛒', color: '#FF9800'),
  TaskCategory(name: 'Learning', emoji: '📚', color: '#4CAF50'),
  TaskCategory(name: 'Finance', emoji: '💰', color: '#FFC107'),
  TaskCategory(name: 'Home', emoji: '🏠', color: '#795548'),
];

/// Predefined Priorities
const List<TaskPriority> predefinedPriorities = [
  TaskPriority(level: 'high', points: 30, emoji: '🔴', color: '#FF6B6B'),
  TaskPriority(level: 'medium', points: 20, emoji: '🟡', color: '#FFA500'),
  TaskPriority(level: 'low', points: 10, emoji: '🟢', color: '#4CAF50'),
];
