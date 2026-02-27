// ============================================================
// gamification_row.dart
// Clean, modular Gamification Icons Row for Dark Mode Health App
// Architecture: Model → NeonIconItem widget → GamificationRow
// ============================================================

import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────
// 1. DATA MODEL
// ────────────────────────────────────────────────────────────

/// Holds all data needed to render a single gamification icon.
class GamificationItem {
  final String title;
  final IconData iconData;
  final Color glowColor;
  final int? badge;

  const GamificationItem({
    required this.title,
    required this.iconData,
    required this.glowColor,
    this.badge,
  });
}

// ────────────────────────────────────────────────────────────
// 2. BASE WIDGET — one isolated neon icon item
// ────────────────────────────────────────────────────────────

class NeonIconItem extends StatelessWidget {
  final GamificationItem item;
  final VoidCallback? onTap;

  // Layout constants — theo iconhome spec (88×88, border 3px)
  static const double _boxSize = 88.0;
  static const double _iconSize = 44.0;
  static const double _radius = 20.0;
  static const double _borderWidth = 3.0;
  static const double _glowBlur = 14.0;
  static const double _glowSpread = 1.5;
  static const double _glowOpacity = 0.55;
  static const double _bgOpacity = 0.10; // tinted dark surface
  static const double _labelSize = 12.0;

  const NeonIconItem({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color glow = item.glowColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Neon box ──────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _boxSize,
                  height: _boxSize,
                  decoration: BoxDecoration(
                    // Dark, slightly tinted background
                    color: glow.withValues(alpha: _bgOpacity),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: glow.withValues(alpha: 0.7),
                      width: _borderWidth,
                    ),
                    boxShadow: [
                      // Outer neon glow
                      BoxShadow(
                        color: glow.withValues(alpha: _glowOpacity),
                        blurRadius: _glowBlur,
                        spreadRadius: _glowSpread,
                      ),
                      // Inner subtle glow (depth)
                      BoxShadow(
                        color: glow.withValues(alpha: 0.2),
                        blurRadius: 4,
                        spreadRadius: -1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      item.iconData,
                      size: _iconSize,
                      color: glow,
                      shadows: [
                        Shadow(
                            color: glow.withValues(alpha: 0.9), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                // Badge
                if (item.badge != null)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: glow,
                        shape: BoxShape.circle,
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

            const SizedBox(height: 8),

            // ── Label ─────────────────────────────────────
            Text(
              item.title,
              style: TextStyle(
                fontSize: _labelSize,
                fontWeight: FontWeight.w600,
                color: glow.withValues(alpha: 0.9),
                letterSpacing: 0.2,
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

  // ── 5 gamification items — single source of truth ──────
  static const List<GamificationItem> _items = [
    GamificationItem(
      // Thử thách: cờ đích đến — biểu tượng hoàn thành thử thách
      title: 'Thử thách',
      iconData: Icons.flag_rounded,
      glowColor: Color(0xFFFF6B35),
    ),
    GamificationItem(
      // Mục tiêu: target/crosshair — biểu tượng nhắm mục tiêu
      title: 'Mục tiêu',
      iconData: Icons.track_changes_rounded,
      glowColor: Color(0xFF00E676),
    ),
    GamificationItem(
      // Streak: lửa — chuỗi ngày liên tiếp
      title: 'Streak',
      iconData: Icons.local_fire_department_rounded,
      glowColor: Color(0xFFFF1744),
      badge: 7,
    ),
    GamificationItem(
      // Thành tích: huy chương quân sự — biểu tượng thành tích cao
      title: 'Thành tích',
      iconData: Icons.military_tech_rounded,
      glowColor: Color(0xFFFFD700),
    ),
    GamificationItem(
      // Thống kê: insights — biểu tượng phân tích dữ liệu
      title: 'Thống kê',
      iconData: Icons.insights_rounded,
      glowColor: Color(0xFF448AFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
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
