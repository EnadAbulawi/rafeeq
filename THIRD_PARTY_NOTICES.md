# Third-party content and notices

The root MIT license covers the original Rafeeq application code and original
project documentation. It does not relicense third-party texts, fonts, libraries,
recitations or artwork. Keep their respective copyright and license notices.

## Quran text — Tanzil

`assets/data/quran.json`, `design/tanzil-uthmani.xml` and associated text come from
[Tanzil](https://tanzil.net), Uthmani 1.1. The original copyright block is retained
in both the XML and JSON. The [Tanzil Text License](https://tanzil.net/docs/Text_License)
permits verbatim distribution with attribution, a link and the original notice;
it prohibits changing the Quran text. Preserve the original verse strings and
notice when changing storage or UI. Pagination metadata is attributed to Tanzil
in `design/content-provenance.json`.

## Adhkar datasets — fetched separately

The source repositories are:

- https://github.com/osamayy/azkar-db
- https://github.com/wafaaelmaandy/Hisn-Muslim-Json

No explicit dataset redistribution license was declared by either repository
when checked on 2026-11-17. Consequently the raw snapshots and combined Adhkar
JSON are excluded from this public repository. `tool/prepare_content.py` fetches
pinned upstream revisions directly for local development and verifies their
contents before preparing the 77 selected entries. Fetching those sources does
not establish permission to redistribute them; determine the applicable rights
or replace the data with a suitably licensed source before distributing your own
app. The existing local datasets are not deleted by the publication process.

Descriptions of virtues are preserved as supplied and attributed to their
dataset. Matching a source does not independently authenticate every narration.

## Fonts and QCF rendering

- IBM Plex Sans Arabic: bundled OFL notice in `assets/fonts/IBM-Plex-OFL.txt`.
- Amiri: bundled OFL notice in `assets/fonts/Amiri-OFL.txt`.
- `qcf_quran_plus` 0.1.1: MIT package code. Its notice, also covering the adapted
  CPAL handling, is retained at `docs/third-party/qcf_quran_plus-LICENSE.txt`.
  QCF fonts and their upstream terms remain separate from Rafeeq's MIT license.
  They are acquired through the package dependency, not copied into this repo.

## Recitation

Streaming MP3 files come from [EveryAyah](https://everyayah.com/data/). No audio
files are bundled here. `just_audio` performs playback. Rafeeq does not claim
ownership of the recordings or grant rights to redistribute recordings.

## Dependencies and design

Flutter, sqflite, just_audio, audio_session, flutter_local_notifications,
flutter_timezone and timezone retain their own licenses. `pubspec.lock` pins
the versions used. The in-app license screen exposes Flutter's collected notices.
Rafeeq's original UI implementation follows the project's Stitch design export;
private export metadata and download URLs are not published. No Google or Stitch
endorsement is implied.
