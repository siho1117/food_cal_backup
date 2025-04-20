// lib/widgets/settings/monthly_weight_goal_dialog.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MonthlyWeightGoalDialog extends StatefulWidget {
  final double? currentMonthlyGoal;
  final bool isMetric;
  final Function(double) onGoalSaved;

  const MonthlyWeightGoalDialog({
    Key? key,
    this.currentMonthlyGoal,
    required this.isMetric,
    required this.onGoalSaved,
  }) : super(key: key);

  @override
  State<MonthlyWeightGoalDialog> createState() =>
      _MonthlyWeightGoalDialogState();
}

class _MonthlyWeightGoalDialogState extends State<MonthlyWeightGoalDialog> {
  late bool _isMetric;
  late bool _isGain;
  late int _selectedRangeIndex;

  // Weight loss ranges in kg (used when _isGain is false)
  final List<Map<String, dynamic>> _weightLossRanges = [
    {
      'range': '0-2',
      'midpoint': 1.0,
      'suggestion': 'Gentle, sustainable pace ideal for beginners',
    },
    {
      'range': '2-4',
      'midpoint': 3.0,
      'suggestion': 'Moderate pace, suitable for most people',
    },
    {
      'range': '4-6',
      'midpoint': 5.0,
      'suggestion': 'Faster pace, requires exercise and strict diet',
    },
    {
      'range': '6-8',
      'midpoint': 7.0,
      'suggestion': 'Ambitious goal, may not be sustainable long-term',
    },
  ];

  // Weight gain ranges in kg (used when _isGain is true)
  final List<Map<String, dynamic>> _weightGainRanges = [
    {
      'range': '0-2',
      'midpoint': 1.0,
      'suggestion': 'Lean muscle building with minimal fat gain',
    },
    {
      'range': '2-4',
      'midpoint': 3.0,
      'suggestion': 'Balanced muscle building approach for most',
    },
    {
      'range': '4-6',
      'midpoint': 5.0,
      'suggestion': 'Bulking phase, will include some fat gain',
    },
    {
      'range': '6-8',
      'midpoint': 7.0,
      'suggestion': 'Aggressive bulk, requires very high calorie intake',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    // Initialize with weight loss direction by default
    _isGain = false;

    // Default to 2-4 kg range (index 1)
    _selectedRangeIndex = 1;

    // Set initial selected range if a value exists
    if (widget.currentMonthlyGoal != null) {
      final absGoal = widget.currentMonthlyGoal!.abs();
      _isGain = widget.currentMonthlyGoal! > 0;

      // Find the appropriate range
      if (absGoal < 2.0) {
        _selectedRangeIndex = 0;
      } else if (absGoal < 4.0) {
        _selectedRangeIndex = 1;
      } else if (absGoal < 6.0) {
        _selectedRangeIndex = 2;
      } else {
        _selectedRangeIndex = 3;
      }
    }
  }

  void _toggleUnit() {
    setState(() {
      _isMetric = !_isMetric;
    });
  }

  void _toggleDirection() {
    setState(() {
      _isGain = !_isGain;
    });
  }

  void _selectRange(int index) {
    setState(() {
      _selectedRangeIndex = index;
    });
  }

  // Get the appropriate range list based on gain/loss direction
  List<Map<String, dynamic>> get _currentRanges {
    return _isGain ? _weightGainRanges : _weightLossRanges;
  }

  void _saveGoal() {
    // Get the midpoint value of the selected range
    final midpoint = _currentRanges[_selectedRangeIndex]['midpoint'] as double;

    // Apply direction (gain/loss)
    final directedValue = _isGain ? midpoint : -midpoint;

    // Pass back the selected monthly goal
    widget.onGoalSaved(directedValue);
    Navigator.of(context).pop();
  }

  // Convert kg range to lbs
  String _formatRange(String kgRange) {
    if (_isMetric) return '$kgRange kg';

    // Parse the range
    final parts = kgRange.split('-');
    final startKg = double.parse(parts[0]);
    final endKg = double.parse(parts[1]);

    // Convert to lbs (rounded to nearest whole number)
    final startLbs = (startKg * 2.20462).round();
    final endLbs = (endKg * 2.20462).round();

    return '$startLbs-$endLbs lbs';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Monthly Weight Goal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Unit toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Imperial',
                    style: TextStyle(
                      color: !_isMetric ? Colors.black : Colors.grey,
                      fontWeight:
                          !_isMetric ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Switch(
                    value: _isMetric,
                    onChanged: (value) => _toggleUnit(),
                    activeColor: AppTheme.primaryBlue,
                  ),
                  Text(
                    'Metric',
                    style: TextStyle(
                      color: _isMetric ? Colors.black : Colors.grey,
                      fontWeight:
                          _isMetric ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Direction toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDirectionOption(
                    icon: Icons.trending_down,
                    label: 'Lose',
                    isSelected: !_isGain,
                    color: Colors.red,
                    onTap: () {
                      if (_isGain) _toggleDirection();
                    },
                  ),
                  _buildDirectionOption(
                    icon: Icons.trending_up,
                    label: 'Gain',
                    isSelected: _isGain,
                    color: Colors.green,
                    onTap: () {
                      if (!_isGain) _toggleDirection();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Monthly goal display
              Text(
                'Select monthly ${_isGain ? 'gain' : 'loss'} range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 16),

              // Range selection
              ...List.generate(_currentRanges.length, (index) {
                return _buildRangeOption(
                  range: _formatRange(_currentRanges[index]['range']),
                  suggestion: _currentRanges[index]['suggestion'],
                  isSelected: _selectedRangeIndex == index,
                  onTap: () => _selectRange(index),
                );
              }),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeOption({
    required String range,
    required String suggestion,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = _isGain ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Range indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                range,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Suggestion text
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),

            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
