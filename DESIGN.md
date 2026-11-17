# Design System: Rafeeq

## 1. Visual Theme & Atmosphere
Quiet Arabic editorial reading companion. Balanced density (4), restrained variance (3), minimal motion (2). The supplied Stitch screens override generic taste defaults. Reference: project 16158290261872249461; light screen 9a160d487c8f4f08a06062e0da339848; night screen 37a11a717a574a82ba1e75ca4c7c8d69. Original exports are in design/.

## 2. Color Palette & Roles
Ivory #F8F7F3 canvas; white #FFFFFF surfaces; forest #315C52 actions; sage #E8EEE8 supporting surfaces; charcoal #242B28 text; sand #D8C7AA ornamental details. Secondary text is darkened from #828A85 for readable contrast. Night: canvas #161D1A, surface #1F2623, text #EAE6DF, muted #9CA7A1, border #333F3A.

## 3. Typography Rules
Locally bundled IBM Plex Sans Arabic for UI, regular and semibold. Amiri for Quran and supplication text, with 2.0 line height and no character spacing that breaks Arabic shaping. 14-16 logical pixels body; 22-28 headings; 28 Quran text. Never synthesize scripture.

## 4. Component Stylings
Actual exported HTML uses 16-24 pixel card radii and round counter rings; follow these over the project's earlier 4 pixel design-system prose. White panels, fine borders, restrained depth. Forest primary actions. Empty counters start at zero. Loading and errors must be explicit and retryable. Counter feedback is a short press response and optional haptics.

## 5. Layout Principles
RTL by locale. Mobile first: 16 pixel gutters below 360 logical pixels, otherwise 20; 16 pixel top and 24 pixel bottom padding. Use an 8 pixel rhythm. Primary and settings content is centered at a maximum of 720 pixels; Quran reading remains 680 pixels. Wrap actions at large text scales. Scroll screens; lazy Quran rows. Five navigation destinations. Native system status bar and SafeArea replace the presentation's simulated phone frame. No fixed location or fabricated prayer countdown.

Shared controls use 52 pixel minimum filled/outlined buttons, 48 pixel text-button touch targets, 16 pixel field padding, 44 pixel icon/number badges and rounded 4 pixel progress tracks. Page titles are 24, app-bar titles 20, list titles 16, body copy 14, and supporting copy 12–13 logical pixels. Preserve user font settings and device text scaling; QCF lines retain their dedicated fixed layout. Counter numerals fit their bounds, while long-form content wraps and scrolls.

## 6. Motion & Interaction
Respect reduced motion. Short built-in Material press/fade feedback; no infinite decorative animation in a reading application. Persist all preferences locally. Minimum 48 pixel controls. Goal setting is optional and conveys no religious reward claim.

## 7. Anti-Patterns
No neon, heavy gradients, oversized shadows, fake statistics, placeholder religious text, text/image overlaps, cloud account requirements, or runtime font downloads. Do not replace source text with normalized search text.
