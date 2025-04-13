import 'package:flutter/material.dart';
import '../widgets/weight_entry_widget.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/weight_entry.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Color constants to replace AppTheme
  final Color primaryBlue = const Color(0xFF0052CC);
  final Color secondaryBeige = const Color(0xFFF5EFE0);

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
      barrierDismissible: false, // User must tap a button to dismiss dialog
      barrierColor:
          Colors.black.withOpacity(0.8), // Makes background opaque/dark
      builder: (context) => WeightEntryWidget(
        initialWeight: _currentWeight,
        isMetric: _isMetric,
        onWeightSaved: (weight, isMetric) async {
          setState(() {
            // Weight is already in metric as the widget handles conversion
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

  // Calculate BMI if height is available
  Future<String> _getBmiText() async {
    final bmi = await _userRepository.calculateBMI();
    if (bmi == null) {
      return 'Set height in profile';
    }

    final classification = _userRepository.getBMIClassification(bmi);
    return '${bmi.toStringAsFixed(1)} - $classification';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOOD CAL',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'YOUR PROGRESS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Current Weight Card
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
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.monitor_weight,
                          color: primaryBlue,
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
                          color: primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // BMI Card
              FutureBuilder<String>(
                  future: _getBmiText(),
                  builder: (context, snapshot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: Colors.green,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Body Mass Index',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.data ?? 'Calculating...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

              const SizedBox(height: 30),

              // Weekly summary
              Text(
                'WEEKLY OVERVIEW',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Chart placeholder
              Container(
                height: 220,
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
                    const Text(
                      'Calorie Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      // Placeholder for chart
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) {
                            // Random heights for bar chart placeholders
                            final heights = [
                              0.6,
                              0.9,
                              0.7,
                              0.8,
                              0.5,
                              0.75,
                              0.85
                            ];
                            final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 120 * heights[index],
                                  decoration: BoxDecoration(
                                    color: index == 6
                                        ? primaryBlue
                                        : primaryBlue.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  days[index],
                                  style: TextStyle(
                                    fontWeight: index == 6
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color:
                                        index == 6 ? primaryBlue : Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Average Daily',
                      '1,850',
                      'kcal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '-2.5',
                      'lbs',
                      Icons.trending_down,
                      Colors.green,
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
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Donut chart placeholder
              Container(
                height: 220,
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
                    // Donut chart placeholder
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: secondaryBeige,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1,850',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Legend
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Protein', '25%', Colors.red),
                          const SizedBox(height: 12),
                          _buildLegendItem('Carbs', '55%', Colors.green),
                          const SizedBox(height: 12),
                          _buildLegendItem('Fat', '20%', Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          percentage,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
