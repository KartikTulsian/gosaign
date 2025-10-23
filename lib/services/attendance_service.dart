// lib/services/attendance_service.dart
import 'package:flutter/cupertino.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();

  factory AttendanceService() => _instance;

  AttendanceService._internal();

  // final List<Map<String, dynamic>> _entries = [];
  //
  // List<Map<String, dynamic>> get entries => _entries;
  //
  // void addEntry(Map<String, dynamic> data) {
  //   _entries.add(data);
  // }
  //
  // void clear() => _entries.clear();

  final ValueNotifier<List<Map<String, dynamic>>> entriesNotifier = ValueNotifier([]);

  void addEntry(Map<String, dynamic> entry) {
    final alreadyExists = entriesNotifier.value.any(
          (e) => e['womanId'] == entry['womanId'],
    );
    if (!alreadyExists) {
      entriesNotifier.value = [...entriesNotifier.value, entry];
    }
  }

  void removeEntry(String womanId) {
    entriesNotifier.value =
        entriesNotifier.value.where((e) => e['womanId'] != womanId).toList();
  }
}
