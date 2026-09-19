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
    this.imageOpacity = 0.68,
    this.imageHeight = 440,
    this.darken = false,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    // The supplied screens historically passed very small opacities (0.08–0.18).
    // That made the identity effectively invisible on real devices. V3 deliberately
    // enforces a readable scenic floor while keeping the content layer dominant.
    final scenicOpacity = imageOpacity.clamp(0.52, 0.88).toDouble();
    final height = imageHeight < 400 ? 440.0 : imageHeight;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: bg),
        if (asset != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: IgnorePointer(
              child: Image.asset(asset!, fit: BoxFit.cover, alignment: alignment),
            ),
          ),
        if (asset != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height + 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (darken ? AppColors.darkBackground : AppColors.darkBackground)
                          .withValues(alpha: 0.18),
                      AppColors.darkBackground.withValues(alpha: 0.10),
                      bg.withValues(alpha: 0.35),
                      bg,
                    ],
                    stops: const [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
        if (asset != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: IgnorePointer(
              child: ColoredBox(color: AppColors.darkBackground.withValues(alpha: (1 - scenicOpacity) * 0.35)),
            ),
          ),
        child,
      ],
    );
  }
}

class WirdiAppBarBackground extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  const WirdiAppBarBackground({super.key, required this.asset, this.alignment = Alignment.topCenter});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover, alignment: alignment),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkBackground.withValues(alpha: 0.28),
                AppColors.darkBackground.withValues(alpha: 0.78),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class WirdiScenicHero extends StatelessWidget {
  final String asset;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final bool showLogo;
  const WirdiScenicHero({
    super.key,
    required this.asset,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.height = 190,
    this.showLogo = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: .55)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .14), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(asset, fit: BoxFit.cover),
        DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,
            colors: [AppColors.darkBackground.withValues(alpha:.05), AppColors.darkBackground.withValues(alpha:.34), AppColors.darkBackground.withValues(alpha:.90)]),
          ),),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            Row(children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 10),
              if (showLogo) Container(width: 46,height:46,padding: const EdgeInsets.all(4),decoration: BoxDecoration(color: const Color(0xFFF7F4EA).withValues(alpha:.96),borderRadius: BorderRadius.circular(14)),child: Image.asset('assets/images/ui/wirdi_logo.png')),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
            const Spacer(),
            Text(title, textAlign: TextAlign.start, style: const TextStyle(color: Colors.white,fontSize: 24,fontWeight: FontWeight.w900,height:1.05)),
            if (subtitle != null) ...[const SizedBox(height:6),Text(subtitle!,style: const TextStyle(color: Colors.white70,fontSize:12.5,fontWeight:FontWeight.w600))],
            const SizedBox(height:10),
            Container(width:74,height:3,decoration:BoxDecoration(color:AppColors.goldAccent,borderRadius:BorderRadius.circular(99))),
          ]),
        ),
      ]),
    );
  }
}

class WirdiPill extends StatelessWidget {
  final String label; final bool selected; final VoidCallback? onTap; final IconData? icon;
  const WirdiPill({super.key,required this.label,this.selected=false,this.onTap,this.icon});
  @override Widget build(BuildContext context)=>Material(color:selected?AppColors.primaryEmerald:Colors.white.withValues(alpha:.90),borderRadius:BorderRadius.circular(999),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(999),child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:9),child:Row(mainAxisSize:MainAxisSize.min,children:[if(icon!=null) ...[Icon(icon,size:16,color:selected?Colors.white:AppColors.primaryEmerald),const SizedBox(width:5)],Text(label,style:TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:selected?Colors.white:AppColors.primaryEmerald))]))));
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
    final border = AppColors.goldAccent.withValues(alpha: 0.24);
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
  final bool useGoldAccent;

  const WirdiFeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.useGoldAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryEmerald;
    final accentColor = useGoldAccent ? AppColors.goldAccent : primary;
    final fgOnHighlight = useGoldAccent ? AppColors.darkBackground : Colors.white;
    return Material(
      color: highlighted ? accentColor : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldAccent.withValues(alpha: highlighted ? 0.0 : 0.18)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: highlighted ? fgOnHighlight : primary, size: 27),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? fgOnHighlight : null,
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
      height: 238,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.55), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(backgroundAsset, fit: BoxFit.cover, alignment: Alignment.center),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackground.withValues(alpha: 0.08),
                  AppColors.darkBackground.withValues(alpha: 0.50),
                  AppColors.darkBackground.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F6).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.goldAccent, width: 1.4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 14)],
                    ),
                    child: Image.asset('assets/images/ui/wirdi_logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 10),
                  Container(width: 92, height: 2, decoration: BoxDecoration(color: AppColors.goldAccent, borderRadius: BorderRadius.circular(99))),
                ],
              ),
            ),
          ),
          if (onTap != null)
            const PositionedDirectional(
              top: 14,
              end: 14,
              child: CircleAvatar(backgroundColor: Color(0x33111111), radius: 19, child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)),
            ),
        ],
      ),
    );
    return onTap == null ? content : GestureDetector(onTap: onTap, child: content);
  }
}

