import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/user_profile.dart';
import '../../utils/formula.dart';

class DailyBurnWidget extends StatelessWidget {
  final UserProfile? userProfile;
  final double? currentWeight;

  const DailyBurnWidget({
    Key? key,
    required this.userProfile,
    required this.currentWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate BMR for use in exercise recommendations
    final bmr = Formula.calculateBMR(
      weight: currentWeight,
      height: userProfile?.height,
      age: userProfile?.age,
      gender: userProfile?.gender,
    );

    // Calculate recommended exercise burn
    final burnRecommendation = Formula.calculateRecommendedExerciseBurn(
      monthlyWeightGoal: userProfile?.monthlyWeightGoal,
      bmr: bmr,
      activityLevel: userProfile?.activityLevel,
      age: userProfile?.age,
      gender: userProfile?.gender,
      currentWeight: currentWeight,
    );

    // Extract values from the recommendation
    final dailyBurn = burnRecommendation['daily_burn'] as int;
    final weeklyBurn = burnRecommendation['weekly_burn'] as int;
    final lightMinutes = burnRecommendation['light_minutes'] as int;
    final moderateMinutes = burnRecommendation['moderate_minutes'] as int;
    final intenseMinutes = burnRecommendation['intense_minutes'] as int;
    final recommendationType =
        burnRecommendation['recommendation_type'] as String;
    final safetyAdjusted = burnRecommendation['safety_adjusted'] as bool;

    // Get descriptive text based on recommendation type
    String recommendationText;
    Color recommendationColor;

    switch (recommendationType) {
      case 'loss':
        recommendationText = 'Supports your weight loss goal';
        recommendationColor = Colors.green;
        break;
      case 'gain':
        recommendationText = 'Supports your muscle gain goal';
        recommendationColor = Colors.blue;
        break;
      case 'maintain':
        recommendationText = 'Helps maintain your current weight';
        recommendationColor = AppTheme.primaryBlue;
        break;
      default:
        recommendationText =
            'Complete your profile for a personalized recommendation';
        recommendationColor = Colors.grey;
    }

    // Check if we have enough data for a recommendation
    final hasRecommendation = dailyBurn > 0;

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
                'Daily Exercise Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main content - depends on whether we have recommendation data
          if (hasRecommendation)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily and weekly burn targets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCalorieBurnIndicator(
                      title: 'Daily Burn',
                      calories: dailyBurn,
                      subtitle: 'calories',
                      isPrimary: true,
                    ),
                    _buildCalorieBurnIndicator(
                      title: 'Weekly Burn',
                      calories: weeklyBurn,
                      subtitle: 'calories',
                      isPrimary: false,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Recommendation text
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: recommendationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        recommendationType == 'loss'
                            ? Icons.trending_down
                            : (recommendationType == 'gain'
                                ? Icons.trending_up
                                : Icons.loop),
                        color: recommendationColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendationText,
                          style: TextStyle(
                            color: recommendationColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Exercise time recommendations
                const Text(
                  'RECOMMENDED EXERCISE TIME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                // Exercise options
                _buildExerciseOption(
                  intensity: 'Light',
                  examples: 'Walking, yoga, stretching',
                  minutes: lightMinutes,
                  color: Colors.green,
                ),

                const SizedBox(height: 8),

                _buildExerciseOption(
                  intensity: 'Moderate',
                  examples: 'Brisk walking, cycling, swimming',
                  minutes: moderateMinutes,
                  color: AppTheme.primaryBlue,
                ),

                const SizedBox(height: 8),

                _buildExerciseOption(
                  intensity: 'Intense',
                  examples: 'Running, HIIT, sports',
                  minutes: intenseMinutes,
                  color: Colors.orange,
                ),

                const SizedBox(height: 12),

                // Note on exercise recommendations
                Text(
                  'Note: Choose any one of these options to meet your daily goal. Mix different intensities throughout the week for best results.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          else
            // Show message when data is insufficient for recommendations
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
                    'To get a personalized exercise recommendation, please update your profile with your height, weight, age, gender, activity level, and monthly weight goal.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Regular exercise is important regardless of your weight goals. Aim for at least 150 minutes of moderate activity each week.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalorieBurnIndicator({
    required String title,
    required int calories,
    required String subtitle,
    required bool isPrimary,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppTheme.primaryBlue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isPrimary ? AppTheme.primaryBlue : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$calories',
            style: TextStyle(
              fontSize: isPrimary ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppTheme.primaryBlue : Colors.grey[800],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isPrimary
                  ? AppTheme.primaryBlue.withOpacity(0.8)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseOption({
    required String intensity,
    required String examples,
    required int minutes,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${minutes}m',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intensity,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  examples,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
