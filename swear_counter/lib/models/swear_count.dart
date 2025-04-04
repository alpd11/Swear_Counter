import 'package:flutter/material.dart';

class WeeklySwearCount {
  final int day;
  final int count;

  WeeklySwearCount({
    required this.day,
    required this.count,
  });
}

class DailySwearCount {
  final DateTime date;
  final int count;

  DailySwearCount({
    required this.date,
    required this.count,
  });
} 