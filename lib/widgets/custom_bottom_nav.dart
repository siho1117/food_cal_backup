import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
    // Very dark beige, almost brown for stronger contrast
    final navBarColor = AppTheme.primaryBlue; // Very dark beige
    final primaryBlue = const Color.fromARGB(
        255, 255, 147, 46); // App's primary blue for selected button

    return CurvedNavigationBar(
      index: currentIndex,
      height: 75, // Maintained height
      backgroundColor: Colors.transparent,
      color: navBarColor, // Very dark beige navigation bar
      buttonBackgroundColor: primaryBlue, // Selected button is blue
      animationCurve: Curves.easeOutCubic,
      animationDuration: const Duration(milliseconds: 400),
      items: [
        _buildNavItem(Icons.home_rounded, 'Home', 0),
        _buildNavItem(Icons.bar_chart_rounded, 'Progress', 1),
        _buildNavItem(Icons.camera_alt_rounded, 'Camera', 2),
        _buildNavItem(Icons.fitness_center_rounded, 'Exercise', 3),
        _buildNavItem(Icons.settings_rounded, 'Settings', 4),
      ],
      onTap: onTap,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;

    return Padding(
      padding: isSelected
          ? const EdgeInsets.all(10.0) // Regular padding for selected items
          : const EdgeInsets.fromLTRB(
              10, 16, 10, 5), // More top padding for unselected
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSelected ? 28 : 24,
            color: Colors.white,
          ),
          // Only show label if not selected (as selected items move up)
          if (!isSelected)
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
