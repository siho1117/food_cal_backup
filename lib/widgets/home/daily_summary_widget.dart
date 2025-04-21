// lib/widgets/home/daily_summary_widget.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/user_repository.dart';

class DailySummaryWidget extends StatefulWidget {
  final DateTime date;

  const DailySummaryWidget({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  State<DailySummaryWidget> createState() => _DailySummaryWidgetState();
}

class _DailySummaryWidgetState extends State<DailySummaryWidget> {
  final FoodRepository _foodRepository = FoodRepository();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = true;
  int _totalCalories = 0;
  int _calorieGoal = 2000; // Default value
  Map<String, double> _macros = {
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(DailySummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load user profile to get calorie goal
      final userProfile = await _userRepository.getUserProfile();
      final currentWeight =
          (await _userRepository.getLatestWeightEntry())?.weight;

      // Calculate calorie goal if we have enough data
      if (userProfile != null &&
          currentWeight != null &&
          userProfile.height != null &&
          userProfile.age != null &&
          userProfile.gender != null &&
          userProfile.activityLevel != null) {
        // Calculate BMR
        double? bmr;
        if (userProfile.gender == 'Male') {
          bmr = (10 * currentWeight) +
              (6.25 * userProfile.height!) -
              (5 * userProfile.age!) +
              5;
        } else if (userProfile.gender == 'Female') {
          bmr = (10 * currentWeight) +
              (6.25 * userProfile.height!) -
              (5 * userProfile.age!) -
              161;
        } else {
          // Average of male and female formulas
          final maleBMR = (10 * currentWeight) +
              (6.25 * userProfile.height!) -
              (5 * userProfile.age!) +
              5;
          final femaleBMR = (10 * currentWeight) +
              (6.25 * userProfile.height!) -
              (5 * userProfile.age!) -
              161;
          bmr = (maleBMR + femaleBMR) / 2;
        }

        // Calculate TDEE based on activity level
        if (bmr != null) {
          final tdee = bmr * userProfile.activityLevel!;

          // Adjust for weight goal if available
          if (userProfile.monthlyWeightGoal != null) {
            // Calculate daily calorie adjustment
            final dailyWeightChangeKg = userProfile.monthlyWeightGoal! / 30;
            final calorieAdjustment =
                dailyWeightChangeKg * 7700; // ~7700 calories per kg

            // Set calorie goal with adjustment
            _calorieGoal = (tdee + calorieAdjustment).round();

            // Ensure minimum safe calories (90% of BMR)
            final minimumCalories = (bmr * 0.9).round();
            if (_calorieGoal < minimumCalories) {
              _calorieGoal = minimumCalories;
            }
          } else {
            // No weight goal, just use TDEE
            _calorieGoal = tdee.round();
          }
        }
      }

      // Load food entries
      final entriesByMeal =
          await _foodRepository.getFoodEntriesByMeal(widget.date);

      // Calculate totals
      int calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      // Process all meals
      for (var mealItems in entriesByMeal.values) {
        for (var item in mealItems) {
          calories += (item.calories * item.servingSize).round();
          protein += item.proteins * item.servingSize;
          carbs += item.carbs * item.servingSize;
          fat += item.fats * item.servingSize;
        }
      }

      if (mounted) {
        setState(() {
          _totalCalories = calories;
          _macros = {
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading daily summary: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate macro percentages
  Map<String, int> _calculateMacroPercentages() {
    final total = _macros['protein']! + _macros['carbs']! + _macros['fat']!;

    if (total <= 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': ((_macros['protein']! / total) * 100).round(),
      'carbs': ((_macros['carbs']! / total) * 100).round(),
      'fat': ((_macros['fat']! / total) * 100).round(),
    };
  }

  // Calculate calorie macro breakdown in grams
  Map<String, String> _calculateMacroGrams() {
    // Updated to remove decimal places
    return {
      'protein': _macros['protein']!.round().toString(),
      'carbs': _macros['carbs']!.round().toString(),
      'fat': _macros['fat']!.round().toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Calculate percentages
    final macroPercentages = _calculateMacroPercentages();
    final macroGrams = _calculateMacroGrams();

    // Calculate calorie progress percentage
    final calorieProgress = (_totalCalories / _calorieGoal).clamp(0.0, 1.0);
    final caloriesRemaining = _calorieGoal - _totalCalories;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                color: AppTheme.primaryBlue,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calorie display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_totalCalories',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $_calorieGoal cal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                caloriesRemaining > 0
                    ? '${caloriesRemaining} cal left'
                    : '${-caloriesRemaining} cal over',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: caloriesRemaining > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          LinearProgressIndicator(
            value: calorieProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              calorieProgress >= 1.0 ? Colors.red : AppTheme.primaryBlue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 20),

          // Macro breakdown
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          // Macro ratio visualization
          Row(
            children: [
              _buildMacroInfo(
                'Protein',
                macroGrams['protein']!,
                macroPercentages['protein']!,
                Colors.red,
              ),
              _buildMacroInfo(
                'Carbs',
                macroGrams['carbs']!,
                macroPercentages['carbs']!,
                Colors.green,
              ),
              _buildMacroInfo(
                'Fat',
                macroGrams['fat']!,
                macroPercentages['fat']!,
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Macro ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                _buildMacroBar(macroPercentages['protein']!, Colors.red),
                _buildMacroBar(macroPercentages['carbs']!, Colors.green),
                _buildMacroBar(macroPercentages['fat']!, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(
      String label, String grams, int percentage, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$grams g',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(int percentage, Color color) {
    // Set a minimum visible percentage if any value exists
    final displayPercentage = percentage > 0 && percentage < 5 ? 5 : percentage;

    return Expanded(
      flex: displayPercentage,
      child: Container(
        height: 16,
        color: color,
      ),
    );
  }
}
