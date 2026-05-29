import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ExpiryItem {
  final int id;
  final String name;
  final String status;
  double initialLife; // days — can be updated by user
  bool confirmed;

  ExpiryItem({
    required this.id,
    required this.name,
    required this.status,
    required this.initialLife,
    this.confirmed = false,
  });

  factory ExpiryItem.fromJson(Map<String, dynamic> j) => ExpiryItem(
        id:          int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        name:        j['item_name']?.toString() ?? 'Unknown',
        status:      j['status']?.toString() ?? 'acceptable',
        initialLife: double.tryParse(
                       j['initial_life']?.toString() ?? '7',
                     ) ?? 7,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ExpiryScreen extends StatefulWidget {
  const ExpiryScreen({super.key});

  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> {
  List<ExpiryItem> _items    = [];
  bool             _loading  = true;
  String?          _error;

  String get _baseUrl => kIsWeb
      ? 'http://localhost:8080'
      : 'http://192.168.1.8:8080';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> _loadItems() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/get_expiry'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as List;
        setState(() {
          _items   = raw.map((j) => ExpiryItem.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not reach server.\n$e'; _loading = false; });
    }
  }

  // ── Save expiry to backend ─────────────────────────────────────────────────
  Future<void> _saveExpiry(ExpiryItem item) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/set_expiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': item.id, 'initial_life': item.initialLife}),
      );
    } catch (_) {
      // Silent — local state already updated
    }
  }

  // ── Date picker dialog ─────────────────────────────────────────────────────
  Future<void> _pickDate(ExpiryItem item) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate:   now,
      lastDate:    now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final days = picked.difference(now).inDays.toDouble().clamp(1.0, 365.0);
    setState(() {
      item.initialLife = days;
      item.confirmed   = true;
    });
    await _saveExpiry(item);
  }

  // ── Use default ────────────────────────────────────────────────────────────
  Future<void> _useDefault(ExpiryItem item) async {
    setState(() { item.confirmed = true; });
    await _saveExpiry(item);
  }

  // ── Status colour ──────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'spoiled':    return AppColors.spoiledColor;
      case 'danger':     return AppColors.dangerColor;
      case 'acceptable': return AppColors.acceptColor;
      default:           return AppColors.goodColor;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'spoiled':    return AppColors.spoiledBg;
      case 'danger':     return AppColors.dangerBg;
      case 'acceptable': return AppColors.acceptBg;
      default:           return AppColors.goodBg;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned:          true,
            expandedHeight:  130,
            backgroundColor: AppColors.primary,
            elevation:       0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background:   _ExpiryHeader(onRefresh: _loadItems),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: _SummaryBar(items: _items),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.medium),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSub, fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _loadItems,
                          child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No items in fridge.',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                        fontSize: 14)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ItemCard(
                    item:       _items[i],
                    statusColor: _statusColor(_items[i].status),
                    statusBg:    _statusBg(_items[i].status),
                    onAddDate:   () => _pickDate(_items[i]),
                    onDefault:   () => _useDefault(_items[i]),
                  ),
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ExpiryHeader({required this.onRefresh});

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
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 12,
        bottom: 40,
        left:   20,
        right:  20,
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Expiry Setup',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Confirm or set shelf life for each item',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:         Colors.white.withOpacity(0.15),
                borderRadius:  BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<ExpiryItem> items;
  const _SummaryBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final total     = items.length;
    final confirmed = items.where((i) => i.confirmed).length;
    final fraction  = total > 0 ? confirmed / total : 0.0;

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$confirmed / $total confirmed',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${(fraction * 100).toInt()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           fraction,
              minHeight:       4,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:      const AlwaysStoppedAnimation(
                  Color(0xFF6EE0A0)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ExpiryItem item;
  final Color      statusColor;
  final Color      statusBg;
  final VoidCallback onAddDate;
  final VoidCallback onDefault;

  const _ItemCard({
    required this.item,
    required this.statusColor,
    required this.statusBg,
    required this.onAddDate,
    required this.onDefault,
  });

  @override
  Widget build(BuildContext context) {
    final days = item.initialLife.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.confirmed
              ? AppColors.goodColor.withOpacity(0.4)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Image placeholder ─────────────────────────────────────────────
          Container(
            width:  80,
            height: 90,
            decoration: BoxDecoration(
              color:        AppColors.surfaceAlt,
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_rounded,
                    size: 30, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 4),
                Text(
                  item.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.w800,
                    color:      AppColors.medium.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.textPrimary,
                          ),
                          maxLines:  1,
                          overflow:  TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize:   9,
                            fontWeight: FontWeight.w700,
                            color:      statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Days info
                  Row(
                    children: [
                      Icon(
                        item.confirmed
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size:  13,
                        color: item.confirmed
                            ? AppColors.goodColor
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.confirmed
                            ? 'Set to $days day${days == 1 ? '' : 's'}'
                            : 'Default: $days day${days == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          color:    item.confirmed
                              ? AppColors.goodText
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Buttons
                  if (!item.confirmed)
                    Row(
                      children: [
                        // Add date button
                        Expanded(
                          child: _CardButton(
                            label:  'Add Date',
                            icon:   Icons.calendar_today_rounded,
                            color:  AppColors.primary,
                            filled: true,
                            onTap:  onAddDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Default button
                        Expanded(
                          child: _CardButton(
                            label:  'Default',
                            icon:   Icons.auto_awesome_rounded,
                            color:  AppColors.medium,
                            filled: false,
                            onTap:  onDefault,
                          ),
                        ),
                      ],
                    )
                  else
                    // Confirmed state
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:        AppColors.goodBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: AppColors.goodColor),
                          SizedBox(width: 6),
                          Text(
                            'Expiry confirmed',
                            style: TextStyle(
                              fontSize:   11,
                              color:      AppColors.goodText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CardButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     filled;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border:       Border.all(
            color: filled ? color : color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size:  13,
                color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}