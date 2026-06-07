import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Toggle states (UI-only for now) ────────────────────────────────────────
  bool _notifySpoiled = true;
  bool _notifyDanger = true;
  bool _notifyMissing = false;
  bool _darkMode = false;
  bool _autoRefresh = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          AppHeader(
            title: 'Settings',
            subtitle: 'Preferences & configuration',
            onRefresh: null,
            onNotification: null,
          ),

          // ── Body ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Profile card ─────────────────────────────────────────────
                _ProfileCard(),
                const SizedBox(height: 24),

                // ── Notifications section ────────────────────────────────────
                _SectionHeader(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _ToggleTile(
                      icon: Icons.warning_rounded,
                      iconBg: AppColors.spoiledBg,
                      iconColor: AppColors.spoiledColor,
                      title: 'Spoiled alerts',
                      subtitle: 'Notify when items expire',
                      value: _notifySpoiled,
                      onChanged: (v) => setState(() => _notifySpoiled = v),
                    ),
                    _Divider(),
                    _ToggleTile(
                      icon: Icons.access_time_rounded,
                      iconBg: AppColors.dangerBg,
                      iconColor: AppColors.dangerColor,
                      title: 'Expiry warnings',
                      subtitle: 'Notify before items expire',
                      value: _notifyDanger,
                      onChanged: (v) => setState(() => _notifyDanger = v),
                    ),
                    _Divider(),
                    _ToggleTile(
                      icon: Icons.search_rounded,
                      iconBg: const Color(0xFFFFF3CD),
                      iconColor: const Color(0xFFD97706),
                      title: 'Missing item alerts',
                      subtitle: 'Notify when items leave fridge',
                      value: _notifyMissing,
                      onChanged: (v) => setState(() => _notifyMissing = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Fridge section ───────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.kitchen_rounded,
                  label: 'Fridge',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _NavTile(
                      icon: Icons.thermostat_rounded,
                      iconBg: AppColors.goodBg,
                      iconColor: AppColors.goodColor,
                      title: 'Temperature unit',
                      subtitle: 'Celsius (°C)',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.wifi_rounded,
                      iconBg: AppColors.acceptBg,
                      iconColor: AppColors.acceptColor,
                      title: 'Sensor connection',
                      subtitle: '192.168.1.8 · Connected',
                      onTap: () {},
                    ),
                    _Divider(),
                    _ToggleTile(
                      icon: Icons.refresh_rounded,
                      iconBg: AppColors.surfaceAlt,
                      iconColor: AppColors.medium,
                      title: 'Auto-refresh data',
                      subtitle: 'Refresh every 5 minutes',
                      value: _autoRefresh,
                      onChanged: (v) => setState(() => _autoRefresh = v),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Appearance section ───────────────────────────────────────
                _SectionHeader(
                  icon: Icons.palette_rounded,
                  label: 'Appearance',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _ToggleTile(
                      icon: Icons.dark_mode_rounded,
                      iconBg: const Color(0xFFE8E8F0),
                      iconColor: const Color(0xFF5B5B8A),
                      title: 'Dark mode',
                      subtitle: 'Switch to dark theme',
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.language_rounded,
                      iconBg: AppColors.acceptBg,
                      iconColor: AppColors.acceptColor,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Data & Privacy section ───────────────────────────────────
                _SectionHeader(
                  icon: Icons.shield_rounded,
                  label: 'Data & Privacy',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _NavTile(
                      icon: Icons.download_rounded,
                      iconBg: AppColors.goodBg,
                      iconColor: AppColors.goodColor,
                      title: 'Export data',
                      subtitle: 'Download your fridge history',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.delete_outline_rounded,
                      iconBg: AppColors.spoiledBg,
                      iconColor: AppColors.spoiledColor,
                      title: 'Clear all data',
                      subtitle: 'Remove all stored items',
                      onTap: () => _showClearDataDialog(context),
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.privacy_tip_outlined,
                      iconBg: AppColors.surfaceAlt,
                      iconColor: AppColors.textMuted,
                      title: 'Privacy policy',
                      subtitle: 'View our privacy policy',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── About section ────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _NavTile(
                      icon: Icons.eco_rounded,
                      iconBg: AppColors.goodBg,
                      iconColor: AppColors.goodColor,
                      title: 'Recens',
                      subtitle: 'Version 1.0.0',
                      onTap: () {},
                      showChevron: false,
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.star_outline_rounded,
                      iconBg: const Color(0xFFFFF8DC),
                      iconColor: const Color(0xFFD4A853),
                      title: 'Rate the app',
                      subtitle: 'Let us know what you think',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavTile(
                      icon: Icons.mail_outline_rounded,
                      iconBg: AppColors.acceptBg,
                      iconColor: AppColors.acceptColor,
                      title: 'Contact support',
                      subtitle: 'Get help with the app',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── App signature ─────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.medium],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            size: 26, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recens',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Smart freshness · Zero waste',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear all data?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will permanently remove all stored fridge items and history. This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppColors.textSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.spoiledColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.medium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.person_rounded,
                size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Fridge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Recens · Smart Kitchen',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('Edit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.medium),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.medium,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 0.8, color: AppColors.divider),
        ),
      ],
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.pale,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _NavTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;

  const _IconBox(
      {required this.icon, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.border,
    );
  }
}