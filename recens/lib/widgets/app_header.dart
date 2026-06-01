import 'package:flutter/material.dart';
import '../theme.dart';

/// A unified gradient header used across all screens.
///
/// Parameters:
///   [title]       – main title shown centred
///   [subtitle]    – smaller line below title (optional)
///   [onRefresh]   – callback for the refresh icon (shown on the right)
///   [onNotification] – callback for the bell icon (shown on the left)
///   [expandedHeight] – collapsed + expanded height (default 130)
///   [bottomWidget]   – optional widget pinned below the gradient area
///   [bottomHeight]   – height of [bottomWidget] (needed for PreferredSize)
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onNotification;
  final double expandedHeight;
  final PreferredSizeWidget? bottomWidget;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onRefresh,
    this.onNotification,
    this.expandedHeight = 130,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeaderBackground(
          title: title,
          subtitle: subtitle,
          onRefresh: onRefresh,
          onNotification: onNotification,
        ),
      ),
      bottom: bottomWidget,
    );
  }
}

// ── Gradient background with centred title ────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onNotification;

  const _HeaderBackground({
    required this.title,
    this.subtitle,
    this.onRefresh,
    this.onNotification,
  });

  @override
 @override
Widget build(BuildContext context) {
  final topPad = MediaQuery.of(context).padding.top;
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.medium],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                onTap: onNotification,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OrnamentalDivider(),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _OrnamentalDivider(),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: onRefresh,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

// ── Small rounded icon button ─────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// ── Thin ornamental divider with centre dot ───────────────────────────────────
class _OrnamentalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 32, height: 0.8, color: Colors.white38),
        const SizedBox(width: 6),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white38,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(width: 32, height: 0.8, color: Colors.white38),
      ],
    );
  }
}