import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/user_profile.dart';
import '../activity_level_info_dialog.dart';
import '../../utils/formula.dart'; // Import our new Formula utility

class TDEECalculatorWidget extends StatelessWidget {
  final UserProfile? userProfile;
  final double? currentWeight;

  const TDEECalculatorWidget({
    Key? key,
    required this.userProfile,
    required this.currentWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use centralized Formula class for calculations
    final bmr = Formula.calculateBMR(
      weight: currentWeight,
      height: userProfile?.height,
      age: userProfile?.age,
      gender: userProfile?.gender,
    );

    final tdee = Formula.calculateTDEE(
      bmr: bmr,
      activityLevel: userProfile?.activityLevel,
    );

    final missingData = Formula.getMissingData(
      profile: userProfile,
      currentWeight: currentWeight,
    );

    final calorieGoals = Formula.getCalorieTargets(tdee);

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
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppTheme.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Daily Calorie Needs (TDEE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => showActivityLevelInfoDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TDEE and BMR values
          if (tdee != null) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    '${tdee.round()}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const Text(
                    'calories/day',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // BMR info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BMR',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        bmr != null ? '${bmr.round()} cals' : 'Not available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Resting metabolism',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Activity Level
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        Formula.getActivityLevelText(
                            userProfile?.activityLevel),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userProfile?.activityLevel != null
                            ? 'Multiplier: ${userProfile!.activityLevel!.toStringAsFixed(2)}'
                            : 'Not set',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Calorie goals
            const Text(
              'CALORIE TARGETS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildCalorieGoalItem(
                  'Weight Loss',
                  '${calorieGoals['lose']}',
                  Colors.green,
                ),
                _buildCalorieGoalItem(
                  'Maintain',
                  '${calorieGoals['maintain']}',
                  AppTheme.primaryBlue,
                ),
                _buildCalorieGoalItem(
                  'Weight Gain',
                  '${calorieGoals['gain']}',
                  Colors.orange,
                ),
              ],
            ),
          ],

          // If TDEE is not available, show missing data message
          if (tdee == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                        'Missing profile data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To calculate your TDEE, please update your profile with: ${missingData.join(", ")}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go to Settings tab to complete your profile.',
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

          const SizedBox(height: 10),

          // What is TDEE explanation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TDEE (Total Daily Energy Expenditure) is the total number of calories you burn each day based on your BMR and physical activity level.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieGoalItem(String label, String calories, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              calories,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'cals/day',
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
