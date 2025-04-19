import 'package:flutter/material.dart';
import '../lib/config/theme.dart';
import '../lib/data/models/user_profile.dart'; // Add this import

class CalorieCalculationWidget extends StatelessWidget {
  final UserProfile? userProfile;
  final double? currentWeight;
  final Function() onTap;

  const CalorieCalculationWidget({
    Key? key,
    required this.userProfile,
    required this.currentWeight,
    required this.onTap,
  }) : super(key: key);

  // Calculate BMR using Mifflin-St Jeor Equation
  double? _calculateBMR() {
    if (userProfile == null ||
        currentWeight == null ||
        userProfile!.height == null ||
        userProfile!.age == null ||
        userProfile!.gender == null) {
      return null;
    }

    final weight = currentWeight!; // in kg
    final height = userProfile!.height!; // in cm
    final age = userProfile!.age!;
    final gender = userProfile!.gender;

    if (gender == 'Male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender == 'Female') {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // If gender not specified or other, use an average
    final maleBMR = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    final femaleBMR = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    return (maleBMR + femaleBMR) / 2;
  }

  // Calculate TDEE
  double? _calculateTDEE() {
    final bmr = _calculateBMR();
    if (bmr == null || userProfile?.activityLevel == null) {
      return null;
    }

    return bmr * userProfile!.activityLevel!;
  }

  // Format calorie values
  String _formatCalories(double? calories) {
    if (calories == null) {
      return 'Not available';
    }
    return '${calories.round()} kcal';
  }

  // Get activity level text
  String _getActivityLevelText() {
    if (userProfile?.activityLevel == null) {
      return 'Not set';
    }

    final level = userProfile!.activityLevel!;
    if (level < 1.3) return 'Sedentary';
    if (level < 1.45) return 'Light';
    if (level < 1.65) return 'Moderate';
    if (level < 1.8) return 'Active';
    return 'Very Active';
  }

  @override
  Widget build(BuildContext context) {
    final bmr = _calculateBMR();
    final tdee = _calculateTDEE();

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  'Calorie Calculation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
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
              ],
            ),

            const SizedBox(height: 16),

            // BMR and TDEE rows
            Row(
              children: [
                // BMR column
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
                        _formatCalories(bmr),
                        style: const TextStyle(
                          fontSize: 18,
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

                // TDEE column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TDEE',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatCalories(tdee),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getActivityLevelText(),
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

            const SizedBox(height: 12),

            // Note about calculations
            Text(
              userProfile?.gender == null ||
                      userProfile?.age == null ||
                      userProfile?.height == null
                  ? 'Complete your profile to see accurate calculations'
                  : 'Daily calorie burn based on your profile data',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
