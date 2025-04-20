import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HeightPickerDialog extends StatefulWidget {
  final double? initialHeight;
  final bool isMetric;
  final Function(double) onHeightSelected;

  const HeightPickerDialog({
    Key? key,
    this.initialHeight,
    required this.isMetric,
    required this.onHeightSelected,
  }) : super(key: key);

  @override
  State<HeightPickerDialog> createState() => _HeightPickerDialogState();
}

class _HeightPickerDialogState extends State<HeightPickerDialog> {
  late bool _isMetric;
  late double _selectedHeight;

  // Imperial values
  late int _feet;
  late int _inches;

  // Metric value
  late int _cm;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    // Set initial height
    _selectedHeight = widget.initialHeight ?? (_isMetric ? 170.0 : 67.0);

    if (_isMetric) {
      _cm = _selectedHeight.round();
    } else {
      // Convert to feet and inches
      final totalInches = _selectedHeight / 2.54;
      _feet = (totalInches / 12).floor();
      _inches = (totalInches % 12).round();
    }
  }

  void _toggleUnit() {
    setState(() {
      if (_isMetric) {
        // Convert cm to feet/inches
        final totalInches = _cm / 2.54;
        _feet = (totalInches / 12).floor();
        _inches = (totalInches % 12).round();
      } else {
        // Convert feet/inches to cm
        _cm = ((_feet * 12) + _inches) * 2.54.round();
      }

      _isMetric = !_isMetric;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return AlertDialog(
      title: const Text('Height'),
      content: SizedBox(
        height: 240,
        child: Column(
          children: [
            // Unit toggle
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
                  onChanged: (value) => _toggleUnit(),
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

            const SizedBox(height: 20),

            // Height display
            Text(
              _isMetric ? '$_cm cm' : '$_feet\' $_inches"',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Height picker
            Expanded(
              child: _isMetric
                  ? // Centimeters picker
                  CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _cm - 100, // Adjusted for range start
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() => _cm = index + 100);
                      },
                      children: List.generate(
                        121, // 100cm to 220cm
                        (index) => Center(
                          child: Text(
                            '${index + 100} cm',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    )
                  : // Feet and inches picker
                  Row(
                      children: [
                        // Feet picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem:
                                  _feet - 3, // Adjusted for range start
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _feet = index + 3);
                            },
                            children: List.generate(
                              6, // 3ft to 8ft
                              (index) => Center(
                                child: Text(
                                  '${index + 3} ft',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Inches picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _inches,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _inches = index);
                            },
                            children: List.generate(
                              12, // 0 to 11 inches
                              (index) => Center(
                                child: Text(
                                  '$index in',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            double heightValue;
            if (_isMetric) {
              heightValue = _cm.toDouble();
            } else {
              heightValue = ((_feet * 12) + _inches) * 2.54;
            }

            widget.onHeightSelected(heightValue);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
