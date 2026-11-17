import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/controllers/app_controller.dart';

class HomeVerseCard extends StatelessWidget {
  const HomeVerseCard({
    super.key,
    required this.controller,
    required this.onRead,
  });
  final AppController controller;
  final VoidCallback onRead;
  @override
  Widget build(BuildContext context) {
    final original = controller.quran.verse(13, 28);
    final offset = original.indexOf('أَلَا');
    final excerpt = offset < 0 ? original : original.substring(offset);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23443C),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'آية اليوم وتأمل',
                    style: TextStyle(color: AppColors.sand, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              const Flexible(
                child: Text(
                  'سورة الرعد • ٢٨',
                  style: TextStyle(color: Color(0xFFCFDDD8), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '﴿ $excerpt ﴾',
            textAlign: TextAlign.center,
            style: AppTypography.sacred.copyWith(
              fontSize: 24,
              height: 1.9,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'السكينة ليست غياب الصخب من حولك، بل طمأنينة القلب بالله في كل حال.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: Color(0xFFCFDDD8),
            ),
          ),
          const Divider(height: 24, color: Color(0xFF4C766B)),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'لحظة للقراءة والتدبر',
                  style: TextStyle(color: AppColors.sand, fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: onRead,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text(
                  'اقرأ السورة',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
