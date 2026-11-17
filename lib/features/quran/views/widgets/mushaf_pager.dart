import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../app/controllers/app_controller.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../repositories/quran_repository.dart';
import '../../services/qcf_mushaf_service.dart';
import 'mushaf_loading_view.dart';

class MushafPager extends StatefulWidget {
  const MushafPager({
    super.key,
    required this.controller,
    required this.position,
    required this.onPositionChanged,
    required this.onVerseTap,
    this.preparePage,
  });
  final AppController controller;
  final Future<void> Function(int)? preparePage;
  final ReadingPosition position;
  final ValueChanged<ReadingPosition> onPositionChanged, onVerseTap;
  @override
  State<MushafPager> createState() => _MushafPagerState();
}

class _MushafPagerState extends State<MushafPager> {
  late final PageController pages;
  late int current;
  late Future<void> preparing;
  final loadingStage = ValueNotifier(MushafLoadingStage.page);
  int request = 0;
  Future<void> _prepare(int page) {
    final active = ++request;
    loadingStage.value = MushafLoadingStage.page;
    final custom = widget.preparePage;
    return (custom != null
            ? custom(page)
            : QcfMushafService.preparePage(
                page,
                onStage: (stage) {
                  if (mounted && active == request) loadingStage.value = stage;
                },
              ))
        .timeout(const Duration(seconds: 30));
  }

  @override
  void initState() {
    super.initState();
    current = QcfMushafService.pageFor(widget.position);
    pages = PageController(initialPage: current - 1);
    preparing = _prepare(current);
  }

  @override
  void didUpdateWidget(covariant MushafPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = QcfMushafService.pageFor(widget.position);
    if (target != current) {
      current = target;
      preparing = _prepare(current);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pages.hasClients) pages.jumpToPage(current - 1);
      });
    }
  }

  @override
  void dispose() {
    request++;
    loadingStage.dispose();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: preparing,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AppMessage(
          'تعذر تجهيز صفحة المصحف. أعد المحاولة أو اختر العرض العمودي من خيارات القارئ.',
          retry: () => setState(() {
            preparing = _prepare(current);
          }),
        );
      }
      final ready = snapshot.connectionState == ConnectionState.done;
      // Retain the page controller while preparing the next page's QCF font.
      // Opaque cover prevents private-use glyphs from appearing before loading.
      return Stack(
        children: [
          if (ready || QcfMushafService.isPagePrepared(pages.initialPage + 1))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1,
                maxScaleFactor: 1,
                child: qcf.QuranPageView(
                  key: const Key('mushaf-pages'),
                  pageController: pages,
                  highlights: [
                    for (final bookmark in widget.controller.bookmarks)
                      qcf.HighlightVerse(
                        surah: bookmark.surah,
                        verseNumber: bookmark.verse,
                        page: QcfMushafService.pageFor(bookmark),
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .18),
                      ),
                  ],
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  isTajweed: false,
                  enableTwoPageLayout: false,
                  pageBackgroundColor: Theme.of(context)
                      .scaffoldBackgroundColor,
                  onPageChanged: (page) {
                    if (page == current) return;
                    current = page;
                    setState(() {
                      preparing = _prepare(page);
                    });
                    widget.onPositionChanged(QcfMushafService.pageStart(page));
                  },
                  onVerseTap: (s, v) =>
                      widget.onVerseTap(ReadingPosition(s, v)),
                  onLongPress: (s, v, _) =>
                      widget.onVerseTap(ReadingPosition(s, v)),
                ),
              ),
            ),
          if (!ready)
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: loadingStage,
                builder: (context, stage, _) => MushafLoadingView(
                  surah: widget.controller.quran.name(
                    QcfMushafService.pageStart(current).surah,
                  ),
                  page: current,
                  stage: stage,
                ),
              ),
            ),
        ],
      );
    },
  );
}
