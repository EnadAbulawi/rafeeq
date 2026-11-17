import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/dhikr.dart';

class AdhkarReaderView extends StatefulWidget {
  const AdhkarReaderView({
    super.key,
    required this.controller,
    required this.category,
  });
  final AppController controller;
  final String category;
  @override
  State<AdhkarReaderView> createState() => _AdhkarReaderViewState();
}

class _AdhkarReaderViewState extends State<AdhkarReaderView> {
  int index = 0;
  @override
  void initState() {
    super.initState();
    final entries = widget.controller.entries(widget.category);
    final first = entries.indexWhere(
      (e) => widget.controller.completed(e) < e.count,
    );
    index = first < 0 ? 0 : first;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entries = controller.entries(widget.category);
    return Scaffold(
      appBar: AppBar(
        title: Text(adhkarCategories[widget.category] ?? 'الأذكار'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (entries.isEmpty) {
            return const AppMessage('لا توجد نصوص متاحة في هذا القسم.');
          }
          final entry = entries[index];
          final completed = controller.completed(entry);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: AppLayout.pagePadding(context),
                children: [
                  Text(
                    'الذكر ${arabicNumber(index + 1)} من ${arabicNumber(entries.length)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: controller.categoryProgress(widget.category),
                  ),
                  const SizedBox(height: 24),
                  AppSurfaceCard(
                    padding: 24,
                    child: Column(
                      children: [
                        SelectableText(
                          entry.text,
                          style: AppTypography.sacred.copyWith(
                            fontSize: controller.adhkarFontSize,
                            fontFamily: controller.adhkarFontFamily,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 32),
                        Text(
                          'المصدر: ${entry.reference}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          entry.source,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (entry.virtue?.isNotEmpty == true) ...[
                    AppSurfaceCard(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'فضل الذكر',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            entry.virtue!,
                            style: const TextStyle(height: 1.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'كما ورد في المصدر: ${entry.source}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  FilledButton.icon(
                    key: const Key('repeat-dhikr'),
                    onPressed: completed >= entry.count
                        ? null
                        : () {
                            controller.repeatDhikr(entry);
                            if (controller.haptic) {
                              HapticFeedback.selectionClick();
                            }
                          },
                    icon: Icon(
                      completed >= entry.count
                          ? Icons.check
                          : Icons.touch_app_outlined,
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        completed >= entry.count
                            ? 'اكتمل الذكر'
                            : 'اضغط للتكرار • ${arabicNumber(completed)} / ${arabicNumber(entry.count)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: index == 0
                            ? null
                            : () => setState(() => index--),
                        child: const Text('السابق'),
                      ),
                      FilledButton.tonal(
                        onPressed: index == entries.length - 1
                            ? null
                            : () => setState(() => index++),
                        child: const Text('التالي'),
                      ),
                    ],
                  ),
                  if (controller.categoryProgress(widget.category) == 1)
                    const AppMessage('أتممت أذكار هذا القسم اليوم.'),
                  TextButton(
                    onPressed: () async {
                      final reset = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('إعادة أذكار القسم؟'),
                          content: const Text(
                            'سيُصفّر تقدم هذا القسم لليوم فقط.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('إعادة البدء'),
                            ),
                          ],
                        ),
                      );
                      if (reset == true) {
                        controller.resetCategory(widget.category);
                        setState(() => index = 0);
                      }
                    },
                    child: const Text('إعادة بدء القسم'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
