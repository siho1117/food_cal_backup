import 'package:flutter/material.dart';
import 'dart:math' as math;
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
      return const Color(0xFF4285F4); // Blue for Underweight
    } else if (bmiValue! < 25) {
      return const Color(0xFF0F9D58); // Green for Normal
    } else if (bmiValue! < 30) {
      return const Color(0xFFF4B400); // Yellow for Overweight
    } else {
      return const Color(0xFFDB4437); // Red for Obese
    }
  }

  // Get description text based on BMI classification
  String _getDescriptionForBMI() {
    if (bmiValue == null) return "Add your height and weight to see your BMI";

    if (bmiValue! < 18.5) {
      return "Your BMI is underweight. Maintaining a balanced diet is recommended.";
    } else if (bmiValue! < 25) {
      return "Your BMI is normal. Maintaining a balanced diet and regular exercise is recommended.";
    } else if (bmiValue! < 30) {
      return "Your BMI is overweight. Small dietary changes and increasing physical activity can help.";
    } else {
      return "Your BMI indicates obesity. Consider consulting a healthcare professional.";
    }
  }

  // Calculate percentage for gauge display (0-100%)
  double _getBMIPercentage() {
    if (bmiValue == null) return 0;

    // Map BMI range 14-40 to 0-100%
    double percentage = ((bmiValue! - 14) / (40 - 14)) * 100;

    // Clamp to 0-100% range
    return percentage.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getColorForBMI();
    final description = _getDescriptionForBMI();

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
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Body Mass Index',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // BMI value centered
          Center(
            child: Text(
              bmiValue != null ? bmiValue!.toStringAsFixed(1) : "—",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Classification pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                classification,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal color bar for BMI range
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4285F4), // Blue
                        Color(0xFF0F9D58), // Green
                        Color(0xFFF4B400), // Yellow
                        Color(0xFFDB4437), // Red
                      ],
                      stops: [0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),

                // Category labels
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Underweight',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      Text(
                        'Normal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F9D58),
                        ),
                      ),
                      Text(
                        'Overweight',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF4B400),
                        ),
                      ),
                      Text(
                        'Obese',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDB4437),
                        ),
                      ),
                    ],
                  ),
                ),

                // Marker for current BMI
                if (bmiValue != null)
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 32) *
                            _getBMIPercentage() /
                            100 -
                        6,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Advice box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
