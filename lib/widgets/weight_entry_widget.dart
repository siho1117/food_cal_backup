import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeightEntryWidget extends StatefulWidget {
  final Function(double, bool) onWeightSaved;
  final double? initialWeight;
  final bool isMetric;

  const WeightEntryWidget({
    Key? key,
    required this.onWeightSaved,
    this.initialWeight,
    this.isMetric = true,
  }) : super(key: key);

  @override
  State<WeightEntryWidget> createState() => _WeightEntryWidgetState();
}

class _WeightEntryWidgetState extends State<WeightEntryWidget> {
  late bool _isMetric;
  late double _selectedWeight;

  // App colors - defined directly here instead of using AppTheme
  final Color primaryBlue = const Color(0xFF0052CC);

  // Weight ranges - stored in their respective units
  final double _minWeightKg = 1.0;
  final double _maxWeightKg = 999.0;
  final double _minWeightLbs = 2.2; // ~1kg in lbs
  final double _maxWeightLbs = 2200.0; // ~999kg in lbs

  // For scale movement
  late ScrollController _scaleController;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    // Initialize with provided weight or default values
    if (widget.initialWeight != null) {
      _selectedWeight = widget.initialWeight!;
    } else {
      _selectedWeight = _isMetric ? 70.0 : 154.0; // Default values
    }

    // Initialize scale position
    _scaleController = ScrollController(
      initialScrollOffset: _calculateScrollPosition(),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  double _calculateScrollPosition() {
    final min = _isMetric ? _minWeightKg : _minWeightLbs;

    // Each weight unit takes 40 pixels (increased from 20 for better spacing)
    final itemWidth = 40.0;

    // Calculate position - offset by selected weight from minimum weight
    return (_selectedWeight - min) * itemWidth;
  }

  void _handleScaleScroll() {
    final min = _isMetric ? _minWeightKg : _minWeightLbs;
    final offset = _scaleController.offset;
    final itemWidth = 40.0; // Match the spacing in calculateScrollPosition

    // Calculate weight based on scroll position
    final weightFromScroll = min + (offset / itemWidth);

    // Round to 1 decimal place
    final roundedWeight = (weightFromScroll * 10).round() / 10;

    if (_selectedWeight != roundedWeight) {
      // If crossing a whole number, trigger haptic feedback
      if (_selectedWeight.floor() != roundedWeight.floor()) {
        HapticFeedback.lightImpact();
      }

      setState(() {
        _selectedWeight = roundedWeight;
      });
    }
  }

  void _toggleUnit() {
    setState(() {
      if (_isMetric) {
        // Convert kg to lbs
        _selectedWeight = _selectedWeight * 2.20462;
      } else {
        // Convert lbs to kg
        _selectedWeight = _selectedWeight / 2.20462;
      }
      _isMetric = !_isMetric;

      // Update scale position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaleController.jumpTo(_calculateScrollPosition());
      });
    });

    HapticFeedback.mediumImpact(); // Vibration feedback
  }

  void _saveWeight() {
    // Convert to metric for storage if needed
    final metricWeight =
        _isMetric ? _selectedWeight : _selectedWeight / 2.20462;

    // Always save in metric units with the user's display preference
    widget.onWeightSaved(metricWeight, _isMetric);
    Navigator.of(context).pop();
  }

  // Format weight to show 1 decimal place
  String get formattedWeight {
    return _selectedWeight.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      // Make background opaque with barrierColor in the showDialog call
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'Edit Weight',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Placeholder to balance the layout
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 20),

            // Unit toggle switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Imperial',
                  style: TextStyle(
                    color: !_isMetric ? Colors.black : Colors.grey,
                    fontWeight:
                        !_isMetric ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: _isMetric,
                  onChanged: (value) {
                    _toggleUnit();
                  },
                  activeColor: primaryBlue,
                ),
                Text(
                  'Metric',
                  style: TextStyle(
                    color: _isMetric ? Colors.black : Colors.grey,
                    fontWeight: _isMetric ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Current weight label
            const Text(
              'Current Weight',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            // Weight display
            Text(
              '$formattedWeight ${_isMetric ? 'kg' : 'lbs'}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // Moving scale with indicator
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  // Scale background
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),

                  // Center indicator (fixed)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 3,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Scrollable scale
                  NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        _handleScaleScroll();
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      controller: _scaleController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // Start padding
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 2),

                          // Scale markings - Generate for metric or imperial
                          ...List.generate(
                            // Generate 10x as many ticks to have one for each 0.1
                            _isMetric
                                ? ((_maxWeightKg - _minWeightKg) * 10).toInt() +
                                    1
                                : ((_maxWeightLbs - _minWeightLbs) * 10)
                                        .toInt() +
                                    1,
                            (index) {
                              // Calculate weight with one decimal place
                              final weight = _isMetric
                                  ? _minWeightKg + (index / 10)
                                  : _minWeightLbs + (index / 10);

                              // Check if this is a whole number
                              final isWhole = weight.toInt() == weight;
                              // Check if this is a X.0 number (e.g., 70.0, 71.0)
                              final isDecimal = (weight * 10).toInt() % 10 == 0;

                              return SizedBox(
                                width:
                                    4, // Space each 0.1 increment by 4px (so each whole unit is 40px)
                                child: Column(
                                  children: [
                                    Container(
                                      width:
                                          isWhole ? 2 : (isDecimal ? 1.5 : 1),
                                      height:
                                          isWhole ? 40 : (isDecimal ? 25 : 15),
                                      color: isWhole
                                          ? Colors.black
                                          : (isDecimal
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // End padding
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
