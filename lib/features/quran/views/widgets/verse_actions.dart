import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../repositories/quran_repository.dart';
import '../../controllers/quran_audio_controller.dart';

Future<void> showVerseActions(
  BuildContext context,
  AppController controller,
  ReadingPosition position, {
  QuranAudioController? audio,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * .8,
  ),
  builder: (context) => SafeArea(
    top: false,
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        Text(
          'سورة ${controller.quran.name(position.surah)} • الآية ${arabicNumber(position.verse)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (audio != null)
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  audio.playVerse(position);
                },
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('استماع للآية'),
              ),
            FilledButton.icon(
              onPressed: () {
                controller.markReading(position);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('حفظ موضع القراءة'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                controller.toggleBookmark(position);
                Navigator.pop(context);
              },
              icon: Icon(
                controller.bookmarked(position)
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
              ),
              label: Text(
                controller.bookmarked(position) ? 'إزالة العلامة' : 'حفظ علامة',
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        SelectableText(
          controller.quran.verse(position.surah, position.verse),
          style: AppTypography.sacred,
        ),
      ],
    ),
  ),
);
