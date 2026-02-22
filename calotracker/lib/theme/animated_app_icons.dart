// Animated App Icons - Lucide Animated Icons Wrapper
// Premium animated icons for CaloTracker using flutter_lucide_animated
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    // Note: lucide.leaf is not available in flutter_lucide_animated v0.0.4
    // Using sparkles as the closest nature-themed animated icon available
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

  static Widget edit({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.pencil, size: size, color: color);

  static Widget trash({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.trash, size: size, color: color);

  static Widget checkCircle({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.circle_check,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget alertCircle({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.exclamationmark_circle, size: size, color: color);

  static Widget info({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.info, size: size, color: color);

  static Widget trophy({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(Icons.emoji_events, size: size, color: color);

  static Widget share({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.share, size: size, color: color);

  static Widget moreVertical({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.ellipsis_vertical, size: size, color: color);

  static Widget lock({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => lucide.LucideAnimatedIcon(
    icon: lucide.lock,
    size: size,
    color: color,
    trigger: trigger,
    controller: controller,
  );

  static Widget globe({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.globe, size: size, color: color);

  static Widget shield({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.shield, size: size, color: color);

  static Widget flag({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.flag, size: size, color: color);

  static Widget userPlus({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.person_add, size: size, color: color);

  static Widget send({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.paperplane, size: size, color: color);

  static Widget image({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.photo, size: size, color: color);

  static Widget filter({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.slider_horizontal_3, size: size, color: color);

  static Widget target({
    double size = 24,
    Color color = const Color(0xFF000000),
    lucide.AnimationTrigger trigger = lucide.AnimationTrigger.onTap,
    lucide.LucideAnimatedIconController? controller,
  }) => Icon(CupertinoIcons.scope, size: size, color: color);
}
