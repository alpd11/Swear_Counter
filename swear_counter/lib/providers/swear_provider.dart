import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/llm_service.dart';
import '../models/swear_category.dart';
import '../models/swear_count.dart';

class SwearProvider with ChangeNotifier {
  int _swearCount = 0;
  final List<SwearCategory> _categories = [];
  final List<DailySwearCount> _dailyCounts = [];
  final List<WeeklySwearCount> _weeklyCounts = [];
  final _llmService = LLMService();

  int get swearCount => _swearCount;
  List<SwearCategory> get categories => _categories;
  List<DailySwearCount> get dailyCounts => _dailyCounts;
  List<WeeklySwearCount> get weeklyCounts => _weeklyCounts;

  Future<void> checkSpeech(String transcript) async {
    print('Checking speech for swears: "$transcript"');
    final hasSwear = await _llmService.containsSwearing(transcript);
    print('Has swear: $hasSwear');
    if (hasSwear) {
      _swearCount++;
      print('Swear detected! New count: $_swearCount');
      await saveSwearCount();
      notifyListeners();
    }
  }

  Future<void> saveSwearCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('swearCount', _swearCount);
  }

  Future<void> loadSwearCount() async {
    final prefs = await SharedPreferences.getInstance();
    _swearCount = prefs.getInt('swearCount') ?? 0;
    notifyListeners();
  }

  void incrementCounter() {
    _swearCount++;
    notifyListeners();
  }

  void resetCounter() {
    _swearCount = 0;
    notifyListeners();
  }

  void updateCategories(List<SwearCategory> newCategories) {
    _categories.clear();
    _categories.addAll(newCategories);
    notifyListeners();
  }

  void addDailyCount(int count) {
    final today = DateTime.now();
    final existingIndex = _dailyCounts.indexWhere(
      (d) => d.date.year == today.year && 
              d.date.month == today.month && 
              d.date.day == today.day
    );

    if (existingIndex >= 0) {
      _dailyCounts[existingIndex] = DailySwearCount(
        date: today,
        count: _dailyCounts[existingIndex].count + count
      );
    } else {
      _dailyCounts.add(DailySwearCount(date: today, count: count));
    }

    // Keep only last 7 days
    if (_dailyCounts.length > 7) {
      _dailyCounts.removeRange(0, _dailyCounts.length - 7);
    }

    _updateWeeklyCounts();
    notifyListeners();
  }

  void _updateWeeklyCounts() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    _weeklyCounts.clear();
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dailyCount = _dailyCounts.firstWhere(
        (d) => d.date.year == date.year && 
                d.date.month == date.month && 
                d.date.day == date.day,
        orElse: () => DailySwearCount(date: date, count: 0),
      );
      _weeklyCounts.add(WeeklySwearCount(day: i, count: dailyCount.count));
    }
  }
}
