import 'package:flutter/material.dart';

class AboutAppWidget extends StatelessWidget {
  final String appVersion;
  final VoidCallback onViewPrivacyPolicy;
  final VoidCallback onViewTerms;

  const AboutAppWidget({
    Key? key,
    required this.appVersion,
    required this.onViewPrivacyPolicy,
    required this.onViewTerms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAboutItem(
            context,
            'App Version',
            appVersion,
            Icons.info_outline,
            primaryBlue,
          ),
          const Divider(),
          InkWell(
            onTap: onViewPrivacyPolicy,
            child: _buildAboutItem(
              context,
              'Privacy Policy',
              '',
              Icons.privacy_tip_outlined,
              primaryBlue,
              showChevron: true,
            ),
          ),
          const Divider(),
          InkWell(
            onTap: onViewTerms,
            child: _buildAboutItem(
              context,
              'Terms of Service',
              '',
              Icons.description_outlined,
              primaryBlue,
              showChevron: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color primaryColor, {
    bool showChevron = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
            )
          else if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }
}
