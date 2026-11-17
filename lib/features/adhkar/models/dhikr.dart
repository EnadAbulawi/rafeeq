import 'dart:convert';

import 'package:flutter/services.dart';

const adhkarCategories = <String, String>{
  'morning': 'أذكار الصباح',
  'evening': 'أذكار المساء',
  'sleep': 'أذكار النوم',
  'wake': 'أذكار الاستيقاظ',
  'prayer': 'أذكار بعد الصلاة',
  'misc': 'أذكار متنوعة',
};

class Dhikr {
  const Dhikr({
    required this.id,
    required this.category,
    required this.text,
    required this.count,
    required this.reference,
    required this.source,
    this.virtue,
  });
  final String id, category, text, reference, source;
  final String? virtue;
  final int count;

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    final result = Dhikr(
      id: json['id'] as String,
      category: json['category'] as String,
      text: json['text'] as String,
      count: json['count'] as int,
      reference: json['reference'] as String,
      source: json['source'] as String,
      virtue: (json['virtue'] as String?)?.trim(),
    );
    if (result.count < 1 ||
        result.text.trim().isEmpty ||
        result.reference.trim().isEmpty ||
        !adhkarCategories.containsKey(result.category)) {
      throw const FormatException('Invalid dhikr entry');
    }
    return result;
  }
}

class AdhkarRepository {
  static Future<List<Dhikr>> load() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/data/adhkar.json'),
    ) as List;
    final entries = data
        .map((e) => Dhikr.fromJson(e as Map<String, dynamic>))
        .toList();
    if (entries.map((e) => e.id).toSet().length != entries.length) {
      throw const FormatException('Duplicate dhikr identifiers');
    }
    return List.unmodifiable(entries);
  }
}
