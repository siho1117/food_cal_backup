import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/models/user_profile.dart';
import '../widgets/activity_level_info_dialog.dart';
import 'dart:math' as math;

class CalorieCalculatorWidget extends StatelessWidget {
  final UserProfile? userProfile;
  final double? currentWeight;
  final VoidCallback onTap;

  const CalorieCalculatorWidget({
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
    if (level < 1.45) return 'Light Activity';
    if (level < 1.65) return 'Moderate Activity';
    if (level < 1.8) return 'Active';
    return 'Very Active';
  }

  @override
  Widget build(BuildContext context) {
    final bmr = _calculateBMR();
    final tdee = _calculateTDEE();

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
                'Calorie Calculation',
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

          // Data visualization area
          Row(
            children: [
              // Left side - placeholder for calorie chart
              Expanded(
                flex: 1,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Complete profile for calorie data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right side - macro pie chart
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Macros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Center(
                        child: MacroPieChart(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

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
                      bmr != null ? '${bmr.round()}' : 'Not available',
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
                      tdee != null ? '${tdee.round()}' : 'Not available',
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
                : 'Daily calorie needs based on your activity level',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class MacroPieChart extends StatelessWidget {
  final Map<String, double> macroRatios;
  final Map<String, Color> macroColors;

  MacroPieChart({
    Key? key,
    Map<String, double>? macroRatios,
    Map<String, Color>? macroColors,
  })  : macroRatios =
            macroRatios ?? {'Protein': 0.25, 'Carbs': 0.50, 'Fat': 0.25},
        macroColors = macroColors ??
            {
              'Protein': Colors.red,
              'Carbs': Colors.green,
              'Fat': Colors.blue,
            },
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _MacroPieChartPainter(
              macroRatios: macroRatios,
              macroColors: macroColors,
            ),
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MacroPieChartPainter extends CustomPainter {
  final Map<String, double> macroRatios;
  final Map<String, Color> macroColors;

  _MacroPieChartPainter({
    required this.macroRatios,
    required this.macroColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top (12 o'clock)

    macroRatios.forEach((macro, ratio) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = macroColors[macro] ?? Colors.grey;

      final sweepAngle = 2 * math.pi * ratio;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
