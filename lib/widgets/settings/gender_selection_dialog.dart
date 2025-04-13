import 'package:flutter/material.dart';

class GenderSelectionDialog extends StatelessWidget {
  final String? currentGender;
  final Function(String) onGenderSelected;

  const GenderSelectionDialog({
    Key? key,
    this.currentGender,
    required this.onGenderSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);
    final genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

    return AlertDialog(
      title: const Text('Gender'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: genders.length,
          itemBuilder: (context, index) {
            final gender = genders[index];
            final isSelected = gender == currentGender;

            return ListTile(
              title: Text(
                gender,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: primaryBlue)
                  : null,
              onTap: () {
                onGenderSelected(gender);
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
