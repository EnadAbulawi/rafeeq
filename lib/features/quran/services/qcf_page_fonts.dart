import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

/// Loads bundled fonts directly, without the package's persistent disk cache or
/// its five-variant loader. Registers the two monochrome families and the
/// original family required by verse-number spans; glyph tables are unchanged.
abstract final class QcfPageFonts {
  static final _loaded = <int>{};
  static final _pending = <int, Future<void>>{};
  static bool isReady(int page) => _loaded.contains(page);

  static Future<void> load(int page) {
    if (page < 1 || page > 604) {
      return Future.error(RangeError.range(page, 1, 604));
    }
    if (isReady(page)) return Future.value();
    final existing = _pending[page];
    if (existing != null) return existing;
    late final Future<void> task;
    task = _load(page).timeout(const Duration(seconds: 25)).whenComplete(() {
      if (identical(_pending[page], task)) _pending.remove(page);
    });
    _pending[page] = task;
    return task;
  }

  static Future<void> _load(int page) async {
    final base = QcfFontLoader.getBaseFontFamily(page);
    final asset = await rootBundle.load(
      'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/$base.ttf.gz',
    );
    final fonts = await compute(
      decodeQcfPageFonts,
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );
    for (var i = 0; i < fonts.length; i++) {
      final family = switch (i) {
        0 => QcfFontLoader.getNoTajweedLightFamily(page),
        1 => QcfFontLoader.getNoTajweedDarkFamily(page),
        _ => QcfFontLoader.getTajweedLightFamily(page),
      };
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(fonts[i])));
      await loader.load();
    }
    _loaded.add(page);
  }
}

/// CPAL palette handling follows qcf_quran_plus (MIT, Copyright 2026 Hussein).
/// Its license is retained in docs/third-party/qcf_quran_plus-LICENSE.txt.
List<Uint8List> decodeQcfPageFonts(Uint8List compressed) {
  final original = Uint8List.fromList(gzip.decode(compressed));
  if (original.length < 12) throw const FormatException('Invalid QCF font');
  final header = ByteData.sublistView(original);
  final tables = header.getUint16(4);
  if (tables < 1 || 12 + tables * 16 > original.length) {
    throw const FormatException('Invalid font table directory');
  }
  int? palette;
  int paletteLength = 0;
  for (var i = 0; i < tables; i++) {
    final record = 12 + i * 16;
    if (header.getUint32(record) == 0x4350414C) {
      palette = header.getUint32(record + 8);
      paletteLength = header.getUint32(record + 12);
      break;
    }
  }
  if (palette == null ||
      paletteLength < 12 ||
      palette + paletteLength > original.length) {
    throw const FormatException('Missing QCF color palette');
  }
  final count = header.getUint16(palette + 6);
  final start = palette + header.getUint32(palette + 8);
  if (start < palette || start + count * 4 > palette + paletteLength) {
    throw const FormatException('Invalid QCF color records');
  }
  return [
    for (final color in [0, 255])
      () {
        final bytes = Uint8List.fromList(original);
        for (var i = 0; i < count; i++) {
          final offset = start + i * 4;
          bytes[offset] = color;
          bytes[offset + 1] = color;
          bytes[offset + 2] = color;
          // Preserve alpha, including transparent records.
        }
        return bytes;
      }(),
    // QuranLine uses this family for ayah-end glyphs even in monochrome mode.
    original,
  ];
}
