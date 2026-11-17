# Quran package selection — 2026-10-31

| Option | Reviewed version | Fit for Rafeeq |
| --- | --- | --- |
| [qcf_quran](https://pub.dev/packages/qcf_quran) | 0.0.5 | Bundled page-specific fonts, no extra runtime dependency; reviewed QcfPage implementation still builds a flowing Text.rich with screen-based sizing, and allocates recognizers in a StatelessWidget build. |
| [qcf_quran_plus](https://pub.dev/packages/qcf_quran_plus) | 0.1.1 | Selected for rendering. Explicit line_start/line_end and per-line glyph data, fixed page-line layout, verse callbacks, night variants, no state-management framework dependency. Bundled fonts work offline. |
| [quran_library](https://pub.dev/packages/quran_library) | 5.0.1 | Integrated rendering, recitation/download/background audio, plus recording and sherpa_onnx recitation checking. The current dependency surface introduces GetX and capabilities beyond this app's requirements. |
| [quran_audio](https://pub.dev/packages/quran_audio) | 1.0.0 | Useful full audio subsystem; brings GetX, storage, audio_service and desktop media backend. Not selected because Rafeeq needs a small reader-scoped Android playback path. |
| [just_audio](https://pub.dev/packages/just_audio) | 0.10.6 | Selected audio engine, with audio_session 0.2.4. Wraps playback behind an injectable backend and retains the app's ChangeNotifier approach. |

The user-supplied spelling qcfquran has no pub.dev package API record; the actual reviewed names are qcf_quran and qcf_quran_plus. Selection is based on the published archives and live package metadata rather than a claim that any library is universally best.

## Integration

- Replaces the prior Amiri text-flow Mushaf renderer with qcf_quran_plus's QuranPageView. The existing vertical reader, saved positions, bookmarks, search, counters and SQLite snapshot remain in place.
- Pins qcf_quran_plus exactly to 0.1.1. Its public startup helper loads all 604 fonts. A narrowly isolated, documented implementation import initializes only its data repository. Rafeeq's QcfPageFonts loads the requested bundled page directly and registers two monochrome families plus the original family required for verse numbers, without disk caching or runtime downloads.
- A loading cover prevents showing private-use font codepoints before registration. Retry is available for page loading errors. Fixed Mushaf scaling preserves the source lines; vertical mode remains available for scalable accessible reading.
- The QCF dataset and the prior Tanzil index differ in page placement for 56 verse IDs. This is an observed mismatch; its upstream cause has not been established. Display navigation and highlights therefore use the QCF package's own page map, with source (surah, verse) IDs preserved. Both range inventories cover the canonical 6236 verse IDs exactly once.
- EveryAyah streaming: Alafasy_128kbps, Husary_128kbps, Abdul_Basit_Murattal_192kbps. Verified live HTTP 200 / audio/mpeg and MP3 headers for 001001 and 114006 in every selected directory. Source: https://everyayah.com/data/ . This is endpoint verification, not an audible native playback test.
- Play/pause/resume, stop, reciter selection, repeat one verse, optional continuation to the end of the surah, and explicit loading/retry states. Verse action sheets and the vertical reader offer listening actions. Audio is initialized only on first play, pauses on backgrounding and is disposed when leaving the reader. No background media notification service or download manager is claimed.
- Android adds INTERNET only. No microphone permission, recognition engine, analytics or paid fallback. Local reading remains offline; streamed recitation requires network access and sends the selected reciter/verse request to EveryAyah.

## Size and licensing

Published archive inventory: qcf_quran 58.00 MiB unpacked total; qcf_quran_plus 75.12 MiB unpacked total. These include source and assets, and are not APK size measurements. Bundled QCF fonts will increase the next build's assets; no APK was built or measured in this task. The old APK and installed phone version are unchanged.

Package source is MIT; QCF/KFGQPC font upstream distribution terms still need to be observed. Keep this alongside the existing Quran/Adhkar provenance notes. Content inventory tests verify IDs and ranges; they do not independently certify every glyph in third-party font files.

## User workflow preference

Do not create APKs or update a phone by default. Build only when the user explicitly requests an APK or a physical-device run that requires a Debug runtime build. End implementation work with a short report covering changes, verification and limitations.


## Verification outcome

- `flutter analyze`: no issues.
- `flutter test --concurrency=1 --timeout 90s --reporter expanded`: 42 passed. Includes nine audio-controller tests, all canonical QCF range IDs, the differing-boundary navigation regression, renderer callbacks/marks, last-page/large-text behavior, and a real package widget rendering exactly 15 lines on standard page 3.
- Visually inspected package-font previews for page 1 and standard page 3. Latest preview: `build/previews/qcf-standard-page-3.png`.
- Installed package inventory: 604 gzip page fonts, 68,711,812 bytes (65.53 MiB), not loaded en masse at startup. This cost is relevant to a future requested APK; no APK size inference is made here.
- Confirmed the pre-existing APK SHA256 remains `1a558b488cb7f4f8f1328ff6527e5f4fcf5f598619a231579d4341d009faadaa`. No APK build/install or real-device playback was performed in this task.


## Later requested device run

At the user's explicit request to run on the attached phone, a native Debug build was produced and installed successfully after fixing Kotlin cache compilation. The user confirmed both visible QCF verses and audible recitation on OPPO CPH2217. Earlier statements that native playback was unverified describe the source-only integration stage; this later user confirmation establishes basic audible playback on that device. Full reciter/interruption/long-session coverage remains unverified. No Release distribution APK was requested or produced.

## Reader loading recovery and home alignment

The subsequently installed reader was observed on the attached OPPO displaying
only its loading indicator and footer. Its captured process log did not identify
a Dart exception; the USB connection dropped again during further inspection.
This confirms the reported symptom, not a specific corrupt-cache diagnosis.

The earlier reader awaited data and font initialization without a deadline.
It now loads bundled page fonts directly in an isolate, registers the original
verse-number family plus the light/dark monochrome families, and avoids the
package's persistent font cache and two unused variants. Initialization is
bounded, incomplete failed data initialization is cleared for retry, and a clear
retry message replaces indefinite loading. The vertical reader remains available.

`flutter analyze` passes; 49 tests pass. Five new tests cover cold initialization
without a path-provider plugin/cache, stalled-load timeout/retry, leaving while
loading, preservation of glyph tables and original number-font bytes, and invalid
pages. Standard page 3 still renders 15 lines; its preview was checked visually,
including verse-number ornaments. These checks do not establish the fix on the
physical phone because no new APK was built or installed for this change.

Home now follows the exported Stitch home layout, colors, typography, hero card,
two-column feature grid, daily summary and compact navigation. Prototype-only
location, countdown and sample statistics are replaced with working actions and
actual local data. Light/dark and 200% text layouts were tested and previewed.
