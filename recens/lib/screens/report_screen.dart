import 'package:flutter/material.dart';
import '../theme.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

/// Generate mock hourly temps for a given day offset (0 = today, -1 = yesterday…)
List<double> _hourlyTempsForDay(int dayOffset) {
  final base = 3.8 + (dayOffset.abs() % 3) * 0.2;
  return List.generate(24, (i) {
    final wave = 0.4 * ((i - 12).abs() / 12.0);
    return double.parse((base + wave + (i % 3) * 0.1).toStringAsFixed(1));
  });
}

/// Generate mock daily avg temps for a given week offset (0 = this week)
List<_DayTemp> _dailyTempsForWeek(int weekOffset) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return List.generate(7, (i) {
    final t = 3.6 + (weekOffset.abs() % 2) * 0.3 + (i % 3) * 0.2;
    return _DayTemp(days[i], double.parse(t.toStringAsFixed(1)));
  });
}

/// Monthly waste-saved stats — keyed by month offset (0 = current month)
const Map<int, List<_WastePoint>> _wasteByMonth = {
  0: [
    _WastePoint('Wk 1', 3), _WastePoint('Wk 2', 4),
    _WastePoint('Wk 3', 5), _WastePoint('Wk 4', 2),
  ],
  -1: [
    _WastePoint('Wk 1', 2), _WastePoint('Wk 2', 3),
    _WastePoint('Wk 3', 4), _WastePoint('Wk 4', 5),
  ],
  -2: [
    _WastePoint('Wk 1', 1), _WastePoint('Wk 2', 2),
    _WastePoint('Wk 3', 3), _WastePoint('Wk 4', 4),
  ],
  -3: [
    _WastePoint('Wk 1', 4), _WastePoint('Wk 2', 3),
    _WastePoint('Wk 3', 2), _WastePoint('Wk 4', 5),
  ],
  -4: [
    _WastePoint('Wk 1', 2), _WastePoint('Wk 2', 1),
    _WastePoint('Wk 3', 3), _WastePoint('Wk 4', 2),
  ],
  -5: [
    _WastePoint('Wk 1', 1), _WastePoint('Wk 2', 2),
    _WastePoint('Wk 3', 1), _WastePoint('Wk 4', 3),
  ],
};

class _DayTemp {
  final String label;
  final double temp;
  const _DayTemp(this.label, this.temp);
}

class _WastePoint {
  final String label;
  final int saved;
  const _WastePoint(this.label, this.saved);
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _monthLabel(int offset) {
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month + offset);
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  // Temperature state
  DateTime _selectedDate = DateTime.now();
  bool _showDailyTemp = false;

  // Waste state
  int _wasteMonthOffset = 0; // 0 = current, -1 = last month, etc.

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _animate() {
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month - 3),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _animate();
    }
  }

  void _shiftDate(int days) {
    final now = DateTime.now();
    final candidate = _selectedDate.add(Duration(days: days));
    if (candidate.isAfter(now)) return;
    setState(() => _selectedDate = candidate);
    _animate();
  }

  // ── Waste month navigation ───────────────────────────────────────────────────
  void _shiftMonth(int delta) {
    final next = _wasteMonthOffset + delta;
    if (next > 0 || next < -5) return;
    setState(() => _wasteMonthOffset = next);
    _animate();
  }

  int get _dayOffset {
    final now = DateTime.now();
    return _selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final hourly = _hourlyTempsForDay(_dayOffset);
    final daily = _dailyTempsForWeek(_dayOffset ~/ 7);
    final avg = hourly.reduce((a, b) => a + b) / hourly.length;
    final wasteData = _wasteByMonth[_wasteMonthOffset]!;
    final maxWaste = wasteData.map((e) => e.saved).reduce((a, b) => a > b ? a : b);
    final isToday = _dayOffset == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            toolbarHeight: 80,
            backgroundColor: AppColors.primary,
            elevation: 0,
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _OrnamentalDivider(),
                        const SizedBox(height: 4),
                        const Text(
                          'Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Insights & Analytics',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
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
                _SummaryRow(avgTemp: avg),
                const SizedBox(height: 20),

                // ── Temperature card ────────────────────────────────────────
                _ReportCard(
                  title: 'Fridge Temperature',
                  subtitle: _showDailyTemp
                      ? 'Week of ${_formatDate(_selectedDate)}'
                      : _formatDate(_selectedDate),
                  icon: Icons.thermostat_rounded,
                  iconColor: AppColors.goodColor,
                  // Date nav row in header trailing
                  trailing: _DateNavRow(
                    label: isToday ? 'Today' : _formatDate(_selectedDate),
                    onPrev: () => _shiftDate(-1),
                    onNext: isToday ? null : () => _shiftDate(1),
                    onPickDate: _pickDate,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _showDailyTemp
                            ? _BarChart(
                                points: daily,
                                safeMin: 2.0,
                                safeMax: 5.0,
                              )
                            : _HourlyChart(
                                hourly: hourly,
                                avg: avg,
                              ),
                      ),
                      const SizedBox(height: 10),
                      // Toggle pill
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showDailyTemp = !_showDailyTemp);
                            _animate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.border, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showDailyTemp
                                      ? Icons.access_time_rounded
                                      : Icons.calendar_view_week_rounded,
                                  size: 12,
                                  color: AppColors.textSub,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _showDailyTemp
                                      ? 'Show hourly view'
                                      : 'Show weekly view',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Waste card ───────────────────────────────────────────────
                _ReportCard(
                  title: 'Waste Reduced',
                  subtitle: 'Items saved from expiry',
                  icon: Icons.eco_rounded,
                  iconColor: AppColors.medium,
                  trailing: _MonthNavRow(
                    label: _monthLabel(_wasteMonthOffset),
                    onPrev: _wasteMonthOffset > -5 ? () => _shiftMonth(-1) : null,
                    onNext: _wasteMonthOffset < 0 ? () => _shiftMonth(1) : null,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _WasteSavedChart(
                      data: wasteData,
                      maxVal: maxWaste,
                    ),
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

// ── Date nav row ──────────────────────────────────────────────────────────────
class _DateNavRow extends StatelessWidget {
  final String label;
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
        _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ),
        _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

// ── Month nav row ─────────────────────────────────────────────────────────────
class _MonthNavRow extends StatelessWidget {
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _MonthNavRow({required this.label, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSub,
          ),
        ),
        _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

// ── Arrow button ──────────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

// ── Summary pills ─────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final double avgTemp;
  const _SummaryRow({required this.avgTemp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            icon: Icons.thermostat_rounded,
            label: 'Avg Temp',
            value: '${avgTemp.toStringAsFixed(1)}°C',
            color: AppColors.goodColor,
            bg: AppColors.goodBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryPill(
            icon: Icons.eco_rounded,
            label: 'Items Saved',
            value: '14',
            color: AppColors.medium,
            bg: AppColors.surfaceAlt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryPill(
            icon: Icons.trending_up_rounded,
            label: 'This Month',
            value: '+27%',
            color: AppColors.acceptColor,
            bg: AppColors.acceptBg,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

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
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Hourly chart widget ───────────────────────────────────────────────────────
class _HourlyChart extends StatelessWidget {
  final List<double> hourly;
  final double avg;

  const _HourlyChart({required this.hourly, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.goodBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 13, color: AppColors.goodColor),
                  const SizedBox(width: 5),
                  Text(
                    'Avg ${avg.toStringAsFixed(1)}°C — optimal range',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goodText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: _LineChart(
            values: hourly,
            minY: 2.0,
            maxY: 6.0,
            color: AppColors.goodColor,
            fillColor: AppColors.goodBg,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('00:00',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text('06:00',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text('12:00',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text('18:00',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text('Now',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
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

// ── Custom line chart ─────────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<double> values;
  final double minY;
  final double maxY;
  final Color color;
  final Color fillColor;

  const _LineChart({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 100),
      painter: _LineChartPainter(
        values: values,
        minY: minY,
        maxY: maxY,
        color: color,
        fillColor: fillColor,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double minY;
  final double maxY;
  final Color color;
  final Color fillColor;

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
        ..color = fillColor.withOpacity(0.6)
        ..style = PaintingStyle.fill,
    );

    final linePath = Path()..moveTo(0, yFor(values[0]));
    for (int i = 1; i < values.length; i++) {
      final prev = Offset((i - 1) * stepX, yFor(values[i - 1]));
      final curr = Offset(i * stepX, yFor(values[i]));
      final cp1 = Offset(prev.dx + stepX * 0.4, prev.dy);
      final cp2 = Offset(curr.dx - stepX * 0.4, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < values.length; i += 6) {
      canvas.drawCircle(Offset(i * stepX, yFor(values[i])), 3,
          Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.color != color;
}

// ── Daily bar chart ───────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_DayTemp> points;
  final double safeMin;
  final double safeMax;

  const _BarChart({required this.points, required this.safeMin, required this.safeMax});

  @override
  Widget build(BuildContext context) {
    const double maxBarHeight = 90.0;
    const double maxDisplay = 6.5;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final barH =
              (p.temp / maxDisplay).clamp(0.0, 1.0) * maxBarHeight;
          final inRange = p.temp >= safeMin && p.temp <= safeMax;
          final barColor =
              inRange ? AppColors.goodColor : AppColors.dangerColor;
          final bgColor = inRange ? AppColors.goodBg : AppColors.dangerBg;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${p.temp}°',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: barColor)),
                  const SizedBox(height: 3),
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: barColor.withOpacity(0.4), width: 0.8),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.label,
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

// ── Waste bar chart ───────────────────────────────────────────────────────────
class _WasteSavedChart extends StatelessWidget {
  final List<_WastePoint> data;
  final int maxVal;

  const _WasteSavedChart({required this.data, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    const double maxBarHeight = 90.0;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((p) {
          final barH =
              (p.saved / (maxVal + 2)).clamp(0.0, 1.0) * maxBarHeight;
          final intensity = p.saved / maxVal;
          final barColor =
              Color.lerp(AppColors.pale, AppColors.primary, intensity)!;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${p.saved}',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: barColor)),
                  const SizedBox(height: 3),
                  Container(
                    height: barH,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withOpacity(0.5), barColor],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.label,
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

// ── Ornamental divider ────────────────────────────────────────────────────────
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
              color: Colors.white38, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Container(width: 32, height: 0.8, color: Colors.white38),
      ],
    );
  }
}