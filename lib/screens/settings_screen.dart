import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_profile.dart';
import '../data/models/weight_entry.dart';
import '../widgets/settings/profile_picture_widget.dart';
import '../widgets/settings/date_picker_dialog.dart';
import '../widgets/settings/height_picker_dialog.dart';
import '../widgets/settings/gender_selection_dialog.dart';
import '../widgets/settings/activity_level_dialog.dart';
import '../widgets/settings/feedback_widget.dart';
import '../widgets/settings/monthly_weight_goal_dialog.dart';
import '../widgets/settings/weight_entry_dialog.dart';
import '../utils/formula.dart';

class SettingsScreen extends StatefulWidget {
  // New parameter to check if we should show back button
  final bool showBackButton;

  const SettingsScreen({
    Key? key,
    this.showBackButton = false,
  }) : super(key: key);

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
        onDateSelected: (selectedDate, calculatedAge) async {
          if (_userProfile != null) {
            // Update profile with both birthDate and calculated age
            final updatedProfile = _userProfile!.copyWith(
              birthDate: selectedDate,
              age: calculatedAge,
            );

            print('Saving age: $calculatedAge'); // Debug print
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

  // Show monthly weight goal dialog
  void _showMonthlyWeightGoalDialog() async {
    await _createUserProfileIfNeeded();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => MonthlyWeightGoalDialog(
        currentMonthlyGoal: _userProfile?.monthlyWeightGoal,
        isMetric: _isMetric,
        onGoalSaved: (monthlyGoal) async {
          if (_userProfile != null) {
            final updatedProfile = _userProfile!.copyWith(
              monthlyWeightGoal: monthlyGoal,
            );
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

  // Feedback function
  void _sendFeedback() {
    // Implementation for sending feedback
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
      // Add an app bar with back button when needed
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: primaryBlue,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xFF0052CC),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - only show this if not showing the appbar
              if (!widget.showBackButton)
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

                    // Height - Now using Formula.formatHeight
                    _buildDetailItem(
                      icon: Icons.height,
                      title: 'Height',
                      value: Formula.formatHeight(
                        height: _userProfile?.height,
                        isMetric: _isMetric,
                      ),
                      onTap: _showHeightPickerDialog,
                    ),

                    const Divider(height: 1),

                    // Current weight - Already using Formula.formatWeight
                    _buildDetailItem(
                      icon: Icons.monitor_weight,
                      title: 'Current Weight',
                      value: Formula.formatWeight(
                        weight: _currentWeight,
                        isMetric: _isMetric,
                      ),
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

                    // Activity level - Using Formula.getActivityLevelText
                    _buildDetailItem(
                      icon: Icons.directions_run,
                      title: 'Activity Level',
                      value: Formula.getActivityLevelText(
                          _userProfile?.activityLevel),
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
                          setState(() {
                            _userProfile = updatedProfile;
                          });
                        }
                      },
                    ),

                    const Divider(height: 1),

                    // Monthly weight goal
                    _buildDetailItem(
                      icon: Icons.speed,
                      title: 'Monthly Weight Goal',
                      value: _userProfile?.monthlyWeightGoal != null
                          ? '${Formula.formatMonthlyWeightGoal(
                              goal: _userProfile!.monthlyWeightGoal,
                              isMetric: _isMetric,
                            )}'
                          : 'Not set',
                      onTap: _showMonthlyWeightGoalDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Feedback section
              Text(
                'FEEDBACK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
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
