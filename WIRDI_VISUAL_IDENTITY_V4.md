# Wirdi Visual Identity V4 — Full UI Redesign Patch

This patch is intended to be overlaid on the current Wirdi project. It redesigns the main visual surfaces around the supplied Wirdi brand-board reference while preserving the existing application services and feature logic.

## Main screens redesigned
- Splash: branded scenic background + Wirdi mark.
- Home: full scenic hero, logo/greeting, quick actions, next-prayer hero, Quran/Wird cards, moon card, hadith/verse cards.
- Quran: scenic hero + premium content surface while keeping the existing tabs, search, favorites, and repository logic.
- Azkar: scenic hero + existing category/dua logic.
- Prayer Times: scenic next-prayer card with the existing live prayer data, countdown, notification controls, weather and sunrise/sunset.
- Qibla: scenic Kaaba hero while retaining compass/location logic.
- Radio: scenic Kaaba hero while retaining station, favorites, search and sleep-timer logic.
- Moon: cinematic moon hero while retaining calculated phases and sighting disclaimer.
- Profile/Account: scenic profile hero while retaining auth/sync/delete logic.
- Settings: scenic settings hero while retaining all settings controls.

## New page-specific image assets
All files end in `_hero_v4` and are derived/graded specifically for Wirdi's Emerald/Deep-Teal/Gold visual language.

## Palette
- Emerald: #0F766E
- Deep green/navy: #071A17
- Gold: #D4AF37
- Warm ivory: #F7F4EA

## Logic intentionally preserved
Notifications, prayer calculations, Firebase/Auth, RadioService, Quran repository/reader, favorites, Khatma, Adhkar data/scheduling, Qibla sensors/location and other feature services were not rewritten as part of this visual redesign.

## Validation
The working environment used to prepare this patch does not contain the Flutter SDK, so run the project's normal CI validation after overlaying the files:

    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --debug

