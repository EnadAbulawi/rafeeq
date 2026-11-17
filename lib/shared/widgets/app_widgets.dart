import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

String arabicNumber(Object value) => value.toString().replaceAllMapped(
  RegExp('[0-9]'),
  (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)],
);

class AppPageScroll extends StatelessWidget {
  const AppPageScroll({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.maxWidth),
      child: ListView(
        padding: AppLayout.pagePadding(context),
        children: children,
      ),
    ),
  );
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, this.icon, this.label, this.size = 44});
  final IconData? icon;
  final String? label;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: label == null
        ? Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary)
        : Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
  );
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.medium,
    this.radius = AppRadius.card,
    this.color,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double padding;
  final double radius;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class AppMessage extends StatelessWidget {
  const AppMessage(this.message, {super.key, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu_book_outlined, size: 40),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('إعادة المحاولة')),
      ],
    ),
  );
}

Future<bool> confirmReset(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بدء جلسة جديدة؟'),
        content: const Text(
          'سيُصفّر عداد الجلسة فقط، مع الاحتفاظ بمجموع اليوم والإجمالي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تصفير الجلسة'),
          ),
        ],
      ),
    ) ??
    false;
