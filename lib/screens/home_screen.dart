// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/home/target_calories_widget.dart'; // Import the new widget

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with app name and collage style
              Container(
                height: 280,
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    // App name
                    Positioned(
                      top: 10,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'FOOD CAL',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Track your meals,\nFeel your best',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Decorative elements
                    Positioned(
                      right: 20,
                      top: 40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.food_bank,
                          size: 60,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 100,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 30,
                      child: Icon(
                        Icons.local_cafe,
                        color: AppTheme.primaryBlue,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),

              // Blue feature box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppTheme.primaryBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRACK YOUR DAILY INTAKE\nAND MAINTAIN A HEALTHY\nLIFESTYLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 1.4,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(
                          Icons.breakfast_dining,
                          color: Colors.white,
                          size: 24,
                        ),
                        Icon(
                          Icons.lunch_dining,
                          color: Colors.white,
                          size: 24,
                        ),
                        Icon(
                          Icons.dinner_dining,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Target Calories Widget (NEW)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TargetCaloriesWidget(),
                  ],
                ),
              ),

              // Today's summary
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY\'S SUMMARY',
                      style: AppTheme.titleStyle,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                  ],
                ),
              ),

              // Recent meals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECENT MEALS',
                      style: AppTheme.titleStyle,
                    ),
                    const SizedBox(height: 16),
                    _buildRecentMealsList(),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                    'Calories', '1,200', '2,000', Colors.orange),
              ),
              Expanded(
                child: _buildSummaryItem('Protein', '45g', '80g', Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Carbs', '120g', '250g', Colors.green),
              ),
              Expanded(
                child: _buildSummaryItem('Fat', '30g', '65g', Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String current, String target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              current,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / $target',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.6, // 60% progress as a placeholder
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildRecentMealsList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];
        List<String> times = ['8:30 AM', '12:45 PM', '7:15 PM'];
        List<String> calories = ['320', '520', '450'];
        List<IconData> icons = [
          Icons.breakfast_dining,
          Icons.lunch_dining,
          Icons.dinner_dining
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icons[index],
                  color: AppTheme.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meals[index],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      times[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${calories[index]} kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
