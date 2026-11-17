import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_widgets.dart';

class HomeFeatureTile extends StatelessWidget {
  const HomeFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.compact = false,
    this.sand = false,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool compact, sand;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = sand && scheme.brightness == Brightness.light
        ? const Color(0xFFF2EDE2)
        : scheme.secondaryContainer;
    final color = sand && scheme.brightness == Brightness.light
        ? const Color(0xFF8C6D3B)
        : scheme.primary;
    final symbol = Container(
      padding: EdgeInsets.all(compact ? 10 : 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return AppSurfaceCard(
      radius: 16,
      padding: compact ? 12 : 16,
      onTap: onTap,
      child: compact
          ? Row(
              children: [
                symbol,
                const SizedBox(width: 10),
                Expanded(child: text),
              ],
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      symbol,
                      const SizedBox(width: 6),
                      if (badge != null)
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tint,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(fontSize: 10, color: color),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  text,
                ],
              ),
            ),
    );
  }
}
