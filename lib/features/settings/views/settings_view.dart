import 'package:flutter/material.dart';

import '../../../app/controllers/app_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/sources_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AppPageScroll(
        children: [
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خط التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _FontPicker(
                  label: 'نوع خط الواجهة',
                  value: controller.fontFamily,
                  onChanged: (v) => controller.setTypography(family: v),
                ),
                const SizedBox(height: 16),
                Text(
                  'حجم خط الواجهة • ${arabicNumber((controller.fontScale * 100).round())}٪',
                ),
                Slider(
                  key: const Key('app-font-scale'),
                  value: controller.fontScale,
                  min: .85,
                  max: 1.35,
                  divisions: 10,
                  label:
                      '${arabicNumber((controller.fontScale * 100).round())}٪',
                  onChanged: (v) => controller.setTypography(scale: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خط نصوص الأذكار',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _FontPicker(
                  label: 'نوع خط الأذكار',
                  value: controller.adhkarFontFamily,
                  onChanged: (v) => controller.setTypography(dhikrFamily: v),
                ),
                const SizedBox(height: 16),
                Text(
                  'حجم نص الذكر • ${arabicNumber(controller.adhkarFontSize.round())}',
                ),
                Slider(
                  key: const Key('dhikr-font-size'),
                  value: controller.adhkarFontSize,
                  min: 22,
                  max: 44,
                  divisions: 11,
                  onChanged: (v) => controller.setTypography(dhikrSize: v),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'سبحان الله وبحمده',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: controller.adhkarFontFamily,
                      fontSize: controller.adhkarFontSize,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تظهر التغييرات مباشرة وتُحفظ تلقائيًا. يحافظ عرض صفحات المصحف على توزيع أسطره.',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
                TextButton(
                  onPressed: () => controller.setTypography(
                    scale: 1,
                    dhikrSize: 28,
                    family: 'IBMPlexArabic',
                    dhikrFamily: 'Amiri',
                  ),
                  child: const Text('استعادة الخط الافتراضي'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('المظهر الليلي'),
                  value: controller.dark,
                  onChanged: (_) => controller.toggleTheme(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الاهتزاز عند العدّ'),
                  value: controller.haptic,
                  onChanged: controller.setHaptic,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('إعدادات الإشعارات'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          NotificationSettingsView(controller: controller),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('عن رفيق ومصادره'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SourcesView(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FontPicker extends StatelessWidget {
  const _FontPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label, value;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: const [
      DropdownMenuItem(value: 'IBMPlexArabic', child: Text('العربي الحديث')),
      DropdownMenuItem(value: 'Amiri', child: Text('الأميري')),
    ],
    onChanged: onChanged,
  );
}

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key, required this.controller});
  final AppController controller;
  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  @override
  void initState() {
    super.initState();
    widget.controller.reminders.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.controller.reminders;
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الإشعارات')),
      body: ListenableBuilder(
        listenable: r,
        builder: (context, _) {
          final p = r.preferences;
          return AppPageScroll(
            children: [
              const Text(
                'تذكيرات يومية تختار أوقاتها',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'يطلب رفيق إذن الإشعارات عند التفعيل. المواعيد حسب توقيت جهازك، ويمكنك إيقافها في أي وقت.',
                style: TextStyle(height: 1.7),
              ),
              const SizedBox(height: 16),
              if (!r.supported)
                const AppMessage(
                  'التذكيرات المحلية متاحة حاليًا على Android وiPhone.',
                ),
              AppSurfaceCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تفعيل التذكيرات'),
                      subtitle: Text(
                        !r.supported
                            ? 'غير متاحة على هذا الجهاز'
                            : r.busy
                            ? 'جارٍ تحديث التذكيرات…'
                            : p.enabled && r.allowed
                            ? '${arabicNumber(r.scheduledCount)} تذكيرات مجدولة'
                            : p.enabled
                            ? 'تحقق من إذن الإشعارات'
                            : 'متوقفة',
                      ),
                      value: p.enabled,
                      onChanged: r.busy || !r.supported
                          ? null
                          : (v) => r.update(p.copyWith(enabled: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('صوت الإشعارات'),
                      value: p.sound,
                      onChanged: r.busy || !r.supported
                          ? null
                          : (v) => r.update(p.copyWith(sound: v)),
                    ),
                  ],
                ),
              ),
              if (r.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  r.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: r.busy ? null : r.refresh,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
              const SizedBox(height: 16),
              for (var i = 0; i < p.times.length; i++) ...[
                AppSurfaceCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.times[i].title),
                        value: p.times[i].enabled,
                        onChanged: r.busy || !r.supported
                            ? null
                            : (v) {
                                final times = [...p.times];
                                times[i] = times[i].copyWith(enabled: v);
                                r.update(p.copyWith(times: times));
                              },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('موعد التذكير'),
                        trailing: Text(
                          arabicNumber(
                            TimeOfDay(
                              hour: p.times[i].minutes ~/ 60,
                              minute: p.times[i].minutes % 60,
                            ).format(context),
                          ),
                        ),
                        onTap: r.busy || !r.supported
                            ? null
                            : () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: p.times[i].minutes ~/ 60,
                                    minute: p.times[i].minutes % 60,
                                  ),
                                );
                                if (time == null || !mounted) return;
                                final current = r.preferences;
                                final times = [...current.times];
                                times[i] = times[i].copyWith(
                                  minutes: time.hour * 60 + time.minute,
                                );
                                await r.update(current.copyWith(times: times));
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'هذه مواعيد تختارها أنت، وليست مواقيت صلاة محسوبة. قد يؤخر نظام الجهاز التذكير قليلًا لتوفير البطارية.',
                style: TextStyle(fontSize: 12, height: 1.7),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: r.busy || !r.supported ? null : r.test,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('إرسال إشعار تجريبي'),
              ),
              TextButton(
                onPressed: r.busy || !r.supported ? null : r.openSettings,
                child: const Text('إذن الإشعارات في إعدادات الجهاز'),
              ),
            ],
          );
        },
      ),
    );
  }
}
