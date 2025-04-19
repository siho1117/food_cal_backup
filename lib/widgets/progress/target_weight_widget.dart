import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TargetWeightWidget extends StatelessWidget {
  final double? targetWeight;
  final double? currentWeight;
  final bool isMetric;
  final VoidCallback onTap;

  const TargetWeightWidget({
    Key? key,
    required this.targetWeight,
    required this.currentWeight,
    required this.isMetric,
    required this.onTap,
  }) : super(key: key);

  String _formatWeight(double? weight) {
    if (weight == null) return 'Not set';

    final displayWeight = isMetric ? weight : weight * 2.20462;
    return displayWeight.toStringAsFixed(1) + (isMetric ? ' kg' : ' lbs');
  }

  double _calculateProgress() {
    if (targetWeight == null || currentWeight == null) {
      return 0.0;
    }

    // If target equals current, return 100%
    if ((targetWeight! - currentWeight!).abs() < 0.1) {
      return 1.0;
    }

    // If losing weight
    if (currentWeight! > targetWeight!) {
      // Assume starting point was 20% higher than target
      final startWeight = targetWeight! * 1.2;
      final totalToLose = startWeight - targetWeight!;
      final lost = startWeight - currentWeight!;

      return (lost / totalToLose).clamp(0.0, 1.0);
    }
    // If gaining weight
    else {
      // Assume starting point was 20% lower than target
      final startWeight = targetWeight! * 0.8;
      final totalToGain = targetWeight! - startWeight;
      final gained = currentWeight! - startWeight;

      return (gained / totalToGain).clamp(0.0, 1.0);
    }
  }

  String _getProgressText() {
    if (targetWeight == null || currentWeight == null) {
      return 'Set a target weight to track progress';
    }

    final difference = currentWeight! - targetWeight!;
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

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();

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
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: AppTheme.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Target Weight',
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
                    Icons.edit,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Target weight display
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _formatWeight(targetWeight),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _formatWeight(currentWeight),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.accentColor,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),

            const SizedBox(height: 8),

            // Progress text
            Text(
              _getProgressText(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
                fontStyle:
                    targetWeight == null ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
