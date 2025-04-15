import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../data/models/exercise_models.dart';

class CalorieBurnChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final int days;

  const CalorieBurnChart({
    Key? key,
    required this.logs,
    this.days = 7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort logs by date
    final sortedLogs = List<ExerciseLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group logs by day
    final Map<String, List<ExerciseLog>> logsByDay = {};
    final now = DateTime.now();

    // Initialize all days with empty lists
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateString = _formatDate(date);
      logsByDay[dateString] = [];
    }

    // Add logs to corresponding days
    for (final log in sortedLogs) {
      final dateString = _formatDate(log.timestamp);
      if (logsByDay.containsKey(dateString)) {
        logsByDay[dateString]!.add(log);
      }
    }

    // Calculate total calories for each day
    final Map<String, int> caloriesByDay = {};
    logsByDay.forEach((date, dayLogs) {
      caloriesByDay[date] =
          dayLogs.fold(0, (sum, log) => sum + log.caloriesBurned);
    });

    // Find the maximum calories for scaling
    final maxCalories = caloriesByDay.values.isEmpty
        ? 100
        : caloriesByDay.values.reduce(math.max);

    // Get ordered days for display
    final orderedDays = List<String>.from(logsByDay.keys.toList())
      ..sort((a, b) => a.compareTo(b)); // Sort chronologically

    // Filter to get only the days within our range and reverse for display
    final displayDays = orderedDays.take(days).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Calories Burned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Last $days days',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${maxCalories.round()} cal', style: _yAxisStyle),
                    Text('${(maxCalories * 0.75).round()} cal',
                        style: _yAxisStyle),
                    Text('${(maxCalories * 0.5).round()} cal',
                        style: _yAxisStyle),
                    Text('${(maxCalories * 0.25).round()} cal',
                        style: _yAxisStyle),
                    Text('0 cal', style: _yAxisStyle),
                  ],
                ),

                const SizedBox(width: 8),

                // Chart bars
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth =
                          constraints.maxWidth / displayDays.length;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: displayDays.map((day) {
                          final calories = caloriesByDay[day] ?? 0;
                          final normalizedHeight = maxCalories > 0
                              ? (calories / maxCalories) * 150
                              : 0.0;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: barWidth - 8, // Spacing between bars
                                height: normalizedHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getShortDayName(day),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Calories Burned'),
                ],
              ),
              Text(
                'Total: ${caloriesByDay.values.fold(0, (sum, calories) => sum + calories)} cal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Format date as YYYY-MM-DD for consistent key format
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get short day name (e.g., "Mon")
  String _getShortDayName(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) return '';

    final year = int.tryParse(parts[0]) ?? 2021;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    final date = DateTime(year, month, day);

    // Get weekday name
    switch (date.weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  // Get Y-axis label text style
  TextStyle get _yAxisStyle => TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
      );
}
