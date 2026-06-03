import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/report_screen.dart';
/// A simple fixed gradient header — title + two icon buttons only.
/// Nothing is pinned below it; screens render extra controls as sliver content.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onNotification;

  // Kept for API compatibility — ignored.
  final double expandedHeight;
  final PreferredSizeWidget? bottomWidget; // ignored — moved to screen body

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
    const double toolbarH = 80.0;

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: toolbarH,
      toolbarHeight: toolbarH,
      backgroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: _HeaderBackground(
          title: title,
          subtitle: subtitle,
          onNotification: onNotification,
        ),
      ),
    );
  }
}

// ── Gradient background ───────────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onNotification;

  const _HeaderBackground({
    required this.title,
    this.subtitle,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                icon: Icons.bar_chart_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  );
                },
              ),
            ],
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