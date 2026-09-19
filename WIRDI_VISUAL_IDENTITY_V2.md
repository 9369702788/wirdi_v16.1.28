# Wirdi 1.54.0+20 — Visual Identity v2

## What changed
- Premium Emerald / Gold / Ivory visual system retained and expanded.
- Floating rounded bottom navigation with active-state treatment.
- Reusable Wirdi brand primitives: scenic backgrounds, glass cards, feature tiles, section titles, and brand hero.
- Home redesigned with a branded scenic hero and four quick-action tiles.
- Quran, Azkar, Prayer, Qibla, Radio, and Moon screens receive subtle contextual scenic backgrounds.
- Splash screen now uses the actual Wirdi visual mark asset.
- Added dedicated UI image assets cropped from the supplied Wirdi visual board: logo, Quran, Kaaba, moon, lantern.
- Existing notification, radio, Quran, prayer, authentication, favorites, and storage logic was not intentionally changed.
- Added `assets/images/ui/` to Flutter asset declarations.

## Test build
Run:
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
