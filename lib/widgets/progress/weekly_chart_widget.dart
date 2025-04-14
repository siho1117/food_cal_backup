import 'package:flutter/material.dart';
import '../../config/theme.dart';

class WeeklyChartWidget extends StatelessWidget {
  const WeeklyChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  final heights = [0.6, 0.9, 0.7, 0.8, 0.5, 0.75, 0.85];
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 120 * heights[index],
                        decoration: BoxDecoration(
                          color: index == 6
                              ? AppTheme.primaryBlue
                              : AppTheme.primaryBlue.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: TextStyle(
                          fontWeight:
                              index == 6 ? FontWeight.bold : FontWeight.normal,
                          color:
                              index == 6 ? AppTheme.primaryBlue : Colors.grey,
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
    );
  }
}
