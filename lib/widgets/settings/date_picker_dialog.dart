import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DateOfBirthPickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime selectedDate, int calculatedAge) onDateSelected;

  const DateOfBirthPickerDialog({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<DateOfBirthPickerDialog> createState() =>
      _DateOfBirthPickerDialogState();
}

class _DateOfBirthPickerDialogState extends State<DateOfBirthPickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate =
        widget.initialDate ?? DateTime(now.year - 30, now.month, now.day);
  }

  // Calculate age as integer value
  int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return age;
  }

  // Format age for display
  String getFormattedAge(DateTime dob) {
    return '${calculateAge(dob)} years';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Date of Birth',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Age display
              Text(
                'Age: ${getFormattedAge(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Date display
              Text(
                _formatDate(_selectedDate),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Date picker - make it taller and wider
              SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Month picker
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        looping: true,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              index + 1,
                              _selectedDate.day,
                            );
                          });
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedDate.month - 1,
                        ),
                        children: [
                          'January',
                          'February',
                          'March',
                          'April',
                          'May',
                          'June',
                          'July',
                          'August',
                          'September',
                          'October',
                          'November',
                          'December'
                        ]
                            .map((month) => Center(
                                  child: Text(
                                    month,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Day picker
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        looping: true,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              index + 1,
                            );
                          });
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedDate.day - 1,
                        ),
                        children: List.generate(
                            31,
                            (index) => Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                )),
                      ),
                    ),

                    // Year picker
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedDate = DateTime(
                              DateTime.now().year - index,
                              _selectedDate.month,
                              _selectedDate.day,
                            );
                          });
                        },
                        scrollController: FixedExtentScrollController(
                          initialItem: DateTime.now().year - _selectedDate.year,
                        ),
                        children: List.generate(
                            100,
                            (index) => Center(
                                  child: Text(
                                    '${DateTime.now().year - index}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                )),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      // Pass both selected date and calculated age
                      widget.onDateSelected(
                          _selectedDate, calculateAge(_selectedDate));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
