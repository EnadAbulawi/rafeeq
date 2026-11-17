class ReminderTime {
  const ReminderTime(
    this.key,
    this.title,
    this.body,
    this.minutes, {
    this.enabled = true,
  });
  final String key, title, body;
  final int minutes;
  final bool enabled;
  ReminderTime copyWith({int? minutes, bool? enabled}) => ReminderTime(
    key,
    title,
    body,
    minutes ?? this.minutes,
    enabled: enabled ?? this.enabled,
  );
}

class ReminderPreferences {
  const ReminderPreferences({
    this.enabled = false,
    this.sound = true,
    this.times = const [
      ReminderTime('morning', 'أذكار الصباح', 'ابدأ يومك بوقت للذكر.', 420),
      ReminderTime(
        'evening',
        'أذكار المساء',
        'خذ وقتًا هادئًا لأذكار المساء.',
        1080,
      ),
      ReminderTime('reading', 'ورد القرآن', 'موعدك مع قراءة القرآن.', 1200),
      ReminderTime(
        'salawat',
        'الصلاة على النبي',
        'تذكير بالصلاة على النبي ﷺ.',
        960,
      ),
    ],
  });
  final bool enabled, sound;
  final List<ReminderTime> times;
  ReminderPreferences copyWith({
    bool? enabled,
    bool? sound,
    List<ReminderTime>? times,
  }) => ReminderPreferences(
    enabled: enabled ?? this.enabled,
    sound: sound ?? this.sound,
    times: times ?? this.times,
  );
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'sound': sound,
    'times': {
      for (final t in times)
        t.key: {'minutes': t.minutes, 'enabled': t.enabled},
    },
  };
  factory ReminderPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReminderPreferences();
    final times = json['times'] as Map<String, dynamic>? ?? {};
    return ReminderPreferences(
      enabled: json['enabled'] as bool? ?? false,
      sound: json['sound'] as bool? ?? true,
      times: [
        for (final t in const ReminderPreferences().times)
          () {
            final saved = times[t.key] as Map<String, dynamic>?;
            final minutes = saved?['minutes'] as int? ?? t.minutes;
            if (minutes < 0 || minutes >= 1440) {
              throw const FormatException('Invalid reminder time');
            }
            return t.copyWith(
              minutes: minutes,
              enabled: saved?['enabled'] as bool? ?? t.enabled,
            );
          }(),
      ],
    );
  }
}
