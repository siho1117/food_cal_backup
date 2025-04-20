import 'package:flutter/material.dart';
import '../config/theme.dart';

class ActivityLevelInfoDialog extends StatelessWidget {
  const ActivityLevelInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          const Text('Calorie Calculations'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BMR (Basal Metabolic Rate)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The number of calories your body needs to maintain basic functions at rest. Calculated using the Mifflin-St Jeor Equation:',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'For men:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5'),
                  SizedBox(height: 8),
                  Text(
                    'For women:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                      'BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TDEE (Total Daily Energy Expenditure)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The total calories you burn in a day, based on your BMR and activity level:',
            ),
            const SizedBox(height: 8),
            _buildActivityLevelDetail(
              level: 'Sedentary (1.2)',
              description: 'Little or no exercise, desk job',
            ),
            _buildActivityLevelDetail(
              level: 'Light (1.375)',
              description: 'Light exercise 1-3 days/week',
            ),
            _buildActivityLevelDetail(
              level: 'Moderate (1.55)',
              description: 'Moderate exercise 3-5 days/week',
            ),
            _buildActivityLevelDetail(
              level: 'Active (1.725)',
              description: 'Hard exercise 6-7 days/week',
            ),
            _buildActivityLevelDetail(
              level: 'Very Active (1.9)',
              description: 'Very hard daily exercise or physical job',
            ),
            const SizedBox(height: 8),
            const Text(
              'TDEE = BMR × Activity Multiplier',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
          ),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

  Widget _buildActivityLevelDetail({
    required String level,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: level,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Show Activity Level Info Dialog
void showActivityLevelInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ActivityLevelInfoDialog(),
  );
}
