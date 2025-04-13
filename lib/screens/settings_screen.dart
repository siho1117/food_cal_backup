import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_profile.dart';
import '../data/models/weight_entry.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/weight_entry_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Color constants
  final Color primaryBlue = const Color(0xFF0052CC);
  final Color secondaryBeige = const Color(0xFFF5EFE0);

  // User repository
  final UserRepository _userRepository = UserRepository();

  // User data
  UserProfile? _userProfile;
  double? _currentWeight;
  bool _isMetric = true;
  bool _isLoading = true;
  String _appTheme = 'system';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final userProfile = await _userRepository.getUserProfile();

      // Load latest weight entry
      final latestWeight = await _userRepository.getLatestWeightEntry();

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          if (userProfile != null) {
            _isMetric = userProfile.isMetric;
          }

          if (latestWeight != null) {
            _currentWeight = latestWeight.weight; // Always in kg
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Format weight based on user's preferred unit system
  String get _formattedWeight {
    if (_currentWeight == null) return 'Not set';

    final displayWeight =
        _isMetric ? _currentWeight! : _currentWeight! * 2.20462;
    return displayWeight.toStringAsFixed(1) + (_isMetric ? ' kg' : ' lbs');
  }

  // Calculate age from date of birth
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

  // Create a new user profile if one doesn't exist
  Future<void> _createUserProfileIfNeeded() async {
    if (_userProfile == null) {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newProfile = UserProfile(
        id: userId,
        isMetric: _isMetric,
      );

      await _userRepository.saveUserProfile(newProfile);
      setState(() {
        _userProfile = newProfile;
      });
    }
  }

  // Show weight entry dialog
  void _showWeightEntryDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => WeightEntryDialog(
        initialWeight: _currentWeight,
        isMetric: _isMetric,
        onWeightSaved: (weight, isMetric) async {
          setState(() {
            _currentWeight = weight; // Always in metric
            _isMetric = isMetric;
          });

          // Update user preference for units if needed
          if (_userProfile != null && _userProfile!.isMetric != isMetric) {
            final updatedProfile = _userProfile!.copyWith(isMetric: isMetric);
            await _userRepository.saveUserProfile(updatedProfile);
            setState(() {
              _userProfile = updatedProfile;
            });
          }

          // Save new weight entry
          final entry = WeightEntry.create(weight: weight);
          await _userRepository.addWeightEntry(entry);
        },
      ),
    );
  }

  // Show date of birth picker
  void _showDateOfBirthPicker() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => DateOfBirthPickerDialog(
        initialDate: _userProfile?.birthDate,
        onDateSelected: (selectedDate) async {
          if (_userProfile != null) {
            final updatedProfile =
                _userProfile!.copyWith(birthDate: selectedDate);
            await _userRepository.saveUserProfile(updatedProfile);

            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Show height picker dialog
  void _showHeightPickerDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => HeightPickerDialog(
        initialHeight: _userProfile?.height,
        isMetric: _isMetric,
        onHeightSelected: (heightValue) async {
          if (_userProfile != null) {
            final updatedProfile = _userProfile!.copyWith(height: heightValue);
            await _userRepository.saveUserProfile(updatedProfile);

            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Show gender selection dialog
  void _showGenderDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => GenderSelectionDialog(
        currentGender: _userProfile?.gender,
        onGenderSelected: (gender) async {
          if (_userProfile != null) {
            final updatedProfile = _userProfile!.copyWith(gender: gender);
            await _userRepository.saveUserProfile(updatedProfile);

            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Show activity level selector
  void _showActivityLevelDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ActivityLevelDialog(
        currentLevel: _userProfile?.activityLevel,
        onLevelSelected: (level) async {
          if (_userProfile != null) {
            final updatedProfile = _userProfile!.copyWith(activityLevel: level);
            await _userRepository.saveUserProfile(updatedProfile);

            setState(() {
              _userProfile = updatedProfile;
            });
          }
        },
      ),
    );
  }

  // Show avatar picker
  void _showAvatarPicker() async {
    await _createUserProfileIfNeeded();

    // This would normally use ProfilePictureWidget.showAvatarPicker
    // For now, just set a placeholder URL
    setState(() {
      _avatarUrl = 'https://source.unsplash.com/random/100x100?person';
    });
  }

  // Data management functions
  void _exportData() {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importData() {
    // Implementation for data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data imported successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearData() async {
    // Implementation for clearing data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data has been cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Feedback function
  void _sendFeedback() {
    // Implementation for sending feedback
  }

  // Theme change function
  void _changeTheme(String theme) {
    setState(() {
      _appTheme = theme;
    });

    // Implementation for theme change
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: secondaryBeige,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: secondaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOOD CAL',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Profile picture
              Center(
                child: ProfilePictureWidget(
                  avatarUrl: _avatarUrl,
                  onTap: _showAvatarPicker,
                ),
              ),

              const SizedBox(height: 30),

              // Personal details section
              Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // User details card
              Container(
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
                  children: [
                    // Date of birth
                    _buildDetailItem(
                      icon: Icons.cake,
                      title: 'Date of Birth',
                      value: _userProfile?.birthDate != null
                          ? '${DateFormat('MMM d, yyyy').format(_userProfile!.birthDate!)} (${_calculateAge(_userProfile!.birthDate!)})'
                          : 'Not set',
                      onTap: _showDateOfBirthPicker,
                    ),

                    const Divider(height: 1),

                    // Height
                    _buildDetailItem(
                      icon: Icons.height,
                      title: 'Height',
                      value: _userProfile?.height != null
                          ? _userProfile!.formattedHeight()
                          : 'Not set',
                      onTap: _showHeightPickerDialog,
                    ),

                    const Divider(height: 1),

                    // Current weight
                    _buildDetailItem(
                      icon: Icons.monitor_weight,
                      title: 'Current Weight',
                      value: _formattedWeight,
                      onTap: _showWeightEntryDialog,
                    ),

                    const Divider(height: 1),

                    // Gender
                    _buildDetailItem(
                      icon: Icons.person,
                      title: 'Gender',
                      value: _userProfile?.gender ?? 'Not set',
                      onTap: _showGenderDialog,
                    ),

                    const Divider(height: 1),

                    // Activity level
                    _buildDetailItem(
                      icon: Icons.directions_run,
                      title: 'Activity Level',
                      value: _getActivityLevelText(),
                      onTap: _showActivityLevelDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Preferences section
              Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Preferences card
              Container(
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
                  children: [
                    // Units
                    _buildDetailItem(
                      icon: Icons.straighten,
                      title: 'Units',
                      value: _isMetric ? 'Metric' : 'Imperial',
                      onTap: () async {
                        await _createUserProfileIfNeeded();

                        setState(() {
                          _isMetric = !_isMetric;
                        });

                        if (_userProfile != null) {
                          final updatedProfile =
                              _userProfile!.copyWith(isMetric: _isMetric);
                          await _userRepository.saveUserProfile(updatedProfile);
                        }
                      },
                    ),

                    const Divider(height: 1),

                    // Theme
                    ThemeSelectorWidget(
                      currentTheme: _appTheme,
                      onThemeChanged: _changeTheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Data management section
              Text(
                'DATA MANAGEMENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // Data management card
              DataManagementWidget(
                onExport: _exportData,
                onImport: _importData,
                onClearData: _clearData,
              ),

              const SizedBox(height: 30),

              // About section
              Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

              // About app card
              AboutAppWidget(
                appVersion: '1.0.0',
                onViewPrivacyPolicy: () {},
                onViewTerms: () {},
              ),

              const SizedBox(height: 16),

              // Feedback option
              Container(
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
                child: FeedbackWidget(
                  onSendFeedback: _sendFeedback,
                ),
              ),

              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  String _getActivityLevelText() {
    if (_userProfile?.activityLevel == null) return 'Not set';

    final level = _userProfile!.activityLevel!;

    if (level < 1.3) return 'Sedentary';
    if (level < 1.45) return 'Light';
    if (level < 1.65) return 'Moderate';
    if (level < 1.8) return 'Active';
    return 'Very Active';
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
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
}
