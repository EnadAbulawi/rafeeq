import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_widgets.dart';
import '../../controllers/quran_audio_controller.dart';
import '../../repositories/quran_repository.dart';

class ReaderFooter extends StatelessWidget {
  const ReaderFooter({
    super.key,
    required this.audio,
    required this.position,
    required this.page,
    required this.onOptions,
  });
  final QuranAudioController audio;
  final ReadingPosition position;
  final int page;
  final VoidCallback onOptions;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: audio,
    builder: (context, _) => SizedBox(
      height: 48,
      child: Row(
        children: [
          const BackButton(),
          Expanded(
            child: Text(
              '${QuranRepository().name(position.surah)} • ${arabicNumber(page)}',
              key: const Key('reader-location'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel:
                  'سورة ${QuranRepository().name(position.surah)}، صفحة ${arabicNumber(page)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (audio.current != null || audio.busy)
            IconButton(
              key: const Key('reader-quick-audio'),
              tooltip: audio.error != null
                  ? 'تعذر تشغيل التلاوة'
                  : audio.busy
                  ? 'جارٍ تحميل التلاوة'
                  : audio.playing
                  ? 'إيقاف مؤقت'
                  : 'متابعة التلاوة',
              onPressed: audio.busy
                  ? null
                  : audio.error != null
                  ? onOptions
                  : () => audio.toggle(position),
              icon: Icon(
                audio.error != null
                    ? Icons.error_outline
                    : audio.busy
                    ? Icons.hourglass_empty
                    : audio.playing
                    ? Icons.pause
                    : Icons.play_arrow,
                color: audio.error != null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          IconButton(
            key: const Key('reader-options'),
            tooltip: 'خيارات القارئ',
            onPressed: onOptions,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    ),
  );
}
