import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Increased height to allow for camera button
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        clipBehavior:
            Clip.none, // Important to show camera button above container
        children: [
          // Regular navigation items in a row
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home'),
                _buildNavItem(1, Icons.bar_chart, 'Progress'),
                // Empty space for the camera button
                const SizedBox(width: 60),
                _buildNavItem(3, Icons.fitness_center, 'Exercise'),
                _buildNavItem(4, Icons.settings, 'Settings'),
              ],
            ),
          ),

          // Center camera button (positioned on top of the row)
          Positioned(
            top: -25, // Raised higher to be more visible
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                      begin: 1.0, end: currentIndex == 2 ? 1.2 : 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.accentColor,
                              AppTheme.primaryBlue,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Ripple effect indicator for selected item
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCirc,
            bottom: 0,
            left: _getIndicatorPosition(currentIndex, context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: currentIndex == 2 ? 0 : 50, // No indicator for camera
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getIndicatorPosition(int index, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;

    // Adjust position based on index, considering the camera button
    if (index == 0) return itemWidth / 2 - 25;
    if (index == 1) return itemWidth * 1.5 - 25;
    if (index == 3) return itemWidth * 3.5 - 25;
    if (index == 4) return itemWidth * 4.5 - 25;

    return 0; // For camera button
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: isSelected ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: value,
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
