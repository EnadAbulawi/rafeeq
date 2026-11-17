import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../quran/services/qcf_mushaf_service.dart';

class HomeDailyProgress extends StatelessWidget {
  const HomeDailyProgress({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final done = [
      'morning',
      'evening',
    ].where((c) => controller.categoryProgress(c) == 1).length;
    final reading = controller.lastReading;
    final stats = [
      _DailyStat(arabicNumber('$done/2'), 'الأذكار اليومية'),
      _DailyStat(
        reading == null ? '—' : arabicNumber(QcfMushafService.pageFor(reading)),
        'آخر صفحة',
      ),
      _DailyStat(arabicNumber(controller.daily(false)), 'مجموع التسبيحات'),
    ];
    return AppSurfaceCard(
      radius: 16,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'إنجازك اليوم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: Text(
                  arabicNumber(
                    MaterialLocalizations.of(context)
                        .formatShortMonthDay(controller.clock()),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (MediaQuery.textScalerOf(context).scale(1) > 1.4)
            Column(
              children: [
                for (final stat in stats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: stat,
                  ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: stats[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  const _DailyStat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
