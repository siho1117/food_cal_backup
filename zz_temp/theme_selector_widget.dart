import 'package:flutter/material.dart';

class ThemeSelectorWidget extends StatelessWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const ThemeSelectorWidget({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return InkWell(
      onTap: () => _showThemeSelector(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.palette,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Theme',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getThemeDisplayName(currentTheme),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return 'System Default';
    }
  }

  void _showThemeSelector(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, 'Light', 'light', primaryBlue),
            _buildThemeOption(context, 'Dark', 'dark', primaryBlue),
            _buildThemeOption(context, 'System Default', 'system', primaryBlue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label,
      String themeValue, Color primaryColor) {
    final bool isSelected = currentTheme == themeValue;

    return ListTile(
      leading: Icon(
        themeValue == 'light'
            ? Icons.wb_sunny
            : themeValue == 'dark'
                ? Icons.nightlight_round
                : Icons.smartphone,
        color: isSelected ? primaryColor : Colors.grey,
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: primaryColor,
            )
          : null,
      selected: isSelected,
      onTap: () {
        onThemeChanged(themeValue);
        Navigator.of(context).pop();
      },
    );
  }
}
