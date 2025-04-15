import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/models/exercise_models.dart';
import '../data/repositories/exercise_repository.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseId,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final ExerciseRepository _repository = ExerciseRepository();
  Exercise? _exercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercise = await _repository.getExerciseById(widget.exerciseId);
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercise: $e')),
        );
      }
    }
  }

  void _navigateToLoggingScreen() {
    if (_exercise == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseLoggingPlaceholder(exercise: _exercise!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exercise Details'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: AppTheme.textLight,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_exercise == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exercise Details'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: AppTheme.textLight,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Exercise not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: _exercise!.type.color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _exercise!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or color
                  Container(
                    color: _exercise!.type.color,
                    child: _exercise!.imageUrl != null
                        ? Image.network(
                            _exercise!.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              _exercise!.type.icon,
                              size: 80,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise info cards
                  _buildInfoCards(),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _exercise!.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Target muscles
                  const Text(
                    'TARGET MUSCLES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildChipList(_exercise!.targetMuscles),

                  const SizedBox(height: 24),

                  // Equipment needed
                  if (_exercise!.equipment.isNotEmpty) ...[
                    const Text(
                      'EQUIPMENT NEEDED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChipList(_exercise!.equipment),
                    const SizedBox(height: 24),
                  ],

                  // Video preview
                  if (_exercise!.videoUrl != null) ...[
                    const Text(
                      'INSTRUCTIONAL VIDEO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildVideoPreview(),
                    const SizedBox(height: 24),
                  ],

                  // Spacing for bottom button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // Start exercise button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToLoggingScreen,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow),
        label: const Text('START EXERCISE'),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Exercise type
          _buildInfoCard(
            icon: _exercise!.type.icon,
            title: 'Type',
            value: _exercise!.type.displayName,
            color: _exercise!.type.color,
          ),

          // Difficulty level
          _buildInfoCard(
            icon: Icons.trending_up,
            title: 'Level',
            value: _exercise!.level.displayName,
            color: _exercise!.level.color,
          ),

          // Calories
          _buildInfoCard(
            icon: Icons.local_fire_department,
            title: 'Calories',
            value: '${_exercise!.caloriesPerMinute}/min',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(item),
          backgroundColor: AppTheme.secondaryBeige,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: const TextStyle(color: AppTheme.textDark),
        );
      }).toList(),
    );
  }

  Widget _buildVideoPreview() {
    // Placeholder for video preview
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Watch Video',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for exercise logging screen
class ExerciseLoggingPlaceholder extends StatelessWidget {
  final Exercise exercise;

  const ExerciseLoggingPlaceholder({Key? key, required this.exercise})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.textLight,
      ),
      body: Center(
        child: Text('Exercise logging screen will be implemented soon'),
      ),
    );
  }
}
