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
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Body Fat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Body fat percentage in center
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (bodyFatPercentage != null)
                    const Text(
                      '%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),

            // Estimated label underneath
            Center(
              child: Text(
                isEstimated ? 'Estimated' : '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
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
