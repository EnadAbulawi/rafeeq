import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/quran_audio_controller.dart';
import '../../repositories/quran_repository.dart';
import '../../services/qcf_mushaf_service.dart';
import 'quran_audio_controls.dart';

class ReaderOptionsSheet extends StatefulWidget {
  const ReaderOptionsSheet({
    super.key,
    required this.controller,
    required this.audio,
    required this.position,
    required this.onMove,
  });
  final AppController controller;
  final QuranAudioController audio;
  final ReadingPosition position;
  final ValueChanged<ReadingPosition> onMove;
  @override
  State<ReaderOptionsSheet> createState() => _ReaderOptionsSheetState();
}

class _ReaderOptionsSheetState extends State<ReaderOptionsSheet> {
  late int surah = widget.position.surah;
  late int verse = widget.position.verse;
  void navigate(ReadingPosition p) {
    Navigator.pop(context);
    widget.onMove(p);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .78,
    minChildSize: .4,
    maxChildSize: .95,
    builder: (context, scroll) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final page = QcfMushafService.pageFor(widget.position);
        return ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
            AppLayout.gutter(context),
            0,
            AppLayout.gutter(context),
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          children: [
            PageHeading(
              'خيارات القارئ',
              'سورة ${controller.quran.name(widget.position.surah)} • صفحة ${arabicNumber(page)}',
              action: IconButton(
                tooltip: 'إغلاق الخيارات',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            const SectionHeading('طريقة القراءة'),
            RadioGroup<bool>(
              groupValue: controller.quranVertical,
              onChanged: (value) {
                if (value != null) controller.setQuranVertical(value);
              },
              child: const Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    title: Text('صفحات المصحف'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    value: true,
                    title: Text('آيات عمودية'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الوضع الليلي'),
              value: controller.dark,
              onChanged: (_) => controller.toggleTheme(),
            ),
            const Divider(height: 32),
            const SectionHeading('الانتقال'),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: page == 1
                      ? null
                      : () => navigate(QcfMushafService.pageStart(page - 1)),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('الصفحة السابقة'),
                ),
                OutlinedButton.icon(
                  onPressed: page == 604
                      ? null
                      : () => navigate(QcfMushafService.pageStart(page + 1)),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('الصفحة التالية'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey('reader-surah-$surah'),
              initialValue: surah,
              isExpanded: true,
              menuMaxHeight: 300,
              decoration: const InputDecoration(labelText: 'السورة'),
              items: [
                for (var s = 1; s <= 114; s++)
                  DropdownMenuItem(
                    value: s,
                    child: Text(
                      '${arabicNumber(s)} • ${controller.quran.name(s)}',
                    ),
                  ),
              ],
              onChanged: (s) {
                if (s != null) {
                  setState(() {
                    surah = s;
                    verse = 1;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('reader-verse-$surah-$verse'),
              initialValue: verse,
              isExpanded: true,
              menuMaxHeight: 300,
              decoration: const InputDecoration(labelText: 'الآية'),
              items: [
                for (var v = 1; v <= controller.quran.count(surah); v++)
                  DropdownMenuItem(
                    value: v,
                    child: Text('الآية ${arabicNumber(v)}'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => verse = v);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => navigate(ReadingPosition(surah, verse)),
              child: const Text('انتقال'),
            ),
            const Divider(height: 32),
            const SectionHeading('التلاوة'),
            const Text('الاستماع عبر الإنترنت', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            QuranAudioControls(audio: widget.audio, position: widget.position),
          ],
        );
      },
    ),
  );
}
