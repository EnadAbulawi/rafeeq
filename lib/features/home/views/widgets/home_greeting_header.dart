import 'package:flutter/material.dart';

import '../../../../app/controllers/app_controller.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../settings/views/settings_view.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      arabicNumber(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(controller.clock()),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _HeaderAction(
                    tooltip: 'تبديل المظهر',
                    icon: controller.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    onTap: controller.toggleTheme,
                  ),
                  const SizedBox(width: 8),
                  _settings(context),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'السلام عليكم ورحمة الله',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'رفيقك اليومي للذكر والقرآن والتأمل',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabicNumber(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(controller.clock()),
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'السلام عليكم ورحمة الله',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'رفيقك اليومي للذكر والقرآن والتأمل',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _HeaderAction(
              tooltip: 'تبديل المظهر',
              icon: controller.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              onTap: controller.toggleTheme,
            ),
            _HeaderAction(
              tooltip: 'الإعدادات',
              icon: Icons.settings_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SettingsView(controller: controller),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _settings(BuildContext context) => _HeaderAction(
    tooltip: 'الإعدادات',
    icon: Icons.settings_outlined,
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SettingsView(controller: controller),
      ),
    ),
  );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    iconSize: 20,
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: Icon(icon),
  );
}
