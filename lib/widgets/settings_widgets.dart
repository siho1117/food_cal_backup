import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ===== THEME SELECTOR =====

class ThemeSelectorWidget extends StatelessWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const ThemeSelectorWidget({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return InkWell(
      onTap: () => _showThemeSelector(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.palette,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Theme',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getThemeDisplayName(currentTheme),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return 'System Default';
    }
  }

  void _showThemeSelector(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, 'Light', 'light', primaryBlue),
            _buildThemeOption(context, 'Dark', 'dark', primaryBlue),
            _buildThemeOption(context, 'System Default', 'system', primaryBlue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label,
      String themeValue, Color primaryColor) {
    final bool isSelected = currentTheme == themeValue;

    return ListTile(
      leading: Icon(
        themeValue == 'light'
            ? Icons.wb_sunny
            : themeValue == 'dark'
                ? Icons.nightlight_round
                : Icons.smartphone,
        color: isSelected ? primaryColor : Colors.grey,
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: primaryColor,
            )
          : null,
      selected: isSelected,
      onTap: () {
        onThemeChanged(themeValue);
        Navigator.of(context).pop();
      },
    );
  }
}

// ===== PROFILE PICTURE SELECTOR =====

class ProfilePictureWidget extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onTap;

  const ProfilePictureWidget({
    Key? key,
    this.avatarUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar with edit button
            Stack(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        )
                      : null,
                ),

                // Edit button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Label
            const Text(
              'Edit Profile Picture',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== DATA MANAGEMENT WIDGET =====

class DataManagementWidget extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onClearData;

  const DataManagementWidget({
    Key? key,
    required this.onExport,
    required this.onImport,
    required this.onClearData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDataOption(
            context,
            'Export Data',
            'Backup your data as a file',
            Icons.upload_file,
            onExport,
            primaryBlue,
          ),
          const Divider(),
          _buildDataOption(
            context,
            'Import Data',
            'Restore from a backup file',
            Icons.download_rounded,
            onImport,
            primaryBlue,
          ),
          const Divider(),
          _buildDataOption(
            context,
            'Clear All Data',
            'Remove all your personal data',
            Icons.delete_forever,
            () => _confirmClearData(context),
            primaryBlue,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color primaryColor, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red.withOpacity(0.5) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // Confirmation dialog for data clearing
  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all your data, including weight history, '
            'profile information, and settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }
}

// ===== FEEDBACK WIDGET =====

class FeedbackWidget extends StatelessWidget {
  final VoidCallback onSendFeedback;

  const FeedbackWidget({
    Key? key,
    required this.onSendFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showFeedbackDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.feedback,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Help us improve the app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    final Color primaryBlue = const Color(0xFF0052CC);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We appreciate your feedback! Please let us know how we can improve the app.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'Your feedback here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final feedback = feedbackController.text.trim();
              if (feedback.isNotEmpty) {
                // Call the feedback handler
                onSendFeedback();

                // Show thank you toast
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ===== ABOUT APP WIDGET =====

class AboutAppWidget extends StatelessWidget {
  final String appVersion;
  final VoidCallback onViewPrivacyPolicy;
  final VoidCallback onViewTerms;

  const AboutAppWidget({
    Key? key,
    required this.appVersion,
    required this.onViewPrivacyPolicy,
    required this.onViewTerms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAboutItem(
            context,
            'App Version',
            appVersion,
            Icons.info_outline,
            primaryBlue,
          ),
          const Divider(),
          InkWell(
            onTap: onViewPrivacyPolicy,
            child: _buildAboutItem(
              context,
              'Privacy Policy',
              '',
              Icons.privacy_tip_outlined,
              primaryBlue,
              showChevron: true,
            ),
          ),
          const Divider(),
          InkWell(
            onTap: onViewTerms,
            child: _buildAboutItem(
              context,
              'Terms of Service',
              '',
              Icons.description_outlined,
              primaryBlue,
              showChevron: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color primaryColor, {
    bool showChevron = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            )
          else if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }
}

// ===== DATE OF BIRTH PICKER DIALOG =====

class DateOfBirthPickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;

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

  String _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return '$age years';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return AlertDialog(
      title: const Text('Date of Birth'),
      content: SizedBox(
        height: 240,
        child: Column(
          children: [
            // Age display
            Text(
              'Age: ${_calculateAge(_selectedDate)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Date display
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 20),

            // Date picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1923), // 100 years ago
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDateSelected(_selectedDate);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ===== HEIGHT PICKER DIALOG =====

class HeightPickerDialog extends StatefulWidget {
  final double? initialHeight;
  final bool isMetric;
  final Function(double) onHeightSelected;

  const HeightPickerDialog({
    Key? key,
    this.initialHeight,
    required this.isMetric,
    required this.onHeightSelected,
  }) : super(key: key);

  @override
  State<HeightPickerDialog> createState() => _HeightPickerDialogState();
}

class _HeightPickerDialogState extends State<HeightPickerDialog> {
  late bool _isMetric;
  late double _selectedHeight;

  // Imperial values
  late int _feet;
  late int _inches;

  // Metric value
  late int _cm;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    // Set initial height
    _selectedHeight = widget.initialHeight ?? (_isMetric ? 170.0 : 67.0);

    if (_isMetric) {
      _cm = _selectedHeight.round();
    } else {
      // Convert to feet and inches
      final totalInches = _selectedHeight / 2.54;
      _feet = (totalInches / 12).floor();
      _inches = (totalInches % 12).round();
    }
  }

  void _toggleUnit() {
    setState(() {
      if (_isMetric) {
        // Convert cm to feet/inches
        final totalInches = _cm / 2.54;
        _feet = (totalInches / 12).floor();
        _inches = (totalInches % 12).round();
      } else {
        // Convert feet/inches to cm
        _cm = ((_feet * 12) + _inches) * 2.54.round();
      }

      _isMetric = !_isMetric;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return AlertDialog(
      title: const Text('Height'),
      content: SizedBox(
        height: 240,
        child: Column(
          children: [
            // Unit toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Imperial',
                  style: TextStyle(
                    color: !_isMetric ? Colors.black : Colors.grey,
                    fontWeight:
                        !_isMetric ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: _isMetric,
                  onChanged: (value) => _toggleUnit(),
                  activeColor: primaryBlue,
                ),
                Text(
                  'Metric',
                  style: TextStyle(
                    color: _isMetric ? Colors.black : Colors.grey,
                    fontWeight: _isMetric ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Height display
            Text(
              _isMetric ? '$_cm cm' : '$_feet\' $_inches"',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Height picker
            Expanded(
              child: _isMetric
                  ? // Centimeters picker
                  CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _cm - 100, // Adjusted for range start
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() => _cm = index + 100);
                      },
                      children: List.generate(
                        121, // 100cm to 220cm
                        (index) => Center(
                          child: Text(
                            '${index + 100} cm',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    )
                  : // Feet and inches picker
                  Row(
                      children: [
                        // Feet picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem:
                                  _feet - 3, // Adjusted for range start
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _feet = index + 3);
                            },
                            children: List.generate(
                              6, // 3ft to 8ft
                              (index) => Center(
                                child: Text(
                                  '${index + 3} ft',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Inches picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _inches,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _inches = index);
                            },
                            children: List.generate(
                              12, // 0 to 11 inches
                              (index) => Center(
                                child: Text(
                                  '$index in',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            double heightValue;
            if (_isMetric) {
              heightValue = _cm.toDouble();
            } else {
              heightValue = ((_feet * 12) + _inches) * 2.54;
            }

            widget.onHeightSelected(heightValue);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ===== ACTIVITY LEVEL DIALOG =====

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

// ===== GENDER SELECTION DIALOG =====

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
