import 'package:flutter/material.dart';
import '../theme.dart';

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor)),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSub,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Freshness Bar ─────────────────────────────────────────────────────────────
class FreshnessBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;

  const FreshnessBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: height,
        backgroundColor: AppColors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ── Card Container ────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final double size;

  const IconBox({
    super.key,
    required this.icon,
    this.bg = AppColors.surfaceAlt,
    this.iconColor = AppColors.medium,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: size * 0.52, color: iconColor),
    );
  }
}
