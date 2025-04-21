// lib/widgets/food/food_item_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/food_item.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FoodItemCard({
    Key? key,
    required this.foodItem,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate values based on serving size
    final nutritionValues = foodItem.getNutritionForServing();

    // Extract values and log them for debugging
    final calories = nutritionValues['calories']!.round();
    // Updated to remove decimal places for macronutrients
    final protein = nutritionValues['proteins']!.round().toString();
    final carbs = nutritionValues['carbs']!.round().toString();
    final fat = nutritionValues['fats']!.round().toString();

    // Print for debugging
    print(
        'FoodItemCard - ${foodItem.name}: calories=$calories, protein=$protein, carbs=$carbs, fat=$fat');
    print(
        'Original values - calories: ${foodItem.calories}, proteins: ${foodItem.proteins}, carbs: ${foodItem.carbs}, fats: ${foodItem.fats}');
    print('Serving size: ${foodItem.servingSize}');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Food image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: foodItem.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(foodItem.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return const Icon(
                              Icons.fastfood,
                              color: AppTheme.primaryBlue,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        color: AppTheme.primaryBlue,
                        size: 30,
                      ),
              ),

              const SizedBox(width: 12),

              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and meal type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            foodItem.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMealTypeColor(foodItem.mealType)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatMealType(foodItem.mealType),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getMealTypeColor(foodItem.mealType),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Serving info
                    Text(
                      '${foodItem.servingSize} ${foodItem.servingUnit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Macro info
                    Row(
                      children: [
                        _buildMacroInfo('P', protein, Colors.red),
                        _buildMacroInfo('C', carbs, Colors.green),
                        _buildMacroInfo('F', fat, Colors.blue),
                        const Spacer(),
                        Text(
                          '$calories cal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button if provided
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.grey[600],
                  onPressed: onDelete,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value g',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMealType(String mealType) {
    // Capitalize first letter
    if (mealType.isEmpty) return 'Snack';
    return mealType.substring(0, 1).toUpperCase() +
        mealType.substring(1).toLowerCase();
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
