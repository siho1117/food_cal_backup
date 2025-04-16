// lib/data/models/user_profile.dart
import '../../utils/formula.dart';

class UserProfile {
  final String id;
  final String? name;
  final int? age;
  final double? height; // Stored in cm
  final bool isMetric; // User's preferred unit system
  final String? gender;
  final double? goalWeight; // Stored in kg
  final double? activityLevel; // 1.2 (sedentary) - 1.9 (very active)
  final DateTime? birthDate; // New field for date of birth
  final double?
      monthlyWeightGoal; // New field for monthly weight change goal in kg

  UserProfile({
    required this.id,
    this.name,
    this.age,
    this.height,
    this.isMetric = true,
    this.gender,
    this.goalWeight,
    this.activityLevel,
    this.birthDate,
    this.monthlyWeightGoal,
  });

  // Copy constructor for updating user profile
  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    double? height,
    bool? isMetric,
    String? gender,
    double? goalWeight,
    double? activityLevel,
    DateTime? birthDate,
    double? monthlyWeightGoal,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      isMetric: isMetric ?? this.isMetric,
      gender: gender ?? this.gender,
      goalWeight: goalWeight ?? this.goalWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      birthDate: birthDate ?? this.birthDate,
      monthlyWeightGoal: monthlyWeightGoal ?? this.monthlyWeightGoal,
    );
  }

  // Format height based on user's preferred unit system
  String formattedHeight() {
    if (height == null) return 'Not set';

    if (isMetric) {
      return '$height cm';
    } else {
      // Convert cm to feet and inches
      final totalInches = height! / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return '$feet\' $inches"';
    }
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    print('Saving UserProfile with age: $age'); // Debug print
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'isMetric': isMetric,
      'gender': gender,
      'goalWeight': goalWeight,
      'activityLevel': activityLevel,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'monthlyWeightGoal': monthlyWeightGoal,
    };
  }

  // Create from map for retrieval
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Ensure proper type conversion for age
    int? ageValue;
    if (map['age'] != null) {
      if (map['age'] is int) {
        ageValue = map['age'] as int;
      } else if (map['age'] is double) {
        ageValue = (map['age'] as double).toInt();
      } else if (map['age'] is String) {
        ageValue = int.tryParse(map['age'] as String);
      }
    }

    // Debug print
    print('Loading UserProfile with age: $ageValue');

    final profile = UserProfile(
      id: map['id'],
      name: map['name'],
      age: ageValue,
      height: map['height'],
      isMetric: map['isMetric'] ?? true,
      gender: map['gender'],
      goalWeight: map['goalWeight'],
      activityLevel: map['activityLevel'],
      birthDate: map['birthDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['birthDate'])
          : null,
      monthlyWeightGoal: map['monthlyWeightGoal'],
    );

    // Add debug print after creating the profile
    profile.debugPrint();

    return profile;
  }

  // Debug method to print all user profile details
  void debugPrint() {
    print("\n===== USER PROFILE DEBUG INFO =====");
    print("ID: $id");
    print("Name: $name");
    print("Age: $age");
    print("Height: ${height != null ? '$height cm' : 'Not set'}");
    print("Gender: ${gender ?? 'Not set'}");
    print("Is Metric: $isMetric");
    print("Goal Weight: ${goalWeight != null ? '$goalWeight kg' : 'Not set'}");
    print(
        "Monthly Weight Goal: ${monthlyWeightGoal != null ? '$monthlyWeightGoal kg' : 'Not set'}");
    print("Activity Level: ${activityLevel ?? 'Not set'}");
    print(
        "Birth Date: ${birthDate != null ? birthDate.toString() : 'Not set'}");
    print("Complete Map: ${toMap()}");
    print("===================================\n");
  }
}
