import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/llm_service.dart';
import '../services/firebase_service.dart';
import '../models/swear_category.dart';
import '../models/swear_count.dart';

class SwearProvider with ChangeNotifier {
  int _swearCount = 0;
  final List<SwearCategory> _categories = [];
  final List<DailySwearCount> _dailyCounts = [];
  final List<WeeklySwearCount> _weeklyCounts = [];
  final _llmService = LLMService();
  final _firebaseService = FirebaseService();
  
  // Keep track of recently processed words to avoid duplicates
  final List<String> _recentlyProcessedTexts = [];
  static const int _maxRecentTextsToStore = 10;

  int get swearCount => _swearCount;
  List<SwearCategory> get categories => _categories;
  List<DailySwearCount> get dailyCounts => _dailyCounts;
  List<WeeklySwearCount> get weeklyCounts => _weeklyCounts;

  Future<void> checkSpeech(String transcript) async {
    // Check if this is a duplicate of recently processed text
    if (_recentlyProcessedTexts.contains(transcript)) {
      print('Ignoring duplicate text: "$transcript"');
      return;
    }
    
    // Add to recently processed list
    _recentlyProcessedTexts.add(transcript);
    if (_recentlyProcessedTexts.length > _maxRecentTextsToStore) {
      _recentlyProcessedTexts.removeAt(0);
    }
    
    print('Checking speech for swears: "$transcript"');
    final swearWordCount = await _llmService.countSwearWords(transcript);
    print('Swear word count: $swearWordCount');
    
    if (swearWordCount > 0) {
      // Increment by the actual number of swear words found
      _swearCount += swearWordCount;
      print('Swear words detected! New count: $_swearCount');
      
      // Get detailed analysis for categories
      try {
        final analysis = await _llmService.analyzeText(transcript);
        
        // Update categories
        for (var category in analysis.categories) {
          final existingCategoryIndex = _categories.indexWhere(
            (c) => c.category.toLowerCase() == category.category.toLowerCase()
          );
          
          if (existingCategoryIndex >= 0) {
            // Update existing category
            final existingCategory = _categories[existingCategoryIndex];
            _categories[existingCategoryIndex] = SwearCategory(
              category: existingCategory.category,
              count: existingCategory.count + category.count,
              examples: [...existingCategory.examples, ...category.examples].toSet().toList(),
            );
          } else {
            // Add new category
            _categories.add(SwearCategory(
              category: category.category,
              count: category.count,
              examples: category.examples,
            ));
          }
        }
        
        // Add to daily counts
        addDailyCount(swearWordCount);
      } catch (e) {
        print('Error updating swear categories: $e');
      }
      
      await saveSwearCount();
      
      // Sync swear count with friends
      try {
        await _firebaseService.updateSwearCount(_swearCount);
      } catch (e) {
        print('Error syncing swear count with friends: $e');
      }
      
      notifyListeners();
    }
  }

  void addDailyCount(int count) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Check if we already have an entry for today
    final existingDailyIndex = _dailyCounts.indexWhere(
      (element) => 
        element.date.year == todayDate.year &&
        element.date.month == todayDate.month &&
        element.date.day == todayDate.day
    );
    
    if (existingDailyIndex >= 0) {
      // Update existing entry
      final existingCount = _dailyCounts[existingDailyIndex];
      _dailyCounts[existingDailyIndex] = DailySwearCount(
        date: existingCount.date,
        count: existingCount.count + count,
      );
    } else {
      // Add new entry for today
      _dailyCounts.add(DailySwearCount(
        date: todayDate,
        count: count,
      ));
    }
    
    // Keep only last 7 days
    if (_dailyCounts.length > 7) {
      _dailyCounts.sort((a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)
      _dailyCounts.removeRange(7, _dailyCounts.length);
    }
    
    updateWeeklyCounts();
  }
  
  void updateWeeklyCounts() {
    _weeklyCounts.clear();
    
    // Get day of week for each daily count (0 = Monday, 6 = Sunday)
    for (var dailyCount in _dailyCounts) {
      final dayOfWeek = dailyCount.date.weekday - 1; // Convert to 0-based index
      
      // Check if we already have an entry for this day
      final existingIndex = _weeklyCounts.indexWhere((e) => e.day == dayOfWeek);
      
      if (existingIndex >= 0) {
        // Update existing entry
        _weeklyCounts[existingIndex] = WeeklySwearCount(
          day: dayOfWeek,
          count: _weeklyCounts[existingIndex].count + dailyCount.count,
        );
      } else {
        // Add new entry
        _weeklyCounts.add(WeeklySwearCount(
          day: dayOfWeek,
          count: dailyCount.count,
        ));
      }
    }
    
    // Fill in missing days with zero
    for (var i = 0; i < 7; i++) {
      if (_weeklyCounts.indexWhere((e) => e.day == i) < 0) {
        _weeklyCounts.add(WeeklySwearCount(day: i, count: 0));
      }
    }
    
    // Sort by day
    _weeklyCounts.sort((a, b) => a.day.compareTo(b.day));
  }

  Future<void> saveSwearCount() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save total count
    await prefs.setInt('swearCount', _swearCount);
    
    // Save categories
    final List<String> categoryList = _categories.map((cat) => 
      '${cat.category}:${cat.count}:${cat.examples.join(",")}'
    ).toList();
    await prefs.setStringList('categories', categoryList);
    
    // Save daily counts
    final List<String> dailyCountList = _dailyCounts.map((daily) => 
      '${daily.date.millisecondsSinceEpoch}:${daily.count}'
    ).toList();
    await prefs.setStringList('dailyCounts', dailyCountList);
  }

  Future<void> loadSwearCount() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load total count
    _swearCount = prefs.getInt('swearCount') ?? 0;
    
    // Load daily counts
    final List<String>? dailyCountList = prefs.getStringList('dailyCounts');
    if (dailyCountList != null) {
      _dailyCounts.clear();
      for (var dailyString in dailyCountList) {
        final parts = dailyString.split(':');
        if (parts.length == 2) {
          final date = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]));
          _dailyCounts.add(DailySwearCount(
            date: date,
            count: int.parse(parts[1]),
          ));
        }
      }
      
      // Update weekly counts based on loaded daily counts
      updateWeeklyCounts();
    }
    
    // Sync the count to friends
    try {
      await _firebaseService.updateSwearCount(_swearCount);
    } catch (e) {
      print('Error syncing initial swear count with friends: $e');
    }
    
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _swearCount = 0;
    _categories.clear();
    _dailyCounts.clear();
    _weeklyCounts.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('swearCount');
    await prefs.remove('categories');
    await prefs.remove('dailyCounts');
    
    // Also update the zero count to friends
    try {
      await _firebaseService.updateSwearCount(0);
    } catch (e) {
      print('Error syncing reset swear count with friends: $e');
    }
    
    notifyListeners();
  }

  void resetCounter() {
    _swearCount = 0;
    notifyListeners();
  }
}
