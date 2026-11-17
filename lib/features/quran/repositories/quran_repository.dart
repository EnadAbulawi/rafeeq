import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

String normalizeArabic(String value) => value
    .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06EDـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .trim();

class ReadingPosition {
  const ReadingPosition(this.surah, this.verse);
  final int surah, verse;
  String get id => '$surah:$verse';
  bool get valid =>
      surah >= 1 &&
      surah <= 114 &&
      verse >= 1 &&
      verse <= QuranRepository().count(surah);
  static ReadingPosition parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid reading position');
    }
    final position = ReadingPosition(int.parse(parts[0]), int.parse(parts[1]));
    if (!position.valid) {
      throw const FormatException('Invalid reading position');
    }
    return position;
  }
}

class QuranRepository {
  static List<Map<String, dynamic>>? _surahs;
  static List<ReadingPosition>? _pageStarts;
  static const pageCount = 604;
  static Future<void> load() async {
    if (_surahs != null && _pageStarts != null) return;
    final raw = await rootBundle.loadString('assets/data/quran.json');
    final data = await compute(_parseQuran, raw);
    final metadata = jsonDecode(
      await rootBundle.loadString('assets/data/quran-pages.json'),
    ) as Map<String, dynamic>;
    final pages = (metadata['pages'] as List).cast<Map<String, dynamic>>();
    final starts = <ReadingPosition>[];
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final s = page['surah'] as int, v = page['verse'] as int;
      if (page['page'] != i + 1 ||
          s < 1 ||
          s > 114 ||
          v < 1 ||
          v > (data[s - 1]['verses'] as List).length ||
          (starts.isNotEmpty &&
              (s < starts.last.surah ||
                  (s == starts.last.surah && v <= starts.last.verse)))) {
        throw const FormatException('Invalid Quran page boundaries');
      }
      starts.add(ReadingPosition(s, v));
    }
    if (starts.length != pageCount || starts.first.id != '1:1') {
      throw const FormatException('Incomplete Quran pagination');
    }
    _surahs = data;
    _pageStarts = List.unmodifiable(starts);
  }

  List<Map<String, dynamic>> get _data {
    final data = _surahs;
    if (data == null) {
      throw StateError('Quran dataset not loaded');
    }
    return data;
  }

  ReadingPosition pageStart(int page) => _pageStarts![page - 1];
  int pageFor(ReadingPosition position) {
    if (!position.valid) {
      throw const FormatException('Invalid reading position');
    }
    var low = 0, high = pageCount;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      final start = _pageStarts![mid];
      if (start.surah < position.surah ||
          (start.surah == position.surah && start.verse <= position.verse)) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  List<ReadingPosition> pageVerses(int page) {
    final start = pageStart(page);
    final end = page == pageCount
        ? ReadingPosition(114, count(114) + 1)
        : pageStart(page + 1);
    return [
      for (var s = start.surah; s <= end.surah; s++)
        for (
          var v = s == start.surah ? start.verse : 1;
          v <= (s == end.surah ? end.verse - 1 : count(s));
          v++
        )
          ReadingPosition(s, v),
    ];
  }

  String name(int surah) => _data[surah - 1]['name'] as String;
  int count(int surah) => (_data[surah - 1]['verses'] as List).length;
  String verse(int surah, int verse) =>
      (_data[surah - 1]['verses'] as List)[verse - 1] as String;
  String? basmalaFor(int surah) => _data[surah - 1]['basmala'] as String?;
  Future<List<String>> search(String query) =>
      compute(_searchVerses, <Object>[query, _data]);
}

List<Map<String, dynamic>> _parseQuran(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final data = (json['surahs'] as List).cast<Map<String, dynamic>>();
  if (data.length != 114 ||
      data.fold<int>(0, (n, s) => n + (s['verses'] as List).length) != 6236) {
    throw const FormatException('Invalid Quran dataset');
  }
  for (var i = 0; i < data.length; i++) {
    if (data[i]['id'] != i + 1 ||
        (data[i]['name'] as String).isEmpty ||
        (data[i]['verses'] as List).any((v) => v is! String || v.isEmpty)) {
      throw const FormatException('Invalid Quran structure');
    }
  }
  return data;
}

List<String> _searchVerses(List<Object> args) {
  final needle = normalizeArabic(args[0] as String);
  if (needle.length < 2) return [];
  final data = (args[1] as List).cast<Map<String, dynamic>>();
  final result = <String>[];
  for (var s = 0; s < data.length; s++) {
    final verses = (data[s]['verses'] as List).cast<String>();
    for (var v = 0; v < verses.length; v++) {
      if (normalizeArabic(verses[v]).contains(needle)) {
        result.add('${s + 1}:${v + 1}');
      }
    }
  }
  return result;
}
