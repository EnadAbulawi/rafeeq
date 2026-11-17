import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:rafeeq/app/controllers/app_controller.dart';
import 'package:rafeeq/features/adhkar/models/dhikr.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';
import 'package:rafeeq/features/quran/services/qcf_mushaf_service.dart';
import 'package:rafeeq/features/quran/services/qcf_page_fonts.dart';
import 'package:rafeeq/features/quran/views/widgets/mushaf_pager.dart';
import 'package:rafeeq/features/quran/views/widgets/mushaf_loading_view.dart';

import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppController app;
  setUpAll(() async {
    await QuranRepository.load();
    app = AppController(MemoryStore(), await AdhkarRepository.load());
  });
  tearDownAll(() => app.dispose());

  Widget reader({Future<void> Function(int)? prepare}) => MaterialApp(
    home: Scaffold(
      body: MushafPager(
        controller: app,
        position: const ReadingPosition(2, 6),
        onPositionChanged: (_) {},
        onVerseTap: (_) {},
        preparePage: prepare,
      ),
    ),
  );

  testWidgets(
    'cold reader loads bundled fonts without path provider or cache',
    (tester) async {
      expect(QcfMushafService.isPagePrepared(3), false);
      await tester.runAsync(() async {
        await tester.pumpWidget(reader());
        expect(find.byType(MushafLoadingView), findsOneWidget);
        // Keep asset IO, isolate callbacks and font registration in real async
        // time. Joining this request also checks in-flight load deduplication.
        await QcfMushafService.preparePage(3);
      });
      await tester.pumpAndSettle();
      expect(QcfMushafService.isPagePrepared(3), true);
      expect(find.byType(MushafLoadingView), findsNothing);
      expect(find.byType(qcf.QuranPageView), findsOneWidget);
      final page = tester
          .widgetList<qcf.QuranSinglePageWidget>(
            find.byType(qcf.QuranSinglePageWidget),
          )
          .firstWhere((p) => p.pageIndex == 3);
      expect(page.page.lines.length, 15);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('stalled load times out and retry opens the page', (
    tester,
  ) async {
    var calls = 0;
    final stalled = Completer<void>();
    await tester.pumpWidget(
      reader(
        prepare: (_) {
          calls++;
          return calls == 1 ? stalled.future : Future.value();
        },
      ),
    );
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byType(MushafLoadingView), findsNothing);
    expect(find.textContaining('تعذر تجهيز صفحة المصحف'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(qcf.QuranPageView), findsOneWidget);
    stalled.complete();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during loading handles late completion', (tester) async {
    final pending = Completer<void>();
    await tester.pumpWidget(reader(prepare: (_) => pending.future));
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test(
    'monochrome variants preserve every glyph and non-palette byte',
    () async {
      final asset = await rootBundle.load(
        'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/QCF4005_COLOR-Regular.ttf.gz',
      );
      final compressed = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );
      final original = Uint8List.fromList(gzip.decode(compressed));
      final data = ByteData.sublistView(original);
      var palette = -1;
      for (var i = 0; i < data.getUint16(4); i++) {
        final record = 12 + 16 * i;
        if (data.getUint32(record) == 0x4350414C) {
          palette = data.getUint32(record + 8);
        }
      }
      expect(palette, greaterThanOrEqualTo(0));
      final start = palette + data.getUint32(palette + 8);
      final count = data.getUint16(palette + 6);
      final fonts = decodeQcfPageFonts(compressed);
      expect(fonts.length, 3);
      expect(
        fonts[2],
        original,
        reason: 'Verse numbers need the original family',
      );
      for (var variant = 0; variant < 2; variant++) {
        final font = fonts[variant];
        final restored = Uint8List.fromList(font);
        for (var record = 0; record < count; record++) {
          final offset = start + record * 4;
          expect(
            font.sublist(offset, offset + 3),
            List.filled(3, variant == 0 ? 0 : 255),
          );
          restored.setRange(offset, offset + 3, original, offset);
        }
        expect(restored, original);
      }
    },
  );

  test('invalid pages fail immediately', () async {
    await expectLater(QcfPageFonts.load(0), throwsRangeError);
    await expectLater(QcfPageFonts.load(605), throwsRangeError);
  });
}
