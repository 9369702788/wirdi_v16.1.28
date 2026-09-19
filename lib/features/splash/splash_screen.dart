import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Screen 1 — Splash: "إعطاء إحساس روحاني فاخر عند بداية التطبيق"
/// Gradient Emerald/Gold, fade + light sweep, ~2s display.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/splash_hero_v4.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackground.withValues(alpha: 0.30),
                  AppColors.darkBackground.withValues(alpha: 0.84),
                ],
              ),
            ),
          ),
          Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 124,
                  height: 124,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: AppColors.goldAccent, width: 1.6),
                    boxShadow: [BoxShadow(color: AppColors.goldAccent.withValues(alpha: 0.18), blurRadius: 26)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: Image.asset('assets/images/ui/wirdi_logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aboutTagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
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
