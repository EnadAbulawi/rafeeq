import 'dart:convert';

import 'package:rafeeq/core/storage/local_store.dart';

class MemoryStore implements LocalStore {
  Map<String, dynamic>? data;
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> read() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> write(Map<String, dynamic> value) async {
    if (fail) throw StateError('Simulated storage failure');
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<void> close() async {}
}
