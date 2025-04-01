import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/llm_service.dart';

class SwearProvider extends ChangeNotifier {
  int _swearCount = 0;
  final _llmService = LLMService();

  int get swearCount => _swearCount;

  Future<void> checkSpeech(String transcript) async {
    final hasSwear = await _llmService.containsSwearing(transcript);
    if (hasSwear) {
      _swearCount++;
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

  void resetCounter() async {
    _swearCount = 0;
    await saveSwearCount();
    notifyListeners();
  }
}
