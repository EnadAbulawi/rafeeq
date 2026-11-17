import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'widgets/counter_ring.dart';

class CounterView extends StatelessWidget {
  const CounterView({
    super.key,
    required this.controller,
    this.salawat = false,
  });
  final AppController controller;
  final bool salawat;
  @override
  Widget build(BuildContext context) {
    final counter = controller.counter(salawat);
    final target = controller.selectedPhrase == 2
        ? 34
        : controller.selectedPhrase < 3
        ? 33
        : 100;
    return ListView(
      padding: AppLayout.pagePadding(context),
      children: [
        PageHeading(
          salawat ? 'الصلاة على النبي ﷺ' : 'المسبحة الإلكترونية',
          salawat ? 'وقت للذكر والصلاة والسلام' : 'تسبيح هادئ مع حفظ جلساتك',
          action: IconButton(
            tooltip: 'تصفير الجلسة',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              if (await confirmReset(context)) controller.resetSession(salawat);
            },
          ),
        ),
        if (!salawat)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tasbihPhrases.length; i++)
                ChoiceChip(
                  label: Text(tasbihPhrases[i]),
                  selected: i == controller.selectedPhrase,
                  onSelected: (_) => controller.selectPhrase(i),
                ),
            ],
          ),
        if (salawat)
          const AppSurfaceCard(
            child: Text(
              'اللهم صلِّ وسلم على نبينا محمد',
              textAlign: TextAlign.center,
              style: AppTypography.sacred,
            ),
          ),
        const SizedBox(height: 24),
        CounterRing(
          count: salawat ? controller.daily(true) : counter.session,
          label: salawat
              ? 'صلوات اليوم'
              : tasbihPhrases[controller.selectedPhrase],
          progress: salawat
              ? controller.goalProgress
              : (counter.session == 0
                    ? 0
                    : ((counter.session - 1) % target + 1) / target),
          onTap: () {
            controller.increment(salawat);
            if (controller.haptic) HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 24),
        Text(
          salawat ? 'صلوات اليوم' : tasbihPhrases[controller.selectedPhrase],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (!salawat)
          Text(
            'هدف الجولة: ${arabicNumber(target)}',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 24),
        AppSurfaceCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                ('الجلسة الحالية', counter.session),
                ('مجموع اليوم', controller.daily(salawat)),
                ('المجموع التراكمي', controller.lifetime(salawat)),
              ];
              if (constraints.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21) {
                return Column(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const Divider(),
                      _StatRow(stats[i].$1, stats[i].$2),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              arabicNumber(stats[i].$2),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stats[i].$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (salawat) ...[
          const SizedBox(height: 16),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.salawatGoal == 0
                      ? 'الهدف اليومي غير مفعّل'
                      : 'الهدف اليومي: ${arabicNumber(controller.salawatGoal)} • ${arabicNumber((controller.goalProgress * 100).round())}٪',
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: controller.goalProgress),
                TextButton(
                  onPressed: () => _editGoal(context),
                  child: const Text('تعديل الهدف'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppSurfaceCard(
          padding: 4,
          child: SwitchListTile(
            title: const Text('الاهتزاز اللمسي'),
            value: controller.haptic,
            onChanged: controller.setHaptic,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'تصفير الجلسة لا يمسح مجموع اليوم أو الإجمالي. يُحسب اليوم بحسب تاريخ جهازك.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _editGoal(BuildContext context) async {
    final input = TextEditingController(
      text: controller.salawatGoal.toString(),
    );
    final form = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هدفك اليومي'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: input,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'عدد الصلوات',
              helperText: 'صفر لتعطيل الهدف',
            ),
            validator: (value) {
              final n = int.tryParse(_westernDigits(value ?? ''));
              return n == null || n < 0 || n > 100000
                  ? 'أدخل عددًا من صفر إلى ١٠٠٠٠٠'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(_westernDigits(input.text)));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    // Dialog route finishes its exit animation before text resources are released.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (result != null) controller.setGoal(result);
  }

  String _westernDigits(String value) => value.replaceAllMapped(
    RegExp('[٠-٩]'),
    (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString(),
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          arabicNumber(value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ],
  );
}
