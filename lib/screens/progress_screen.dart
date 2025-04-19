import 'package:flutter/material.dart';
import '../widgets/settings/weight_entry_dialog.dart'; // Kept in the original location
import '../widgets/progress/target_weight_dialog.dart'; // Updated path
import '../widgets/progress/target_weight_widget.dart'; // Updated path
import '../widgets/progress/bmr_calculator_widget.dart'; // Updated path
import '../widgets/progress/tdee_calculator_widget.dart'; // Updated path
import '../data/repositories/user_repository.dart';
import '../data/models/weight_entry.dart';
import '../data/models/user_profile.dart';
import '../widgets/progress/bmi_widget.dart';
import '../widgets/progress/body_fat_widget.dart';
import '../config/theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // User data
  double _currentWeight = 70.0; // Default in kg
  double? _targetWeight; // Target weight in kg
  bool _isMetric = true;
  final UserRepository _userRepository = UserRepository();
  UserProfile? _userProfile; // Store user profile

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user profile for unit preference
      final userProfile = await _userRepository.getUserProfile();

      // Load latest weight entry
      final latestWeight = await _userRepository.getLatestWeightEntry();

      if (mounted) {
        setState(() {
          _userProfile = userProfile; // Store the user profile

          if (userProfile != null) {
            _isMetric = userProfile.isMetric;
            _targetWeight = userProfile.goalWeight; // Load target weight
          }

          if (latestWeight != null) {
            _currentWeight = latestWeight.weight; // Always in kg
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _showWeightEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => WeightEntryDialog(
        initialWeight: _currentWeight,
        isMetric: _isMetric,
        onWeightSaved: (weight, isMetric) async {
          setState(() {
            _currentWeight = weight;
            _isMetric = isMetric;
          });

          // Save to data repository
          final weightEntry = WeightEntry.create(weight: weight);
          await _userRepository.addWeightEntry(weightEntry);

          // Update user preference for units if changed
          if (_userProfile != null && _userProfile!.isMetric != isMetric) {
            final updatedProfile = _userProfile!.copyWith(isMetric: isMetric);
            await _userRepository.saveUserProfile(updatedProfile);
            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Show target weight dialog
  void _showTargetWeightDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => TargetWeightDialog(
        initialTargetWeight: _targetWeight,
        isMetric: _isMetric,
        onWeightSaved: (weight, isMetric) async {
          setState(() {
            _targetWeight = weight; // Always in metric
            _isMetric = isMetric;
          });

          // Update user profile
          if (_userProfile != null) {
            final updatedProfile = _userProfile!.copyWith(
              goalWeight: weight,
              isMetric: isMetric,
            );
            await _userRepository.saveUserProfile(updatedProfile);
            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Create a new user profile if one doesn't exist
  Future<void> _createUserProfileIfNeeded() async {
    if (_userProfile == null) {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newProfile = UserProfile(
        id: userId,
        isMetric: _isMetric,
      );

      await _userRepository.saveUserProfile(newProfile);
      setState(() {
        _userProfile = newProfile;
      });
    }
  }

  String get _formattedWeight {
    final displayWeight = _isMetric ? _currentWeight : _currentWeight * 2.20462;
    return displayWeight.toStringAsFixed(1) + (_isMetric ? ' kg' : ' lbs');
  }

  // Current weight card widget
  Widget _buildCurrentWeightCard() {
    return GestureDetector(
      onTap: _showWeightEntryDialog,
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
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.monitor_weight,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedWeight,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Edit button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Weight Card
              _buildCurrentWeightCard(),

              const SizedBox(height: 20),

              // Target Weight Widget
              TargetWeightWidget(
                targetWeight: _targetWeight,
                currentWeight: _currentWeight,
                isMetric: _isMetric,
                onTap: _showTargetWeightDialog,
              ),

              const SizedBox(height: 20),

              // TDEE Calculator Widget
              TDEECalculatorWidget(
                userProfile: _userProfile,
                currentWeight: _currentWeight,
              ),

              const SizedBox(height: 20),

              // BMR Calculator Widget
              BMRCalculatorWidget(
                userProfile: _userProfile,
                currentWeight: _currentWeight,
              ),

              const SizedBox(height: 20),

              // BMI and Body Fat widgets in a row
              SizedBox(
                height: 130, // Fixed height for both widgets
                child: FutureBuilder<double?>(
                  future: _userRepository.calculateBMI(),
                  builder: (context, snapshot) {
                    final bmiValue = snapshot.data;
                    String classification = "Not set";

                    if (bmiValue != null) {
                      classification =
                          _userRepository.getBMIClassification(bmiValue);
                    }

                    // Extract profile data needed for body fat calculation
                    final String? gender = _userProfile?.gender;
                    final int? age = _userProfile?.age;

                    // Calculate body fat using the formula in the repository
                    double? bodyFatValue;
                    String bodyFatClassification = "";

                    if (bmiValue != null) {
                      bodyFatValue = _calculateBodyFat(bmiValue, age, gender);

                      if (bodyFatValue != null) {
                        bodyFatClassification =
                            _getBodyFatClassification(bodyFatValue, gender);
                      }
                    }

                    return Row(
                      children: [
                        // BMI Widget
                        BMIWidget(
                          bmiValue: bmiValue,
                          classification: classification,
                        ),

                        const SizedBox(width: 16),

                        // Body Fat Widget
                        BodyFatWidget(
                          bodyFatPercentage: bodyFatValue,
                          classification: bodyFatClassification,
                          isEstimated: true,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  // Calculate body fat percentage using the Deurenberg formula
  double? _calculateBodyFat(double? bmi, int? age, String? gender) {
    if (bmi == null) return null;

    // Default age if not available - using 30 as a reasonable middle value
    final int calculationAge = age ?? 30;

    // Deurenberg formula: Body Fat % = 1.2 × BMI + 0.23 × age - 10.8 × sex - 5.4
    // Where sex is 1 for males and 0 for females
    double genderFactor;
    if (gender == 'Male') {
      genderFactor = 1.0;
    } else if (gender == 'Female') {
      genderFactor = 0.0;
    } else {
      // If gender not specified, use an average (0.5)
      // This is a compromise for unknown gender
      genderFactor = 0.5;
    }

    // Calculate using the formula
    double result =
        (1.2 * bmi) + (0.23 * calculationAge) - (10.8 * genderFactor) - 5.4;

    // Ensure result is in a reasonable range (minimum 3%, maximum 60%)
    return result.clamp(3.0, 60.0);
  }

  // Get classification for body fat percentage - gender specific
  String _getBodyFatClassification(double bodyFat, String? gender) {
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
      // Gender-neutral classifications (compromise)
      if (bodyFat < 10) return 'Essential';
      if (bodyFat < 18) return 'Athletic';
      if (bodyFat < 22) return 'Fitness';
      if (bodyFat < 28) return 'Average';
      if (bodyFat < 35) return 'Above Avg';
      return 'Obese';
    }
  }
}
