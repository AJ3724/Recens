import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../widgets/shared.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

String get _apiUrl {
  if (kIsWeb) return 'http://localhost:8080/get_items';
  return 'http://192.168.1.8:8080/get_items';
}

// ── Model ─────────────────────────────────────────────────────────────────────
class PredictionItem {
  final int id;
  final String itemName;
  final String type;
  final int oldTemp;
  final int newTemp;
  final int humidity;
  final int initialLife;
  final int timeBeforeTimeInBetween;
  final int lifeRemaining;
  final String status;
  final int? itemNameVal;
  final int? typeVal;
  final double? oldDecay;
  final double? spikeDamage;

  const PredictionItem({
    required this.id,
    required this.itemName,
    required this.type,
    required this.oldTemp,
    required this.newTemp,
    required this.humidity,
    required this.initialLife,
    required this.timeBeforeTimeInBetween,
    required this.lifeRemaining,
    required this.status,
    this.itemNameVal,
    this.typeVal,
    this.oldDecay,
    this.spikeDamage,
  });

  factory PredictionItem.fromJson(Map<String, dynamic> json) {
    return PredictionItem(
      id: int.parse(json['id'].toString()),
      itemName: json['item_name'] ?? '',
      type: json['type'] ?? '',
      oldTemp: int.parse(json['old_temp'].toString()),
      newTemp: int.parse(json['new_temp'].toString()),
      humidity: int.parse(json['humidity'].toString()),
      initialLife: int.parse(json['initial_life'].toString()),
      timeBeforeTimeInBetween:
          int.parse(json['time_before_time_in_between'].toString()),
      lifeRemaining: int.parse(json['life_remaining'].toString()),
      status: json['status'] ?? '',
      itemNameVal: json['item_name_val'] != null
          ? int.parse(json['item_name_val'].toString())
          : null,
      typeVal: json['type_val'] != null
          ? int.parse(json['type_val'].toString())
          : null,
      oldDecay: json['old_decay'] != null
          ? double.parse(json['old_decay'].toString())
          : null,
      spikeDamage: json['spike_damage'] != null
          ? double.parse(json['spike_damage'].toString())
          : null,
    );
  }

  double get freshnessFraction =>
      initialLife > 0 ? (lifeRemaining / initialLife).clamp(0.0, 1.0) : 0.0;

  FridgeStatus get fridgeStatus {
    switch (status.toLowerCase()) {
      case 'good':
        return FridgeStatus.good;
      case 'acceptable':
        return FridgeStatus.acceptable;
      case 'danger':
        return FridgeStatus.danger;
      case 'spoiled':
        return FridgeStatus.spoiled;
      default:
        if (lifeRemaining <= 0) return FridgeStatus.spoiled;
        if (lifeRemaining / initialLife < 0.2) return FridgeStatus.danger;
        if (lifeRemaining / initialLife < 0.5) return FridgeStatus.acceptable;
        return FridgeStatus.good;
    }
  }

  Color get statusColor {
    switch (fridgeStatus) {
      case FridgeStatus.good:
        return AppColors.goodColor;
      case FridgeStatus.acceptable:
        return AppColors.acceptColor;
      case FridgeStatus.danger:
        return AppColors.dangerColor;
      case FridgeStatus.spoiled:
        return AppColors.spoiledColor;
    }
  }

  Color get badgeBg {
    switch (fridgeStatus) {
      case FridgeStatus.good:
        return AppColors.goodBg;
      case FridgeStatus.acceptable:
        return AppColors.acceptBg;
      case FridgeStatus.danger:
        return AppColors.dangerBg;
      case FridgeStatus.spoiled:
        return AppColors.spoiledBg;
    }
  }

  Color get badgeText {
    switch (fridgeStatus) {
      case FridgeStatus.good:
        return AppColors.goodText;
      case FridgeStatus.acceptable:
        return AppColors.acceptText;
      case FridgeStatus.danger:
        return AppColors.dangerText;
      case FridgeStatus.spoiled:
        return AppColors.spoiledText;
    }
  }

  String get statusLabel {
    switch (fridgeStatus) {
      case FridgeStatus.good:
        return 'Good';
      case FridgeStatus.acceptable:
        return 'Acceptable';
      case FridgeStatus.danger:
        return 'Danger';
      case FridgeStatus.spoiled:
        return 'Spoiled';
    }
  }

  String get daysLabel {
    if (fridgeStatus == FridgeStatus.spoiled) return 'Expired';
    if (lifeRemaining < 24) return '${lifeRemaining}h left';
    final days = (lifeRemaining / 24).toStringAsFixed(1);
    return '$days days left';
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'vegetable':
        return Icons.grass_rounded;
      case 'fruit':
        return Icons.energy_savings_leaf_rounded;
      case 'dairy':
        return Icons.water_drop_outlined;
      case 'meat':
        return Icons.restaurant_rounded;
      case 'herb':
        return Icons.eco_rounded;
      case 'grain':
        return Icons.grain_rounded;
      case 'condiment':
        return Icons.local_dining_rounded;
      case 'beverage':
        return Icons.local_drink_rounded;
      default:
        return Icons.kitchen_rounded;
    }
  }
}

enum FridgeStatus { good, acceptable, danger, spoiled }

const Map<String, IconData> categoryIcons = {
  'vegetable': Icons.grass_rounded,
  'fruit': Icons.energy_savings_leaf_rounded,
  'dairy': Icons.water_drop_outlined,
  'meat': Icons.restaurant_rounded,
  'herb': Icons.eco_rounded,
  'grain': Icons.grain_rounded,
  'condiment': Icons.local_dining_rounded,
  'beverage': Icons.local_drink_rounded,
};

const List<String> categoryOrder = [
  'vegetable', 'fruit', 'herb', 'meat', 'dairy', 'grain', 'condiment', 'beverage',
];

// ── Main Screen ───────────────────────────────────────────────────────────────
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  List<PredictionItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
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
          _items = data.map((j) => PredictionItem.fromJson(j)).toList();
          _loading = false;
        });
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

  void _showItemDetail(BuildContext context, PredictionItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  Map<String, List<PredictionItem>> _buildGrouped() {
    final Map<String, List<PredictionItem>> grouped = {};
    for (final cat in categoryOrder) {
      final items = _items.where((i) => i.type.toLowerCase() == cat).toList();
      if (items.isNotEmpty) grouped[cat] = items;
    }
    for (final item in _items) {
      final k = item.type.toLowerCase();
      if (!grouped.containsKey(k)) {
        grouped[k] = _items.where((i) => i.type.toLowerCase() == k).toList();
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final dangerCount  = _items.where((i) => i.fridgeStatus == FridgeStatus.danger).length;
    final spoiledCount = _items.where((i) => i.fridgeStatus == FridgeStatus.spoiled).length;
    final goodCount    = _items.where((i) => i.fridgeStatus == FridgeStatus.good).length;
    final acceptCount  = _items.where((i) => i.fridgeStatus == FridgeStatus.acceptable).length;
    final grouped      = _buildGrouped();
    final categories   = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: const [
            Icon(Icons.kitchen_rounded, size: 18, color: AppColors.textSub),
            SizedBox(width: 8),
            Text('My Fridge'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('${_items.length} items',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSub)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _fetchItems,
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetchItems)
              : _items.isEmpty
                  ? const Center(
                      child: Text('No items found',
                          style: TextStyle(color: AppColors.textSub)))
                  : _FridgeBody(
                      dangerCount: dangerCount,
                      spoiledCount: spoiledCount,
                      goodCount: goodCount,
                      acceptCount: acceptCount,
                      grouped: grouped,
                      categories: categories,
                      onItemTap: (item) => _showItemDetail(context, item),
                    ),
    );
  }
}

// ── Fridge Body ───────────────────────────────────────────────────────────────
class _FridgeBody extends StatelessWidget {
  final int dangerCount, spoiledCount, goodCount, acceptCount;
  final Map<String, List<PredictionItem>> grouped;
  final List<String> categories;
  final void Function(PredictionItem) onItemTap;

  const _FridgeBody({
    required this.dangerCount,
    required this.spoiledCount,
    required this.goodCount,
    required this.acceptCount,
    required this.grouped,
    required this.categories,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status overview card ─────────────────────────────────────────
          _StatusOverviewCard(
            goodCount: goodCount,
            acceptCount: acceptCount,
            dangerCount: dangerCount,
            spoiledCount: spoiledCount,
          ),

          const SizedBox(height: 20),

          // ── Fridge interior container ────────────────────────────────────
          _FridgeContainer(
            grouped: grouped,
            categories: categories,
            onItemTap: onItemTap,
          ),
        ],
      ),
    );
  }
}

// ── Status Overview Card ──────────────────────────────────────────────────────
class _StatusOverviewCard extends StatelessWidget {
  final int goodCount, acceptCount, dangerCount, spoiledCount;
  const _StatusOverviewCard({
    required this.goodCount,
    required this.acceptCount,
    required this.dangerCount,
    required this.spoiledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FRIDGE OVERVIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OvCard(count: goodCount,    label: 'Good',       bg: AppColors.goodBg,    text: AppColors.goodText),
              const SizedBox(width: 8),
              _OvCard(count: acceptCount,  label: 'Acceptable', bg: AppColors.acceptBg,  text: AppColors.acceptText),
              const SizedBox(width: 8),
              _OvCard(count: dangerCount,  label: 'Danger',     bg: AppColors.dangerBg,  text: AppColors.dangerText),
              const SizedBox(width: 8),
              _OvCard(count: spoiledCount, label: 'Spoiled',    bg: AppColors.spoiledBg, text: AppColors.spoiledText),
            ],
          ),
        ],
      ),
    );
  }
}

class _OvCard extends StatelessWidget {
  final int count;
  final String label;
  final Color bg, text;
  const _OvCard(
      {required this.count,
      required this.label,
      required this.bg,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: text)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 9, color: text.withOpacity(0.8)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Fridge Container ──────────────────────────────────────────────────────────
class _FridgeContainer extends StatelessWidget {
  final Map<String, List<PredictionItem>> grouped;
  final List<String> categories;
  final void Function(PredictionItem) onItemTap;

  const _FridgeContainer({
    required this.grouped,
    required this.categories,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fridgeWall,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fridgeShelfEdge.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            // ── LED light strip ────────────────────────────────────────────
            _LightStrip(),

            // ── Category shelves ───────────────────────────────────────────
            for (final category in categories) ...[
              _FridgeShelf(
                label: '${category[0].toUpperCase()}${category.substring(1)}s',
                labelIcon: categoryIcons[category] ?? Icons.category_rounded,
                count: grouped[category]!.length,
                child: _CategoryGrid(
                  items: grouped[category]!,
                  onTap: onItemTap,
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── LED Light Strip ───────────────────────────────────────────────────────────
class _LightStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.goodBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.pale.withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 14; i++) ...[
            const SizedBox(width: 10),
            Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Fridge Shelf ──────────────────────────────────────────────────────────────
class _FridgeShelf extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final int? count;
  final Widget child;

  const _FridgeShelf({
    required this.label,
    required this.labelIcon,
    required this.child,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.fridgeLabelBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(labelIcon,
                        size: 12, color: AppColors.fridgeLabelText),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fridgeLabelText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 17, height: 17,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$count',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.fridgeLabelText)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: child,
        ),

        // Glass shelf edge
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(double.infinity, 14),
          painter: _ShelfEdgePainter(),
        ),
      ],
    );
  }
}

class _ShelfEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 2, size.width, 10), const Radius.circular(2)),
      Paint()..color = AppColors.fridgeShelf,
    );
    canvas.drawLine(
      const Offset(0, 2),
      Offset(size.width, 2),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(4, 12),
      Offset(size.width - 4, 12),
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..strokeWidth = 2,
    );
    for (final x in [8.0, size.width - 8]) {
      canvas.drawCircle(
          Offset(x, 7), 3, Paint()..color = AppColors.fridgeShelfEdge);
    }
  }

  @override
  bool shouldRepaint(_ShelfEdgePainter old) => false;
}

// ── Category Grid ─────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final List<PredictionItem> items;
  final void Function(PredictionItem) onTap;

  const _CategoryGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FridgeItemCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}

// ── Fridge Item Card ──────────────────────────────────────────────────────────
class _FridgeItemCard extends StatelessWidget {
  final PredictionItem item;
  final VoidCallback onTap;

  const _FridgeItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: item.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(item.icon,
                          size: 30,
                          color: AppColors.medium.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textSub)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Detail Sheet ─────────────────────────────────────────────────────────
class _ItemDetailSheet extends StatelessWidget {
  final PredictionItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(item.icon, size: 28, color: AppColors.medium),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(item.type,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSub)),
                  ],
                ),
              ),
              StatusBadge(
                  label: item.statusLabel,
                  bg: item.badgeBg,
                  textColor: item.badgeText),
            ],
          ),

          const SizedBox(height: 20),

          // Freshness bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Life remaining',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSub)),
              Text(item.daysLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.statusColor)),
            ],
          ),
          const SizedBox(height: 6),
          FreshnessBar(
              fraction: item.freshnessFraction,
              color: item.statusColor,
              height: 6),

          const SizedBox(height: 20),

          // Details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Previous Temp', value: '${item.oldTemp}°C'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Current Temp',  value: '${item.newTemp}°C'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Humidity',      value: '${item.humidity}%'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Initial Life',  value: '${item.initialLife}h'),
                const SizedBox(height: 10),
                _InfoRow(label: 'Time Interval', value: '${item.timeBeforeTimeInBetween}h'),
                const SizedBox(height: 10),
                _InfoRow(
                    label: 'Life Remaining',
                    value: '${item.lifeRemaining}h'),
                if (item.oldDecay != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                      label: 'Decay Rate',
                      value: item.oldDecay!.toStringAsFixed(4)),
                ],
                if (item.spikeDamage != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                      label: 'Spike Damage',
                      value: item.spikeDamage!.toStringAsFixed(4)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSub)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}