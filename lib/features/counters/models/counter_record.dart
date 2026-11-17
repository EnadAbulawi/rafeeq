String localDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CounterRecord {
  CounterRecord({this.session = 0, this.lifetime = 0, Map<String, int>? days})
    : days = Map.unmodifiable(days ?? {});
  final int session;
  final int lifetime;
  final Map<String, int> days;

  int daily(DateTime date) => days[localDay(date)] ?? 0;

  CounterRecord increment(DateTime date) => CounterRecord(
    session: session + 1,
    lifetime: lifetime + 1,
    days: {...days, localDay(date): daily(date) + 1},
  );
  CounterRecord resetSession() => CounterRecord(lifetime: lifetime, days: days);
  Map<String, dynamic> toJson() => {
    'session': session,
    'lifetime': lifetime,
    'days': days,
  };

  factory CounterRecord.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as int;
    final lifetime = json['lifetime'] as int;
    final days = (json['days'] as Map<String, dynamic>).cast<String, int>();
    if (session < 0 ||
        lifetime < session ||
        days.values.any((v) => v < 0) ||
        days.values.fold(0, (a, b) => a + b) != lifetime ||
        days.keys.any((key) => !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key))) {
      throw const FormatException('Invalid counter data');
    }
    return CounterRecord(session: session, lifetime: lifetime, days: days);
  }
}
