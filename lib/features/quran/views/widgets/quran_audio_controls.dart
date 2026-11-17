import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_widgets.dart';
import '../../controllers/quran_audio_controller.dart';
import '../../repositories/quran_repository.dart';

class QuranAudioControls extends StatelessWidget {
  const QuranAudioControls({
    super.key,
    required this.audio,
    required this.position,
  });
  final QuranAudioController audio;
  final ReadingPosition position;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: audio,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('reciter-${audio.reciterIndex}'),
          initialValue: audio.reciterIndex,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'القارئ'),
          onChanged: (i) {
            if (i != null) audio.selectReciter(i);
          },
          items: [
            for (var i = 0; i < quranReciters.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  quranReciters[i].name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('recitation-toggle'),
              onPressed: audio.busy ? null : () => audio.toggle(position),
              icon: Icon(audio.playing ? Icons.pause : Icons.play_arrow),
              label: Text(audio.playing ? 'إيقاف مؤقت' : 'تشغيل التلاوة'),
            ),
            OutlinedButton.icon(
              onPressed: audio.current == null && !audio.busy
                  ? null
                  : audio.stop,
              icon: const Icon(Icons.stop),
              label: const Text('إيقاف التلاوة'),
            ),
          ],
        ),
        if (audio.busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        if (audio.current case final ReadingPosition p)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${QuranRepository().name(p.surah)} • الآية ${arabicNumber(p.verse)}',
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('تكرار الآية'),
          value: audio.repeat,
          onChanged: audio.setRepeat,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('متابعة آيات السورة'),
          value: audio.continueRecitation,
          onChanged: audio.setContinue,
        ),
        if (audio.error != null) ...[
          Text(
            audio.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: () => audio.playVerse(audio.current ?? position),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ],
    ),
  );
}
