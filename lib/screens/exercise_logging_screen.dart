import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../data/models/exercise_models.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/user_repository.dart';
import '../widgets/exercise/intensity_selector.dart';

class ExerciseLoggingScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseLoggingScreen({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  State<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends State<ExerciseLoggingScreen> {
  final ExerciseRepository _exerciseRepository = ExerciseRepository();
  final UserRepository _userRepository = UserRepository();

  // Exercise parameters
  ExerciseLevel _selectedIntensity = ExerciseLevel.intermediate;
  int _durationMinutes = 0;
  int _durationSeconds = 0;
  int _calories = 0;
  bool _isActive = false;
  String? _notes;

  // Timer related
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Text editing controller for notes
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with exercise default intensity
    _selectedIntensity = widget.exercise.level;
    _calculateCalories();
  }

  @override
  void dispose() {
    _stopTimer();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer(); // Ensure any existing timer is stopped

    setState(() {
      _isActive = true;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _durationMinutes = _elapsedSeconds ~/ 60;
        _durationSeconds = _elapsedSeconds % 60;
        _calculateCalories();
      });
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    setState(() {
      _isActive = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
      _durationMinutes = 0;
      _durationSeconds = 0;
      _calculateCalories();
    });
  }

  void _calculateCalories() {
    // Apply intensity multiplier to base calories
    double intensityMultiplier;
    switch (_selectedIntensity) {
      case ExerciseLevel.beginner:
        intensityMultiplier = 0.8;
        break;
      case ExerciseLevel.intermediate:
        intensityMultiplier = 1.0;
        break;
      case ExerciseLevel.advanced:
        intensityMultiplier = 1.2;
        break;
      case ExerciseLevel.expert:
        intensityMultiplier = 1.5;
        break;
    }

    // Calculate total duration in minutes (including partial minutes)
    final totalMinutes = _durationMinutes + (_durationSeconds / 60);

    // Calculate calories burned
    setState(() {
      _calories = (widget.exercise.caloriesPerMinute *
              totalMinutes *
              intensityMultiplier)
          .round();
    });
  }

  void _onIntensityChanged(ExerciseLevel level) {
    setState(() {
      _selectedIntensity = level;
      _calculateCalories();
    });
  }

  Future<void> _saveExerciseLog() async {
    if (_elapsedSeconds < 10) {
      // Don't save if duration is too short
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise duration too short to log')),
      );
      return;
    }

    try {
      // Get current user weight for the log
      final latestWeight = await _userRepository.getLatestWeightEntry();

      // Create an exercise log
      final log = ExerciseLog.create(
        exerciseId: widget.exercise.id,
        durationMinutes: _durationMinutes +
            (_durationSeconds >= 30 ? 1 : 0), // Round up if 30+ seconds
        caloriesBurned: _calories,
        intensityLevel: _selectedIntensity,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        userWeight: latestWeight?.weight,
      );

      // Save to repository
      final success = await _exerciseRepository.addExerciseLog(log);

      if (success && mounted) {
        // Show success message and close the screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise logged successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log exercise')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      appBar: AppBar(
        title: Text(widget.exercise.name),
        backgroundColor: widget.exercise.type.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exercise type header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.exercise.type.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.exercise.type.icon,
                      color: widget.exercise.type.color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.exercise.type.displayName,
                      style: TextStyle(
                        color: widget.exercise.type.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Timer display
              _buildTimerDisplay(),

              const SizedBox(height: 32),

              // Timer controls
              _buildTimerControls(),

              const SizedBox(height: 32),

              // Intensity selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INTENSITY LEVEL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntensitySelector(
                    initialIntensity: _selectedIntensity,
                    onIntensityChanged: _onIntensityChanged,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Calories burned
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CALORIES BURNED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$_calories',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Notes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOTES (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add notes about this workout...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Log exercise button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExerciseLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'LOG EXERCISE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Progress indicator
            CircularProgressIndicator(
              value: _isActive ? null : 1.0, // Indeterminate when active
              strokeWidth: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _isActive ? AppTheme.primaryBlue : Colors.grey[400]!,
              ),
            ),
            // Time display
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_durationMinutes.toString().padLeft(2, '0')}:${_durationSeconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Text(
                    'minutes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        FloatingActionButton(
          onPressed: _resetTimer,
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          heroTag: 'reset',
          child: const Icon(Icons.restart_alt),
        ),

        const SizedBox(width: 24),

        // Start/Stop button
        FloatingActionButton.large(
          onPressed: _isActive ? _stopTimer : _startTimer,
          backgroundColor: _isActive ? Colors.red : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          heroTag: 'startStop',
          child: Icon(_isActive ? Icons.pause : Icons.play_arrow),
        ),

        const SizedBox(width: 24),

        // Manual add button
        FloatingActionButton(
          onPressed: () {
            // Show dialog to manually add time
            _showAddTimeDialog();
          },
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          heroTag: 'add',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _showAddTimeDialog() {
    int minutes = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration in minutes:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (minutes > 0) {
                          setState(() => minutes--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle),
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '$minutes',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => minutes++);
                      },
                      icon: const Icon(Icons.add_circle),
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add the minutes to the current timer
              setState(() {
                _elapsedSeconds += minutes * 60;
                _durationMinutes = _elapsedSeconds ~/ 60;
                _durationSeconds = _elapsedSeconds % 60;
                _calculateCalories();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}
