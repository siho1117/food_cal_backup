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
      return const Color(0xFF3F8EFC); // Blue for Underweight
    } else if (bmiValue! < 25) {
      return const Color(0xFF2EC973); // Green for Normal
    } else if (bmiValue! < 30) {
      return const Color(0xFFFF9A3D); // Orange for Overweight
    } else {
      return const Color(0xFFFF5A5A); // Red for Obese
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getColorForBMI();

    return Container(
      width: MediaQuery.of(context).size.width *
          0.44, // About half of screen width
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and BMI text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: primaryColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'BMI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // BMI Value
          Center(
            child: Text(
              bmiValue != null ? bmiValue!.toStringAsFixed(1) : "—",
              style: TextStyle(
                fontSize: 42, // Reduced size
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Classification below the BMI value
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                classification,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
