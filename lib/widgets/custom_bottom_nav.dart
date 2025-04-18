import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../config/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Function()? onCameraCapture;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onCameraCapture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Very dark beige, almost brown for stronger contrast
    final navBarColor = AppTheme.primaryBlue; // Very dark beige
    final primaryBlue = const Color.fromARGB(
        255, 255, 147, 46); // App's primary blue for selected button

    // Check if we're on the camera screen
    final isCameraScreen = currentIndex == 2;

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
        // Custom camera button that changes based on screen
        _buildCameraNavItem(isCameraScreen),
        _buildNavItem(Icons.fitness_center_rounded, 'Exercise', 3),
        _buildNavItem(Icons.settings_rounded, 'Settings', 4),
      ],
      onTap: (index) {
        // Special handling for camera button when on camera screen
        if (index == 2 && isCameraScreen && onCameraCapture != null) {
          onCameraCapture!();
        } else {
          onTap(index);
        }
      },
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

  Widget _buildCameraNavItem(bool isCameraScreen) {
    // If we're on the camera screen, show a camera shutter button
    // Otherwise, show the normal camera icon
    if (isCameraScreen) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.camera,
            size: 32,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Regular camera nav item
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.camera_alt_rounded,
              size: 24,
              color: Colors.white,
            ),
            Text(
              'Camera',
              style: TextStyle(
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
}
