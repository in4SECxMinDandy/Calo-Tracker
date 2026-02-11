// Animated App Icons - Lucide Animated Icons Wrapper
// Premium animated icons for CaloTracker using flutter_lucide_animated
import 'package:flutter/material.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;

/// Lớp tiện ích cung cấp Lucide Animated Icons cho CaloTracker.
/// Mỗi phương thức trả về một Widget LucideAnimatedIcon đã được cấu hình sẵn.
class AnimatedAppIcons {
  AnimatedAppIcons._();

  // ==================== ĐIỀU HƯỚNG (NAVIGATION) ====================

  static Widget home({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.home,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget community({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.users,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget statistics({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.chart_bar_increasing,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget profile({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.user,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget ai({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.sparkles,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget settings({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.settings,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  // ==================== HÀNH ĐỘNG (ACTIONS) ====================

  static Widget scan({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.scan_face,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget heart({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.heart,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget bell({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.bell,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget search({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.search,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget calendar({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.calendar_days,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget bookmark({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.bookmark,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget messageCircle({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.message_circle,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  // ==================== SỨC KHỎE (HEALTH) ====================

  static Widget flame({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.flame,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget droplet({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.droplet,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget moon({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.moon,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget leaf({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.sparkles,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget zap({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.zap,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  // ==================== KHÁC (OTHER) ====================

  static Widget plus({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.plus,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );
}
