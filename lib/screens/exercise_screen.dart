import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_profile.dart';
import '../widgets/exercise/daily_burn_widget.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final UserRepository _userRepository = UserRepository();
  UserProfile? _userProfile;
  double? _currentWeight;
  bool _isLoading = true;

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
          _currentWeight = latestWeight?.weight;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Only EXERCISE TRACKER text
                    const Text(
                      'EXERCISE TRACKER',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Daily Exercise Goal Widget - Now the only widget on this screen
                    DailyBurnWidget(
                      userProfile: _userProfile,
                      currentWeight: _currentWeight,
                    ),

                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
      ),
    );
  }
}
