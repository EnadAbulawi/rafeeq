import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_widgets.dart';

class CounterRing extends StatelessWidget {
  const CounterRing({
    super.key,
    required this.count,
    required this.progress,
    required this.onTap,
    required this.label,
  });
  final int count;
  final double progress;
  final VoidCallback onTap;
  final String label;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = math.min(248.0, constraints.maxWidth);
      return Center(
        child: Semantics(
          button: true,
          label: '$label، ${arabicNumber(count)}، اضغط للزيادة',
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const Key('counter-tap'),
                      onTap: onTap,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: size - 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      arabicNumber(count),
                                      style: TextStyle(
                                        fontSize: 64,
                                        height: 1.2,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'اضغط للذكر',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
