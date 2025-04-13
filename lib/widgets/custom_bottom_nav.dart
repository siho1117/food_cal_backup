import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // For interpolating between indices
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width only in build method
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTabItem(0, Icons.home, 'Home'),
              _buildTabItem(1, Icons.bar_chart, 'Progress'),
              Expanded(child: Container()), // Empty space for camera button
              _buildTabItem(3, Icons.fitness_center, 'Exercise'),
              _buildTabItem(4, Icons.settings, 'Settings'),
            ],
          ),

          // Animated indicator
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // Calculate start and end positions for animation
              final itemWidth = screenWidth / 5;

              // Current and previous positions
              final double startPosition =
                  _getPositionForIndex(_previousIndex, itemWidth);
              final double endPosition =
                  _getPositionForIndex(widget.currentIndex, itemWidth);

              // Interpolate between positions based on animation value
              final double currentPosition = startPosition +
                  (_animationController.value * (endPosition - startPosition));

              return Positioned(
                left: currentPosition - 30, // Center the 60px wide circle
                top: 10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.currentIndex == 2
                        ? AppTheme.primaryBlue // Camera background color
                        : Colors.green, // Regular indicator color
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.currentIndex == 2
                                ? AppTheme.primaryBlue
                                : Colors.green)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForIndex(widget.currentIndex),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),

          // Clickable areas (transparent overlays)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTappableArea(0),
              _buildTappableArea(1),
              _buildTappableArea(2), // Camera
              _buildTappableArea(3),
              _buildTappableArea(4),
            ],
          ),
        ],
      ),
    );
  }

  // Calculate position based on index and item width
  double _getPositionForIndex(int index, double itemWidth) {
    switch (index) {
      case 0:
        return itemWidth / 2;
      case 1:
        return itemWidth * 1.5;
      case 2:
        return itemWidth * 2.5; // Camera button position
      case 3:
        return itemWidth * 3.5; // Exercise
      case 4:
        return itemWidth * 4.5;
      default:
        return 0.0;
    }
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.bar_chart;
      case 2:
        return Icons.camera_alt;
      case 3:
        return Icons.fitness_center;
      case 4:
        return Icons.settings;
      default:
        return Icons.home;
    }
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final bool isSelected = widget.currentIndex == index;
    final Color color = isSelected ? Colors.green : Colors.white54;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableArea(int index) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(index),
        child: Container(
          height: 80,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
