// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';
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
              // Padding at the top (placeholder for future design)
              const SizedBox(height: 20),

              // Daily Summary Widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DailySummaryWidget(
                  date: _selectedDate,
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
