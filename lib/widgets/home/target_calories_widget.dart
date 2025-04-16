// lib/widgets/home/target_calories_widget.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_profile.dart';
import '../../utils/formula.dart';

class TargetCaloriesWidget extends StatefulWidget {
  const TargetCaloriesWidget({Key? key}) : super(key: key);

  @override
  State<TargetCaloriesWidget> createState() => _TargetCaloriesWidgetState();
}

class _TargetCaloriesWidgetState extends State<TargetCaloriesWidget> {
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = true;
  UserProfile? _userProfile;
  double? _currentWeight;
  int _targetCalories = 0;
  String _goalDescription = "";
  Map<String, dynamic> _macros = {
    'protein_percentage': 30,
    'carbs_percentage': 45,
    'fat_percentage': 25,
    'protein_per_kg': 1.8,
    'recommended_protein_grams': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final userProfile = await _userRepository.getUserProfile();

      // Load latest weight entry
      final latestWeight = await _userRepository.getLatestWeightEntry();

      // Calculate BMR
      final bmr = Formula.calculateBMR(
        weight: latestWeight?.weight,
        height: userProfile?.height,
        age: userProfile?.age,
        gender: userProfile?.gender,
      );

      // Calculate target calories
      final targetCalories = Formula.calculateRecommendedCalorieIntake(
        bmr: bmr,
        activityLevel: userProfile?.activityLevel,
        monthlyWeightGoal: userProfile?.monthlyWeightGoal,
      );

      // Get goal description
      final goalDescription = Formula.getCalorieGoalDescription(
        userProfile?.monthlyWeightGoal,
      );

      // Calculate personalized macronutrient ratios
      final macros = Formula.calculateMacronutrientRatio(
        monthlyWeightGoal: userProfile?.monthlyWeightGoal,
        activityLevel: userProfile?.activityLevel,
        gender: userProfile?.gender,
        age: userProfile?.age,
        currentWeight: latestWeight?.weight,
      );

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _currentWeight = latestWeight?.weight;
          _targetCalories = targetCalories;
          _goalDescription = goalDescription;
          _macros = macros;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate macro grams based on percentages and total calories
  int _calculateMacroGrams(int percentage, int calories, int caloriesPerGram) {
    return ((calories * percentage / 100) / caloriesPerGram).round();
  }

  // Get color based on macronutrient
  Color _getMacroColor(String macro) {
    switch (macro) {
      case 'Protein':
        return Colors.red.shade600;
      case 'Carbs':
        return Colors.green.shade600;
      case 'Fat':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCompleteData = _targetCalories > 0;

    // Calculate macro grams based on percentages and total calories
    final proteinGrams = hasCompleteData
        ? _calculateMacroGrams(
            _macros['protein_percentage'], _targetCalories, 4)
        : 0;
    final carbsGrams = hasCompleteData
        ? _calculateMacroGrams(_macros['carbs_percentage'], _targetCalories, 4)
        : 0;
    final fatGrams = hasCompleteData
        ? _calculateMacroGrams(_macros['fat_percentage'], _targetCalories, 9)
        : 0;

    return Container(
      width: double.infinity,
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
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Daily Calorie Target',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // If loading, show progress indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // If data is available, show the target calories
          if (!_isLoading && hasCompleteData) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    _targetCalories.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    'calories/day $_goalDescription',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Macronutrient breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMacroItem(
                  label: 'Protein',
                  percentage: _macros['protein_percentage'],
                  grams: proteinGrams,
                  color: _getMacroColor('Protein'),
                ),
                _buildMacroItem(
                  label: 'Carbs',
                  percentage: _macros['carbs_percentage'],
                  grams: carbsGrams,
                  color: _getMacroColor('Carbs'),
                ),
                _buildMacroItem(
                  label: 'Fat',
                  percentage: _macros['fat_percentage'],
                  grams: fatGrams,
                  color: _getMacroColor('Fat'),
                ),
              ],
            ),

            // Protein recommendation based on body weight
            if (_macros.containsKey('protein_per_kg') &&
                _macros.containsKey('recommended_protein_grams') &&
                _macros['recommended_protein_grams'] > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended protein: ${_macros['recommended_protein_grams']}g ' +
                            '(${_macros['protein_per_kg'].toStringAsFixed(1)}g per kg of body weight)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // If missing data, show configuration message
          if (!_isLoading && !hasCompleteData) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Complete your profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please update your profile with your height, weight, age, gender, activity level, and monthly weight goal to see your personalized calorie target.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to settings screen
                      // Note: You may need to adjust this navigation based on your app's routing setup
                      Navigator.pushNamed(context, '/settings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required int percentage,
    required int grams,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$grams g',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
