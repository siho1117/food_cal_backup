// lib/widgets/home/food_log_widget.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/food_item.dart';
import '../../data/repositories/food_repository.dart';

class FoodLogWidget extends StatefulWidget {
  final DateTime date;
  final bool showHeader;
  final VoidCallback? onFoodAdded;

  const FoodLogWidget({
    Key? key,
    required this.date,
    this.showHeader = true,
    this.onFoodAdded,
  }) : super(key: key);

  @override
  State<FoodLogWidget> createState() => _FoodLogWidgetState();
}

class _FoodLogWidgetState extends State<FoodLogWidget> {
  final FoodRepository _foodRepository = FoodRepository();
  bool _isLoading = true;
  Map<String, List<FoodItem>> _foodByMeal = {};

  // Track expanded sections
  final Map<String, bool> _expandedSections = {
    'breakfast': true,
    'lunch': true,
    'dinner': true,
    'snack': true,
  };

  @override
  void initState() {
    super.initState();
    _loadFoodEntries();
  }

  @override
  void didUpdateWidget(FoodLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if date changes
    if (oldWidget.date != widget.date) {
      _loadFoodEntries();
    }
  }

  Future<void> _loadFoodEntries() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final entriesByMeal =
          await _foodRepository.getFoodEntriesByMeal(widget.date);

      if (mounted) {
        setState(() {
          _foodByMeal = entriesByMeal;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading food entries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate total calories for a meal
  int _calculateMealCalories(List<FoodItem> items) {
    return items.fold(
        0, (sum, item) => sum + (item.calories * item.servingSize).round());
  }

  // Calculate macro breakdown for a meal
  Map<String, double> _calculateMealMacros(List<FoodItem> items) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var item in items) {
      totalProtein += item.proteins * item.servingSize;
      totalCarbs += item.carbs * item.servingSize;
      totalFat += item.fats * item.servingSize;
    }

    return {
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  // Calculate macro percentages
  Map<String, int> _calculateMacroPercentages(Map<String, double> macros) {
    final total = macros['protein']! + macros['carbs']! + macros['fat']!;

    if (total <= 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': ((macros['protein']! / total) * 100).round(),
      'carbs': ((macros['carbs']! / total) * 100).round(),
      'fat': ((macros['fat']! / total) * 100).round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Check if there are any food entries
    final bool hasEntries = _foodByMeal.values.any((list) => list.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional header
        if (widget.showHeader) ...[
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadFoodEntries,
                color: AppTheme.primaryBlue,
              )
            ],
          ),
          const SizedBox(height: 10),
        ],

        // No entries message
        if (!hasEntries)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No food logged for today. Use the camera button to log your meals.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

        // Food entries by meal type
        if (hasEntries) ...[
          ...['breakfast', 'lunch', 'dinner', 'snack'].map((mealType) {
            final mealItems = _foodByMeal[mealType] ?? [];

            // Skip empty meal types
            if (mealItems.isEmpty) {
              return const SizedBox.shrink();
            }

            final totalCalories = _calculateMealCalories(mealItems);
            final macros = _calculateMealMacros(mealItems);
            final macroPercentages = _calculateMacroPercentages(macros);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: ExpansionTile(
                initiallyExpanded: _expandedSections[mealType] ?? true,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedSections[mealType] = expanded;
                  });
                },
                title: Row(
                  children: [
                    _buildMealTypeIcon(mealType),
                    const SizedBox(width: 12),
                    Text(
                      mealType.substring(0, 1).toUpperCase() +
                          mealType.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Text(
                        '$totalCalories cal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Macro ratio pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'P: ${macroPercentages['protein']}% C: ${macroPercentages['carbs']}% F: ${macroPercentages['fat']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  // Macro progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildMacroProgressBar(
                          'P',
                          macroPercentages['protein']! / 100,
                          Colors.red,
                        ),
                        _buildMacroProgressBar(
                          'C',
                          macroPercentages['carbs']! / 100,
                          Colors.green,
                        ),
                        _buildMacroProgressBar(
                          'F',
                          macroPercentages['fat']! / 100,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...mealItems.map((item) => _buildFoodItemTile(item)),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildMealTypeIcon(String mealType) {
    IconData iconData;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        iconData = Icons.breakfast_dining;
        break;
      case 'lunch':
        iconData = Icons.lunch_dining;
        break;
      case 'dinner':
        iconData = Icons.dinner_dining;
        break;
      case 'snack':
        iconData = Icons.fastfood;
        break;
      default:
        iconData = Icons.food_bank;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildMacroProgressBar(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
              Text(
                ' ${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(FoodItem item) {
    // Calculate calories for this item with serving size
    final itemCalories = (item.calories * item.servingSize).round();

    // Calculate nutrient values with serving size - updated to remove decimal places
    final protein = (item.proteins * item.servingSize).round();
    final carbs = (item.carbs * item.servingSize).round();
    final fat = (item.fats * item.servingSize).round();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        item.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'P: ${protein}g • C: ${carbs}g • F: ${fat}g • ${item.servingSize} ${item.servingUnit}',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      trailing: Text(
        '$itemCalories cal',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () {
        // TODO: Add food item detail view or edit
      },
      onLongPress: () {
        _showDeleteConfirmation(item);
      },
    );
  }

  void _showDeleteConfirmation(FoodItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Food'),
        content: Text('Remove ${item.name} from your food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Delete the food entry
              final success = await _foodRepository.deleteFoodEntry(
                item.id,
                item.timestamp,
              );

              if (success) {
                // Reload the food entries
                _loadFoodEntries();

                // Notify the parent widget if needed
                if (widget.onFoodAdded != null) {
                  widget.onFoodAdded!();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }
}
