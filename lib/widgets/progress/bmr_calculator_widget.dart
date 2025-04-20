import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/user_profile.dart';

class BMRCalculatorWidget extends StatelessWidget {
  final UserProfile? userProfile;
  final double? currentWeight;

  const BMRCalculatorWidget({
    Key? key,
    required this.userProfile,
    required this.currentWeight,
  }) : super(key: key);

  /// Calculate BMR using Mifflin-St Jeor Equation
  double? calculateBMR() {
    // Check if all required data is available
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

    // Gender-specific BMR calculation
    if (gender == 'Male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender == 'Female') {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // If gender is not specified or other, use an average of male and female values
    final maleBMR = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    final femaleBMR = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    return (maleBMR + femaleBMR) / 2;
  }

  /// Check which data is missing for BMR calculation
  List<String> getMissingData() {
    final missingData = <String>[];

    if (userProfile == null) {
      missingData.add("Profile");
      return missingData;
    }

    if (currentWeight == null) {
      missingData.add("Weight");
    }

    if (userProfile!.height == null) {
      missingData.add("Height");
    }

    if (userProfile!.age == null) {
      missingData.add("Age");
    }

    if (userProfile!.gender == null) {
      missingData.add("Gender");
    }

    return missingData;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate BMR
    final bmrValue = calculateBMR();
    final missingData = getMissingData();

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
                'Basal Metabolic Rate (BMR)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // BMR Value display
          Center(
            child: Column(
              children: [
                Text(
                  bmrValue != null ? '${bmrValue.round()}' : 'Not available',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color:
                        bmrValue != null ? AppTheme.primaryBlue : Colors.grey,
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

          const SizedBox(height: 16),

          // If BMR is available, show explanation
          if (bmrValue != null) ...[
            const Text(
              'Your Basal Metabolic Rate (BMR) is the number of calories your body needs to maintain basic physiological functions while at complete rest.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Formula used
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mifflin-St Jeor Equation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Men: (10 × weight) + (6.25 × height) - (5 × age) + 5',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Women: (10 × weight) + (6.25 × height) - (5 × age) - 161',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // If BMR is not available, show missing data message
          if (bmrValue == null) ...[
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
                    'To calculate your BMR, please update your profile with: ${missingData.join(", ")}',
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

          if (bmrValue != null) ...[
            const SizedBox(height: 16),

            // Status message when BMR is calculated
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BMR calculation complete based on your profile data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
