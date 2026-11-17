import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../repositories/quran_repository.dart';
import 'qcf_page_fonts.dart';

import 'package:flutter/foundation.dart';

// Version 0.1.1 does not export lazy data initialization. Keep this pinned
// compatibility call isolated; the public startup helper loads all 604 fonts.
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/widgets/quran_page/quran_repository.dart'
    as qcf_data;

enum MushafLoadingStage { page, font }

abstract final class QcfMushafService {
  static int pageFor(ReadingPosition position) =>
      getPageNumber(position.surah, position.verse);
  static ReadingPosition pageStart(int page) {
    final first = getPageData(page).first as Map;
    return ReadingPosition(first['surah'] as int, first['start'] as int);
  }

  static bool isPagePrepared(int page) =>
      qcf_data.QuranRepository.instance.isReady && QcfPageFonts.isReady(page);
  static Future<void> preparePage(
    int page, {
    ValueChanged<MushafLoadingStage>? onStage,
  }) async {
    final timer = Stopwatch()..start();
    onStage?.call(
      qcf_data.QuranRepository.instance.isReady
          ? MushafLoadingStage.font
          : MushafLoadingStage.page,
    );
    try {
      await Future.wait([
        qcf_data.QuranRepository.instance.ensureLoaded(604).then((_) {
          if (!QcfPageFonts.isReady(page)) {
            onStage?.call(MushafLoadingStage.font);
          }
        }),
        QcfPageFonts.load(page),
      ]).timeout(const Duration(seconds: 30));
      debugPrint('QCF page $page ready in ${timer.elapsedMilliseconds}ms');
    } catch (error, stack) {
      // The pinned repository retains failed initialization futures. Clear an
      // incomplete initialization so the reader's retry can start fresh.
      if (!qcf_data.QuranRepository.instance.isReady) {
        // ignore: invalid_use_of_visible_for_testing_member
        qcf_data.QuranRepository.instance.debugReset();
      }
      debugPrint('QCF page $page preparation failed: $error\n$stack');
      rethrow;
    }
  }
}
