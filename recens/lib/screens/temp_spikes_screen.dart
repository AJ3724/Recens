import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../config/api_config.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class TempSpikeAlert {
  final String id;
  final String itemName;
  final int    alertLevel;
  final String severity;
  final String spikeStart;
  final int    timeInSpike;
  final String durationLabel;
  final String zone;
  final String title;
  final String description;
  final String detectedAt;

  const TempSpikeAlert({
    required this.id,
    required this.itemName,
    required this.alertLevel,
    required this.severity,
    required this.spikeStart,
    required this.timeInSpike,
    required this.durationLabel,
    required this.zone,
    required this.title,
    required this.description,
    required this.detectedAt,
  });

  factory TempSpikeAlert.fromJson(Map<String, dynamic> json) => TempSpikeAlert(
        id:            json['id']?.toString()            ?? '',
        itemName:      json['item_name']?.toString()     ?? '',
        alertLevel:    (json['alert_level'] as num?)?.toInt() ?? 1,
        severity:      json['severity']?.toString()      ?? 'info',
        spikeStart:    json['spike_start']?.toString()   ?? '',
        timeInSpike:   (json['time_in_spike'] as num?)?.toInt() ?? 0,
        durationLabel: json['duration_label']?.toString() ?? '',
        zone:          json['zone']?.toString()           ?? '',
        title:         json['title']?.toString()          ?? '',
        description:   json['description']?.toString()    ?? '',
        detectedAt:    json['detected_at']?.toString()    ?? '',
      );

  Color get levelColor {
    switch (alertLevel) {
      case 3:  return const Color(0xFFB03A2E);
      case 2:  return const Color(0xFFD97706);
      default: return const Color(0xFF2E86C1);
    }
  }

  Color get levelBg {
    switch (alertLevel) {
      case 3:  return const Color(0xFFFEE2E2);
      case 2:  return const Color(0xFFFFF7ED);
      default: return const Color(0xFFEFF6FF);
    }
  }

  Color get levelBorder {
    switch (alertLevel) {
      case 3:  return const Color(0xFFFCA5A5);
      case 2:  return const Color(0xFFFCD34D);
      default: return const Color(0xFF93C5FD);
    }
  }

  String get severityLabel {
    switch (alertLevel) {
      case 3:  return 'Critical';
      case 2:  return 'Warning';
      default: return 'Info';
    }
  }

  IconData get icon {
    switch (alertLevel) {
      case 3:  return Icons.thermostat_rounded;
      case 2:  return Icons.device_thermostat_rounded;
      default: return Icons.thermostat_outlined;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class TempSpikesScreen extends StatefulWidget {
  const TempSpikesScreen({super.key});

  @override
  State<TempSpikesScreen> createState() => _TempSpikesScreenState();
}

class _TempSpikesScreenState extends State<TempSpikesScreen> {
  List<TempSpikeAlert> _spikes  = [];
  bool                 _loading = true;
  String?              _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.tempSpikes))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _spikes  = data.map((j) => TempSpikeAlert.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Server error: ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Could not reach server.\n$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned:              true,
            expandedHeight:      80,
            toolbarHeight:       80,
            backgroundColor:     AppColors.primary,
            elevation:           0,
            scrolledUnderElevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.none,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.medium],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Temperature Spikes',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!_loading && _spikes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_spikes.length} active alert${_spikes.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorView(message: _error!, onRetry: _fetch),
            )
          else if (_spikes.isEmpty)
            const SliverFillRemaining(
              child: _EmptyView(),
            )
          else ...[
            // ── Summary banner ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SummaryBanner(spikes: _spikes),
              ),
            ),

            // ── Section label ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    const Text(
                      'Active spike alerts',
                      style: TextStyle(
                        fontSize:      11,
                        fontWeight:    FontWeight.w600,
                        color:         AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${_spikes.length})',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cards ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SpikeCard(spike: _spikes[i]),
                  ),
                  childCount: _spikes.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final List<TempSpikeAlert> spikes;
  const _SummaryBanner({required this.spikes});

  int _count(int level) => spikes.where((s) => s.alertLevel == level).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A1A0A), Color(0xFFB03A2E)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFFB03A2E).withOpacity(0.25),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thermometer icon block
          Container(
            width:  56,
            height: 56,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.thermostat_rounded,
                size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temperature Spike Summary',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SummaryChip(
                        label: 'Critical',
                        count: _count(3),
                        color: const Color(0xFFFF6B6B)),
                    const SizedBox(width: 8),
                    _SummaryChip(
                        label: 'Warning',
                        count: _count(2),
                        color: const Color(0xFFFFD93D)),
                    const SizedBox(width: 8),
                    _SummaryChip(
                        label: 'Info',
                        count: _count(1),
                        color: const Color(0xFF74C0FC)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spike Card ────────────────────────────────────────────────────────────────
class _SpikeCard extends StatelessWidget {
  final TempSpikeAlert spike;
  const _SpikeCard({required this.spike});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: spike.levelBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      spike.levelColor.withOpacity(0.08),
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
            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        spike.levelBg,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: spike.levelBorder),
              ),
              child: Icon(spike.icon, size: 22, color: spike.levelColor),
            ),
            const SizedBox(width: 12),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spike.title,
                          style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      spike.levelColor,
                          ),
                        ),
                      ),
                      // Severity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:        spike.levelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: spike.levelColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          spike.severityLabel,
                          style: TextStyle(
                            fontSize:   9,
                            fontWeight: FontWeight.w700,
                            color:      spike.levelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Description
                  Text(
                    spike.description,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    AppColors.textSub,
                        height:   1.4),
                  ),
                  const SizedBox(height: 10),

                  // ── Metadata row ─────────────────────────────────────────
                  Wrap(
                    spacing:   8,
                    runSpacing: 6,
                    children: [
                      _MetaChip(
                        icon:  Icons.timer_outlined,
                        label: spike.durationLabel,
                        bg:    spike.levelBg,
                        color: spike.levelColor,
                      ),
                      if (spike.spikeStart.isNotEmpty)
                        _MetaChip(
                          icon:  Icons.access_time_rounded,
                          label: spike.spikeStart,
                          bg:    spike.levelBg,
                          color: spike.levelColor,
                        ),
                      if (spike.zone.isNotEmpty && spike.zone != 'unknown')
                        _MetaChip(
                          icon:  Icons.place_outlined,
                          label: 'Zone: ${spike.zone}',
                          bg:    spike.levelBg,
                          color: spike.levelColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Detected at
                  Text(
                    'Detected: ${spike.detectedAt}',
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
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    bg;
  final Color    color;
  const _MetaChip(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error views ───────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thermostat_outlined,
                size:  52,
                color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 14),
            const Text(
              'No temperature spikes detected',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your fridge temperature has been stable.',
              style:     TextStyle(fontSize: 12, color: AppColors.textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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