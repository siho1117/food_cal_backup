class WeightEntry {
  final String id; // Unique identifier
  final double
      weight; // Weight in kg (always stored in kg regardless of display preference)
  final DateTime timestamp; // When the entry was recorded
  final String? note; // Optional note for the entry

  WeightEntry({
    required this.id,
    required this.weight,
    required this.timestamp,
    this.note,
  });

  // Format weight based on unit system
  String formattedWeight(bool isMetric, {int decimalPlaces = 1}) {
    final double displayWeight = isMetric ? weight : weight * 2.20462;
    return displayWeight.toStringAsFixed(decimalPlaces);
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
    };
  }

  // Create from map for retrieval
  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      weight: map['weight'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      note: map['note'],
    );
  }

  // Create a new entry with a unique ID
  factory WeightEntry.create({
    required double weight,
    DateTime? timestamp,
    String? note,
  }) {
    final now = timestamp ?? DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    return WeightEntry(
      id: id,
      weight: weight,
      timestamp: now,
      note: note,
    );
  }
}
