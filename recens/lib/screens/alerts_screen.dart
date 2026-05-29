import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/notification_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
enum AlertType { good, acceptable, danger, spoiled }

class AlertItem {
  final String title;
  final String description;
  final String time;
  final AlertType type;

  const AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    AlertType t;
    switch ((json['type'] ?? '').toLowerCase()) {
      case 'spoiled':
        t = AlertType.spoiled;
        break;
      case 'danger':
        t = AlertType.danger;
        break;
      case 'acceptable':
        t = AlertType.acceptable;
        break;
      case 'good':
        t = AlertType.good;
        break;
      default:
        t = AlertType.acceptable;
    }
    return AlertItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      type: t,
    );
  }

  Color get borderColor {
    switch (type) {
      case AlertType.good:
        return AppColors.goodColor;
      case AlertType.acceptable:
        return AppColors.acceptColor;
      case AlertType.danger:
        return AppColors.dangerColor;
      case AlertType.spoiled:
        return AppColors.spoiledColor;
    }
  }

  Color get bgColor {
    switch (type) {
      case AlertType.good:
        return AppColors.goodBg;
      case AlertType.acceptable:
        return AppColors.acceptBg;
      case AlertType.danger:
        return AppColors.dangerBg;
      case AlertType.spoiled:
        return AppColors.spoiledBg;
    }
  }

  Color get iconBg {
    switch (type) {
      case AlertType.good:
        return const Color(0xFFBFEDD4);
      case AlertType.acceptable:
        return const Color(0xFFBFDDE5);
      case AlertType.danger:
        return const Color(0xFFFFE5A0);
      case AlertType.spoiled:
        return const Color(0xFFC8D2E8);
    }
  }

  Color get iconColor {
    switch (type) {
      case AlertType.good:
        return AppColors.goodColor;
      case AlertType.acceptable:
        return AppColors.acceptColor;
      case AlertType.danger:
        return AppColors.dangerColor;
      case AlertType.spoiled:
        return AppColors.spoiledColor;
    }
  }

  Color get titleColor {
    switch (type) {
      case AlertType.good:
        return AppColors.goodText;
      case AlertType.acceptable:
        return AppColors.acceptText;
      case AlertType.danger:
        return AppColors.dangerText;
      case AlertType.spoiled:
        return AppColors.spoiledText;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.good:
        return Icons.check_circle_rounded;
      case AlertType.acceptable:
        return Icons.info_outline_rounded;
      case AlertType.danger:
        return Icons.access_time_rounded;
      case AlertType.spoiled:
        return Icons.warning_rounded;
    }
  }
}

// ── Filter Tab Model ──────────────────────────────────────────────────────────
enum _Filter { all, good, acceptable, danger, spoiled }

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'All';
      case _Filter.good:
        return 'Good';
      case _Filter.acceptable:
        return 'Acceptable';
      case _Filter.danger:
        return 'Danger';
      case _Filter.spoiled:
        return 'Spoiled';
    }
  }

  Color get activeBg {
    switch (this) {
      case _Filter.all:
        return AppColors.primary;
      case _Filter.good:
        return AppColors.goodColor;
      case _Filter.acceptable:
        return AppColors.acceptColor;
      case _Filter.danger:
        return AppColors.dangerColor;
      case _Filter.spoiled:
        return AppColors.spoiledColor;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  List<AlertItem> _alerts = [];
  bool _loading = true;
  String? _error;
  _Filter _activeFilter = _Filter.all;

  static const int _fridgeTemp = 4;
  static const int _fridgeHumidity = 72;

  String get _apiUrl => kIsWeb
    ? 'http://localhost:8080/get_alerts'
    : 'http://192.168.1.8:8080/get_alerts';

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _alerts = data.map((j) => AlertItem.fromJson(j)).toList();
          _loading = false;
        });

        final spoiledItems =
            _alerts.where((a) => a.type == AlertType.spoiled).toList();
        final dangerItems =
            _alerts.where((a) => a.type == AlertType.danger).toList();

        if (spoiledItems.isNotEmpty) {
          await NotificationService.showNotification(
            id: 1,
            title: '🚨 Spoiled Items in Your Fridge',
            body:
                '${spoiledItems.length} item${spoiledItems.length == 1 ? '' : 's'} spoiled. Remove them immediately!',
          );
        }

        if (dangerItems.isNotEmpty) {
          await NotificationService.showNotification(
            id: 2,
            title: '⚠️ Items Expiring Soon',
            body:
                '${dangerItems.length} item${dangerItems.length == 1 ? '' : 's'} will expire soon. Use them now!',
          );
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not reach server.\n$e';
        _loading = false;
      });
    }
  }

  List<AlertItem> get _filteredAlerts {
    if (_activeFilter == _Filter.all) return _alerts;
    return _alerts.where((a) {
      switch (_activeFilter) {
        case _Filter.good:
          return a.type == AlertType.good;
        case _Filter.acceptable:
          return a.type == AlertType.acceptable;
        case _Filter.danger:
          return a.type == AlertType.danger;
        case _Filter.spoiled:
          return a.type == AlertType.spoiled;
        case _Filter.all:
          return true;
      }
    }).toList();
  }

  int _countOf(AlertType type) =>
      _alerts.where((a) => a.type == type).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAlerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (_alerts.isNotEmpty)
                  Text('${_alerts.length}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSub)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    NotificationService.showNotification(
                      id: 0,
                      title: '🧊 Fridge Check Reminder',
                      body:
                          'Time to check your fridge! Some items may need attention.',
                    );
                  },
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.textSub),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _fetchAlerts,
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSub),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetchAlerts)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FridgeStatusCard(
                              temp: _fridgeTemp,
                              humidity: _fridgeHumidity,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                _CountCard(
                                  count: _countOf(AlertType.good),
                                  label: 'Good',
                                  bg: AppColors.goodBg,
                                  numColor: AppColors.goodText,
                                  lblColor: const Color(0xFF1A5E35),
                                  onTap: () => setState(
                                      () => _activeFilter = _Filter.good),
                                  isActive: _activeFilter == _Filter.good,
                                  activeColor: AppColors.goodColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count: _countOf(AlertType.acceptable),
                                  label: 'Accept.',
                                  bg: AppColors.acceptBg,
                                  numColor: AppColors.acceptText,
                                  lblColor: const Color(0xFF005A6B),
                                  onTap: () => setState(
                                      () => _activeFilter = _Filter.acceptable),
                                  isActive: _activeFilter == _Filter.acceptable,
                                  activeColor: AppColors.acceptColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count: _countOf(AlertType.danger),
                                  label: 'Danger',
                                  bg: AppColors.dangerBg,
                                  numColor: AppColors.dangerText,
                                  lblColor: const Color(0xFF7A5000),
                                  onTap: () => setState(
                                      () => _activeFilter = _Filter.danger),
                                  isActive: _activeFilter == _Filter.danger,
                                  activeColor: AppColors.dangerColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count: _countOf(AlertType.spoiled),
                                  label: 'Spoiled',
                                  bg: AppColors.spoiledBg,
                                  numColor: AppColors.spoiledText,
                                  lblColor: const Color(0xFF2A3E7A),
                                  onTap: () => setState(
                                      () => _activeFilter = _Filter.spoiled),
                                  isActive: _activeFilter == _Filter.spoiled,
                                  activeColor: AppColors.spoiledColor,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _FilterBar(
                              active: _activeFilter,
                              onSelect: (f) =>
                                  setState(() => _activeFilter = f),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Text(
                                  _activeFilter == _Filter.all
                                      ? 'All alerts'
                                      : '${_activeFilter.label} alerts',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${filtered.length})',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    filtered.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 44,
                                        color: AppColors.textMuted
                                            .withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _activeFilter == _Filter.all
                                          ? 'No alerts — everything looks fresh!'
                                          : 'No ${_activeFilter.label.toLowerCase()} alerts',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSub),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _AlertCard(alert: filtered[i]),
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }
}

// ── Fridge Status Card ────────────────────────────────────────────────────────
class _FridgeStatusCard extends StatelessWidget {
  final int temp;
  final int humidity;
  const _FridgeStatusCard({required this.temp, required this.humidity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4A2A), Color(0xFF1A7A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _FridgeIllustration(temp: temp),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fridge Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.thermostat_rounded,
                      value: '$temp°C',
                      label: 'Temp',
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
                      icon: Icons.water_drop_outlined,
                      value: '$humidity%',
                      label: 'Humidity',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6EE0A0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online · Normal range',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatPill(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Fridge Illustration ───────────────────────────────────────────────────────
class _FridgeIllustration extends StatelessWidget {
  final int temp;
  const _FridgeIllustration({required this.temp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ac_unit_rounded,
                    size: 12, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shelf(),
                  const SizedBox(height: 4),
                  _shelf(),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 16,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shelf() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withOpacity(0.25),
      );
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _Filter active;
  final void Function(_Filter) onSelect;
  const _FilterBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Filter.values.map((f) {
          final isActive = f == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? f.activeBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? f.activeBg : AppColors.border,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: f.activeBg.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? Colors.white : AppColors.textSub,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSub)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count Card ────────────────────────────────────────────────────────────────
class _CountCard extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color numColor;
  final Color lblColor;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _CountCard({
    required this.count,
    required this.label,
    required this.bg,
    required this.numColor,
    required this.lblColor,
    required this.onTap,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : numColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive
                      ? Colors.white.withOpacity(0.85)
                      : lblColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.bgColor,
        borderRadius: BorderRadius.circular(14),
        border:
            Border(left: BorderSide(color: alert.borderColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: alert.iconBg,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(alert.icon, size: 18, color: alert.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: alert.titleColor)),
                const SizedBox(height: 3),
                Text(alert.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                        height: 1.4)),
                const SizedBox(height: 5),
                Text(alert.time,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}