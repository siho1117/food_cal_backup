import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function onSettingsTap;

  const CustomAppBar({
    Key? key,
    required this.onSettingsTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.secondaryBeige, // Fixed background color
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App name - always shown, larger font size
              const Text(
                'FOOD CAL',
                style: TextStyle(
                  fontSize: 32, // Larger font size
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 2,
                ),
              ),

              // Settings icon button
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
                onPressed: () => onSettingsTap(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
