import '../models/user_profile.dart';
import '../models/weight_entry.dart';
import '../storage/local_storage.dart';
import '../../utils/formula.dart';

class UserRepository {
  static const String _userProfileKey = 'user_profile';
  static const String _weightEntriesKey = 'weight_entries';

  final LocalStorage _storage = LocalStorage();

  // Get the user profile
  Future<UserProfile?> getUserProfile() async {
    final profileMap = await _storage.getObject(_userProfileKey);

    if (profileMap == null) return null;

    try {
      return UserProfile.fromMap(profileMap);
    } catch (e) {
      print('Error retrieving user profile: $e');
      return null;
    }
  }

  // Save the user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      return await _storage.setObject(_userProfileKey, profile.toMap());
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Update goal weight
  Future<bool> updateGoalWeight(double goalWeight) async {
    final profile = await getUserProfile();
    if (profile == null) return false;

    final updatedProfile = profile.copyWith(goalWeight: goalWeight);
    return await saveUserProfile(updatedProfile);
  }

  // Get goal weight
  Future<double?> getGoalWeight() async {
    final profile = await getUserProfile();
    return profile?.goalWeight;
  }

  // Add a new weight entry
  Future<bool> addWeightEntry(WeightEntry entry) async {
    final entries = await getWeightEntries();
    entries.add(entry);
    return _saveWeightEntries(entries);
  }

  // Get all weight entries
  Future<List<WeightEntry>> getWeightEntries() async {
    final entriesList = await _storage.getObjectList(_weightEntriesKey);

    if (entriesList == null || entriesList.isEmpty) return [];

    try {
      return entriesList.map((map) => WeightEntry.fromMap(map)).toList();
    } catch (e) {
      print('Error retrieving weight entries: $e');
      return [];
    }
  }

  // Get weight entries within a date range
  Future<List<WeightEntry>> getWeightEntriesInRange(
      DateTime startDate, DateTime endDate) async {
    final entries = await getWeightEntries();

    return entries.where((entry) {
      return entry.timestamp.isAfter(startDate) &&
          entry.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get the latest weight entry
  Future<WeightEntry?> getLatestWeightEntry() async {
    final entries = await getWeightEntries();

    if (entries.isEmpty) return null;

    // Sort by timestamp (newest first)
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.first;
  }

  // Delete a weight entry
  Future<bool> deleteWeightEntry(String id) async {
    final entries = await getWeightEntries();
    final filtered = entries.where((entry) => entry.id != id).toList();

    if (filtered.length == entries.length) {
      // No entry was removed
      return false;
    }

    return _saveWeightEntries(filtered);
  }

  // Internal method to save weight entries
  Future<bool> _saveWeightEntries(List<WeightEntry> entries) async {
    try {
      final entriesMaps = entries.map((entry) => entry.toMap()).toList();
      return await _storage.setObjectList(_weightEntriesKey, entriesMaps);
    } catch (e) {
      print('Error saving weight entries: $e');
      return false;
    }
  }

  // Calculate BMI using Formula utility
  Future<double?> calculateBMI() async {
    final profile = await getUserProfile();
    final weightEntry = await getLatestWeightEntry();

    if (profile == null || weightEntry == null) {
      return null;
    }

    return Formula.calculateBMI(
      height: profile.height,
      weight: weightEntry.weight,
    );
  }

  // Get BMI classification using Formula utility
  String getBMIClassification(double bmi) {
    return Formula.getBMIClassification(bmi);
  }

  // Track weight change over a period
  Future<double?> getWeightChangeSince(DateTime startDate) async {
    final entries = await getWeightEntries();
    return Formula.calculateWeightChange(
        entries: entries, startDate: startDate);
  }

  // Calculate progress percentage toward goal weight
  Future<double> calculateGoalProgress() async {
    final profile = await getUserProfile();
    final latestEntry = await getLatestWeightEntry();

    if (profile?.goalWeight == null || latestEntry == null) {
      return 0.0;
    }

    return Formula.calculateGoalProgress(
      currentWeight: latestEntry.weight,
      targetWeight: profile!.goalWeight,
    );
  }

  // Get remaining weight to goal
  Future<double?> getRemainingWeightToGoal() async {
    final profile = await getUserProfile();
    final latestEntry = await getLatestWeightEntry();

    if (profile?.goalWeight == null || latestEntry == null) {
      return null;
    }

    return Formula.getRemainingWeightToGoal(
      currentWeight: latestEntry.weight,
      targetWeight: profile!.goalWeight,
    );
  }

  // Check if this is the first time the user is using the app
  Future<bool> isFirstTimeUser() async {
    final profile = await getUserProfile();
    return profile == null;
  }

  // Create initial user profile with a first weight entry
  Future<bool> createInitialProfile({
    required String name,
    required int age,
    required double height,
    required double weight,
    required bool isMetric,
    required String gender,
    double? goalWeight,
  }) async {
    // If not in metric, convert to metric
    final metricHeight =
        isMetric ? height : height * 2.54; // Convert inches to cm
    final metricWeight =
        isMetric ? weight : weight / 2.20462; // Convert lbs to kg
    final metricGoalWeight = goalWeight != null
        ? (isMetric ? goalWeight : goalWeight / 2.20462)
        : null;

    // Create user profile
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = UserProfile(
      id: userId,
      name: name,
      age: age,
      height: metricHeight, // Always store height in cm
      isMetric: isMetric, // Store user's preferred unit system
      gender: gender,
      goalWeight: metricGoalWeight, // Store goal weight if provided
    );

    // Create weight entry
    final weightEntry = WeightEntry.create(
      weight: metricWeight, // Always store weight in kg
    );

    // Save both
    final profileSaved = await saveUserProfile(profile);
    final weightSaved = await addWeightEntry(weightEntry);

    return profileSaved && weightSaved;
  }
}
