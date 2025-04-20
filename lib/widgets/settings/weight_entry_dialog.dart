import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class WeightEntryDialog extends StatefulWidget {
  final double? initialWeight;
  final bool isMetric;
  final Function(double, bool) onWeightSaved;

  const WeightEntryDialog({
    Key? key,
    required this.initialWeight,
    required this.isMetric,
    required this.onWeightSaved,
  }) : super(key: key);

  @override
  State<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<WeightEntryDialog> {
  late bool _isMetric;
  late double _selectedWeight;

  // For wheel picker
  late int _selectedWholeNumber;
  late int _selectedDecimal;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    // Set initial weight
    if (widget.initialWeight != null) {
      _selectedWeight = widget.initialWeight!;
      if (!_isMetric) {
        // Convert kg to lbs for display
        _selectedWeight = _selectedWeight * 2.20462;
      }
    } else {
      _selectedWeight = _isMetric ? 70.0 : 154.0; // Default values
    }

    // Extract whole and decimal parts
    _selectedWholeNumber = _selectedWeight.floor();
    _selectedDecimal = ((_selectedWeight - _selectedWholeNumber) * 10).round();
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

      // Update components
      _selectedWholeNumber = _selectedWeight.floor();
      _selectedDecimal =
          ((_selectedWeight - _selectedWholeNumber) * 10).round();
    });
  }

  void _saveWeight() {
    // Combine the whole and decimal parts
    final weight = _selectedWholeNumber + (_selectedDecimal / 10);

    // If in imperial, convert back to metric for storage
    final metricWeight = _isMetric ? weight : weight / 2.20462;

    // Pass back the selected weight and unit preference
    widget.onWeightSaved(metricWeight, _isMetric);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF0052CC);

    return AlertDialog(
      title: const Text('Edit Weight'),
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

            // Current weight display
            Text(
              'Current Weight',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 10),

            // Weight value display
            Text(
              '${_selectedWholeNumber}.$_selectedDecimal ${_isMetric ? 'kg' : 'lbs'}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Weight picker
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Whole number picker
                  SizedBox(
                    width: 80,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      looping: false,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedWholeNumber = _isMetric
                              ? index + 30 // 30-250 kg
                              : index + 66; // 66-550 lbs
                        });
                      },
                      scrollController: FixedExtentScrollController(
                        initialItem: _isMetric
                            ? _selectedWholeNumber - 30
                            : _selectedWholeNumber - 66,
                      ),
                      children: List.generate(
                        _isMetric ? 221 : 485, // Range depends on unit
                        (index) => Center(
                          child: Text(
                            _isMetric ? '${index + 30}' : '${index + 66}',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Decimal point
                  const Text(
                    '.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Decimal picker
                  SizedBox(
                    width: 60,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      looping: true,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedDecimal = index;
                        });
                      },
                      scrollController: FixedExtentScrollController(
                        initialItem: _selectedDecimal,
                      ),
                      children: List.generate(
                        10,
                        (index) => Center(
                          child: Text(
                            '$index',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Unit
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Text(
                        _isMetric ? 'kg' : 'lbs',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
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
          onPressed: _saveWeight,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
