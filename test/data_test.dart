import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:rafeeq/features/quran/services/qcf_mushaf_service.dart';
import 'package:rafeeq/features/adhkar/models/dhikr.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(QuranRepository.load);
  test('all 114 surahs match independent verse counts and total 6236', () {
    const counts = [
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6,
    ];
    final q = QuranRepository();
    var total = 0;
    for (var s = 1; s <= 114; s++) {
      expect(q.count(s), counts[s - 1], reason: 'Surah $s');
      expect(q.name(s), isNotEmpty);
      for (var v = 1; v <= counts[s - 1]; v++) {
        final p = ReadingPosition.parse('$s:$v');
        expect(p.valid, true);
        expect(q.verse(s, v).trim(), isNotEmpty);
        total++;
      }
    }
    expect(total, 6236);
  });
  test('basmala is separate except Al-Fatiha and absent for At-Tawba', () {
    final data =
        jsonDecode(File('assets/data/quran.json').readAsStringSync()) as Map;
    final surahs = data['surahs'] as List;
    expect(surahs[0]['basmala'], isNull);
    expect(surahs[8]['basmala'], isNull);
    for (var i = 1; i < 114; i++) {
      if (i != 8) {
        expect(
          normalizeArabic(surahs[i]['basmala'] as String),
          'بسم الله الرحمن الرحيم',
        );
        expect(QuranRepository().basmalaFor(i + 1), surahs[i]['basmala']);
      }
    }
  });
  test('source XML matches every shipped character and sequence', () {
    // Independent extraction of the source XML, not a fixture derived from runtime code.
    final xml = File('design/tanzil-uthmani.xml').readAsStringSync();
    final texts = RegExp(r'<aya index="\d+" text="([^"]+)"')
        .allMatches(xml)
        .map((m) => m[1]!)
        .toList();
    final data =
        jsonDecode(File('assets/data/quran.json').readAsStringSync()) as Map;
    final shipped = [
      for (final s in data['surahs'] as List) ...s['verses'] as List,
    ];
    expect(texts.length, 6236);
    expect(shipped, texts);
    expect(data['notice'], contains('CHANGING IT IS NOT ALLOWED'));
  });
  test('invalid navigation identifiers are rejected', () {
    for (final id in ['0:1', '115:1', '2:287', '1:0', '1:1:1', 'x:y']) {
      expect(() => ReadingPosition.parse(id), throwsFormatException);
    }
  });
  test('Arabic search normalization leaves source text unchanged', () async {
    final q = QuranRepository();
    final original = q.verse(1, 1);
    expect(normalizeArabic('أَإِآٱىـ'), 'ااااي');
    final results = await q.search('الحمد لله');
    expect(results, contains('1:2'));
    expect(await q.search('zzzzzz'), isEmpty);
    expect(q.verse(1, 1), original);
  });
  test(
    'all six dhikr categories contain valid uniquely identified texts',
    () async {
      final entries = await AdhkarRepository.load();
      expect(entries.length, 77);
      expect(entries.map((e) => e.id).toSet().length, entries.length);
      for (final category in adhkarCategories.keys) {
        expect(entries.where((e) => e.category == category), isNotEmpty);
      }
      for (final entry in entries) {
        expect(entry.reference, isNotEmpty);
        expect(entry.count, greaterThan(0));
      }
    },
  );
  test('604 Medina pages cover all verses once in canonical order', () {
    final q = QuranRepository();
    final positions = <String>[];
    for (var page = 1; page <= QuranRepository.pageCount; page++) {
      final verses = q.pageVerses(page);
      expect(verses, isNotEmpty);
      expect(verses.first.id, q.pageStart(page).id);
      for (final p in verses) {
        expect(q.pageFor(p), page);
        positions.add(p.id);
      }
    }
    expect(positions, [
      for (var s = 1; s <= 114; s++)
        for (var v = 1; v <= q.count(s); v++) '$s:$v',
    ]);
    expect(q.pageFor(const ReadingPosition(2, 255)), 42);
    expect(q.pageStart(604).id, '112:1');
  });

  test('QCF metadata supports every preserved surah and verse identifier', () {
    final repository = QuranRepository();
    expect(qcf.totalPagesCount, 604);
    expect(qcf.totalVerseCount, 6236);
    for (var s = 1; s <= 114; s++) {
      expect(qcf.getVerseCount(s), repository.count(s));
      for (var v = 1; v <= repository.count(s); v++) {
        expect(qcf.getPageNumber(s, v), inInclusiveRange(1, 604));
      }
    }
  });
  test('QCF page ranges contain every canonical verse ID exactly once', () {
    final ids = <String>[];
    for (var page = 1; page <= 604; page++) {
      for (final range in qcf.getPageData(page)) {
        for (var v = range['start'] as int; v <= (range['end'] as int); v++) {
          ids.add('${range['surah']}:$v');
        }
      }
    }
    final q = QuranRepository();
    expect(ids, [
      for (var s = 1; s <= 114; s++)
        for (var v = 1; v <= q.count(s); v++) '$s:$v',
    ]);
  });
  test('reader uses QCF boundaries where the legacy page index differs', () {
    const p = ReadingPosition(5, 77);
    expect(QuranRepository().pageFor(p), 121);
    expect(QcfMushafService.pageFor(p), 120);
    expect(QcfMushafService.pageFor(QcfMushafService.pageStart(120)), 120);
  });
}
