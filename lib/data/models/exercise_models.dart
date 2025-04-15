import 'package:flutter/material.dart';

/// Exercise model representing a type of exercise
class Exercise {
  final String id;
  final String name;
  final String description;
  final ExerciseType type;
  final ExerciseLevel level;
  final int caloriesPerMinute; // Estimated calories burned per minute
  final List<String> targetMuscles;
  final List<String> equipment;
  final String? imageUrl;
  final String? videoUrl;
  final int recommendedDuration; // in minutes
  final bool isRecommended;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.level,
    required this.caloriesPerMinute,
    required this.targetMuscles,
    required this.equipment,
    this.imageUrl,
    this.videoUrl,
    required this.recommendedDuration,
    this.isRecommended = false,
  });

  // Create from map for storage/retrieval
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ExerciseType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ExerciseType.cardio,
      ),
      level: ExerciseLevel.values.firstWhere(
        (e) => e.toString() == map['level'],
        orElse: () => ExerciseLevel.beginner,
      ),
      caloriesPerMinute: map['caloriesPerMinute'],
      targetMuscles: List<String>.from(map['targetMuscles']),
      equipment: List<String>.from(map['equipment']),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      recommendedDuration: map['recommendedDuration'],
      isRecommended: map['isRecommended'] ?? false,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'level': level.toString(),
      'caloriesPerMinute': caloriesPerMinute,
      'targetMuscles': targetMuscles,
      'equipment': equipment,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'recommendedDuration': recommendedDuration,
      'isRecommended': isRecommended,
    };
  }

  // Calculate calories burned based on duration
  int calculateCaloriesBurned(int durationMinutes) {
    return caloriesPerMinute * durationMinutes;
  }

  // Create a copy with modified fields
  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseType? type,
    ExerciseLevel? level,
    int? caloriesPerMinute,
    List<String>? targetMuscles,
    List<String>? equipment,
    String? imageUrl,
    String? videoUrl,
    int? recommendedDuration,
    bool? isRecommended,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      level: level ?? this.level,
      caloriesPerMinute: caloriesPerMinute ?? this.caloriesPerMinute,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      equipment: equipment ?? this.equipment,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      recommendedDuration: recommendedDuration ?? this.recommendedDuration,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}

/// Exercise log entry for tracking completed exercises
class ExerciseLog {
  final String id;
  final String exerciseId;
  final DateTime timestamp;
  final int durationMinutes;
  final int caloriesBurned;
  final ExerciseLevel intensityLevel;
  final String? notes;
  final double? userWeight; // To track weight at time of exercise

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.timestamp,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensityLevel,
    this.notes,
    this.userWeight,
  });

  // Create from map for storage/retrieval
  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'],
      exerciseId: map['exerciseId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      durationMinutes: map['durationMinutes'],
      caloriesBurned: map['caloriesBurned'],
      intensityLevel: ExerciseLevel.values.firstWhere(
        (e) => e.toString() == map['intensityLevel'],
        orElse: () => ExerciseLevel.beginner,
      ),
      notes: map['notes'],
      userWeight: map['userWeight'],
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'intensityLevel': intensityLevel.toString(),
      'notes': notes,
      'userWeight': userWeight,
    };
  }

  // Create a new log entry with generated ID
  factory ExerciseLog.create({
    required String exerciseId,
    required int durationMinutes,
    required int caloriesBurned,
    required ExerciseLevel intensityLevel,
    String? notes,
    double? userWeight,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    return ExerciseLog(
      id: id,
      exerciseId: exerciseId,
      timestamp: now,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      intensityLevel: intensityLevel,
      notes: notes,
      userWeight: userWeight,
    );
  }
}

/// Workout plan model for a structured exercise routine
class WorkoutPlan {
  final String id;
  final String name;
  final String description;
  final ExerciseLevel level;
  final int weeklyFrequency; // How many days per week
  final int estimatedWeeklyCalories; // Total calories for complete plan
  final List<WorkoutDay> days;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.weeklyFrequency,
    required this.estimatedWeeklyCalories,
    required this.days,
  });

  // Create from map for storage/retrieval
  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      level: ExerciseLevel.values.firstWhere(
        (e) => e.toString() == map['level'],
        orElse: () => ExerciseLevel.beginner,
      ),
      weeklyFrequency: map['weeklyFrequency'],
      estimatedWeeklyCalories: map['estimatedWeeklyCalories'],
      days:
          (map['days'] as List).map((day) => WorkoutDay.fromMap(day)).toList(),
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.toString(),
      'weeklyFrequency': weeklyFrequency,
      'estimatedWeeklyCalories': estimatedWeeklyCalories,
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  // Get recommended plan based on user stats
  static WorkoutPlan getRecommendedPlan(
    List<WorkoutPlan> availablePlans,
    ExerciseLevel userLevel,
    int targetCalorieDeficit,
  ) {
    // Find plans matching the user's level first
    final levelMatchPlans =
        availablePlans.where((plan) => plan.level == userLevel).toList();

    if (levelMatchPlans.isEmpty) {
      // If no exact level match, find closest level
      final allLevels = ExerciseLevel.values;
      final userLevelIndex = allLevels.indexOf(userLevel);

      // Try to find lower level first if available
      if (userLevelIndex > 0) {
        final lowerLevel = allLevels[userLevelIndex - 1];
        final lowerPlans =
            availablePlans.where((plan) => plan.level == lowerLevel).toList();
        if (lowerPlans.isNotEmpty) {
          levelMatchPlans.addAll(lowerPlans);
        }
      }

      // If still empty, try higher level
      if (levelMatchPlans.isEmpty && userLevelIndex < allLevels.length - 1) {
        final higherLevel = allLevels[userLevelIndex + 1];
        final higherPlans =
            availablePlans.where((plan) => plan.level == higherLevel).toList();
        if (higherPlans.isNotEmpty) {
          levelMatchPlans.addAll(higherPlans);
        }
      }
    }

    // If still no matches, just return the first available plan
    if (levelMatchPlans.isEmpty) {
      return availablePlans.first;
    }

    // Find the plan that gets closest to the target calorie deficit
    levelMatchPlans.sort((a, b) {
      final aDiff = (a.estimatedWeeklyCalories - targetCalorieDeficit).abs();
      final bDiff = (b.estimatedWeeklyCalories - targetCalorieDeficit).abs();
      return aDiff.compareTo(bDiff);
    });

    return levelMatchPlans.first;
  }
}

/// Workout day model representing a single day in a workout plan
class WorkoutDay {
  final String id;
  final String name; // e.g., "Day 1: Cardio Focus"
  final List<WorkoutExercise> exercises;
  final int totalCalories;
  final int totalDuration; // in minutes

  WorkoutDay({
    required this.id,
    required this.name,
    required this.exercises,
    required this.totalCalories,
    required this.totalDuration,
  });

  // Create from map for storage/retrieval
  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    return WorkoutDay(
      id: map['id'],
      name: map['name'],
      exercises: (map['exercises'] as List)
          .map((ex) => WorkoutExercise.fromMap(ex))
          .toList(),
      totalCalories: map['totalCalories'],
      totalDuration: map['totalDuration'],
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((ex) => ex.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
    };
  }
}

/// Workout exercise model representing an exercise in a workout day
class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int durationMinutes;
  final int sets;
  final int? reps;
  final String? restTime;
  final int caloriesBurned;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.durationMinutes,
    this.sets = 1,
    this.reps,
    this.restTime,
    required this.caloriesBurned,
  });

  // Create from map for storage/retrieval
  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'],
      exerciseName: map['exerciseName'],
      durationMinutes: map['durationMinutes'],
      sets: map['sets'] ?? 1,
      reps: map['reps'],
      restTime: map['restTime'],
      caloriesBurned: map['caloriesBurned'],
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'durationMinutes': durationMinutes,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'caloriesBurned': caloriesBurned,
    };
  }
}

/// Exercise type enum
enum ExerciseType {
  cardio,
  strength,
  flexibility,
  balance,
  sports,
  hiit,
}

/// Exercise level enum
enum ExerciseLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

// Extensions to get human-readable names and colors for exercise types
extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.cardio:
        return 'Cardio';
      case ExerciseType.strength:
        return 'Strength';
      case ExerciseType.flexibility:
        return 'Flexibility';
      case ExerciseType.balance:
        return 'Balance';
      case ExerciseType.sports:
        return 'Sports';
      case ExerciseType.hiit:
        return 'HIIT';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseType.cardio:
        return Colors.red;
      case ExerciseType.strength:
        return Colors.blue;
      case ExerciseType.flexibility:
        return Colors.purple;
      case ExerciseType.balance:
        return Colors.teal;
      case ExerciseType.sports:
        return Colors.orange;
      case ExerciseType.hiit:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseType.cardio:
        return Icons.directions_run;
      case ExerciseType.strength:
        return Icons.fitness_center;
      case ExerciseType.flexibility:
        return Icons.self_improvement;
      case ExerciseType.balance:
        return Icons.accessibility_new;
      case ExerciseType.sports:
        return Icons.sports_basketball;
      case ExerciseType.hiit:
        return Icons.timer;
    }
  }
}

// Extensions to get human-readable names for exercise levels
extension ExerciseLevelExtension on ExerciseLevel {
  String get displayName {
    switch (this) {
      case ExerciseLevel.beginner:
        return 'Beginner';
      case ExerciseLevel.intermediate:
        return 'Intermediate';
      case ExerciseLevel.advanced:
        return 'Advanced';
      case ExerciseLevel.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseLevel.beginner:
        return Colors.green;
      case ExerciseLevel.intermediate:
        return Colors.blue;
      case ExerciseLevel.advanced:
        return Colors.orange;
      case ExerciseLevel.expert:
        return Colors.red;
    }
  }
}
