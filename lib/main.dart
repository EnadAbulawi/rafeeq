import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final entry in <String, String>{
      'Tanzil Quran Text': 'assets/data/TANZIL-LICENSE.txt',
      'IBM Plex Sans Arabic': 'assets/fonts/IBM-Plex-OFL.txt',
      'Amiri': 'assets/fonts/Amiri-OFL.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
  runApp(const RafeeqBootstrap());
}
