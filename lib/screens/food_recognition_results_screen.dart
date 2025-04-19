import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/models/food_item.dart';
import '../data/repositories/food_repository.dart';
import '../widgets/food/food_item_card.dart';

class FoodRecognitionResultsScreen extends StatefulWidget {
  final File imageFile;
  final String mealType;

  const FoodRecognitionResultsScreen({
    Key? key,
    required this.imageFile,
    required this.mealType,
  }) : super(key: key);

  @override
  State<FoodRecognitionResultsScreen> createState() =>
      _FoodRecognitionResultsScreenState();
}

class _FoodRecognitionResultsScreenState
    extends State<FoodRecognitionResultsScreen> {
  final FoodRepository _repository = FoodRepository();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<FoodItem> _recognizedItems = [];

  @override
  void initState() {
    super.initState();
    _recognizeFood();
  }

  Future<void> _recognizeFood() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      // Call API to recognize food
      final items = await _repository.recognizeFood(
        widget.imageFile,
        widget.mealType,
      );

      if (mounted) {
        setState(() {
          _recognizedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error recognizing food: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _saveSelectedItems() async {
    if (_recognizedItems.isEmpty) {
      Navigator.of(context).pop(); // Nothing to save
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save all recognized items
      final result = await _repository.saveFoodEntries(_recognizedItems);

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _recognizedItems.length == 1
                    ? '${_recognizedItems[0].name} added to your food log'
                    : '${_recognizedItems.length} items added to your food log',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to previous screen
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save food items'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving food items: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recognition Results',
          style: TextStyle(color: AppTheme.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
      ),
      backgroundColor: AppTheme.secondaryBeige,
      body: _buildBody(),
      bottomNavigationBar: _isLoading || _hasError ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_hasError) {
      return _buildErrorState();
    } else {
      return _buildResultsContent();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Food Recognition Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Unable to recognize food in the image.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _recognizeFood,
              child: const Text('Try Again'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    return Column(
      children: [
        // Image preview
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Results title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'RECOGNIZED FOOD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                '${_recognizedItems.length} ${_recognizedItems.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Results content - either items list or no items message
        _recognizedItems.isEmpty ? _buildNoItemsFound() : _buildItemsList(),
      ],
    );
  }

  Widget _buildNoItemsFound() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_food,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No food recognized',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try taking another photo or add food manually',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recognizedItems.length,
        itemBuilder: (context, index) {
          return FoodItemCard(
            foodItem: _recognizedItems[index],
            onTap: () {
              // TODO: Allow editing food item details
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveSelectedItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text(
              'Add to Food Log',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
