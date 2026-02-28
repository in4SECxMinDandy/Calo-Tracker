// ============================================================
// gamification_row.dart
// Clean, professional Gamification Icons Row
// No neon effects - modern flat design with subtle shadows
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ────────────────────────────────────────────────────────────
// 1. DATA MODEL
// ────────────────────────────────────────────────────────────

/// Holds all data needed to render a single gamification icon.
class GamificationItem {
  final String title;
  final IconData iconData;
  final Color color;
  final int? badge;

  const GamificationItem({
    required this.title,
    required this.iconData,
    required this.color,
    this.badge,
  });
}

// ────────────────────────────────────────────────────────────
// 2. BASE WIDGET — one clean icon item
// ────────────────────────────────────────────────────────────

class NeonIconItem extends StatelessWidget {
  final GamificationItem item;
  final VoidCallback? onTap;

  const NeonIconItem({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = item.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon box ──────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      item.iconData,
                      size: 32,
                      color: color,
                    ),
                  ),
                ),
                // Badge
                if (item.badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${item.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Label ─────────────────────────────────────
            Text(
              item.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.65),
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// 3. MAIN VIEW — list data + horizontal render
// ────────────────────────────────────────────────────────────

class GamificationRow extends StatelessWidget {
  /// Legacy single-tap callback — used when [onItemTaps] is not provided.
  final VoidCallback? onItemTap;

  /// Per-item tap callbacks indexed by position (0–4).
  /// When provided, each item uses its own callback instead of [onItemTap].
  final List<VoidCallback?>? onItemTaps;

  const GamificationRow({super.key, this.onItemTap, this.onItemTaps});

  // ── 2 gamification items — Thành tích & Thống kê ──────
  static const List<GamificationItem> _items = [
    GamificationItem(
      // Thành tích: huy chương
      title: 'Thành tích',
      iconData: CupertinoIcons.rosette,
      color: Color(0xFFFFB800),
    ),
    GamificationItem(
      // Thống kê: biểu đồ
      title: 'Thống kê',
      iconData: CupertinoIcons.chart_bar_alt_fill,
      color: Color(0xFF3B82F6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tap = (onItemTaps != null && index < onItemTaps!.length)
              ? onItemTaps![index]
              : onItemTap;
          return NeonIconItem(item: _items[index], onTap: tap);
        },
      ),
    );
  }
}
