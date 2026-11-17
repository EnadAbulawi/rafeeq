# Validation — 2026-11-17

- Flutter 3.47.2 / Dart 3.13.2 on Windows.
- Application source verification: flutter analyze clean and 69 tests passed.
- Tests cover counters, persistence/migration, canonical Quran IDs, attributed
  content, QCF cold loading/timeout/retry, audio controllers, notification consent,
  plugin channel arguments, timezone/DST, cold notification routing, light/dark UI,
  narrow/tablet layouts and combined device/app text scaling.
- python tool/verify_content.py compares 6236 verses and 77 Adhkar entries,
  including 26 source descriptions, with the original snapshots.
- Public content preparation is checked using local snapshots and fresh downloads
  from immutable upstream commits. Canonical JSON SHA256 ignores serialization
  differences (LF/CRLF), while preserving every source text character.
- Two Python regression tests also check preparation and protection of local edits.
- Public screenshots in docs/screenshots use widget-test sample data.
- Android XML/vector resources were compiled with AAPT2. No APK/AAB was built for
  publication; plugin-channel tests do not prove physical notification delivery.
- The user previously confirmed basic Quran display and audible recitation on an
  Android phone. Latest reminders/icon/UI changes require fresh device validation.
  iOS has not been built here.
- GitHub Actions checks source without binary builds or deployment.

Historical workstation/device reports are retained locally outside this public
repository. Credentials, signing files, private design download metadata,
device dumps and build binaries are excluded.
