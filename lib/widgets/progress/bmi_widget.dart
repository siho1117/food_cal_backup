import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BMIWidget extends StatelessWidget {
  final double? bmiValue;
  final String classification;

  const BMIWidget({
    Key? key,
    required this.bmiValue,
    required this.classification,
  }) : super(key: key);

  // Get appropriate color based on BMI classification
  Color _getColorForBMI() {
    if (bmiValue == null) return Colors.grey;

    if (bmiValue! < 18.5) {
      return const Color.fromARGB(255, 112, 150, 136); // Blue for Underweight
    } else if (bmiValue! < 25) {
      return const Color.fromARGB(255, 55, 115, 109); // Green for Normal
    } else if (bmiValue! < 30) {
      return const Color.fromARGB(255, 193, 77, 59); // Orange for Overweight
    } else {
      return const Color.fromARGB(255, 204, 34, 34); // Red for Obese
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getColorForBMI();

    return Expanded(
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
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BMI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // BMI value in center
            Center(
              child: Text(
                bmiValue != null ? bmiValue!.toStringAsFixed(1) : "—",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            // Classification underneath
            Center(
              child: Text(
                classification,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
