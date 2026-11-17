import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../repositories/quran_repository.dart';

class QuranVerseList extends StatelessWidget {
  const QuranVerseList({
    super.key,
    required this.controller,
    required this.start,
    required this.scroll,
    required this.onMove,
    required this.onListen,
  });
  final AppController controller;
  final ReadingPosition start;
  final ScrollController scroll;
  final ValueChanged<ReadingPosition> onMove;
  final ValueChanged<ReadingPosition> onListen;
  @override
  Widget build(BuildContext context) {
    final repository = controller.quran;
    final verseCount = repository.count(start.surah);
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(20),
      itemCount: verseCount - start.verse + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              Text(
                '${arabicNumber(verseCount)} آية',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const Text('اضغط «حفظ موضع القراءة» عند الآية التي تصل إليها.'),
              if (start.verse > 1)
                TextButton(
                  onPressed: () => onMove(ReadingPosition(start.surah, 1)),
                  child: const Text('القراءة من بداية السورة'),
                ),
              if (start.verse == 1 && start.surah != 1 && start.surah != 9)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    repository.basmalaFor(start.surah)!,
                    style: AppTypography.sacred,
                    textAlign: TextAlign.center,
                  ),
                ),
              const Divider(height: 24),
            ],
          );
        }
        if (index == verseCount - start.verse + 2) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (start.surah > 1)
                  OutlinedButton(
                    onPressed: () =>
                        onMove(ReadingPosition(start.surah - 1, 1)),
                    child: const Text('السورة السابقة'),
                  ),
                if (start.surah < 114)
                  FilledButton.tonal(
                    onPressed: () =>
                        onMove(ReadingPosition(start.surah + 1, 1)),
                    child: const Text('السورة التالية'),
                  ),
              ],
            ),
          );
        }
        final number = start.verse + index - 1;
        final position = ReadingPosition(start.surah, number);
        final isLast = controller.lastReading?.id == position.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppSurfaceCard(
            padding: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  '${repository.verse(start.surah, number)} ﴿${arabicNumber(number)}﴾',
                  textAlign: TextAlign.right,
                  style: AppTypography.sacred,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => controller.markReading(position),
                      icon: Icon(
                        isLast
                            ? Icons.check_circle_outline
                            : Icons.auto_stories_outlined,
                        size: 18,
                      ),
                      label: Text(
                        isLast ? 'موضع القراءة المحفوظ' : 'حفظ موضع القراءة',
                      ),
                    ),
                    IconButton(
                      tooltip: 'استماع للآية',
                      icon: const Icon(Icons.volume_up_outlined),
                      onPressed: () => onListen(position),
                    ),
                    IconButton(
                      tooltip: controller.bookmarked(position)
                          ? 'إزالة العلامة'
                          : 'حفظ علامة',
                      onPressed: () => controller.toggleBookmark(position),
                      icon: Icon(
                        controller.bookmarked(position)
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
