import 'package:flutter/material.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../adhkar/views/adhkar_reader_view.dart';
import '../../quran/repositories/quran_repository.dart';
import '../../quran/views/quran_reader_view.dart';
import 'widgets/home_greeting_header.dart';
import 'widgets/home_verse_card.dart';
import 'widgets/home_feature_grid.dart';
import 'widgets/home_daily_progress.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.controller, required this.navigate});
  final AppController controller;
  final ValueChanged<int> navigate;
  void read(BuildContext context, ReadingPosition p) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => QuranReaderView(controller: controller, position: p),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final morning = controller.clock().hour < 12;
    return ListView(
      padding: AppLayout.pagePadding(context),
      children: [
        HomeGreetingHeader(controller: controller),
        HomeVerseCard(
          controller: controller,
          onRead: () => read(context, const ReadingPosition(13, 28)),
        ),
        HomeFeatureGrid(
          controller: controller,
          navigate: navigate,
          resume: () => read(context, controller.lastReading!),
        ),
        const SizedBox(height: 8),
        HomeDailyProgress(controller: controller),
        const SizedBox(height: 12),
        AppSurfaceCard(
          radius: 16,
          color: Theme.of(context).colorScheme.secondaryContainer,
          padding: 14,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => AdhkarReaderView(
                controller: controller,
                category: morning ? 'morning' : 'evening',
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.bolt_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      morning ? 'ابدأ أذكار الصباح' : 'ابدأ أذكار المساء',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'وقت للقراءة والذكر الهادئ',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
