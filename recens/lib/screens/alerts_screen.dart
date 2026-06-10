import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/notification_service.dart';
import '../widgets/app_header.dart';
import '../config/api_config.dart';

// ── Status Alert Model ────────────────────────────────────────────────────────
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
      title:       json['title']       ?? '',
      description: json['description'] ?? '',
      time:        json['time']        ?? '',
      type:        t,
    );
  }

  Color get borderColor {
    switch (type) {
      case AlertType.good:       return AppColors.goodColor;
      case AlertType.acceptable: return AppColors.acceptColor;
      case AlertType.danger:     return AppColors.dangerColor;
      case AlertType.spoiled:    return AppColors.spoiledColor;
    }
  }

  Color get bgColor {
    switch (type) {
      case AlertType.good:       return AppColors.goodBg;
      case AlertType.acceptable: return AppColors.acceptBg;
      case AlertType.danger:     return AppColors.dangerBg;
      case AlertType.spoiled:    return AppColors.spoiledBg;
    }
  }

  Color get iconBg {
    switch (type) {
      case AlertType.good:       return const Color(0xFFBFEDD4);
      case AlertType.acceptable: return const Color(0xFFBFDDE5);
      case AlertType.danger:     return const Color(0xFFFFE5A0);
      case AlertType.spoiled:    return const Color(0xFFC8D2E8);
    }
  }

  Color get iconColor {
    switch (type) {
      case AlertType.good:       return AppColors.goodColor;
      case AlertType.acceptable: return AppColors.acceptColor;
      case AlertType.danger:     return AppColors.dangerColor;
      case AlertType.spoiled:    return AppColors.spoiledColor;
    }
  }

  Color get titleColor {
    switch (type) {
      case AlertType.good:       return AppColors.goodText;
      case AlertType.acceptable: return AppColors.acceptText;
      case AlertType.danger:     return AppColors.dangerText;
      case AlertType.spoiled:    return AppColors.spoiledText;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.good:       return Icons.check_circle_rounded;
      case AlertType.acceptable: return Icons.info_outline_rounded;
      case AlertType.danger:     return Icons.access_time_rounded;
      case AlertType.spoiled:    return Icons.warning_rounded;
    }
  }
}

// ── Incompatible Item Model ───────────────────────────────────────────────────
class IncompatibleItem {
  final String id;
  final String itemA;
  final String itemB;
  final String title;
  final String description;
  final String detectedAt;

  const IncompatibleItem({
    required this.id,
    required this.itemA,
    required this.itemB,
    required this.title,
    required this.description,
    required this.detectedAt,
  });

  factory IncompatibleItem.fromJson(Map<String, dynamic> json) {
    return IncompatibleItem(
      id:          json['id']?.toString()          ?? '',
      itemA:       json['item_a']?.toString()       ?? '',
      itemB:       json['item_b']?.toString()       ?? '',
      title:       json['title']?.toString()        ?? '',
      description: json['description']?.toString()  ?? '',
      detectedAt:  json['detected_at']?.toString()  ?? '',
    );
  }
}

// ── Missing Item Model ────────────────────────────────────────────────────────
class MissingItem {
  final int    id;
  final String itemName;
  final int    minutesOut;
  final int    alertLevel;
  final String message;

  const MissingItem({
    required this.id,
    required this.itemName,
    required this.minutesOut,
    required this.alertLevel,
    required this.message,
  });

  factory MissingItem.fromJson(Map<String, dynamic> json) {
    return MissingItem(
      id:         int.tryParse(json['id']?.toString()          ?? '0') ?? 0,
      itemName:   json['item_name']?.toString()                         ?? '',
      minutesOut: int.tryParse(json['minutes_out']?.toString() ?? '0') ?? 0,
      alertLevel: int.tryParse(json['alert_level']?.toString() ?? '1') ?? 1,
      message:    json['message']?.toString()                           ?? '',
    );
  }

  String get durationLabel {
    if (minutesOut < 60) return '$minutesOut min';
    final h = minutesOut ~/ 60;
    final m = minutesOut % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Color get urgencyColor {
    switch (alertLevel) {
      case 3:  return const Color(0xFFB03A2E);
      case 2:  return const Color(0xFFD97706);
      default: return const Color(0xFF2E86C1);
    }
  }

  String get urgencyLabel {
    switch (alertLevel) {
      case 3:  return 'Critical';
      case 2:  return 'Warning';
      default: return 'Info';
    }
  }
}

// ── Response type for missing items ──────────────────────────────────────────
enum _MissingResponse { willBeReturned, returned, finished }

// ── Filter Tab ────────────────────────────────────────────────────────────────
enum _Filter { all, good, acceptable, danger, spoiled }

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:        return 'All';
      case _Filter.good:       return 'Good';
      case _Filter.acceptable: return 'Acceptable';
      case _Filter.danger:     return 'Danger';
      case _Filter.spoiled:    return 'Spoiled';
    }
  }

  Color get activeBg {
    switch (this) {
      case _Filter.all:        return AppColors.primary;
      case _Filter.good:       return AppColors.goodColor;
      case _Filter.acceptable: return AppColors.acceptColor;
      case _Filter.danger:     return AppColors.dangerColor;
      case _Filter.spoiled:    return AppColors.spoiledColor;
    }
  }
}

// ── Alert View Mode ───────────────────────────────────────────────────────────
enum _AlertMode { status, missing, incompatible }

// ── Screen ────────────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  // Status alerts state
  List<AlertItem> _alerts        = [];
  bool            _loadingAlerts = true;
  String?         _alertsError;
  _Filter         _activeFilter  = _Filter.all;

  // Missing items state
  List<MissingItem> _missingItems   = [];
  bool              _loadingMissing = true;
  String?           _missingError;
  final Set<int>    _respondingIds  = {};

  // Incompatible items state
  List<IncompatibleItem> _incompatibleItems   = [];
  bool                   _loadingIncompatible = true;
  String?                _incompatibleError;

  // View mode
  _AlertMode _mode = _AlertMode.status;

  static const int _fridgeTemp     = 4;
  static const int _fridgeHumidity = 72;

  String get _alertsUrl       => ApiConfig.alerts;
  String get _missingUrl      => ApiConfig.missingItems;
  String get _responseUrl     => ApiConfig.setResponse;
  String get _incompatibleUrl => ApiConfig.incompatible;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _fetchMissingItems();
    _fetchIncompatibleItems();
  }

  // ── Fetch status alerts ───────────────────────────────────────────────────
  Future<void> _fetchAlerts() async {
    setState(() { _loadingAlerts = true; _alertsError = null; });
    try {
      final response = await http
          .get(Uri.parse(_alertsUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _alerts        = data.map((j) => AlertItem.fromJson(j)).toList();
          _loadingAlerts = false;
        });

        final spoiledItems = _alerts.where((a) => a.type == AlertType.spoiled).toList();
        final dangerItems  = _alerts.where((a) => a.type == AlertType.danger).toList();

        if (spoiledItems.isNotEmpty) {
          await NotificationService.showNotification(
            id:    1,
            title: '🚨 Spoiled Items in Your Fridge',
            body:  '${spoiledItems.length} item${spoiledItems.length == 1 ? '' : 's'} spoiled. Remove them immediately!',
          );
        }
        if (dangerItems.isNotEmpty) {
          await NotificationService.showNotification(
            id:    2,
            title: '⚠️ Items Expiring Soon',
            body:  '${dangerItems.length} item${dangerItems.length == 1 ? '' : 's'} will expire soon. Use them now!',
          );
        }
      } else {
        setState(() { _alertsError = 'Server error: ${response.statusCode}'; _loadingAlerts = false; });
      }
    } catch (e) {
      setState(() { _alertsError = 'Could not reach server.\n$e'; _loadingAlerts = false; });
    }
  }

  // ── Fetch missing items ───────────────────────────────────────────────────
  Future<void> _fetchMissingItems() async {
    setState(() { _loadingMissing = true; _missingError = null; });
    try {
      final response = await http
          .get(Uri.parse(_missingUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _missingItems   = data.map((j) => MissingItem.fromJson(j)).toList();
          _loadingMissing = false;
        });
      } else {
        setState(() { _missingError = 'Server error: ${response.statusCode}'; _loadingMissing = false; });
      }
    } catch (e) {
      setState(() { _missingError = 'Could not reach server.\n$e'; _loadingMissing = false; });
    }
  }

  // ── Fetch incompatible items ──────────────────────────────────────────────
  Future<void> _fetchIncompatibleItems() async {
    setState(() { _loadingIncompatible = true; _incompatibleError = null; });
    try {
      final response = await http
          .get(Uri.parse(_incompatibleUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _incompatibleItems   = data.map((j) => IncompatibleItem.fromJson(j)).toList();
          _loadingIncompatible = false;
        });

        if (_incompatibleItems.isNotEmpty) {
          await NotificationService.showNotification(
            id:    3,
            title: '⚡ Incompatible Items Detected',
            body:  '${_incompatibleItems.length} pair${_incompatibleItems.length == 1 ? '' : 's'} of items should not be stored together.',
          );
        }
      } else {
        setState(() { _incompatibleError = 'Server error: ${response.statusCode}'; _loadingIncompatible = false; });
      }
    } catch (e) {
      setState(() { _incompatibleError = 'Could not reach server.\n$e'; _loadingIncompatible = false; });
    }
  }

  // ── Respond to a missing item ─────────────────────────────────────────────
  Future<void> _respondToItem(MissingItem item, _MissingResponse response) async {
    // ── Will Be Returned: dismiss card locally, no server call ────────────
    if (response == _MissingResponse.willBeReturned) {
      setState(() => _missingItems.removeWhere((i) => i.id == item.id));
      return;
    }

    // ── Returned / Finished: call server then remove card ─────────────────
    setState(() => _respondingIds.add(item.id));

    try {
      final responseStr = response == _MissingResponse.returned ? 'returned' : 'finished';

      final res = await http
          .post(
            Uri.parse(_responseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': item.id, 'user_response': responseStr}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        setState(() {
          // Remove all cards for the same item name (since backend clears all)
          _missingItems.removeWhere((i) => i.itemName == item.itemName);
          _respondingIds.remove(item.id);
        });
      } else {
        setState(() => _respondingIds.remove(item.id));
        _showSnack('Failed to update. Please try again.');
      }
    } catch (e) {
      setState(() => _respondingIds.remove(item.id));
      _showSnack('Connection error. Please try again.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<AlertItem> get _filteredAlerts {
    if (_activeFilter == _Filter.all) return _alerts;
    return _alerts.where((a) {
      switch (_activeFilter) {
        case _Filter.good:       return a.type == AlertType.good;
        case _Filter.acceptable: return a.type == AlertType.acceptable;
        case _Filter.danger:     return a.type == AlertType.danger;
        case _Filter.spoiled:    return a.type == AlertType.spoiled;
        case _Filter.all:        return true;
      }
    }).toList();
  }

  int _countOf(AlertType type) => _alerts.where((a) => a.type == type).length;

  void _onRefresh() {
    _fetchAlerts();
    _fetchMissingItems();
    _fetchIncompatibleItems();
  }

  void _onNotification() {
    NotificationService.showNotification(
      id:    0,
      title: '🧊 Fridge Check Reminder',
      body:  'Time to check your fridge! Some items may need attention.',
    );
  }

  String? _buildSubtitle() {
    switch (_mode) {
      case _AlertMode.status:
        return _alerts.isEmpty ? null : '${_alerts.length} active alert${_alerts.length == 1 ? '' : 's'}';
      case _AlertMode.missing:
        return _missingItems.isEmpty ? null : '${_missingItems.length} item${_missingItems.length == 1 ? '' : 's'} need attention';
      case _AlertMode.incompatible:
        return _incompatibleItems.isEmpty ? null : '${_incompatibleItems.length} incompatible pair${_incompatibleItems.length == 1 ? '' : 's'}';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoadingAll =
        _loadingAlerts && _loadingMissing && _loadingIncompatible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoadingAll
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                AppHeader(
                  title:          'Alerts',
                  subtitle:       _buildSubtitle(),
                  onRefresh:      _onRefresh,
                  onNotification: _onNotification,
                ),

                // ── Static top section ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FridgeStatusCard(
                          temp:     _fridgeTemp,
                          humidity: _fridgeHumidity,
                        ),
                        const SizedBox(height: 16),
                        _ModeToggle(
                          mode:              _mode,
                          statusCount:       _alerts.length,
                          missingCount:      _missingItems.length,
                          incompatibleCount: _incompatibleItems.length,
                          onSelect: (m) => setState(() => _mode = m),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Status Alerts Section ────────────────────────────────────
                if (_mode == _AlertMode.status) ...[
                  if (_loadingAlerts)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child:   Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_alertsError != null)
                    SliverToBoxAdapter(
                      child: _ErrorView(
                          message: _alertsError!, onRetry: _fetchAlerts),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _CountCard(
                                  count:       _countOf(AlertType.good),
                                  label:       'Good',
                                  bg:          AppColors.goodBg,
                                  numColor:    AppColors.goodText,
                                  lblColor:    const Color(0xFF1A5E35),
                                  onTap:       () => setState(() => _activeFilter = _Filter.good),
                                  isActive:    _activeFilter == _Filter.good,
                                  activeColor: AppColors.goodColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count:       _countOf(AlertType.acceptable),
                                  label:       'Accept.',
                                  bg:          AppColors.acceptBg,
                                  numColor:    AppColors.acceptText,
                                  lblColor:    const Color(0xFF005A6B),
                                  onTap:       () => setState(() => _activeFilter = _Filter.acceptable),
                                  isActive:    _activeFilter == _Filter.acceptable,
                                  activeColor: AppColors.acceptColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count:       _countOf(AlertType.danger),
                                  label:       'Danger',
                                  bg:          AppColors.dangerBg,
                                  numColor:    AppColors.dangerText,
                                  lblColor:    const Color(0xFF7A5000),
                                  onTap:       () => setState(() => _activeFilter = _Filter.danger),
                                  isActive:    _activeFilter == _Filter.danger,
                                  activeColor: AppColors.dangerColor,
                                ),
                                const SizedBox(width: 8),
                                _CountCard(
                                  count:       _countOf(AlertType.spoiled),
                                  label:       'Spoiled',
                                  bg:          AppColors.spoiledBg,
                                  numColor:    AppColors.spoiledText,
                                  lblColor:    const Color(0xFF2A3E7A),
                                  onTap:       () => setState(() => _activeFilter = _Filter.spoiled),
                                  isActive:    _activeFilter == _Filter.spoiled,
                                  activeColor: AppColors.spoiledColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _FilterBar(
                              active:   _activeFilter,
                              onSelect: (f) => setState(() => _activeFilter = f),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  _activeFilter == _Filter.all
                                      ? 'All alerts'
                                      : '${_activeFilter.label} alerts',
                                  style: const TextStyle(
                                    fontSize:      11,
                                    fontWeight:    FontWeight.w600,
                                    color:         AppColors.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${_filteredAlerts.length})',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:    AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    _filteredAlerts.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size:  44,
                                        color: AppColors.textMuted.withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _activeFilter == _Filter.all
                                          ? 'No alerts — everything looks fresh!'
                                          : 'No ${_activeFilter.label.toLowerCase()} alerts',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color:    AppColors.textSub),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child:   _AlertCard(alert: _filteredAlerts[i]),
                                ),
                                childCount: _filteredAlerts.length,
                              ),
                            ),
                          ),
                  ],
                ],

                // ── Missing Items Section ────────────────────────────────────
                if (_mode == _AlertMode.missing) ...[
                  if (_loadingMissing)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child:   Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_missingError != null)
                    SliverToBoxAdapter(
                      child: _ErrorView(
                          message: _missingError!,
                          onRetry: _fetchMissingItems),
                    )
                  else if (_missingItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size:  44,
                                  color: AppColors.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'No missing items — all accounted for!',
                                style:     TextStyle(
                                    fontSize: 13, color: AppColors.textSub),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Awaiting response',
                              style: TextStyle(
                                fontSize:      11,
                                fontWeight:    FontWeight.w600,
                                color:         AppColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${_missingItems.length})',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MissingItemCard(
                              item:         _missingItems[i],
                              isResponding: _respondingIds.contains(
                                  _missingItems[i].id),
                              onWillReturn: () => _respondToItem(
                                  _missingItems[i],
                                  _MissingResponse.willBeReturned),
                              onReturned: () => _respondToItem(
                                  _missingItems[i],
                                  _MissingResponse.returned),
                              onFinished: () => _respondToItem(
                                  _missingItems[i],
                                  _MissingResponse.finished),
                            ),
                          ),
                          childCount: _missingItems.length,
                        ),
                      ),
                    ),
                  ],
                ],

                // ── Incompatible Items Section ───────────────────────────────
                if (_mode == _AlertMode.incompatible) ...[
                  if (_loadingIncompatible)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child:   Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_incompatibleError != null)
                    SliverToBoxAdapter(
                      child: _ErrorView(
                        message: _incompatibleError!,
                        onRetry: _fetchIncompatibleItems,
                      ),
                    )
                  else if (_incompatibleItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_outlined,
                                  size:  44,
                                  color: AppColors.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'No incompatible items — great storage!',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textSub),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Incompatible pairs',
                              style: TextStyle(
                                fontSize:      11,
                                fontWeight:    FontWeight.w600,
                                color:         AppColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${_incompatibleItems.length})',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _IncompatibleItemCard(
                                item: _incompatibleItems[i]),
                          ),
                          childCount: _incompatibleItems.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

// ── Missing Item Card ─────────────────────────────────────────────────────────
class _MissingItemCard extends StatelessWidget {
  final MissingItem  item;
  final bool         isResponding;
  final VoidCallback onWillReturn;
  final VoidCallback onReturned;
  final VoidCallback onFinished;

  const _MissingItemCard({
    required this.item,
    required this.isResponding,
    required this.onWillReturn,
    required this.onReturned,
    required this.onFinished,
  });

  static const _borderColor = Color(0xFFFFE4B5);
  static const _iconBg      = Color(0xFFFFF7E6);
  static const _iconBorder  = Color(0xFFFFD580);
  static const _iconColor   = Color(0xFFD97706);
  static const _badgeBg     = Color(0xFFFFF3CD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      _iconColor.withOpacity(0.08),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width:  42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:        _iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: _iconBorder, width: 1),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      size: 22, color: _iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + urgency badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _capitalize(item.itemName),
                              style: const TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w600,
                                color:      AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Urgency level badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color:        item.urgencyColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: item.urgencyColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              item.urgencyLabel,
                              style: TextStyle(
                                fontSize:   9,
                                fontWeight: FontWeight.w700,
                                color:      item.urgencyColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Duration badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:        _badgeBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _iconBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 10, color: _iconColor),
                                const SizedBox(width: 3),
                                Text(
                                  item.durationLabel,
                                  style: const TextStyle(
                                    fontSize:   10,
                                    fontWeight: FontWeight.w600,
                                    color:      _iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.message,
                        style: const TextStyle(
                            fontSize: 12,
                            color:    AppColors.textSub,
                            height:   1.4),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'What happened to this item?',
                        style: TextStyle(
                          fontSize:     11,
                          color:        AppColors.textMuted,
                          fontStyle:    FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color:  const Color(0xFFF0E6D3)),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: isResponding
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width:  22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Row 1: Will be Returned (full width, muted blue)
                      _ActionButton(
                        onTap:       onWillReturn,
                        icon:        Icons.schedule_rounded,
                        label:       'Will Be Returned',
                        bgColor:     const Color(0xFFEFF6FF),
                        borderColor: const Color(0xFFBFDBFE),
                        textColor:   const Color(0xFF1D4ED8),
                        iconColor:   const Color(0xFF3B82F6),
                        fullWidth:   true,
                        subtitle:    'Keep tracking — I\'ll put it back',
                      ),
                      const SizedBox(height: 8),
                      // Row 2: Returned | Finished (split)
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              onTap:       onReturned,
                              icon:        Icons.keyboard_return_rounded,
                              label:       'Returned',
                              bgColor:     AppColors.goodBg,
                              borderColor: AppColors.goodColor.withOpacity(0.4),
                              textColor:   AppColors.goodColor,
                              iconColor:   AppColors.goodColor,
                              fullWidth:   false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              onTap:       onFinished,
                              icon:        Icons.check_circle_outline_rounded,
                              label:       'Finished',
                              bgColor:     const Color(0xFFFEF2F2),
                              borderColor: AppColors.dangerColor.withOpacity(0.3),
                              textColor:   AppColors.dangerColor,
                              iconColor:   AppColors.dangerColor,
                              fullWidth:   false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Reusable action button ────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData     icon;
  final String       label;
  final String?      subtitle;
  final Color        bgColor;
  final Color        borderColor;
  final Color        textColor;
  final Color        iconColor;
  final bool         fullWidth;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.fullWidth,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical:   fullWidth ? 11 : 10,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: borderColor),
        ),
        child: fullWidth
            ? Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      textColor)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: TextStyle(
                                  fontSize: 10,
                                  color:    textColor.withOpacity(0.65))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: iconColor.withOpacity(0.6)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: iconColor),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      textColor)),
                ],
              ),
      ),
    );
  }
}

// ── Mode Toggle ───────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final _AlertMode mode;
  final int statusCount;
  final int missingCount;
  final int incompatibleCount;
  final void Function(_AlertMode) onSelect;

  const _ModeToggle({
    required this.mode,
    required this.statusCount,
    required this.missingCount,
    required this.incompatibleCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label:       'Status',
            icon:        Icons.bar_chart_rounded,
            count:       statusCount,
            isActive:    mode == _AlertMode.status,
            activeColor: AppColors.primary,
            onTap:       () => onSelect(_AlertMode.status),
          ),
          const SizedBox(width: 4),
          _ToggleBtn(
            label:       'Missing',
            icon:        Icons.search_rounded,
            count:       missingCount,
            isActive:    mode == _AlertMode.missing,
            activeColor: const Color(0xFFD97706),
            onTap:       () => onSelect(_AlertMode.missing),
          ),
          const SizedBox(width: 4),
          _ToggleBtn(
            label:       'Incompatible',
            icon:        Icons.warning_amber_rounded,
            count:       incompatibleCount,
            isActive:    mode == _AlertMode.incompatible,
            activeColor: const Color(0xFFB03A2E),
            onTap:       () => onSelect(_AlertMode.incompatible),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final int          count;
  final bool         isActive;
  final Color        activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color:        isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(
                    color:      activeColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset:     const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size:  14,
                  color: isActive ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color:      isActive ? Colors.white : AppColors.textSub,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.25)
                        : activeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      color:      isActive ? Colors.white : activeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Incompatible Item Card ────────────────────────────────────────────────────
class _IncompatibleItemCard extends StatelessWidget {
  final IncompatibleItem item;
  const _IncompatibleItemCard({required this.item});

  static const _redBorder = Color(0xFFE8A0A0);
  static const _redIconBg = Color(0xFFFFDDDD);
  static const _redIcon   = Color(0xFFB03A2E);
  static const _redText   = Color(0xFF7A1010);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _redBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      _redIcon.withOpacity(0.08),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width:  42,
              height: 42,
              decoration: BoxDecoration(
                color:        _redIconBg,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: _redBorder),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 22, color: _redIcon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ItemBadge(label: _capitalize(item.itemA)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: _redIcon),
                      ),
                      _ItemBadge(label: _capitalize(item.itemB)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _capitalize(item.title),
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      _redText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color:    AppColors.textSub,
                      height:   1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.detectedAt,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ItemBadge extends StatelessWidget {
  final String label;
  const _ItemBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: const Color(0xFFE8A0A0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      Color(0xFF7A1010),
        ),
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
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
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
                    color:       Colors.white70,
                    fontSize:    11,
                    letterSpacing: 0.5,
                    fontWeight:  FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatPill(
                        icon:  Icons.thermostat_rounded,
                        value: '$temp°C',
                        label: 'Temp'),
                    const SizedBox(width: 10),
                    _StatPill(
                        icon:  Icons.water_drop_outlined,
                        value: '$humidity%',
                        label: 'Humidity'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width:  6,
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
                          color:      Colors.white,
                          fontSize:   10,
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
  final String   value;
  final String   label;
  const _StatPill(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.12),
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
                  style: const TextStyle(fontSize: 9, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                  color:      Colors.white)),
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
      width:  64,
      height: 96,
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ac_unit_rounded,
                    size:  12,
                    color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color:  Colors.white.withOpacity(0.2)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_shelf(), const SizedBox(height: 4), _shelf()],
              ),
            ),
          ),
          Center(
            child: Container(
              width:  16,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.4),
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
        color:  Colors.white.withOpacity(0.25),
      );
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _Filter              active;
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
                      color: isActive ? f.activeBg : AppColors.border),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color:      f.activeBg.withOpacity(0.3),
                          blurRadius: 6,
                          offset:     const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color:      isActive ? Colors.white : AppColors.textSub,
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
  final String       message;
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
                elevation:       0,
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
  final int          count;
  final String       label;
  final Color        bg;
  final Color        numColor;
  final Color        lblColor;
  final VoidCallback onTap;
  final bool         isActive;
  final Color        activeColor;

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
          duration:  const Duration(milliseconds: 200),
          padding:   const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        isActive ? activeColor : bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(
                    color:      activeColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset:     const Offset(0, 3))]
                : null,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize:   22,
                  fontWeight: FontWeight.w500,
                  color:      isActive ? Colors.white : numColor,
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
        color:        alert.bgColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border(left: BorderSide(color: alert.borderColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
                color: alert.iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(alert.icon, size: 18, color: alert.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        color:      alert.titleColor)),
                const SizedBox(height: 3),
                Text(alert.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSub, height: 1.4)),
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