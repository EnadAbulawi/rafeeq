import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/quran_audio_controller.dart';
import 'widgets/reader_footer.dart';
import 'widgets/reader_options_sheet.dart';
import '../services/qcf_mushaf_service.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../repositories/quran_repository.dart';
import 'widgets/mushaf_pager.dart';
import 'widgets/quran_verse_list.dart';
import 'widgets/verse_actions.dart';

class QuranReaderView extends StatefulWidget {
  const QuranReaderView({
    super.key,
    required this.controller,
    required this.position,
  });
  final AppController controller;
  final ReadingPosition position;
  @override
  State<QuranReaderView> createState() => _QuranReaderViewState();
}

class _QuranReaderViewState extends State<QuranReaderView>
    with WidgetsBindingObserver {
  late ReadingPosition start;
  final audio = QuranAudioController();
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    start = widget.position;
  }

  void move(ReadingPosition p) {
    setState(() => start = p);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    audio.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) unawaited(audio.pause());
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (!start.valid) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppMessage('تعذر فتح هذا الموضع.'),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: controller.quranVertical
                          ? QuranVerseList(
                              controller: controller,
                              start: start,
                              scroll: scroll,
                              onMove: move,
                              onListen: audio.playVerse,
                            )
                          : MushafPager(
                              controller: controller,
                              position: start,
                              onPositionChanged: (p) =>
                                  setState(() => start = p),
                              onVerseTap: (p) {
                                setState(() => start = p);
                                showVerseActions(
                                  context,
                                  controller,
                                  p,
                                  audio: audio,
                                );
                              },
                            ),
                    ),
                  ),
                ),
                ReaderFooter(
                  audio: audio,
                  position: start,
                  page: QcfMushafService.pageFor(start),
                  onOptions: _openOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openOptions() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReaderOptionsSheet(
      controller: widget.controller,
      audio: audio,
      position: start,
      onMove: move,
    ),
  );
}
