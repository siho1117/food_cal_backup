import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BodyFatWidget extends StatelessWidget {
  final double? bodyFatPercentage;
  final String classification;
  final bool isEstimated;

  const BodyFatWidget({
    Key? key,
    required this.bodyFatPercentage,
    required this.classification,
    this.isEstimated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Header with icon and Body Fat text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Colors.black,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Body Fat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Body Fat Value
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  bodyFatPercentage != null
                      ? bodyFatPercentage!.toStringAsFixed(1)
                      : "—",
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (bodyFatPercentage != null)
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Only include the "Estimated" text (no classification)
          Center(
            child: Text(
              'Estimated',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Add extra space to match height with BMI widget if needed
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
