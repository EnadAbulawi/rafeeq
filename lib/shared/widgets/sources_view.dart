import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_widgets.dart';

class SourcesView extends StatelessWidget {
  const SourcesView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('عن رفيق ومصادره')),
    body: AppPageScroll(
      children: [
        const PageHeading('رَفِيق', 'رفيقك اليومي للذكر والقرآن'),
        const AppSurfaceCard(
          child: Text(
            'يعمل رفيق دون حساب أو اتصال. تُحفظ عداداتك وعلاماتك وموضع قراءتك على جهازك. حذف بيانات التطبيق أو إزالته قد يحذف بياناتك.',
          ),
        ),
        const SectionHeading('القرآن الكريم'),
        const SelectableText(
          'البحث والعرض العمودي: نص تنزيل العثماني، الإصدار ١٫١\n١١٤ سورة • ٦٢٣٦ آية\nhttps://tanzil.net\nحقوق النص لمشروع تنزيل ٢٠٠٧–٢٠٢٦، وفق رخصة المشاع الإبداعي Attribution 3.0 وشروطه الخاصة. يُعرض النص كما ورد دون تغيير.',
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: 'https://tanzil.net'),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('نُسخ رابط المصدر')));
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('نسخ رابط تنزيل'),
        ),
        const Text(
          'عرض صفحات المصحف: بيانات الأسطر وخطوط QCF المضمنة في حزمة qcf_quran_plus. يُستخدم فهرس الحزمة لتحديد الصفحات والعلامات.',
        ),
        const SectionHeading('التلاوة'),
        const SelectableText(
          'المصدر: EveryAyah\nhttps://everyayah.com\nالتلاوة عبر الإنترنت، دون تنزيلات تلقائية. يتوقف الصوت عند مغادرة القارئ، ويتوقف مؤقتًا عند انتقال التطبيق للخلفية.',
        ),
        const SectionHeading('الأذكار'),
        const SelectableText(
          'نصوص من حصن المسلم، من مجموعتي osamayy/azkar-db وwafaaelmaandy/Hisn-Muslim-Json. يُعرض مرجع كل ذكر أو معرّفه لدى المصدر داخل جلسة القراءة. لا يتضمن التطبيق كامل كتاب حصن المسلم.\n\nhttps://github.com/osamayy/azkar-db\nhttps://github.com/wafaaelmaandy/Hisn-Muslim-Json',
        ),
        const SectionHeading('الخطوط والتراخيص'),
        const Text(
          'IBM Plex Sans Arabic وAmiri للواجهة والأذكار حسب اختيارك، وQCF لصفحات المصحف. الخطوط مضمّنة وتعمل دون اتصال. يظهر فضل الذكر عند توفر نص له في المصدر المحفوظ، مع نسبة النص إلى مصدره.',
        ),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'رفيق',
            applicationVersion: '١٫٠٫١',
          ),
          child: const Text('عرض التراخيص'),
        ),
      ],
    ),
  );
}
