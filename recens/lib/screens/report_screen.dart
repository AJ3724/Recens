import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _TempPoint {
  final String label;
  final double avg;
  final double min;
  final double max;
  const _TempPoint(this.label, this.avg, this.min, this.max);
}

class _TempData {
  final String mode;
  final String label;
  final List<_TempPoint> points;
  final double overallAvg;
  final double overallMin;
  final double overallMax;
  final double inRangePct;
  const _TempData({
    required this.mode,
    required this.label,
    required this.points,
    required this.overallAvg,
    required this.overallMin,
    required this.overallMax,
    required this.inRangePct,
  });
}

class _WasteMonth {
  final String label;
  final int spoiled;
  final int leftOut;
  final int total;
  final double wasteRate;
  final int spoiledDelta;
  final int leftOutDelta;
  const _WasteMonth({
    required this.label,
    required this.spoiled,
    required this.leftOut,
    required this.total,
    required this.wasteRate,
    required this.spoiledDelta,
    required this.leftOutDelta,
  });
}

class _WasteData {
  final List<_WasteMonth> months;
  final String bestMonth;
  final String worstMonth;
  final double avgSpoiled;
  final int totalSaved;
  const _WasteData({
    required this.months,
    required this.bestMonth,
    required this.worstMonth,
    required this.avgSpoiled,
    required this.totalSaved,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
              'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _toDateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {

  DateTime _selectedDate  = DateTime.now();
  bool     _showWeekly    = false;

  _TempData?   _tempData;
  bool         _tempLoading = true;
  String?      _tempError;

  int         _wasteMonthOffset = 0;
  _WasteData? _wasteData;
  bool        _wasteLoading = true;
  String?     _wasteError;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _fetchTemp();
    _fetchWaste();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _animate() { _animCtrl..reset()..forward(); }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _fetchTemp() async {
    setState(() { _tempLoading = true; _tempError = null; });
    try {
      final mode  = _showWeekly ? 'daily' : 'hourly';
      final query = '?mode=$mode&date=${_toDateStr(_selectedDate)}';
      final uri   = Uri.parse('${AppConfig.baseUrl}/get_avg_temp$query');
      final res   = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');
      final json  = jsonDecode(res.body) as Map<String, dynamic>;

      final rawPts = (json['points'] as List).cast<Map<String, dynamic>>();
      final points = rawPts.map((p) => _TempPoint(
        p['label'] as String,
        (p['avg']  as num).toDouble(),
        (p['min']  as num).toDouble(),
        (p['max']  as num).toDouble(),
      )).toList();

      setState(() {
        _tempData = _TempData(
          mode:       json['mode']         as String,
          label:      json['label']        as String,
          points:     points,
          overallAvg: (json['overall_avg'] as num).toDouble(),
          overallMin: (json['overall_min'] as num).toDouble(),
          overallMax: (json['overall_max'] as num).toDouble(),
          inRangePct: (json['in_range_pct'] as num).toDouble(),
        );
        _tempLoading = false;
      });
      _animate();
    } catch (e) {
      setState(() { _tempError = e.toString(); _tempLoading = false; });
    }
  }

  Future<void> _fetchWaste() async {
    setState(() { _wasteLoading = true; _wasteError = null; });
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/get_waste?months=6');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Server ${res.statusCode}');
      final json = jsonDecode(res.body) as Map<String, dynamic>;

      final rawMonths = (json['months'] as List).cast<Map<String, dynamic>>();
      final months = rawMonths.map((m) => _WasteMonth(
        label:        m['label']           as String,
        spoiled:      (m['spoiled_count']  as num).toInt(),
        leftOut:      (m['left_out_count'] as num).toInt(),
        total:        (m['total_items']    as num).toInt(),
        wasteRate:    (m['waste_rate']     as num).toDouble(),
        spoiledDelta: (m['spoiled_delta']  as num?)?.toInt() ?? 0,
        leftOutDelta: (m['left_out_delta'] as num?)?.toInt() ?? 0,
      )).toList();

      final summary = json['summary'] as Map<String, dynamic>;
      setState(() {
        _wasteData = _WasteData(
          months:     months,
          bestMonth:  summary['best_month']  as String,
          worstMonth: summary['worst_month'] as String,
          avgSpoiled: (summary['avg_spoiled'] as num).toDouble(),
          totalSaved: (summary['total_saved'] as num).toInt(),
        );
        _wasteLoading = false;
      });
    } catch (e) {
      setState(() { _wasteError = e.toString(); _wasteLoading = false; });
    }
  }

  // ── Date navigation ────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(now.year, now.month - 3),
      lastDate:    now,
      builder:     (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchTemp();
    }
  }

  void _shiftDate(int days) {
    final now       = DateTime.now();
    final candidate = _selectedDate.add(Duration(days: days));
    if (candidate.isAfter(now)) return;
    setState(() => _selectedDate = candidate);
    _fetchTemp();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year  == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day   == now.day;
  }

  void _shiftWasteMonth(int delta) {
    final months = _wasteData?.months ?? [];
    final next   = _wasteMonthOffset + delta;
    if (next < 0 || next >= months.length) return;
    setState(() => _wasteMonthOffset = next);
    _animate();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final avgTemp = _tempData?.overallAvg ?? 0.0;
    final saved   = _wasteData?.totalSaved ?? 0;

    final wasteMonths  = _wasteData?.months ?? [];
    final currentWaste = wasteMonths.isNotEmpty
        ? wasteMonths[_wasteMonthOffset]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned:         true,
            expandedHeight: 80,
            toolbarHeight:  80,
            backgroundColor:        AppColors.primary,
            elevation:              0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _OrnamentalDivider(),
                        const SizedBox(height: 4),
                        const Text('Reports',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        const Text('Insights & Analytics',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        _OrnamentalDivider(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                _SummaryRow(
                  avgTemp:    avgTemp,
                  totalSaved: saved,
                  inRangePct: _tempData?.inRangePct ?? 0,
                ),
                const SizedBox(height: 20),

                _ReportCard(
                  title:    'Fridge Temperature',
                  subtitle: _showWeekly
                      ? 'Daily — ${_fmtDate(_selectedDate)}'
                      : 'Hourly — ${_fmtDate(_selectedDate)}',
                  icon:      Icons.thermostat_rounded,
                  iconColor: AppColors.goodColor,
                  trailing: _DateNavRow(
                    label:      _isToday ? 'Today' : _fmtDate(_selectedDate),
                    onPrev:     () => _shiftDate(-1),
                    onNext:     _isToday ? null : () => _shiftDate(1),
                    onPickDate: _pickDate,
                  ),
                  child: _tempLoading
                      ? _LoadingBox()
                      : _tempError != null
                          ? _ErrorBox(message: _tempError!, onRetry: _fetchTemp)
                          : _TempCardBody(
                              data:         _tempData!,
                              fadeAnim:     _fadeAnim,
                              showWeekly:   _showWeekly,
                              onToggleView: () {
                                setState(() => _showWeekly = !_showWeekly);
                                _fetchTemp();
                              },
                            ),
                ),

                const SizedBox(height: 20),

                _ReportCard(
                  title:    'Waste Reduced',
                  subtitle: 'Spoiled & left-out items per month',
                  icon:      Icons.eco_rounded,
                  iconColor: AppColors.medium,
                  trailing: _wasteData != null
                      ? _MonthNavRow(
                          label:  currentWaste?.label ?? '',
                          onPrev: _wasteMonthOffset < wasteMonths.length - 1
                              ? () => _shiftWasteMonth(1)
                              : null,
                          onNext: _wasteMonthOffset > 0
                              ? () => _shiftWasteMonth(-1)
                              : null,
                        )
                      : null,
                  child: _wasteLoading
                      ? _LoadingBox()
                      : _wasteError != null
                          ? _ErrorBox(message: _wasteError!, onRetry: _fetchWaste)
                          : _WasteCardBody(
                              data:         _wasteData!,
                              currentMonth: currentWaste!,
                              fadeAnim:     _fadeAnim,
                            ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Temperature card body
// ─────────────────────────────────────────────────────────────────────────────

class _TempCardBody extends StatelessWidget {
  final _TempData data;
  final Animation<double> fadeAnim;
  final bool showWeekly;
  final VoidCallback onToggleView;

  const _TempCardBody({
    required this.data,
    required this.fadeAnim,
    required this.showWeekly,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final inRange = data.overallAvg >= 2.0 && data.overallAvg <= 5.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        inRange ? AppColors.goodBg : AppColors.dangerBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    inRange
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    size:  13,
                    color: inRange ? AppColors.goodColor : AppColors.dangerColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Avg ${data.overallAvg.toStringAsFixed(1)}°C'
                    ' — ${inRange ? "optimal" : "out of range"}',
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color: inRange ? AppColors.goodText : AppColors.dangerColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '${data.inRangePct.toStringAsFixed(0)}% in range',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: fadeAnim,
          child: data.points.isEmpty
              ? _EmptyChart()
              : SizedBox(
                  height: 100,
                  child: _LineChart(
                    values:    data.points.map((p) => p.avg).toList(),
                    minY:      1.5,
                    maxY:      6.5,
                    color:     inRange ? AppColors.goodColor : AppColors.dangerColor,
                    fillColor: inRange ? AppColors.goodBg    : AppColors.dangerBg,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        if (data.points.isNotEmpty)
          _XAxisLabels(
            labels: _evenlySampled(
                data.points.map((p) => p.label).toList(), 5),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniChip(
                label: 'Min',
                value: '${data.overallMin.toStringAsFixed(1)}°C',
                color: Colors.blueAccent),
            const SizedBox(width: 8),
            _MiniChip(
                label: 'Max',
                value: '${data.overallMax.toStringAsFixed(1)}°C',
                color: AppColors.dangerColor),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: onToggleView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color:        AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showWeekly
                        ? Icons.access_time_rounded
                        : Icons.calendar_view_week_rounded,
                    size:  12,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    showWeekly ? 'Show hourly view' : 'Show daily view',
                    style: const TextStyle(
                        fontSize:   10,
                        color:      AppColors.textSub,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waste card body
// ─────────────────────────────────────────────────────────────────────────────

class _WasteCardBody extends StatelessWidget {
  final _WasteData  data;
  final _WasteMonth currentMonth;
  final Animation<double> fadeAnim;

  const _WasteCardBody({
    required this.data,
    required this.currentMonth,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    final spoiledImproved = currentMonth.spoiledDelta <= 0;
    final leftOutImproved = currentMonth.leftOutDelta <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatPill(
                label:    'Spoiled',
                value:    currentMonth.spoiled.toString(),
                delta:    currentMonth.spoiledDelta,
                improved: spoiledImproved,
                icon:     Icons.dangerous_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatPill(
                label:    'Left Out',
                value:    currentMonth.leftOut.toString(),
                delta:    currentMonth.leftOutDelta,
                improved: leftOutImproved,
                icon:     Icons.door_front_door_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatPill(
                label:    'Total Items',
                value:    currentMonth.total.toString(),
                delta:    null,
                improved: true,
                icon:     Icons.inventory_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: fadeAnim,
          child: _WasteSavedChart(months: data.months),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 13, color: AppColors.goodColor),
            const SizedBox(width: 4),
            Text('Best: ${data.bestMonth}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSub)),
            const SizedBox(width: 12),
            const Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.dangerColor),
            const SizedBox(width: 4),
            Text('Worst: ${data.worstMonth}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSub)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell
// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    iconColor;
  final Widget   child;
  final Widget?  trailing;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  34,
                height: 34,
                decoration: BoxDecoration(
                  color:        AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 10,
                            color:    AppColors.textMuted)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary pills
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double avgTemp;
  final int    totalSaved;
  final double inRangePct;

  const _SummaryRow({
    required this.avgTemp,
    required this.totalSaved,
    required this.inRangePct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            icon:  Icons.thermostat_rounded,
            label: 'Avg Temp',
            value: '${avgTemp.toStringAsFixed(1)}°C',
            color: AppColors.goodColor,
            bg:    AppColors.goodBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryPill(
            icon:  Icons.eco_rounded,
            label: 'Items Saved',
            value: totalSaved.toString(),
            color: AppColors.medium,
            bg:    AppColors.surfaceAlt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryPill(
            icon:  Icons.verified_rounded,
            label: 'In Range',
            value: '${inRangePct.toStringAsFixed(0)}%',
            color: AppColors.acceptColor,
            bg:    AppColors.acceptBg,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final Color    bg;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                  color:      color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize:   9,
                  color:      AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waste stat pill with delta
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String   label;
  final String   value;
  final int?     delta;
  final bool     improved;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.delta,
    required this.improved,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = improved ? AppColors.goodColor : AppColors.dangerColor;
    final bg    = improved ? AppColors.goodBg    : AppColors.dangerBg;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                  color:      color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
          if (delta != null && delta != 0) ...[
            const SizedBox(height: 2),
            Text(
              delta! < 0 ? '${delta}  ▼' : '+${delta}  ▲',
              style: TextStyle(
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  color: delta! < 0
                      ? AppColors.goodColor
                      : AppColors.dangerColor),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini chip (min / max temp)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _MiniChip({
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ',
              style: TextStyle(
                  fontSize: 10, color: color.withOpacity(0.7))),
          Text(value,
              style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w700,
                  color:      color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line chart (temperature)
// ─────────────────────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<double> values;
  final double       minY;
  final double       maxY;
  final Color        color;
  final Color        fillColor;

  const _LineChart({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _LineChartPainter(
            values:    values,
            minY:      minY,
            maxY:      maxY,
            color:     color,
            fillColor: fillColor),
      );
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double minY, maxY;
  final Color  color, fillColor;

  _LineChartPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final range = maxY - minY;
    final stepX = size.width / (values.length - 1);
    double yFor(double v) =>
        size.height - ((v - minY) / range * size.height).clamp(0.0, size.height);

    // Safe-range band
    final bandPaint = Paint()
      ..color = AppColors.goodColor.withOpacity(0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(0, yFor(5.0), size.width, yFor(2.0)), bandPaint);

    // Fill
    final fillPath = Path()..moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      fillPath.lineTo(i * stepX, yFor(values[i]));
    }
    fillPath
      ..lineTo((values.length - 1) * stepX, size.height)
      ..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..color = fillColor.withOpacity(0.55)
          ..style = PaintingStyle.fill);

    // Line
    final linePath = Path()..moveTo(0, yFor(values[0]));
    for (int i = 1; i < values.length; i++) {
      final prev = Offset((i - 1) * stepX, yFor(values[i - 1]));
      final curr = Offset(i * stepX, yFor(values[i]));
      linePath.cubicTo(
          prev.dx + stepX * 0.4, prev.dy,
          curr.dx - stepX * 0.4, curr.dy,
          curr.dx, curr.dy);
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color       = color
          ..strokeWidth = 2.0
          ..style       = PaintingStyle.stroke
          ..strokeCap   = StrokeCap.round);

    // Dots
    final step = (values.length / 5).ceil().clamp(1, values.length);
    for (int i = 0; i < values.length; i += step) {
      canvas.drawCircle(
          Offset(i * stepX, yFor(values[i])), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Waste grouped bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WasteSavedChart extends StatelessWidget {
  final List<_WasteMonth> months;
  const _WasteSavedChart({required this.months});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return _EmptyChart();
    const maxBarH = 80.0;
    final maxVal  = months
        .map((m) => m.spoiled + m.leftOut)
        .fold(0, (a, b) => a > b ? a : b);
    final denom = (maxVal + 2).toDouble();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.reversed.toList().asMap().entries.map((entry) {
          final m        = entry.value;
          final total    = m.spoiled + m.leftOut;
          final barH     = (total / denom).clamp(0.0, 1.0) * maxBarH;
          final spoiledH = m.spoiled > 0
              ? (m.spoiled / denom).clamp(0.0, 1.0) * maxBarH
              : 0.0;
          final leftOutH = barH - spoiledH;
          final shortLabel =
              m.label.length >= 3 ? m.label.substring(0, 3) : m.label;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$total',
                      style: const TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.textSub)),
                  const SizedBox(height: 3),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (spoiledH > 0)
                        Container(
                          height: spoiledH,
                          decoration: BoxDecoration(
                            color: AppColors.dangerColor.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5)),
                          ),
                        ),
                      if (leftOutH > 0)
                        Container(
                          height: leftOutH,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.45),
                            borderRadius: spoiledH <= 0
                                ? BorderRadius.circular(5)
                                : const BorderRadius.vertical(
                                    bottom: Radius.circular(5)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(shortLabel,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation rows
// ─────────────────────────────────────────────────────────────────────────────

class _DateNavRow extends StatelessWidget {
  final String        label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onPickDate;

  const _DateNavRow({
    required this.label,
    this.onPrev,
    this.onNext,
    this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavArrow(icon: Icons.chevron_left_rounded,  onTap: onPrev),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.textSub)),
              ],
            ),
          ),
        ),
        _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  final String        label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _MonthNavRow({required this.label, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavArrow(icon: Icons.chevron_left_rounded,  onTap: onPrev),
          Text(label,
              style: const TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textSub)),
          _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      );
}

class _NavArrow extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(icon,
              size:  18,
              color: onTap != null ? AppColors.primary : AppColors.border),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// X-axis labels
// ─────────────────────────────────────────────────────────────────────────────

class _XAxisLabels extends StatelessWidget {
  final List<String> labels;
  const _XAxisLabels({required this.labels});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map((l) => Text(l,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted)))
            .toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error / empty states
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      );
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 80,
        child: Center(
          child: Text('No data for this period',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisSize:      MainAxisSize.min,   // ← shrink to content
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textMuted, size: 20),
              const SizedBox(height: 4),
              const Text('Could not load data',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize:    Size.zero,
                  padding:        const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  tapTargetSize:  MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ornamental divider
// ─────────────────────────────────────────────────────────────────────────────

class _OrnamentalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 32, height: 0.8, color: Colors.white38),
          const SizedBox(width: 6),
          Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: Colors.white38, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Container(width: 32, height: 0.8, color: Colors.white38),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

List<String> _evenlySampled(List<String> labels, int n) {
  if (labels.length <= n) return labels;
  final step = (labels.length / (n - 1)).floor();
  return List.generate(n, (i) {
    final idx = (i * step).clamp(0, labels.length - 1);
    return labels[idx];
  });
}