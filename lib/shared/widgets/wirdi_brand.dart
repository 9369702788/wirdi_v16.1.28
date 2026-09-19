import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable visual-identity primitives for Wirdi 2.0.
/// Keeps the brand treatment consistent without changing feature logic.
class WirdiBrandBackground extends StatelessWidget {
  final Widget child;
  final String? asset;
  final double imageOpacity;
  final double imageHeight;
  final bool darken;
  final Alignment alignment;

  const WirdiBrandBackground({
    super.key,
    this.child = const SizedBox.shrink(),
    this.asset,
    this.imageOpacity = 0.18,
    this.imageHeight = 330,
    this.darken = false,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: bg),
        if (asset != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: imageOpacity,
                child: Image.asset(asset!, fit: BoxFit.cover, alignment: alignment),
              ),
            ),
          ),
        if (asset != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight + 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      darken
                          ? AppColors.darkBackground.withValues(alpha: 0.35)
                          : Colors.transparent,
                      bg.withValues(alpha: 0.18),
                      bg,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class WirdiGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final bool outlined;

  const WirdiGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 22,
    this.color,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final surface = color ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.94);
    final border = AppColors.primaryEmerald.withValues(alpha: 0.10);
    final card = Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: outlined ? Border.all(color: border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    return onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: card,
            ),
          );
  }
}

class WirdiSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const WirdiSectionTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class WirdiFeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const WirdiFeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryEmerald;
    return Material(
      color: highlighted ? primary : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: highlighted ? 0.0 : 0.10)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: highlighted ? Colors.white : primary, size: 27),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WirdiBrandHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String backgroundAsset;
  final VoidCallback? onTap;

  const WirdiBrandHero({
    super.key,
    required this.title,
    this.subtitle,
    required this.backgroundAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.13), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(backgroundAsset, fit: BoxFit.cover, alignment: Alignment.center),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.darkBackground.withValues(alpha: 0.16),
                  AppColors.darkBackground.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.75), width: 1.2),
                        ),
                        child: Image.asset('assets/images/ui/wirdi_logo.png', fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return onTap == null ? content : GestureDetector(onTap: onTap, child: content);
  }
}
