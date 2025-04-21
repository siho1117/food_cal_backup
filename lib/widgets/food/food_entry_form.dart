// lib/widgets/food/food_entry_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../data/models/food_item.dart';
import '../../data/repositories/food_repository.dart';

class FoodEntryForm extends StatefulWidget {
  final String mealType;
  final FoodItem? initialFoodItem; // For editing existing items
  final Function() onSaved;

  const FoodEntryForm({
    Key? key,
    required this.mealType,
    this.initialFoodItem,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<FoodEntryForm> createState() => _FoodEntryFormState();
}

class _FoodEntryFormState extends State<FoodEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final FoodRepository _repository = FoodRepository();
  bool _isLoading = false;

  // Form fields
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinsController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;
  late TextEditingController _servingSizeController;
  late String _servingUnit;
  late String _selectedMealType;

  // Serving unit options
  final List<String> _servingUnits = [
    'serving',
    'g',
    'ml',
    'oz',
    'cup',
    'tbsp',
    'tsp',
    'piece',
    'slice',
  ];

  // Meal type options
  final List<String> _mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with data if editing
    if (widget.initialFoodItem != null) {
      _nameController =
          TextEditingController(text: widget.initialFoodItem!.name);
      _caloriesController = TextEditingController(
          text: widget.initialFoodItem!.calories.round().toString());
      _proteinsController = TextEditingController(
          text: widget.initialFoodItem!.proteins.round().toString());
      _carbsController = TextEditingController(
          text: widget.initialFoodItem!.carbs.round().toString());
      _fatsController = TextEditingController(
          text: widget.initialFoodItem!.fats.round().toString());
      _servingSizeController = TextEditingController(
          text: widget.initialFoodItem!.servingSize.toString());
      _servingUnit = widget.initialFoodItem!.servingUnit;
      _selectedMealType = widget.initialFoodItem!.mealType;
    } else {
      // Default values for new entry
      _nameController = TextEditingController();
      _caloriesController = TextEditingController();
      _proteinsController = TextEditingController();
      _carbsController = TextEditingController();
      _fatsController = TextEditingController();
      _servingSizeController = TextEditingController(text: '1.0');
      _servingUnit = 'serving';
      _selectedMealType = widget.mealType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create food item from form data
        final foodItem = FoodItem(
          id: widget.initialFoodItem?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          calories: double.parse(_caloriesController.text),
          proteins: double.parse(_proteinsController.text),
          carbs: double.parse(_carbsController.text),
          fats: double.parse(_fatsController.text),
          imagePath: widget.initialFoodItem?.imagePath,
          mealType: _selectedMealType,
          timestamp: DateTime.now(),
          servingSize: double.parse(_servingSizeController.text),
          servingUnit: _servingUnit,
        );

        // Save to repository
        bool success;
        if (widget.initialFoodItem != null) {
          // Update existing item
          success = await _repository.updateFoodEntry(foodItem);
        } else {
          // Add new item
          success = await _repository.saveFoodEntry(foodItem);
        }

        if (success && mounted) {
          // Close the form and notify parent
          Navigator.of(context).pop();
          widget.onSaved();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.initialFoodItem != null ? 'Updated' : 'Added'} ${foodItem.name}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save food item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error saving food: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialFoodItem != null ? 'Edit Food' : 'Add Food',
          style: const TextStyle(color: AppTheme.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
      ),
      backgroundColor: AppTheme.secondaryBeige,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a food name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Meal type dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _mealTypes.map((mealType) {
                        return DropdownMenuItem<String>(
                          value: mealType,
                          child: Text(
                            mealType.substring(0, 1).toUpperCase() +
                                mealType.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMealType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Serving information
                    Row(
                      children: [
                        // Serving size
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _servingSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Serving Size',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              try {
                                final size = double.parse(value);
                                if (size <= 0) {
                                  return 'Must be > 0';
                                }
                              } catch (e) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Serving unit
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _servingUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: _servingUnits.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _servingUnit = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Nutritional information section
                    const Text(
                      'NUTRITIONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Calories
                    TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        helperText: 'Per serving',
                        border: OutlineInputBorder(),
                        suffixText: 'cal',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        try {
                          double.parse(value);
                        } catch (e) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Macronutrients
                    Row(
                      children: [
                        // Protein
                        Expanded(
                          child: TextFormField(
                            controller: _proteinsController,
                            decoration: const InputDecoration(
                              labelText: 'Protein',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Carbs
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            decoration: const InputDecoration(
                              labelText: 'Carbs',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Fat
                        Expanded(
                          child: TextFormField(
                            controller: _fatsController,
                            decoration: const InputDecoration(
                              labelText: 'Fat',
                              border: OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveFood,
                        child: Text(
                          widget.initialFoodItem != null
                              ? 'Update Food'
                              : 'Add Food',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
