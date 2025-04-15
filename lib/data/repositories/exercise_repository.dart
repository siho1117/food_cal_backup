import '../models/exercise_models.dart';
import '../storage/local_storage.dart';
import '../../utils/formula.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;

class ExerciseRepository {
  static const String _exercisesKey = 'exercises';
  static const String _exerciseLogsKey = 'exercise_logs';
  static const String _workoutPlansKey = 'workout_plans';
  static const String _activeWorkoutPlanKey = 'active_workout_plan';

  final LocalStorage _storage = LocalStorage();

  // Get all exercises
  Future<List<Exercise>> getAllExercises() async {
    final exercisesList = await _storage.getObjectList(_exercisesKey);

    if (exercisesList == null || exercisesList.isEmpty) {
      return _getDefaultExercises();
    }

    try {
      return exercisesList.map((map) => Exercise.fromMap(map)).toList();
    } catch (e) {
      print('Error retrieving exercises: $e');
      return _getDefaultExercises();
    }
  }

  // Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    final exercises = await getAllExercises();
    return exercises.firstWhere((ex) => ex.id == id,
        orElse: () => throw Exception('Exercise not found'));
  }

  // Save exercise
  Future<bool> saveExercise(Exercise exercise) async {
    final exercises = await getAllExercises();

    // Check if exercise already exists
    final index = exercises.indexWhere((ex) => ex.id == exercise.id);
    if (index >= 0) {
      exercises[index] = exercise;
    } else {
      exercises.add(exercise);
    }

    return _saveExercises(exercises);
  }

  // Delete exercise
  Future<bool> deleteExercise(String id) async {
    final exercises = await getAllExercises();
    final filtered = exercises.where((ex) => ex.id != id).toList();

    if (filtered.length == exercises.length) {
      return false; // No exercise was removed
    }

    return _saveExercises(filtered);
  }

  // Internal method to save exercises list
  Future<bool> _saveExercises(List<Exercise> exercises) async {
    try {
      final exerciseMaps = exercises.map((ex) => ex.toMap()).toList();
      return await _storage.setObjectList(_exercisesKey, exerciseMaps);
    } catch (e) {
      print('Error saving exercises: $e');
      return false;
    }
  }

  // Get exercise logs
  Future<List<ExerciseLog>> getExerciseLogs() async {
    final logsList = await _storage.getObjectList(_exerciseLogsKey);

    if (logsList == null || logsList.isEmpty) return [];

    try {
      return logsList.map((map) => ExerciseLog.fromMap(map)).toList();
    } catch (e) {
      print('Error retrieving exercise logs: $e');
      return [];
    }
  }

  // Add exercise log
  Future<bool> addExerciseLog(ExerciseLog log) async {
    final logs = await getExerciseLogs();
    logs.add(log);
    return _saveExerciseLogs(logs);
  }

  // Get exercise logs in date range
  Future<List<ExerciseLog>> getExerciseLogsInRange(
      DateTime startDate, DateTime endDate) async {
    final logs = await getExerciseLogs();

    return logs.where((log) {
      return log.timestamp.isAfter(startDate) &&
          log.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get total calories burned in date range
  Future<int> getTotalCaloriesBurnedInRange(
      DateTime startDate, DateTime endDate) async {
    final logs = await getExerciseLogsInRange(startDate, endDate);
    int total = 0;
    for (var log in logs) {
      total += log.caloriesBurned;
    }
    return total;
  }

  // Internal method to save exercise logs
  Future<bool> _saveExerciseLogs(List<ExerciseLog> logs) async {
    try {
      final logMaps = logs.map((log) => log.toMap()).toList();
      return await _storage.setObjectList(_exerciseLogsKey, logMaps);
    } catch (e) {
      print('Error saving exercise logs: $e');
      return false;
    }
  }

  // Get workout plans
  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    final plansList = await _storage.getObjectList(_workoutPlansKey);

    if (plansList == null || plansList.isEmpty) {
      return _getDefaultWorkoutPlans();
    }

    try {
      return plansList.map((map) => WorkoutPlan.fromMap(map)).toList();
    } catch (e) {
      print('Error retrieving workout plans: $e');
      return _getDefaultWorkoutPlans();
    }
  }

  // Get active workout plan
  Future<WorkoutPlan?> getActiveWorkoutPlan() async {
    final planMap = await _storage.getObject(_activeWorkoutPlanKey);
    if (planMap == null) return null;

    try {
      return WorkoutPlan.fromMap(planMap);
    } catch (e) {
      print('Error retrieving active workout plan: $e');
      return null;
    }
  }

  // Set active workout plan
  Future<bool> setActiveWorkoutPlan(WorkoutPlan plan) async {
    try {
      return await _storage.setObject(_activeWorkoutPlanKey, plan.toMap());
    } catch (e) {
      print('Error saving active workout plan: $e');
      return false;
    }
  }

  // Get recommended workout plan based on user profile
  Future<WorkoutPlan?> getRecommendedWorkoutPlan(
      UserProfile userProfile, double currentWeight) async {
    final plans = await getWorkoutPlans();
    if (plans.isEmpty) return null;

    // Determine user's fitness level based on activity level
    ExerciseLevel userLevel;
    if (userProfile.activityLevel == null) {
      userLevel = ExerciseLevel.beginner;
    } else if (userProfile.activityLevel! < 1.3) {
      userLevel = ExerciseLevel.beginner;
    } else if (userProfile.activityLevel! < 1.6) {
      userLevel = ExerciseLevel.intermediate;
    } else {
      userLevel = ExerciseLevel.advanced;
    }

    // Calculate target weekly calorie burn from exercise (to create deficit)
    final tdee = Formula.calculateTDEE(
      bmr: Formula.calculateBMR(
        weight: currentWeight,
        height: userProfile.height,
        age: userProfile.age,
        gender: userProfile.gender,
      ),
      activityLevel: userProfile.activityLevel,
    );

    // Target weekly deficit: We'll aim for 20% from exercise, 80% from diet
    final targetWeeklyDeficit = tdee != null ? (tdee * 0.2 * 7).round() : 3500;

    return WorkoutPlan.getRecommendedPlan(
      plans,
      userLevel,
      targetWeeklyDeficit,
    );
  }

  // Default exercises if none are saved
  List<Exercise> _getDefaultExercises() {
    return [
      Exercise(
        id: '1',
        name: 'Walking',
        description:
            'A low-impact exercise that can help with weight loss and overall fitness.',
        type: ExerciseType.cardio,
        level: ExerciseLevel.beginner,
        caloriesPerMinute: 4,
        targetMuscles: ['Legs', 'Core'],
        equipment: [],
        recommendedDuration: 30,
        isRecommended: true,
      ),
      Exercise(
        id: '2',
        name: 'Running',
        description:
            'A high-impact cardio exercise to improve endurance and burn calories.',
        type: ExerciseType.cardio,
        level: ExerciseLevel.intermediate,
        caloriesPerMinute: 10,
        targetMuscles: ['Legs', 'Core', 'Cardiovascular System'],
        equipment: [],
        recommendedDuration: 20,
      ),
      Exercise(
        id: '3',
        name: 'Push-ups',
        description:
            'A bodyweight exercise that works the chest, shoulders, and triceps.',
        type: ExerciseType.strength,
        level: ExerciseLevel.intermediate,
        caloriesPerMinute: 8,
        targetMuscles: ['Chest', 'Shoulders', 'Triceps', 'Core'],
        equipment: [],
        recommendedDuration: 10,
      ),
      Exercise(
        id: '4',
        name: 'Squats',
        description:
            'A lower body exercise that targets the quads, hamstrings, and glutes.',
        type: ExerciseType.strength,
        level: ExerciseLevel.beginner,
        caloriesPerMinute: 8,
        targetMuscles: ['Quadriceps', 'Hamstrings', 'Glutes', 'Core'],
        equipment: [],
        recommendedDuration: 10,
        isRecommended: true,
      ),
      Exercise(
        id: '5',
        name: 'Yoga',
        description:
            'A practice that combines physical postures, breathing techniques, and meditation.',
        type: ExerciseType.flexibility,
        level: ExerciseLevel.beginner,
        caloriesPerMinute: 4,
        targetMuscles: ['Full Body'],
        equipment: ['Yoga Mat'],
        recommendedDuration: 30,
        isRecommended: true,
      ),
      Exercise(
        id: '6',
        name: 'Cycling',
        description:
            'A low-impact cardio exercise that can be done indoors or outdoors.',
        type: ExerciseType.cardio,
        level: ExerciseLevel.intermediate,
        caloriesPerMinute: 8,
        targetMuscles: ['Legs', 'Core', 'Cardiovascular System'],
        equipment: ['Bicycle or Stationary Bike'],
        recommendedDuration: 30,
      ),
      Exercise(
        id: '7',
        name: 'Plank',
        description: 'A core exercise that improves stability and strength.',
        type: ExerciseType.strength,
        level: ExerciseLevel.beginner,
        caloriesPerMinute: 5,
        targetMuscles: ['Core', 'Shoulders', 'Arms'],
        equipment: [],
        recommendedDuration: 5,
      ),
      Exercise(
        id: '8',
        name: 'Swimming',
        description: 'A full-body workout that\'s easy on the joints.',
        type: ExerciseType.cardio,
        level: ExerciseLevel.intermediate,
        caloriesPerMinute: 10,
        targetMuscles: ['Full Body', 'Cardiovascular System'],
        equipment: ['Access to Pool'],
        recommendedDuration: 30,
      ),
      Exercise(
        id: '9',
        name: 'Jump Rope',
        description:
            'A high-intensity exercise that improves coordination and cardiovascular fitness.',
        type: ExerciseType.cardio,
        level: ExerciseLevel.intermediate,
        caloriesPerMinute: 12,
        targetMuscles: ['Legs', 'Core', 'Shoulders', 'Cardiovascular System'],
        equipment: ['Jump Rope'],
        recommendedDuration: 15,
      ),
      Exercise(
        id: '10',
        name: 'HIIT Workout',
        description:
            'High-intensity interval training alternates between intense bursts of activity and fixed periods of less-intense activity.',
        type: ExerciseType.hiit,
        level: ExerciseLevel.advanced,
        caloriesPerMinute: 15,
        targetMuscles: ['Full Body', 'Cardiovascular System'],
        equipment: [],
        recommendedDuration: 20,
      ),
    ];
  }

  // Default workout plans if none are saved
  List<WorkoutPlan> _getDefaultWorkoutPlans() {
    return [
      WorkoutPlan(
        id: '1',
        name: 'Beginner Weight Loss Plan',
        description: 'A gentle introduction to exercise for weight loss.',
        level: ExerciseLevel.beginner,
        weeklyFrequency: 3,
        estimatedWeeklyCalories: 1200,
        days: [
          WorkoutDay(
            id: '1_1',
            name: 'Day 1: Cardio Focus',
            exercises: [
              WorkoutExercise(
                exerciseId: '1',
                exerciseName: 'Walking',
                durationMinutes: 30,
                caloriesBurned: 120,
              ),
              WorkoutExercise(
                exerciseId: '7',
                exerciseName: 'Plank',
                durationMinutes: 5,
                caloriesBurned: 25,
              ),
            ],
            totalCalories: 145,
            totalDuration: 35,
          ),
          WorkoutDay(
            id: '1_2',
            name: 'Day 2: Strength Basics',
            exercises: [
              WorkoutExercise(
                exerciseId: '4',
                exerciseName: 'Squats',
                durationMinutes: 10,
                sets: 3,
                reps: 10,
                caloriesBurned: 80,
              ),
              WorkoutExercise(
                exerciseId: '1',
                exerciseName: 'Walking',
                durationMinutes: 20,
                caloriesBurned: 80,
              ),
            ],
            totalCalories: 160,
            totalDuration: 30,
          ),
          WorkoutDay(
            id: '1_3',
            name: 'Day 3: Flexibility & Recovery',
            exercises: [
              WorkoutExercise(
                exerciseId: '5',
                exerciseName: 'Yoga',
                durationMinutes: 30,
                caloriesBurned: 120,
              ),
            ],
            totalCalories: 120,
            totalDuration: 30,
          ),
        ],
      ),
      WorkoutPlan(
        id: '2',
        name: 'Intermediate Calorie Burner',
        description:
            'A balanced plan with moderate intensity for steady weight loss.',
        level: ExerciseLevel.intermediate,
        weeklyFrequency: 4,
        estimatedWeeklyCalories: 2000,
        days: [
          WorkoutDay(
            id: '2_1',
            name: 'Day 1: Cardio Blast',
            exercises: [
              WorkoutExercise(
                exerciseId: '2',
                exerciseName: 'Running',
                durationMinutes: 20,
                caloriesBurned: 200,
              ),
              WorkoutExercise(
                exerciseId: '9',
                exerciseName: 'Jump Rope',
                durationMinutes: 10,
                caloriesBurned: 120,
              ),
            ],
            totalCalories: 320,
            totalDuration: 30,
          ),
          WorkoutDay(
            id: '2_2',
            name: 'Day 2: Full Body Strength',
            exercises: [
              WorkoutExercise(
                exerciseId: '3',
                exerciseName: 'Push-ups',
                durationMinutes: 10,
                sets: 3,
                reps: 12,
                caloriesBurned: 80,
              ),
              WorkoutExercise(
                exerciseId: '4',
                exerciseName: 'Squats',
                durationMinutes: 10,
                sets: 3,
                reps: 15,
                caloriesBurned: 80,
              ),
              WorkoutExercise(
                exerciseId: '7',
                exerciseName: 'Plank',
                durationMinutes: 5,
                caloriesBurned: 25,
              ),
            ],
            totalCalories: 185,
            totalDuration: 25,
          ),
          WorkoutDay(
            id: '2_3',
            name: 'Day 3: Active Recovery',
            exercises: [
              WorkoutExercise(
                exerciseId: '5',
                exerciseName: 'Yoga',
                durationMinutes: 30,
                caloriesBurned: 120,
              ),
              WorkoutExercise(
                exerciseId: '1',
                exerciseName: 'Walking',
                durationMinutes: 20,
                caloriesBurned: 80,
              ),
            ],
            totalCalories: 200,
            totalDuration: 50,
          ),
          WorkoutDay(
            id: '2_4',
            name: 'Day 4: High Intensity',
            exercises: [
              WorkoutExercise(
                exerciseId: '10',
                exerciseName: 'HIIT Workout',
                durationMinutes: 20,
                caloriesBurned: 300,
              ),
            ],
            totalCalories: 300,
            totalDuration: 20,
          ),
        ],
      ),
      WorkoutPlan(
        id: '3',
        name: 'Advanced Fat Loss Program',
        description:
            'An intense program designed for maximum calorie burn and muscle definition.',
        level: ExerciseLevel.advanced,
        weeklyFrequency: 5,
        estimatedWeeklyCalories: 3000,
        days: [
          WorkoutDay(
            id: '3_1',
            name: 'Day 1: High Intensity Cardio',
            exercises: [
              WorkoutExercise(
                exerciseId: '10',
                exerciseName: 'HIIT Workout',
                durationMinutes: 25,
                caloriesBurned: 375,
              ),
              WorkoutExercise(
                exerciseId: '9',
                exerciseName: 'Jump Rope',
                durationMinutes: 15,
                caloriesBurned: 180,
              ),
            ],
            totalCalories: 555,
            totalDuration: 40,
          ),
          WorkoutDay(
            id: '3_2',
            name: 'Day 2: Upper Body Focus',
            exercises: [
              WorkoutExercise(
                exerciseId: '3',
                exerciseName: 'Push-ups',
                durationMinutes: 15,
                sets: 4,
                reps: 20,
                caloriesBurned: 120,
              ),
              WorkoutExercise(
                exerciseId: '7',
                exerciseName: 'Plank',
                durationMinutes: 10,
                caloriesBurned: 50,
              ),
              WorkoutExercise(
                exerciseId: '2',
                exerciseName: 'Running',
                durationMinutes: 15,
                caloriesBurned: 150,
              ),
            ],
            totalCalories: 320,
            totalDuration: 40,
          ),
          WorkoutDay(
            id: '3_3',
            name: 'Day 3: Lower Body Power',
            exercises: [
              WorkoutExercise(
                exerciseId: '4',
                exerciseName: 'Squats',
                durationMinutes: 15,
                sets: 4,
                reps: 20,
                caloriesBurned: 120,
              ),
              WorkoutExercise(
                exerciseId: '1',
                exerciseName: 'Walking',
                durationMinutes: 30,
                caloriesBurned: 120,
              ),
            ],
            totalCalories: 240,
            totalDuration: 45,
          ),
          WorkoutDay(
            id: '3_4',
            name: 'Day 4: Cardio Endurance',
            exercises: [
              WorkoutExercise(
                exerciseId: '8',
                exerciseName: 'Swimming',
                durationMinutes: 30,
                caloriesBurned: 300,
              ),
              WorkoutExercise(
                exerciseId: '6',
                exerciseName: 'Cycling',
                durationMinutes: 20,
                caloriesBurned: 160,
              ),
            ],
            totalCalories: 460,
            totalDuration: 50,
          ),
          WorkoutDay(
            id: '3_5',
            name: 'Day 5: Full Body & Flexibility',
            exercises: [
              WorkoutExercise(
                exerciseId: '10',
                exerciseName: 'HIIT Workout',
                durationMinutes: 20,
                caloriesBurned: 300,
              ),
              WorkoutExercise(
                exerciseId: '5',
                exerciseName: 'Yoga',
                durationMinutes: 30,
                caloriesBurned: 120,
              ),
            ],
            totalCalories: 420,
            totalDuration: 50,
          ),
        ],
      ),
    ];
  }

  // Get weekly exercise stats for a date range
  Future<Map<String, dynamic>> getWeeklyStats(
      DateTime startDate, DateTime endDate) async {
    final logs = await getExerciseLogsInRange(startDate, endDate);

    if (logs.isEmpty) {
      return {
        'totalCaloriesBurned': 0,
        'totalMinutes': 0,
        'totalWorkouts': 0,
        'averageCaloriesPerWorkout': 0,
        'mostFrequentExercise': null,
      };
    }

    // Calculate total calories and minutes
    int totalCalories = 0;
    int totalMinutes = 0;
    Map<String, int> exerciseCount = {};

    for (final log in logs) {
      totalCalories += log.caloriesBurned;
      totalMinutes += log.durationMinutes;

      // Count exercise frequency
      if (exerciseCount.containsKey(log.exerciseId)) {
        exerciseCount[log.exerciseId] = exerciseCount[log.exerciseId]! + 1;
      } else {
        exerciseCount[log.exerciseId] = 1;
      }
    }

    // Find most frequent exercise
    String mostFrequentExerciseId = '';
    int maxCount = 0;

    exerciseCount.forEach((id, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentExerciseId = id;
      }
    });

    // Get the exercise details if available
    Exercise? mostFrequentExercise;
    if (mostFrequentExerciseId.isNotEmpty) {
      try {
        mostFrequentExercise = await getExerciseById(mostFrequentExerciseId);
      } catch (e) {
        print('Error fetching most frequent exercise: $e');
      }
    }

    return {
      'totalCaloriesBurned': totalCalories,
      'totalMinutes': totalMinutes,
      'totalWorkouts': logs.length,
      'averageCaloriesPerWorkout':
          logs.length > 0 ? (totalCalories / logs.length).round() : 0,
      'mostFrequentExercise': mostFrequentExercise,
    };
  }

  // Calculate calories needed to burn for weight loss goal
  Future<Map<String, dynamic>> calculateCaloriesForWeightLossGoal(
    UserProfile userProfile,
    double currentWeight,
    double? targetWeight,
    int targetWeeks,
  ) async {
    if (targetWeight == null || targetWeight >= currentWeight) {
      return {
        'weeklyCalorieDeficit': 0,
        'dailyCalorieDeficit': 0,
        'suggestedDailyExerciseCalories': 0,
        'suggestedDailyDietCalories': 0,
      };
    }

    // Calculate total weight to lose
    final weightToLose = currentWeight - targetWeight; // in kg

    // Each kg of fat is approximately 7700 calories
    final totalCalorieDeficit = weightToLose * 7700;

    // Divide by number of weeks to get weekly deficit
    final weeklyCalorieDeficit = totalCalorieDeficit / targetWeeks;

    // Daily deficit
    final dailyCalorieDeficit = weeklyCalorieDeficit / 7;

    // Recommended exercise contribution (20-30% of deficit)
    final suggestedDailyExerciseCalories = dailyCalorieDeficit * 0.25;

    // Recommended diet contribution (70-80% of deficit)
    final suggestedDailyDietCalories = dailyCalorieDeficit * 0.75;

    return {
      'weeklyCalorieDeficit': weeklyCalorieDeficit.round(),
      'dailyCalorieDeficit': dailyCalorieDeficit.round(),
      'suggestedDailyExerciseCalories': suggestedDailyExerciseCalories.round(),
      'suggestedDailyDietCalories': suggestedDailyDietCalories.round(),
    };
  }

  // Get exercise recommendations based on user profile and goals
  Future<List<Exercise>> getRecommendedExercises(
    UserProfile userProfile,
    double currentWeight,
  ) async {
    final allExercises = await getAllExercises();

    // Determine user's fitness level
    ExerciseLevel userLevel;
    if (userProfile.activityLevel == null) {
      userLevel = ExerciseLevel.beginner;
    } else if (userProfile.activityLevel! < 1.3) {
      userLevel = ExerciseLevel.beginner;
    } else if (userProfile.activityLevel! < 1.6) {
      userLevel = ExerciseLevel.intermediate;
    } else {
      userLevel = ExerciseLevel.advanced;
    }

    // Filter exercises based on level
    List<Exercise> recommendedExercises = [];

    // First, include exercises marked as recommended
    recommendedExercises.addAll(
      allExercises.where((ex) => ex.isRecommended),
    );

    // Then, include exercises matching the user's level
    recommendedExercises.addAll(
      allExercises.where(
          (ex) => ex.level == userLevel && !recommendedExercises.contains(ex)),
    );

    // Ensure we have at least 5 exercises
    if (recommendedExercises.length < 5) {
      // Add exercises from adjacent levels
      for (final exercise in allExercises) {
        if (!recommendedExercises.contains(exercise)) {
          recommendedExercises.add(exercise);
          if (recommendedExercises.length >= 5) break;
        }
      }
    }

    // Limit to 6 exercises
    if (recommendedExercises.length > 6) {
      recommendedExercises = recommendedExercises.sublist(0, 6);
    }

    return recommendedExercises;
  }
}
