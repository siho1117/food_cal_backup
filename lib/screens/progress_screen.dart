import 'package:flutter/material.dart';
import '../widgets/weight_entry_dialog.dart'; // Changed from weight_entry_widget.dart
import '../data/repositories/user_repository.dart';
import '../data/models/weight_entry.dart';
import '../widgets/progress/bmi_widget.dart';
import '../widgets/progress/stat_card_widget.dart';
import '../widgets/progress/weekly_chart_widget.dart';
import '../widgets/progress/nutrition_chart_widget.dart';
import '../config/theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // User data
  double _currentWeight = 70.0; // Default in kg
  bool _isMetric = true;
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load user profile for unit preference
    final userProfile = await _userRepository.getUserProfile();

    // Load latest weight entry
    final latestWeight = await _userRepository.getLatestWeightEntry();

    if (mounted) {
      setState(() {
        if (userProfile != null) {
          _isMetric = userProfile.isMetric;
        }

        if (latestWeight != null) {
          _currentWeight = latestWeight.weight; // Always in kg
        }
      });
    }
  }

  void _showWeightEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => WeightEntryDialog(
        // Now using WeightEntryDialog instead
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
          final userProfile = await _userRepository.getUserProfile();
          if (userProfile != null && userProfile.isMetric != isMetric) {
            final updatedProfile = userProfile.copyWith(isMetric: isMetric);
            await _userRepository.saveUserProfile(updatedProfile);
          }
        },
      ),
    );
  }

  String get _formattedWeight {
    final displayWeight = _isMetric ? _currentWeight : _currentWeight * 2.20462;
    return displayWeight.toStringAsFixed(1) + (_isMetric ? ' kg' : ' lbs');
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
              // Current Weight Card - directly integrated in this file
              GestureDetector(
                onTap: _showWeightEntryDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              ),

              const SizedBox(height: 20),

              // BMI Card with enhanced visualization
              FutureBuilder<double?>(
                future: _userRepository.calculateBMI(),
                builder: (context, snapshot) {
                  final bmiValue = snapshot.data;
                  String classification = "Not set";

                  if (bmiValue != null) {
                    classification =
                        _userRepository.getBMIClassification(bmiValue);
                  }

                  return BMIWidget(
                    bmiValue: bmiValue,
                    classification: classification,
                  );
                },
              ),

              const SizedBox(height: 30),

              // Weekly summary
              Text(
                'WEEKLY OVERVIEW',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Weekly chart widget
              const WeeklyChartWidget(),

              const SizedBox(height: 24),

              // Stats section
              Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      title: 'Average Daily',
                      value: '1,850',
                      unit: 'kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardWidget(
                      title: 'This Week',
                      value: '-2.5',
                      unit: 'lbs',
                      icon: Icons.trending_down,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Nutrition breakdown
              Text(
                'NUTRITION BREAKDOWN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Nutrition chart widget
              const NutritionChartWidget(),

              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
