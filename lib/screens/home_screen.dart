// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/home/target_calories_widget.dart';
import '../widgets/home/daily_summary_widget.dart';
import '../widgets/home/food_log_widget.dart';
import '../widgets/food/food_entry_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  void _refreshData() {
    // Force a rebuild to refresh all data
    setState(() {});
  }

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
                height: 200, // Reduced height from 280
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
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.food_bank,
                          size: 50,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Daily Summary Widget (NEW!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DailySummaryWidget(
                  date: _selectedDate,
                ),
              ),

              const SizedBox(height: 20),

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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

              const SizedBox(height: 20),

              // Today's Food Log with Add Food button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Header row with title and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TODAY\'S FOOD LOG',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Food'),
                          onPressed: () {
                            // Show add food form
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FoodEntryForm(
                                  mealType: 'snack', // Default meal type
                                  onSaved: _refreshData,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Food log widget
                    FoodLogWidget(
                      date: _selectedDate,
                      showHeader:
                          false, // Hide the header since we're showing it above
                      onFoodAdded: _refreshData,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Date selector for looking at different days
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        setState(() {
                          _selectedDate =
                              _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                      color: AppTheme.primaryBlue,
                    ),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        _isToday(_selectedDate)
                            ? 'Today'
                            : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _selectedDate.year == DateTime.now().year &&
                              _selectedDate.month == DateTime.now().month &&
                              _selectedDate.day == DateTime.now().day
                          ? null
                          : () {
                              setState(() {
                                _selectedDate =
                                    _selectedDate.add(const Duration(days: 1));
                              });
                            },
                      color: AppTheme.primaryBlue,
                    ),
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

  // Helper method to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
