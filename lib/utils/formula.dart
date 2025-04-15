import '../data/models/user_profile.dart';
import '../data/models/weight_entry.dart';

/// Centralized class for health-related formula calculations
/// All methods are static to allow easy access without instantiation
class Formula {
  // Private constructor to prevent instantiation
  Formula._();

  /// Calculate BMI using the standard formula: weight(kg) / height(m)²
  static double? calculateBMI({
    required double? height, // in cm
    required double? weight, // in kg
  }) {
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return null;
    }

    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI classification based on standard ranges
  static String getBMIClassification(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  /// Calculate body fat percentage using the Deurenberg formula
  /// Body Fat % = 1.2 × BMI + 0.23 × age - 10.8 × sex - 5.4
  /// Where sex is 1 for males and 0 for females
  static double? calculateBodyFat({
    required double? bmi,
    required int? age,
    required String? gender,
  }) {
    if (bmi == null) return null;

    // Default age if not available - using 30 as a reasonable middle value
    final int calculationAge = age ?? 30;

    // Gender factor for the formula
    double genderFactor;
    if (gender == 'Male') {
      genderFactor = 1.0;
    } else if (gender == 'Female') {
      genderFactor = 0.0;
    } else {
      // If gender not specified, use an average (0.5)
      genderFactor = 0.5;
    }

    // Calculate using the formula
    double result =
        (1.2 * bmi) + (0.23 * calculationAge) - (10.8 * genderFactor) - 5.4;

    // Ensure result is in a reasonable range
    return result.clamp(3.0, 60.0);
  }

  /// Get body fat classification based on percentage and gender
  static String getBodyFatClassification(double bodyFat, String? gender) {
    if (gender == 'Male') {
      if (bodyFat < 6) return 'Essential';
      if (bodyFat < 14) return 'Athletic';
      if (bodyFat < 18) return 'Fitness';
      if (bodyFat < 25) return 'Average';
      if (bodyFat < 30) return 'Above Avg';
      return 'Obese';
    } else if (gender == 'Female') {
      if (bodyFat < 14) return 'Essential';
      if (bodyFat < 21) return 'Athletic';
      if (bodyFat < 25) return 'Fitness';
      if (bodyFat < 32) return 'Average';
      if (bodyFat < 38) return 'Above Avg';
      return 'Obese';
    } else {
      // Gender-neutral classifications
      if (bodyFat < 10) return 'Essential';
      if (bodyFat < 18) return 'Athletic';
      if (bodyFat < 22) return 'Fitness';
      if (bodyFat < 28) return 'Average';
      if (bodyFat < 35) return 'Above Avg';
      return 'Obese';
    }
  }

  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
  static double? calculateBMR({
    required double? weight, // in kg
    required double? height, // in cm
    required int? age,
    required String? gender,
  }) {
    if (weight == null || height == null || age == null) {
      return null;
    }

    // Gender-specific BMR calculation
    if (gender == 'Male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (gender == 'Female') {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // If gender is not specified, use an average of male and female values
    final maleBMR = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    final femaleBMR = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    return (maleBMR + femaleBMR) / 2;
  }

  /// Calculate TDEE (Total Daily Energy Expenditure) based on BMR and activity level
  static double? calculateTDEE({
    required double? bmr,
    required double? activityLevel,
  }) {
    if (bmr == null || activityLevel == null) {
      return null;
    }

    return bmr * activityLevel;
  }

  /// Get activity level description based on the multiplier
  static String getActivityLevelText(double? activityLevel) {
    if (activityLevel == null) {
      return 'Not set';
    }

    if (activityLevel < 1.3) return 'Sedentary';
    if (activityLevel < 1.45) return 'Light Activity';
    if (activityLevel < 1.65) return 'Moderate Activity';
    if (activityLevel < 1.8) return 'Active';
    return 'Very Active';
  }

  /// Calculate calorie targets for weight loss, maintenance, and gain
  static Map<String, int> getCalorieTargets(double? tdee) {
    if (tdee == null) {
      return {'lose': 0, 'maintain': 0, 'gain': 0};
    }

    final int maintain = tdee.round();
    final int lose = (maintain * 0.8).round(); // 20% deficit for weight loss
    final int gain = (maintain * 1.15).round(); // 15% surplus for weight gain

    return {'lose': lose, 'maintain': maintain, 'gain': gain};
  }

  /// Calculate progress percentage toward goal weight
  static double calculateGoalProgress({
    required double? currentWeight,
    required double? targetWeight,
  }) {
    if (currentWeight == null || targetWeight == null) {
      return 0.0;
    }

    // If target equals current, return 100%
    if ((targetWeight - currentWeight).abs() < 0.1) {
      return 1.0;
    }

    // If losing weight
    if (currentWeight > targetWeight) {
      // Assume starting point was 20% higher than target
      final startWeight = targetWeight * 1.2;
      final totalToLose = startWeight - targetWeight;
      final lost = startWeight - currentWeight;

      return (lost / totalToLose).clamp(0.0, 1.0);
    }
    // If gaining weight
    else {
      // Assume starting point was 20% lower than target
      final startWeight = targetWeight * 0.8;
      final totalToGain = targetWeight - startWeight;
      final gained = currentWeight - startWeight;

      return (gained / totalToGain).clamp(0.0, 1.0);
    }
  }

  /// Calculate remaining weight to goal
  static double? getRemainingWeightToGoal({
    required double? currentWeight,
    required double? targetWeight,
  }) {
    if (currentWeight == null || targetWeight == null) {
      return null;
    }

    return currentWeight - targetWeight;
  }

  /// Get weight change direction text (to lose/to gain)
  static String getWeightChangeDirectionText({
    required double? currentWeight,
    required double? targetWeight,
    required bool isMetric,
  }) {
    if (currentWeight == null || targetWeight == null) {
      return 'Set a target weight to track progress';
    }

    final difference = currentWeight - targetWeight;
    if (difference.abs() < 0.1) {
      return 'Goal achieved! 🎉';
    }

    // Calculate the absolute difference
    final absoluteDifference = difference.abs();

    // Convert to display units (kg or lbs)
    final displayDifference =
        isMetric ? absoluteDifference : absoluteDifference * 2.20462;

    final formattedDifference = displayDifference.toStringAsFixed(1);
    final units = isMetric ? 'kg' : 'lbs';

    // Return formatted text based on whether gaining or losing
    return difference > 0
        ? '$formattedDifference $units to lose'
        : '$formattedDifference $units to gain';
  }

  /// Format height with proper units
  static String formatHeight({
    required double? height, // in cm
    required bool isMetric,
  }) {
    if (height == null) return 'Not set';

    if (isMetric) {
      return '$height cm';
    } else {
      // Convert cm to feet and inches
      final totalInches = height / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return '$feet\' $inches"';
    }
  }

  /// Format weight with proper units
  static String formatWeight({
    required double? weight,
    required bool isMetric,
    int decimalPlaces = 1,
  }) {
    if (weight == null) return 'Not set';

    final displayWeight = isMetric ? weight : weight * 2.20462;
    return '${displayWeight.toStringAsFixed(decimalPlaces)} ${isMetric ? 'kg' : 'lbs'}';
  }

  /// Calculate weight change over a time period
  static double? calculateWeightChange({
    required List<WeightEntry> entries,
    required DateTime startDate,
  }) {
    if (entries.isEmpty) return null;

    // Sort by timestamp (newest first)
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Get latest weight
    final latestWeight = sortedEntries.first.weight;

    // Find the closest entry to the start date
    WeightEntry? startEntry;
    for (final entry in sortedEntries.reversed) {
      if (entry.timestamp.isAfter(startDate) ||
          entry.timestamp.isAtSameMomentAs(startDate)) {
        startEntry = entry;
        break;
      }
    }

    if (startEntry == null) return null;

    // Calculate change (positive means weight gain, negative means weight loss)
    return latestWeight - startEntry.weight;
  }

  /// Calculate average daily calorie needs based on goals
  static Map<String, int> calculateDailyCalorieNeeds({
    required UserProfile? profile,
    required double? currentWeight,
  }) {
    if (profile == null || currentWeight == null) {
      return {
        'maintenance': 0,
        'lose_slow': 0,
        'lose_medium': 0,
        'lose_fast': 0,
        'gain_slow': 0,
        'gain_medium': 0,
        'gain_fast': 0,
      };
    }

    // Calculate BMR
    final bmr = calculateBMR(
      weight: currentWeight,
      height: profile.height,
      age: profile.age,
      gender: profile.gender,
    );

    if (bmr == null || profile.activityLevel == null) {
      return {
        'maintenance': 0,
        'lose_slow': 0,
        'lose_medium': 0,
        'lose_fast': 0,
        'gain_slow': 0,
        'gain_medium': 0,
        'gain_fast': 0,
      };
    }

    // Calculate TDEE
    final tdee = bmr * profile.activityLevel!;
    final maintenance = tdee.round();

    // Calculate calorie targets for different goals
    return {
      'maintenance': maintenance,
      'lose_slow': (maintenance - 250).round(), // 0.25 kg/week loss
      'lose_medium': (maintenance - 500).round(), // 0.5 kg/week loss
      'lose_fast': (maintenance - 1000).round(), // 1 kg/week loss
      'gain_slow': (maintenance + 250).round(), // 0.25 kg/week gain
      'gain_medium': (maintenance + 500).round(), // 0.5 kg/week gain
      'gain_fast': (maintenance + 1000).round(), // 1 kg/week gain
    };
  }

  /// Get list of missing data for calculations
  static List<String> getMissingData({
    required UserProfile? profile,
    required double? currentWeight,
  }) {
    final missingData = <String>[];

    if (profile == null) {
      missingData.add("Profile");
      return missingData;
    }

    if (currentWeight == null) {
      missingData.add("Weight");
    }

    if (profile.height == null) {
      missingData.add("Height");
    }

    if (profile.age == null) {
      missingData.add("Age");
    }

    if (profile.gender == null) {
      missingData.add("Gender");
    }

    if (profile.activityLevel == null) {
      missingData.add("Activity Level");
    }

    return missingData;
  }
}
