import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/verse_of_the_day_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/models/hadith_models.dart';
import '../../core/services/hadith_repository.dart';
import '../hadith/hadith_collection_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/data/daily_quotes.dart';
import '../../core/models/prayer_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/hijri_date.dart';
import '../../core/services/moon_calculator.dart';
import '../../core/services/prayer_display.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/sunrise_sunset_calculator.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../azkar/azkar_screen.dart';
import '../favorites/favorites_screen.dart';
import '../insights/wirdi_insights_screen.dart';
import '../khatma/khatma_tracker_screen.dart';
import '../prayer/prayer_times_screen.dart';
import '../qibla/qibla_screen.dart';
import '../quran/quran_screen.dart';
import '../ramadan/ramadan_companion_screen.dart';
import '../settings/settings_screen.dart';
import '../tools/islamic_tools_screen.dart';
import '../wird/my_wirdi_screen.dart';
import '../../shared/widgets/wirdi_brand.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  PrayerTimesResult? _prayer;
  bool _prayerFailed = false;
  Timer? _timer;
  String _countdown = '--:--:--';
  bool? _autoDarkAppliedState;

  Map<String, dynamic>? _lastReading;
  int _favoritesCount = 0;
  int _pagesToday = 0;
  int _wirdTarget = 5;
  int _prayedCount = 0;
  int _streak = 0;
  double _khatmaRatio = 0.0;
  double _myWirdiPercent = 0.0;
  List<DailyActivitySummary> _weekSummary = [];
  HadithModel? _hadithOfToday;
  int _hadithStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<int> _updateHadithStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastDate = prefs.getString('last_hadith_view_date');
    var streak = prefs.getInt('hadith_streak') ?? 0;
    if (lastDate == todayKey) {
      return streak;
    }
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    streak = (lastDate == yesterdayKey) ? streak + 1 : 1;
    await prefs.setString('last_hadith_view_date', todayKey);
    await prefs.setInt('hadith_streak', streak);
    return streak;
  }

  Future<void> _loadAll() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    unawaited(_loadPrayer());

    var lastReading = await UserProgressService.lastReading();
    if (lastReading != null && (lastReading['surahName'] as String? ?? '').trim().isEmpty) {
      try {
        final surahs = await QuranRepository.load();
        final number = lastReading['surahNumber'] as int?;
        if (number != null) {
          final match = surahs.firstWhere((s) => s.number == number, orElse: () => surahs.first);
          lastReading = {...lastReading, 'surahName': match.name};
          await UserProgressService.saveLastReading(
            surahNumber: number,
            surahName: match.name,
            ayahNumber: lastReading['ayahNumber'] as int? ?? 1,
          );
        }
      } catch (_) {}
    }
    final favCount = await UserProgressService.totalFavoritesCount();
    final pagesToday = await UserProgressService.pagesReadToday();
    final target = await UserProgressService.dailyWirdTarget();
    final streak = await UserProgressService.wirdStreak();
    final khatmaRatio = await UserProgressService.quranCompletionRatio();
    final weekSummary = await UserProgressService.last7DaysSummary();
    final hadith = await HadithRepository.forToday(languageCode);
    final hadithStreak = await _updateHadithStreak();
    final myWirdi = await MyWirdiStats.load();
    final prayed = await UserProgressService.prayedToday();

    if (!mounted) return;
    setState(() {
      _lastReading = lastReading;
      _favoritesCount = favCount;
      _pagesToday = pagesToday;
      _wirdTarget = target;
      _streak = streak;
      _khatmaRatio = khatmaRatio;
      _weekSummary = weekSummary;
      _hadithOfToday = hadith;
      _hadithStreak = hadithStreak;
      _myWirdiPercent = myWirdi.overallPercent;
      _prayedCount = prayed.length;
    });
    unawaited(WidgetService.updateHadith(hadith));
    unawaited(WidgetService.updateProgress(pagesToday, target, khatmaRatio));
  }

  Future<void> _loadPrayer() async {
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      if (!mounted) return;
      setState(() {
        _prayer = result;
        _prayerFailed = false;
      });
      unawaited(WidgetService.updatePrayerTimes(result.prayers, result.next));
      _startCountdown();
      unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
      unawaited(_loadWeatherAndSun());
    } catch (_) {
      if (!mounted) return;
      setState(() => _prayerFailed = true);
    }
  }

  WeatherData? _weather;
  SunTimes? _sunTimes;

  Future<void> _loadWeatherAndSun() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));
      final sun = SunriseSunsetCalculator.calculate(position.latitude, position.longitude, DateTime.now());
      if (mounted) setState(() => _sunTimes = sun);
    } catch (_) {
      // no-op -- sunrise/sunset row just won't show
    }
    try {
      final weather = await WeatherService.getWeatherAtPrayerTime('now');
      if (mounted) setState(() => _weather = weather);
    } catch (_) {
      // no-op -- weather row just won't show
    }
  }

  String _fmtSunTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _startCountdown() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  /// ROOT CAUSE FIX: this used to call [_loadPrayer] the INSTANT the
  /// visible countdown reached zero -- i.e. exactly when a prayer time
  /// arrives. [_loadPrayer] re-fetches prayer times and reschedules
  /// ALL prayer notifications via
  /// PrayerNotificationScheduler.rescheduleFromResult ->
  /// NotificationService.scheduleAll(), which starts by CANCELLING
  /// every currently-scheduled notification before re-adding them.
  /// With the home dashboard open right as a prayer time arrives
  /// (exactly when its own countdown reaches zero -- an extremely
  /// common case, not an edge case), this raced against and CANCELLED
  /// the "at prayer time" notification (the one with the real Adhan
  /// sound) at the exact moment it was due to fire. By the time the
  /// freshly recomputed schedule ran a moment later, that prayer's
  /// time was already in the past, so scheduleAll()'s "never schedule
  /// something already in the past" guard silently dropped it
  /// forever -- it never got a second chance to fire. The earlier
  /// "X minutes before" reminder was unaffected because it had
  /// already fired well before this race could occur -- exactly the
  /// reported symptom: the early reminder works, the real Adhan
  /// notification at the actual prayer time does not.
  ///
  /// Fix: advance to the next prayer already present in TODAY's
  /// already-fetched list -- a purely local state update with no
  /// network call and no reschedule, so nothing can race the
  /// notifications already correctly scheduled for the rest of the
  /// day. Only fall back to a real [_loadPrayer] (now safe to
  /// reschedule against, since it only runs once per day when today's
  /// list is exhausted) once every prayer in today's list has passed.
  void _updateCountdown() {
    final prayer = _prayer;
    if (prayer == null) return;
    _applyAutoDarkModeIfEnabled(prayer);
    final diff = prayer.next.dateTime.difference(DateTime.now());
    if (diff.isNegative) {
      final upcoming = prayer.prayers.where((p) => p.dateTime.isAfter(DateTime.now())).toList();
      if (upcoming.isNotEmpty) {
        final updated = PrayerTimesResult(
          prayers: prayer.prayers,
          next: upcoming.first,
          isFromCache: prayer.isFromCache,
          cachedAt: prayer.cachedAt,
          locationLabel: prayer.locationLabel,
        );
        if (mounted) setState(() => _prayer = updated);
        return;
      }
      _loadPrayer();
      return;
    }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (mounted) setState(() => _countdown = '$h:$m:$s');
  }

  void _applyAutoDarkModeIfEnabled(PrayerTimesResult prayer) {
    if (!appSettings.autoDarkModeAtMaghrib) return;
    PrayerItem? maghrib;
    PrayerItem? fajr;
    for (final p in prayer.prayers) {
      if (p.name == 'Maghrib') maghrib = p;
      if (p.name == 'Fajr') fajr = p;
    }
    if (maghrib == null || fajr == null) return;
    final now = DateTime.now();
    final isNight = now.isAfter(maghrib.dateTime) || now.isBefore(fajr.dateTime);
    if (_autoDarkAppliedState == isNight) return;
    _autoDarkAppliedState = isNight;
    appSettings.setThemeMode(isNight ? ThemeMode.dark : ThemeMode.light);
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.homeGreetingNight;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final wirdProgress = _wirdTarget == 0 ? 0.0 : (_pagesToday / _wirdTarget).clamp(0.0, 1.0);
    final now = DateTime.now();
    final hijri = HijriDate.fromGregorian(now);
    final gregorian = DateFormat('EEEE d MMMM y', languageCode).format(now);
    final moonAge = MoonCalculator.moonAgeDays(now);
    final moonImageAsset = MoonCalculator.phaseImageAsset(moonAge);
    final next = _prayer?.next;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 18,
        title: Row(children: [
          Container(width: 36,height:36,padding: const EdgeInsets.all(3),decoration: BoxDecoration(color: const Color(0xFFF7F4EA).withValues(alpha:.95),borderRadius: BorderRadius.circular(11)),child: Image.asset('assets/images/ui/wirdi_logo.png')),
          const SizedBox(width: 9),
          Text(l10n.appTitle,style:const TextStyle(fontWeight:FontWeight.w900)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Stack(children:[
        const Positioned.fill(child: WirdiBrandBackground(asset:'assets/images/ui/home_hero_v4.jpg',imageOpacity:.86,imageHeight:520,darken:true)),
        RefreshIndicator(
          onRefresh:_loadAll,
          child: ListView(padding: EdgeInsets.fromLTRB(0, 92, 0, 28 + MediaQuery.of(context).padding.bottom),children:[
            WirdiScenicHero(
              asset:'assets/images/ui/home_hero_v4.jpg',
              title:_greeting(l10n),
              subtitle:'${l10n.homeContinueToday}  •  ${hijri.toStringLocalized(languageCode)}',
              showLogo:true,
              height:205,
              trailing:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.black.withValues(alpha:.24),borderRadius:BorderRadius.circular(999)),child:Text(gregorian,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))),
            ),
            Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Column(children:[
              if (_streak>0 || _prayedCount>0) ...[
                WirdiGlassCard(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),child:Row(children:[
                  Icon(Icons.local_fire_department_rounded,color:AppColors.goldAccent),const SizedBox(width:8),
                  Expanded(child:Text(_streak>0?l10n.homeStreakDays(_streak):l10n.homeContinueToday,style:const TextStyle(fontWeight:FontWeight.w800))),
                  Text(l10n.homePrayersToday(_prayedCount,5),style:const TextStyle(color:AppColors.mutedText,fontSize:11,fontWeight:FontWeight.w700)),
                ])),
                const SizedBox(height:12),
              ],
              WirdiSectionTitle(title:l10n.homeQuickActions),
              const SizedBox(height:10),
              GridView.count(crossAxisCount:4,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:.86,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),children:[
                WirdiFeatureTile(icon:Icons.menu_book_outlined,label:l10n.navQuran,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QuranScreen())),highlighted:true),
                WirdiFeatureTile(icon:Icons.volunteer_activism_outlined,label:l10n.homeQuickAzkar,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AzkarScreen()))),
                WirdiFeatureTile(icon:Icons.access_time_rounded,label:l10n.homeQuickPrayer,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PrayerTimesScreen()))),
                WirdiFeatureTile(icon:Icons.explore_outlined,label:l10n.homeQuickQibla,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QiblaScreen()))),
              ]),
              const SizedBox(height:14),
              WirdiGlassCard(padding:EdgeInsets.zero,child:ClipRRect(borderRadius:BorderRadius.circular(22),child:Stack(children:[
                Image.asset('assets/images/ui/home_hero_v4.jpg',height:176,width:double.infinity,fit:BoxFit.cover),
                Container(height:176,decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,AppColors.darkBackground.withValues(alpha:.92)]))),
                Positioned(left:16,right:16,bottom:14,child:Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l10n.prayerNextPrayerLabel,style:const TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(next==null?'--':prayerDisplayName(l10n,next.name),style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),Text(next==null?'--:--':_countdown,style:TextStyle(color:AppColors.goldAccent,fontSize:15,fontWeight:FontWeight.w800))])),
                  if (_sunTimes!=null) Column(children:[const Icon(Icons.wb_twilight,color:Colors.white70,size:17),Text(_fmtSunTime(_sunTimes!.sunset),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11))]),
                ]),
              ]))),
              const SizedBox(height:14),
              Row(children:[
                Expanded(child:WirdiGlassCard(padding:const EdgeInsets.all(14),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QuranScreen(initialSurahNumber:null))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[const Icon(Icons.auto_stories_outlined,color:AppColors.primaryEmerald),const Spacer(),Text('${(_khatmaRatio*100).round()}%',style:const TextStyle(fontWeight:FontWeight.w900,color:AppColors.primaryEmerald))]),
                  const SizedBox(height:9),Text(l10n.homeContinueReading,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(_lastReading==null?l10n.homeNoLastReading:l10n.homeLastReadingSubtitle(_lastReading!['surahName'] as String? ?? '',_lastReading!['ayahNumber'] as int? ?? 0),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:AppColors.mutedText)),
                  const SizedBox(height:9),LinearProgressIndicator(value:_khatmaRatio,minHeight:5,borderRadius:BorderRadius.circular(99),color:AppColors.goldAccent,backgroundColor:AppColors.primaryEmerald.withValues(alpha:.10)),
                ]))),
                const SizedBox(width:10),
                Expanded(child:WirdiGlassCard(padding:const EdgeInsets.all(14),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MyWirdiScreen())),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[const Icon(Icons.favorite_border,color:AppColors.primaryEmerald),const Spacer(),Text('${(_myWirdiPercent*100).round()}%',style:const TextStyle(fontWeight:FontWeight.w900,color:AppColors.primaryEmerald))]),
                  const SizedBox(height:9),Text(l10n.homeMyWirdiCardTitle,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(l10n.homeWirdProgress(_pagesToday,_wirdTarget),style:const TextStyle(fontSize:11,color:AppColors.mutedText)),
                  const SizedBox(height:9),LinearProgressIndicator(value:_myWirdiPercent,minHeight:5,borderRadius:BorderRadius.circular(99),color:AppColors.primaryEmerald,backgroundColor:AppColors.primaryEmerald.withValues(alpha:.10)),
                ]))),
              ]),
              const SizedBox(height:14),
              WirdiGlassCard(padding:const EdgeInsets.all(15),child:Row(children:[
                ClipOval(child:Image.asset(moonImageAsset,width:48,height:48,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.nightlight_round,size:40))),
                const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(moonPhaseName,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(languageCode=='ar'?'أطوار القمر اليوم':'Today’s moon phase',style:const TextStyle(color:AppColors.mutedText,fontSize:11))])),
                const Icon(Icons.chevron_left,color:AppColors.mutedText),
              ])),
              if (_hadithOfToday!=null) ...[const SizedBox(height:14),WirdiGlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.auto_stories_rounded,color:AppColors.goldAccent),const SizedBox(width:8),Expanded(child:Text(l10n.homeHadithOfTheDay,style:const TextStyle(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>Share.share('${_hadithOfToday!.arabicText}\n\n${_hadithOfToday!.translatedText}'),icon:const Icon(Icons.share_outlined))]),const SizedBox(height:7),Text(_hadithOfToday!.translatedText.isNotEmpty?_hadithOfToday!.translatedText:_hadithOfToday!.arabicText,maxLines:4,overflow:TextOverflow.ellipsis,style:const TextStyle(height:1.45,fontSize:12.5))]))],
              const SizedBox(height:14),
              WirdiGlassCard(child:Row(children:[const Icon(Icons.format_quote,color:AppColors.primaryEmerald),const SizedBox(width:10),Expanded(child:Text(DailyQuotes.forToday().displayFor(languageCode),maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700,height:1.4)))])),
              const SizedBox(height:14),
              WirdiGlassCard(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>QuranScreen(initialSurahNumber:VerseOfTheDayService.forToday().surahNumber,initialAyah:VerseOfTheDayService.forToday().ayahNumber))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(languageCode=='ar'?'آية اليوم':'Verse of the Day',style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:7),Text(VerseOfTheDayService.forToday().arabicText,maxLines:3,overflow:TextOverflow.ellipsis,textAlign:TextAlign.right,style:const TextStyle(fontSize:15,height:1.6)),const SizedBox(height:5),Text('${VerseOfTheDayService.forToday().surahName} • ${VerseOfTheDayService.forToday().ayahNumber}',style:const TextStyle(color:AppColors.mutedText,fontSize:11))]),
              ),
            ])),
          ]),
        ),
      ]),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final int subtitleMaxLines;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.subtitleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryEmerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 3),
                    Text(subtitle, maxLines: subtitleMaxLines, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 14)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final double value;
  final AppLocalizations l10n;
  const _MiniProgress({required this.value, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l10n.homeCompletionPercent((value * 100).round()),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 4,
              backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(AppColors.goldAccent),
            ),
            Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  final List<DailyActivitySummary> summary;
  const _WeekSummaryCard({required this.summary});

  // summary[0] is always Saturday (see UserProgressService.last7DaysSummary),
  // so this list is used positionally, not via weekday lookup.
  static String _dayName(AppLocalizations l10n, int i) => [
        l10n.dayNameSat,
        l10n.dayNameSun,
        l10n.dayNameMon,
        l10n.dayNameTue,
        l10n.dayNameWed,
        l10n.dayNameThu,
        l10n.dayNameFri,
      ][i];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final pastOrTodayDays = summary.where((d) => !d.date.isAfter(todayOnly)).toList();
    final activeDays = pastOrTodayDays.where((d) => d.hasAnyActivity).length;
    final targetMetDays = pastOrTodayDays.where((d) => d.wirdTargetMet).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.homeThisWeek, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  l10n.homeActiveDaysOf(activeDays, pastOrTodayDays.length),
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(summary.length, (i) {
                final day = summary[i];
                final isFuture = day.date.isAfter(todayOnly);
                final isToday = day.date.isAtSameMomentAs(todayOnly);
                final intensity = isFuture
                    ? 0.06
                    : (day.wirdTargetMet ? 1.0 : (day.hasAnyActivity ? 0.5 : 0.12));
                final dayName = _dayName(l10n, i);

                return Expanded(
                  child: Column(
                    children: [
                      Semantics(
                        label: isFuture
                            ? l10n.homeDayNotYet(dayName)
                            : l10n.homeDaySummary(dayName, day.wirdPages, day.azkarCompleted, day.tasbeehTotal, day.prayersDone),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryEmerald.withValues(alpha: intensity),
                            border: isToday ? Border.all(color: AppColors.goldAccent, width: 2) : null,
                          ),
                          alignment: Alignment.center,
                          child: (!isFuture && day.wirdTargetMet)
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isFuture ? AppColors.mutedText.withValues(alpha: 0.5) : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.homeWirdTargetMetSummary(targetMetDays, pastOrTodayDays.length),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosaicBg extends StatefulWidget {
  final int col; // 0-indexed, 0..4
  final int row; // 0-indexed, 0..1
  const _MosaicBg({required this.col, required this.row});

  @override
  State<_MosaicBg> createState() => _MosaicBgState();
}

class _MosaicBgState extends State<_MosaicBg> {
  static ui.Image? _cachedImage;
  ui.Image? _image;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    if (_cachedImage != null) {
      _image = _cachedImage;
    } else {
      final stream = const AssetImage('assets/images/wirdi_mosaic.png')
          .resolve(const ImageConfiguration());
      _listener = ImageStreamListener((info, _) {
        _cachedImage = info.image;
        if (mounted) setState(() => _image = info.image);
      });
      stream.addListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null)
            CustomPaint(painter: _MosaicCellPainter(image: img, col: widget.col, row: widget.row))
          else
            Container(color: const Color(0xFF0F766E)),
          Container(color: Colors.black.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

class _MosaicCellPainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  static const int cols = 5;
  static const int rows = 2;
  _MosaicCellPainter({required this.image, required this.col, required this.row});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / cols;
    final cellH = image.height / rows;
    final srcAspect = cellW / cellH;
    final dstAspect = size.width / size.height;
    Rect src;
    if (srcAspect > dstAspect) {
      final visW = cellH * dstAspect;
      final dx = (cellW - visW) / 2;
      src = Rect.fromLTWH(col * cellW + dx, row * cellH, visW, cellH);
    } else {
      final visH = cellW / dstAspect;
      final dy = (cellH - visH) / 2;
      src = Rect.fromLTWH(col * cellW, row * cellH + dy, cellW, visH);
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _MosaicCellPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.col != col || oldDelegate.row != row;
}
