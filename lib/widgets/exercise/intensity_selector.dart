import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/exercise_models.dart';

class IntensitySelector extends StatefulWidget {
  final ExerciseLevel initialIntensity;
  final Function(ExerciseLevel) onIntensityChanged;

  const IntensitySelector({
    Key? key,
    required this.initialIntensity,
    required this.onIntensityChanged,
  }) : super(key: key);

  @override
  State<IntensitySelector> createState() => _IntensitySelectorState();
}

class _IntensitySelectorState extends State<IntensitySelector> {
  late ExerciseLevel _selectedIntensity;

  @override
  void initState() {
    super.initState();
    _selectedIntensity = widget.initialIntensity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIntensityOption(ExerciseLevel.beginner),
          _buildIntensityOption(ExerciseLevel.intermediate),
          _buildIntensityOption(ExerciseLevel.advanced),
          _buildIntensityOption(ExerciseLevel.expert),
        ],
      ),
    );
  }

  Widget _buildIntensityOption(ExerciseLevel level) {
    final bool isSelected = _selectedIntensity == level;

    // Get appropriate color and icon for each level
    Color color = level.color;
    IconData icon;
    switch (level) {
      case ExerciseLevel.beginner:
        icon = Icons.accessibility_new;
        break;
      case ExerciseLevel.intermediate:
        icon = Icons.directions_walk;
        break;
      case ExerciseLevel.advanced:
        icon = Icons.directions_run;
        break;
      case ExerciseLevel.expert:
        icon = Icons.flash_on;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIntensity = level;
        });
        widget.onIntensityChanged(level);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              level.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
