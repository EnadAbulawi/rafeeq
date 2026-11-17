import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/quran_repository.dart';
import 'quran_reader_view.dart';

class QuranView extends StatefulWidget {
  const QuranView({super.key, required this.controller});
  final AppController controller;
  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final input = TextEditingController();
  Timer? debounce;
  List<String> results = [];
  bool searching = false;
  bool bookmarksOnly = false;
  String? error;
  int generation = 0;
  void search(String query) {
    debounce?.cancel();
    final request = ++generation;
    setState(() {
      searching = query.trim().length >= 2;
      error = null;
      results = [];
    });
    if (!searching) return;
    debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final found = await widget.controller.quran.search(query);
        if (mounted && request == generation) {
          setState(() {
            results = found;
            searching = false;
          });
        }
      } catch (e, stack) {
        debugPrint('Quran search failed: $e\n$stack');
        if (mounted && request == generation) {
          setState(() {
            error = 'تعذر البحث. حاول مرة أخرى.';
            searching = false;
          });
        }
      }
    });
  }

  void open(ReadingPosition position) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          QuranReaderView(controller: widget.controller, position: position),
    ),
  );
  @override
  void dispose() {
    debounce?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final gutter = AppLayout.gutter(context);
    final query = normalizeArabic(input.text);
    final surahs = [
      for (var s = 1; s <= 114; s++)
        if (query.isEmpty ||
            normalizeArabic(controller.quran.name(s)).contains(query) ||
            '$s' == query)
          s,
    ];
    final positions = bookmarksOnly
        ? controller.bookmarks.map((p) => p.id).toList()
        : results;
    final header = <Widget>[
      const PageHeading('القرآن الكريم', 'كلام الله بين يديك، في كل وقت'),
      TextField(
        controller: input,
        onChanged: search,
        decoration: const InputDecoration(
          labelText: 'ابحث في السور والآيات',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('السور'),
            selected: !bookmarksOnly,
            onSelected: (_) => setState(() => bookmarksOnly = false),
          ),
          ChoiceChip(
            label: Text(
              'العلامات • ${arabicNumber(controller.bookmarks.length)}',
            ),
            selected: bookmarksOnly,
            onSelected: (_) => setState(() => bookmarksOnly = true),
          ),
        ],
      ),
      if (controller.lastReading != null && !bookmarksOnly && query.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppSurfaceCard(
            color: Theme.of(context).colorScheme.secondaryContainer,
            onTap: () => open(controller.lastReading!),
            child: Row(
              children: [
                const Icon(Icons.bookmark_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة القراءة',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.quran.name(controller.lastReading!.surah)} • الآية ${arabicNumber(controller.lastReading!.verse)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, size: 20),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
    ];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
          sliver: SliverList.list(children: header),
        ),
        if (bookmarksOnly && positions.isEmpty)
          const SliverToBoxAdapter(
            child: AppMessage('احفظ آية من قارئ المصحف لتظهر علامتها هنا.'),
          ),
        if (!bookmarksOnly) ...[
          SliverList.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final s = surahs[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
                child: AppSurfaceCard(
                  onTap: () => open(ReadingPosition(s, 1)),
                  child: Row(
                    children: [
                      AppIconBadge(label: arabicNumber(s)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سورة ${controller.quran.name(s)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${arabicNumber(controller.quran.count(s))} آية',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                ),
              );
            },
          ),
          if (query.length >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'الآيات المطابقة • ${arabicNumber(results.length)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (searching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              ),
            ),
          if (error != null)
            SliverToBoxAdapter(
              child: AppMessage(error!, retry: () => search(input.text)),
            ),
          if (!searching &&
              error == null &&
              query.length >= 2 &&
              results.isEmpty)
            const SliverToBoxAdapter(
              child: AppMessage('لا توجد آيات مطابقة. جرّب كلمات أخرى.'),
            ),
        ],
        SliverList.builder(
          itemCount: positions.length,
          itemBuilder: (context, index) {
            final p = ReadingPosition.parse(positions[index]);
            return Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
              child: AppSurfaceCard(
                onTap: () => open(p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.quran.name(p.surah)} • الآية ${arabicNumber(p.verse)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.quran.verse(p.surah, p.verse),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 23,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
