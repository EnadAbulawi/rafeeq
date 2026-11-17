import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_widgets.dart';
import '../../services/qcf_mushaf_service.dart';

class MushafLoadingView extends StatelessWidget {
  const MushafLoadingView({
    super.key,
    required this.surah,
    required this.page,
    required this.stage,
  });

  final String surah;
  final int page;
  final MushafLoadingStage stage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = switch (stage) {
      MushafLoadingStage.page => 'جارٍ تجهيز بيانات صفحة المصحف',
      MushafLoadingStage.font => 'جارٍ تجهيز الخط لعرض الآيات بوضوح',
    };
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 320,
            child: AppSurfaceCard(
              padding: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                        ),
                        if (MediaQuery.disableAnimationsOf(context))
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              strokeCap: StrokeCap.round,
                              backgroundColor: scheme.outlineVariant,
                              semanticsLabel: status,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'نهيّئ لك صفحة المصحف',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سورة $surah • الصفحة ${arabicNumber(page)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      status,
                      key: const Key('mushaf-loading-status'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قد يستغرق الفتح الأول وقتًا أطول قليلًا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'القراءة متاحة دون إنترنت',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
