import 'package:flutter/material.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/dhikr.dart';
import 'adhkar_reader_view.dart';

class AdhkarView extends StatelessWidget {
  const AdhkarView({super.key, required this.controller});
  final AppController controller;
  static const icons = [
    Icons.wb_sunny_outlined,
    Icons.dark_mode_outlined,
    Icons.bedtime_outlined,
    Icons.light_mode_outlined,
    Icons.mosque_outlined,
    Icons.auto_awesome_outlined,
  ];
  @override
  Widget build(BuildContext context) => ListView(
    padding: AppLayout.pagePadding(context),
    children: [
      const PageHeading('الأذكار النبوية', 'ذكر وطمأنينة في اليوم والليلة'),
      ...adhkarCategories.entries.indexed.map((item) {
        final category = item.$2;
        final entries = controller.entries(category.key);
        final progress = controller.categoryProgress(category.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppSurfaceCard(
            onTap: entries.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AdhkarReaderView(
                        controller: controller,
                        category: category.key,
                      ),
                    ),
                  ),
            child: Row(
              children: [
                AppIconBadge(icon: icons[item.$1]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${arabicNumber(entries.length)} ذكرًا • ${progress == 1 ? 'مكتمل' : 'ابدأ الآن'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      if (progress > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(value: progress),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
        );
      }),
      Text(
        'يُحفظ التقدم لكل يوم بحسب تاريخ الجهاز. النصوص والمراجع كما وردت في المصدر؛ لا تعني نسبة الإنجاز حكمًا على العبادة.',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
