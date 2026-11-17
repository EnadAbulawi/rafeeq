import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:rafeeq/features/quran/services/qcf_mushaf_service.dart';
import 'package:rafeeq/app/app.dart';
import 'package:rafeeq/app/controllers/app_controller.dart';
import 'package:rafeeq/features/adhkar/models/dhikr.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';
import 'package:rafeeq/features/quran/views/quran_reader_view.dart';
import 'package:rafeeq/features/quran/controllers/quran_audio_controller.dart';
import 'package:rafeeq/features/quran/views/widgets/reader_footer.dart';
import 'package:rafeeq/features/home/views/widgets/home_feature_tile.dart';
import 'package:rafeeq/features/quran/views/widgets/mushaf_loading_view.dart';
import 'package:rafeeq/core/theme/app_theme.dart';

import 'support/memory_store.dart';
import 'support/fake_reminder_backend.dart';

import 'package:rafeeq/features/settings/views/settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Dhikr> entries;
  late AppController app;
  setUpAll(() async {
    PathProviderPlatform.instance = _TestPaths();
    for (final page in [1, 2, 3, 42, 604]) {
      await QcfMushafService.preparePage(page);
    }
    await QuranRepository.load();
    entries = await AdhkarRepository.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final entry in {
      'arsura': 'arsura.ttf',
      'QCF4_BSML': 'QCF4_BSML/QCF4_BSML.ttf',
    }.entries) {
      final font = FontLoader('packages/qcf_quran_plus/${entry.key}')
        ..addFont(
          rootBundle.load(
            'packages/qcf_quran_plus/assets/fonts/${entry.value}',
          ),
        );
      await font.load();
    }

    for (final font in ['IBMPlexArabic', 'Amiri']) {
      final loader = FontLoader(font)
        ..addFont(
          rootBundle.load(
            font == 'Amiri'
                ? 'assets/fonts/Amiri-Regular.ttf'
                : 'assets/fonts/IBMPlexSansArabic-Regular.ttf',
          ),
        );
      await loader.load();
    }
  });
  setUp(() {
    app = AppController(MemoryStore(), entries);
  });
  tearDown(() {
    app.dispose();
  });
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('preview'),
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: RafeeqApp(controller: app),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, int index) async {
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('preview')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/previews')..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('home uses Arabic RTL and real empty data', (tester) async {
    await pump(tester);
    expect(find.text('السلام عليكم ورحمة الله'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
    expect(app.daily(false), 0);
    final adhkar = find.ancestor(
      of: find.text('الأذكار اليومية'),
      matching: find.byType(HomeFeatureTile),
    );
    final quran = find.ancestor(
      of: find.text('القرآن الكريم'),
      matching: find.byType(HomeFeatureTile),
    );
    expect(tester.getTopLeft(adhkar).dy, tester.getTopLeft(quran).dy);
    expect(
      tester.getTopLeft(adhkar).dx,
      greaterThan(tester.getTopLeft(quran).dx),
    );
    expect(find.text('آية اليوم وتأمل'), findsOneWidget);
    expect(find.text('إنجازك اليوم'), findsOneWidget);
    expect(find.text('٠/٢'), findsOneWidget);
    final excerpt = find.textContaining('﴿');
    expect(
      tester.widget<Text>(excerpt).data,
      contains(app.quran.verse(13, 28).split('أَلَا').last),
    );
    expect(tester.takeException(), isNull);
    await capture(tester, 'home-light');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('tablet pages keep a readable shared content width', (
    tester,
  ) async {
    await pump(tester, size: const Size(1024, 1000));
    for (final i in [0, 1, 2, 3, 4]) {
      await tab(tester, i);
      expect(tester.takeException(), isNull, reason: 'Tablet tab $i');
      await capture(tester, 'ui-tablet-$i');
    }
    await tab(tester, 0);
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ListView).first).width,
      lessThanOrEqualTo(720),
    );
    await capture(tester, 'ui-settings-tablet');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('counter stays usable at maximum app and system scaling', (
    tester,
  ) async {
    app.setTypography(scale: 1.35);
    app.toggleTheme();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, size: const Size(320, 740), scale: 2);
    await tab(tester, 3);
    await tester.scrollUntilVisible(
      find.byKey(const Key('counter-tap')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('counter-tap')));
    await tester.pumpAndSettle();
    expect(app.daily(false), 1);
    expect(tester.takeException(), isNull);
    await capture(tester, 'ui-counter-large-dark');
    await tester.scrollUntilVisible(
      find.text('الاهتزاز اللمسي'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'settings change interface font immediately and restore defaults',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('الأميري').last);
      await tester.pumpAndSettle();
      expect(app.fontFamily, 'Amiri');
      tester.widget<Slider>(find.byKey(const Key('app-font-scale'))).onChanged!(
        1.2,
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SettingsView));
      expect(MediaQuery.textScalerOf(context).scale(20), closeTo(24, .01));
      expect(Theme.of(context).textTheme.bodyMedium!.fontFamily, 'Amiri');
      await tester.scrollUntilVisible(find.text('استعادة الخط الافتراضي'), 250);
      await tester.tap(find.text('استعادة الخط الافتراضي'));
      await tester.pumpAndSettle();
      expect(app.fontScale, 1);
      expect(app.fontFamily, 'IBMPlexArabic');
      expect(tester.takeException(), isNull);
      await capture(tester, 'settings-fonts');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'notification settings request consent on enabling and cancel on disabling',
    (tester) async {
      app.dispose();
      final backend = FakeReminderBackend();
      app = AppController(MemoryStore(), entries, reminderBackend: backend);
      await pump(tester);
      await tester.tap(find.byTooltip('الإعدادات'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('إعدادات الإشعارات'), 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('إعدادات الإشعارات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إعدادات الإشعارات'));
      await tester.pumpAndSettle();
      expect(backend.prompts, 0);
      await tester.tap(find.text('تفعيل التذكيرات'));
      await tester.pumpAndSettle();
      expect(backend.prompts, 1);
      expect(app.reminders.scheduledCount, 4);
      await capture(tester, 'settings-notifications');
      await tester.tap(find.text('تفعيل التذكيرات'));
      await tester.pumpAndSettle();
      expect(app.reminders.scheduledCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('settings support combined system and app text enlargement', (
    tester,
  ) async {
    app.dispose();
    app = AppController(
      MemoryStore(),
      entries,
      reminderBackend: FakeReminderBackend(),
    );
    app.setTypography(scale: 1.35, dhikrSize: 44);
    app.toggleTheme();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, size: const Size(320, 740), scale: 2);
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('إعدادات الإشعارات'), 300);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إعدادات الإشعارات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات الإشعارات'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('إرسال إشعار تجريبي'), 300);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إرسال إشعار تجريبي'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'settings-notifications-large');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'cold notification payload opens its corresponding adhkar section',
    (tester) async {
      app.dispose();
      final backend = FakeReminderBackend();
      app = AppController(MemoryStore(), entries, reminderBackend: backend);
      await app.reminders.refresh();
      backend.onOpen!('evening');
      await pump(tester);
      expect(find.text('أذكار المساء'), findsOneWidget);
      expect(app.reminders.destination.value, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'loading explains real preparation and supports accessible themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dark in [false, true]) {
        final stage = dark ? MushafLoadingStage.font : MushafLoadingStage.page;
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('preview'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.create(dark),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(dark ? 2 : 1),
                  disableAnimations: true,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
              home: Scaffold(
                body: MushafLoadingView(surah: 'البقرة', page: 3, stage: stage),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('سورة البقرة • الصفحة ٣'), findsOneWidget);
        expect(find.text('القراءة متاحة دون إنترنت'), findsOneWidget);
        expect(
          find.text(
            dark
                ? 'جارٍ تجهيز الخط لعرض الآيات بوضوح'
                : 'جارٍ تجهيز بيانات صفحة المصحف',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capture(
          tester,
          dark ? 'mushaf-loading-dark-large' : 'mushaf-loading-light',
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('all categories navigate to real texts and count repetitions', (
    tester,
  ) async {
    await pump(tester);
    await tab(tester, 1);
    await capture(tester, 'ui-adhkar-list');
    expect(find.text('أذكار الصباح'), findsOneWidget);
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    final repeat = find.byKey(const Key('repeat-dhikr'));
    await tester.scrollUntilVisible(
      find.text('فضل الذكر'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(entries.first.virtue!), findsOneWidget);
    await capture(tester, 'adhkar-virtue');
    await tester.scrollUntilVisible(
      repeat,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(repeat);
    await tester.pumpAndSettle();
    expect(app.completed(entries.first), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'tasbih and salawat increments stay separate and reset keeps totals',
    (tester) async {
      await pump(tester);
      await tab(tester, 3);
      await tester.ensureVisible(find.byKey(const Key('counter-tap')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('counter-tap')));
      await tester.pumpAndSettle();
      expect(app.daily(false), 1);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await capture(tester, 'tasbih-light');
      await tab(tester, 4);
      await tester.ensureVisible(find.byKey(const Key('counter-tap')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('counter-tap')));
      await tester.pumpAndSettle();
      expect(app.daily(true), 1);
      expect(app.lifetime(false), 1);
      await tester.scrollUntilVisible(
        find.byTooltip('تصفير الجلسة'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('تصفير الجلسة'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تصفير الجلسة'));
      await tester.pumpAndSettle();
      expect(app.counter(true).session, 0);
      expect(app.daily(true), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Quran reader marks position and bookmarks', (tester) async {
    app.setQuranVertical(true);
    await pump(tester);
    await tab(tester, 2);
    await capture(tester, 'ui-quran-list');
    await tester.tap(find.text('سورة الفاتحة'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('حفظ موضع القراءة').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ موضع القراءة').first);
    await tester.pumpAndSettle();
    expect(app.lastReading!.id, '1:1');
    await tester.tap(find.byTooltip('حفظ علامة').first);
    await tester.pumpAndSettle();
    expect(app.bookmarks.single.id, '1:1');
    expect(tester.takeException(), isNull);
    await capture(tester, 'quran-reader');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('night theme uses exported dark surfaces', (tester) async {
    app.toggleTheme();
    await pump(tester);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    await capture(tester, 'home-dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'narrow screen and large Arabic text navigate without overflows',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, size: const Size(320, 740), scale: 2);
      for (var i = 0; i < 5; i++) {
        await tab(tester, i);
        expect(tester.takeException(), isNull, reason: 'Tab $i');
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'mushaf defaults to joined verses with page navigation and verse actions',
    (tester) async {
      await pump(tester);
      await tab(tester, 2);
      await tester.tap(find.text('سورة الفاتحة'));
      await tester.pumpAndSettle();
      expect(app.quranVertical, false);
      expect(find.byKey(const Key('mushaf-pages')), findsOneWidget);
      expect(find.text('الفاتحة • ١'), findsOneWidget);
      await capture(tester, 'mushaf-page-1');
      tester
          .widget<qcf.QuranPageView>(find.byType(qcf.QuranPageView))
          .onVerseTap!(1, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ موضع القراءة'));
      await tester.pumpAndSettle();
      expect(app.lastReading!.id, '1:1');
      tester
          .widget<qcf.QuranPageView>(find.byType(qcf.QuranPageView))
          .onVerseTap!(1, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ علامة'));
      await tester.pumpAndSettle();
      expect(app.bookmarks.single.id, '1:1');
      await tester.tap(find.byKey(const Key('reader-options')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'الصفحة التالية'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'الصفحة التالية'));
      await tester.pumpAndSettle();
      expect(find.text('البقرة • ٢'), findsOneWidget);
      expect(find.text('البقرة • ٢'), findsOneWidget);
      await capture(tester, 'mushaf-page-2');
      await tester.tap(find.byKey(const Key('reader-options')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<bool>, 'آيات عمودية'));
      await tester.pumpAndSettle();
      expect(app.quranVertical, true);
      expect(find.byKey(const Key('mushaf-pages')), findsNothing);
      await tester.tap(find.byTooltip('إغلاق الخيارات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reader-options')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(RadioListTile<bool>, 'صفحات المصحف'),
      );
      await tester.pumpAndSettle();
      expect(app.quranVertical, false);
      await tester.tap(find.byTooltip('إغلاق الخيارات'));
      await tester.pumpAndSettle();
      expect(find.text('البقرة • ٢'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('mushaf opens bookmarked last page and supports large text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, size: const Size(320, 740), scale: 2);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => QuranReaderView(
              controller: app,
              position: const ReadingPosition(114, 6),
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('الناس • ٦٠٤'), findsOneWidget);
    expect(find.byType(qcf.QuranPageView), findsOneWidget);
    await tester.tap(find.byKey(const Key('reader-options')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'الصفحة التالية'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'الصفحة التالية'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(ModalBarrier).last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('QCF standard page preserves all fifteen fixed lines', (
    tester,
  ) async {
    await pump(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => QuranReaderView(
              controller: app,
              position: const ReadingPosition(2, 6),
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('البقرة • ٣'), findsOneWidget);
    final page = tester
        .widgetList<qcf.QuranSinglePageWidget>(
          find.byType(qcf.QuranSinglePageWidget),
        )
        .firstWhere((p) => p.pageIndex == 3);
    expect(page.page.lines.length, 15);
    expect(find.byType(AppBar), findsNothing);
    expect(find.textContaining('استماع عبر الإنترنت'), findsNothing);
    expect(
      tester.getSize(find.byType(qcf.QuranPageView)).height,
      greaterThanOrEqualTo(780),
    );
    expect(tester.takeException(), isNull);
    await capture(tester, 'qcf-standard-page-3');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'unified reader options expose audio and reading settings at large text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, size: const Size(320, 740), scale: 2);
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => QuranReaderView(
                controller: app,
                position: const ReadingPosition(1, 1),
              ),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      await tester.tap(find.byKey(const Key('reader-options')));
      await tester.pumpAndSettle();
      expect(find.text('خيارات القارئ'), findsOneWidget);
      final list = find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('تكرار الآية'),
        250,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      expect(find.text('متابعة آيات السورة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'reader-options-large-text');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'compact audio error opens options without reducing reading height',
    (tester) async {
      final audio = QuranAudioController(
        createBackend: () async => throw StateError('no network'),
      );
      await audio.playVerse(const ReadingPosition(1, 1));
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderFooter(
              audio: audio,
              position: const ReadingPosition(1, 1),
              page: 1,
              onOptions: () => opened = true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(ReaderFooter)).height, 48);
      await tester.tap(find.byTooltip('تعذر تشغيل التلاوة'));
      await tester.pump();
      expect(opened, true);
      await tester.pumpWidget(const SizedBox());
      audio.dispose();
    },
  );
}

class _TestPaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.createTempSync('rafeeq-qcf-').path;
}
