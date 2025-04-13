import 'package:flutter/material.dart';

class ActivityLevelDialog extends StatelessWidget {
  final double? currentLevel;
  final Function(double) onLevelSelected;

  const ActivityLevelDialog({
    Key? key,
    this.currentLevel,
    required this.onLevelSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    final levels = [
      {
        'level': 1.2,
        'title': 'Sedentary',
        'description': 'Little or no exercise'
      },
      {
        'level': 1.375,
        'title': 'Light',
        'description': 'Light exercise 1-3 days/week'
      },
      {
        'level': 1.55,
        'title': 'Moderate',
        'description': 'Moderate exercise 3-5 days/week'
      },
      {
        'level': 1.725,
        'title': 'Active',
        'description': 'Hard exercise 6-7 days/week'
      },
      {
        'level': 1.9,
        'title': 'Very Active',
        'description': 'Very hard exercise & physical job'
      },
    ];

    return AlertDialog(
      title: const Text('Activity Level'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final isSelected = level['level'] == currentLevel;

            return ListTile(
              title: Text(
                level['title'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(level['description'] as String),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: primaryBlue)
                  : null,
              onTap: () {
                onLevelSelected(level['level'] as double);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
