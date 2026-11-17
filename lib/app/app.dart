import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/storage/local_store.dart';
import '../core/theme/app_theme.dart';
import '../features/adhkar/models/dhikr.dart';
import '../features/adhkar/views/adhkar_view.dart';
import '../features/counters/views/counter_view.dart';
import '../features/home/views/home_view.dart';
import '../features/quran/views/quran_view.dart';
import '../features/quran/repositories/quran_repository.dart';
import '../shared/widgets/app_widgets.dart';
import '../features/adhkar/views/adhkar_reader_view.dart';
import '../features/quran/views/quran_reader_view.dart';
import '../features/settings/views/settings_view.dart';
import 'controllers/app_controller.dart';

class RafeeqBootstrap extends StatefulWidget {
  const RafeeqBootstrap({super.key});
  @override
  State<RafeeqBootstrap> createState() => _RafeeqBootstrapState();
}

class _RafeeqBootstrapState extends State<RafeeqBootstrap> {
  late Future<AppController> loading = _load();
  Future<AppController> _load() async {
    await QuranRepository.load();
    final data = await AdhkarRepository.load();
    final store = await SqliteStore.open();
    final controller = AppController(store, data);
    try {
      await controller.load();
      unawaited(controller.reminders.refresh());
      return controller;
    } catch (e, stack) {
      controller.dispose();
      await store.close();
      debugPrint('Startup failed: $e\n$stack');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppController>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return RafeeqApp(controller: snapshot.data!);
      return MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.create(false),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: snapshot.hasError
                  ? AppMessage(
                      'تعذر فتح البيانات المحلية. لن تُحذف بياناتك. أعد المحاولة.',
                      retry: () => setState(() => loading = _load()),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('رَفِيق', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 24),
                          LinearProgressIndicator(),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  );
}

class RafeeqApp extends StatefulWidget {
  const RafeeqApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<RafeeqApp> createState() => _RafeeqAppState();
}

class _RafeeqAppState extends State<RafeeqApp> with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  late String typography;
  String get _typography =>
      '${widget.controller.fontScale}:${widget.controller.fontFamily}';
  late bool dark = widget.controller.dark;
  String? saveError;
  Timer? dayTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    typography = _typography;
    widget.controller.addListener(_preferencesChanged);
    widget.controller.reminders.destination.addListener(_openReminder);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openReminder());
    dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => widget.controller.refreshDate(),
    );
  }

  void _preferencesChanged() {
    if (dark != widget.controller.dark ||
        typography != _typography ||
        saveError != widget.controller.saveError) {
      setState(() {
        dark = widget.controller.dark;
        typography = _typography;
        saveError = widget.controller.saveError;
      });
    }
  }

  void _openReminder() {
    if (!mounted) return;
    final target = widget.controller.reminders.destination.value;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          navigator.currentState == null ||
          widget.controller.reminders.destination.value != target) {
        return;
      }
      widget.controller.reminders.destination.value = null;
      final page = switch (target) {
        'morning' || 'evening' => AdhkarReaderView(
          controller: widget.controller,
          category: target,
        ),
        'reading' => QuranReaderView(
          controller: widget.controller,
          position:
              widget.controller.lastReading ?? const ReadingPosition(1, 1),
        ),
        'salawat' => CounterView(controller: widget.controller, salawat: true),
        _ => NotificationSettingsView(controller: widget.controller),
      };
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshDate();
      unawaited(widget.controller.reminders.refresh());
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(widget.controller.flush());
    }
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_preferencesChanged);
    widget.controller.reminders.destination.removeListener(_openReminder);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    title: 'رفيق',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.create(false, fontFamily: widget.controller.fontFamily),
    darkTheme: AppTheme.create(true, fontFamily: widget.controller.fontFamily),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: _AppTextScaler(
          MediaQuery.textScalerOf(context),
          widget.controller.fontScale,
        ),
      ),
      child: Column(
        children: [
          if (saveError != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(saveError!)),
                      TextButton(
                        onPressed: widget.controller.flush,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child!),
        ],
      ),
    ),
    home: _AppShell(controller: widget.controller),
  );
}

class _AppTextScaler extends TextScaler {
  const _AppTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;
  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.controller});
  final AppController controller;
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int tab = 0;
  void navigate(int value) => setState(() => tab = value);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => switch (tab) {
              1 => AdhkarView(controller: widget.controller),
              2 => QuranView(controller: widget.controller),
              3 => CounterView(controller: widget.controller),
              4 => CounterView(controller: widget.controller, salawat: true),
              _ => HomeView(controller: widget.controller, navigate: navigate),
            },
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: navigate,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          label: 'الأذكار',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'المصحف',
        ),
        NavigationDestination(
          icon: Icon(Icons.radio_button_checked),
          label: 'المسبحة',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          label: 'الصلاة على النبي',
        ),
      ],
    ),
  );
}
