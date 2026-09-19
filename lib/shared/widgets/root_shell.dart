
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/prayer_models.dart';
import '../../core/theme/app_theme.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/home/home_dashboard_screen.dart';
import '../../features/radio/widgets/radio_mini_player.dart';
import '../../features/quran/widgets/quran_mini_player.dart';
import '../../core/services/wirdi_audio_handler.dart';
import '../../features/prayer/prayer_times_screen.dart';
import '../../features/tasbeeh/tasbeeh_screen.dart';
import '../../features/quran/quran_screen.dart';
import '../../features/azkar/azkar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/radio/radio_screen.dart';
import 'wirdi_brand.dart';

class _WirdiNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _WirdiNavItem({required this.label, required this.icon, required this.activeIcon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryEmerald;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.11) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 22, color: selected ? primary : AppColors.mutedText),
              const SizedBox(height: 3),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? primary : AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;
  int? _lastTimezoneOffsetMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rememberTimezoneOffset();

    // Surfaces a background-notification setup failure directly in the
    // app -- previously this only ever went to a debugPrint nobody could
    // see while running a real (non-debug-attached) build.
    if (audioServiceInitError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Background notification setup failed'),
            content: SingleChildScrollView(child: Text(audioServiceInitError!)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-sync when app comes back to foreground
    if (state == AppLifecycleState.resumed &&
        AuthService.instance.isSignedIn) {
      SyncService.instance.syncNow().catchError((_) {});
    }
    // FIX: "Auto dark mode at Maghrib" is normally driven by a per-second
    // timer that only lives in HomeDashboardScreen -- while the phone's
    // screen is off or the app is backgrounded, Android throttles that
    // timer, so the theme could stay stale (e.g. still light well after
    // Maghrib) until that timer happened to tick again. Re-checking with
    // the real current time right when the app is resumed/reopened fixes
    // that up immediately instead of leaving the user waiting.
    if (state == AppLifecycleState.resumed) {
      _refreshAutoDarkModeOnResume();
      _refreshPrayerDataAfterTimezoneChange();
    }
  }

  Future<void> _rememberTimezoneOffset() async {
    _lastTimezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
  }

  Future<void> _refreshPrayerDataAfterTimezoneChange() async {
    final currentOffset = DateTime.now().timeZoneOffset.inMinutes;
    final previousOffset = _lastTimezoneOffsetMinutes;
    _lastTimezoneOffsetMinutes = currentOffset;
    if (previousOffset == null || previousOffset == currentOffset) return;

    try {
      await PrayerService.invalidatePrayerCache();
      final result = await PrayerService.fetchUsingSavedPreference();
      if (!mounted) return;
      await PrayerNotificationScheduler.rescheduleFromResult(context, result);
    } catch (_) {
      // Best effort: the next normal prayer-time refresh will recover.
    }
  }

  Future<void> _refreshAutoDarkModeOnResume() async {
    if (!appSettings.autoDarkModeAtMaghrib) return;
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      PrayerItem? maghrib;
      PrayerItem? fajr;
      for (final p in result.prayers) {
        if (p.name == 'Maghrib') maghrib = p;
        if (p.name == 'Fajr') fajr = p;
      }
      if (maghrib == null || fajr == null) return;
      final now = DateTime.now();
      final isNight = now.isAfter(maghrib.dateTime) || now.isBefore(fajr.dateTime);
      final targetMode = isNight ? ThemeMode.dark : ThemeMode.light;
      if (appSettings.themeMode == targetMode) return;
      await appSettings.setThemeMode(targetMode);
    } catch (_) {
      // Best-effort safety net only -- the Home tab's per-second check
      // remains the primary mechanism while the app is actively open.
    }
  }

  // ORDER MUST EXACTLY MATCH the BottomNavigationBar items below:
  // 0=Home  1=Quran  2=Azkar  3=Prayer  4=Tasbeeh  5=Radio  6=More(Settings)
  static final List<Widget> _screens = [
    const HomeDashboardScreen(),   // 0
    const QuranScreen(),           // 1
    const AzkarScreen(),           // 2
    const PrayerTimesScreen(),     // 3
    const TasbeehScreen(),         // 4
    const RadioScreen(),           // 5  ← Radio BEFORE Settings
    const SettingsScreen(),        // 6
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _screens,
            ),
          ),
          // Mini player — visible whenever a radio station is active
          const RadioMiniPlayer(),
          // Mini player -- visible whenever Quran recitation is active
          const QuranMiniPlayer(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.10)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: List.generate(_screens.length, (i) {
              final labels = [l10n.navHome, l10n.navQuran, l10n.navAzkar, l10n.navPrayer, l10n.navTasbeeh, l10n.radioTitle, l10n.navMore];
              final icons = [
                Icons.home_outlined, Icons.menu_book_outlined, Icons.volunteer_activism_outlined,
                Icons.mosque_outlined, Icons.fingerprint, Icons.podcasts_outlined, Icons.more_horiz,
              ];
              final activeIcons = [
                Icons.home, Icons.menu_book, Icons.volunteer_activism, Icons.mosque,
                Icons.fingerprint, Icons.podcasts, Icons.more_horiz,
              ];
              return Expanded(
                child: _WirdiNavItem(
                  label: labels[i], icon: icons[i], activeIcon: activeIcons[i],
                  selected: _index == i, onTap: () => setState(() => _index = i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
