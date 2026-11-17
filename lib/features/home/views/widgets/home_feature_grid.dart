import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../quran/services/qcf_mushaf_service.dart';
import 'home_feature_tile.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    super.key,
    required this.controller,
    required this.navigate,
    required this.resume,
  });
  final AppController controller;
  final ValueChanged<int> navigate;
  final VoidCallback resume;
  @override
  Widget build(BuildContext context) {
    final saved = controller.lastReading;
    final cards = [
      HomeFeatureTile(
        title: 'الأذكار اليومية',
        subtitle: 'حصن المسلم وأذكار الصباح والمساء',
        icon: Icons.wb_sunny_outlined,
        badge: '٦ أقسام',
        onTap: () => navigate(1),
      ),
      HomeFeatureTile(
        title: 'القرآن الكريم',
        subtitle: saved == null
            ? 'المصحف كاملًا دون اتصال'
            : 'متابعة سورة ${controller.quran.name(saved.surah)} • ص ${arabicNumber(QcfMushafService.pageFor(saved))}',
        icon: Icons.menu_book_outlined,
        sand: true,
        badge: saved == null ? '١١٤ سورة' : 'تابع قراءتك',
        onTap: saved == null ? () => navigate(2) : resume,
      ),
      HomeFeatureTile(
        title: 'المسبحة الذكية',
        subtitle: '${arabicNumber(controller.daily(false))} تسبيحة اليوم',
        icon: Icons.radio_button_checked,
        compact: true,
        onTap: () => navigate(3),
      ),
      HomeFeatureTile(
        title: 'الصلاة على النبي',
        subtitle: '${arabicNumber(controller.daily(true))} صلاة اليوم',
        icon: Icons.favorite_border,
        compact: true,
        onTap: () => navigate(4),
      ),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'المعالم الروحانية',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'الوصول السريع',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.4) {
              return Column(
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ),
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[i]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[i + 1]),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
