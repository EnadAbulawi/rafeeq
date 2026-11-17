# Settings, local reminders and adaptive launcher icon

The home header's settings button opens typography, appearance and notification
settings. Interface font (IBM Plex Sans Arabic/Amiri), interface scale (85–135%),
and independent dhikr font and size (22–44) are persisted in the existing SQLite
snapshot. Device accessibility scaling is composed with the app scale. QCF page
layout retains its fixed scaling; its vertical alternative remains available.
Schema-1 snapshots without new fields load the original defaults and preserve
reading positions, counters and bookmarks.

26 dhikr entries now include the verbatim nonempty description from their
original `design/adhkar-source.json` row, matched by source ID. The reader shows
the description as "فضل الذكر" and attributes it to its source. Other entries
have no fabricated or inferred virtue. `tool/verify_content.py` checks text,
counts, references and these descriptions against the original local snapshots.

Android launcher resources now use background/foreground adaptive layers on
API 26+, a monochrome layer on API 33+, and the existing Rafeeq vector as the
legacy fallback. The launcher chooses the mask; no circular background is baked
into the foreground. iOS continues to use its system-managed icon shape.

Local reminders use flutter_local_notifications 22.3.3 (compatible with the
existing Android SDK/Gradle setup), flutter_timezone 5.1.1 and timezone 0.11.0.
They require no server, Firebase or network connection. The master switch is off
by default. Enabling asks the OS for notification permission; refusing does not
enable reminders. The settings page provides four editable daily reminders,
individual switches, sound control, permission-settings access and a test button.
Times are user choices, not calculated prayer times. Android uses inexact alarms
and can delay them for battery management; no exact-alarm permission is requested.
Only managed IDs 4100–4103 are replaced/cancelled. Status counts actual pending
requests. Boot/update receivers restore stored schedules. Permission/timezone
state is refreshed on app resume. Notification taps open the corresponding
adhkar, Quran reading position, salawat counter or notification settings.

Native setup includes POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, scheduled
notification receivers, Java desugaring, a retained white Android status icon,
and the iOS notification-center delegate. Notification permission is not requested
at application startup. Non-mobile platforms keep the settings functional and
display that local reminders are unavailable.

Validation covers persistence/backward compatibility, consent denial/revocation,
schedule edits/cancellation/failures, actual plugin channel arguments, separate
silent channels, timezone/DST boundaries, cold notification routing, attributed
virtues and UI with device scaling 200% plus app scaling 135%. Android XML/vector
resources compile with AAPT2. Native delivery, boot recovery and launcher masks
still require a freshly installed device build; no APK/AAB or installation is
performed for these source changes.

Official implementation references:
- https://pub.dev/packages/flutter_local_notifications/versions/22.3.3
- https://pub.dev/packages/flutter_timezone/versions/5.1.1
- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
