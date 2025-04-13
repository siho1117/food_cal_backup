import 'package:flutter/material.dart';
import '../config/theme.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder (full screen)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.camera_alt,
                color: Colors.white.withOpacity(0.3),
                size: 100,
              ),
            ),
          ),

          // App name at top
          Positioned(
            top: 50,
            left: 20,
            child: const Text(
              'FOOD CAL',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),

          // Camera controls at bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Instructions
                const Text(
                  'Take a photo of your meal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Camera buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    _buildCameraButton(
                      Icons.photo_library,
                      'Gallery',
                      () {},
                      false,
                    ),

                    // Capture button
                    _buildCameraButton(
                      Icons.camera,
                      'Capture',
                      () {},
                      true,
                    ),

                    // Flash button
                    _buildCameraButton(
                      Icons.flash_on,
                      'Flash',
                      () {},
                      false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isPrimary,
  ) {
    return Column(
      children: [
        // Button
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: isPrimary ? 70 : 50,
            height: isPrimary ? 70 : 50,
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppTheme.accentColor
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  isPrimary ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 30 : 24,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Label
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
