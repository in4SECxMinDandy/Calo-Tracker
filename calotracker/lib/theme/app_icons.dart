// App Icons - Professional Icon Set
// Curated icons for a premium health & wellness app experience
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Professional icon set for CaloTracker
/// Uses Cupertino (iOS) icons as primary with Material fallbacks
class AppIcons {
  AppIcons._();

  // ==================== NAVIGATION ====================
  static const IconData home = CupertinoIcons.house_fill;
  static const IconData homeOutline = CupertinoIcons.house;
  static const IconData statistics = CupertinoIcons.chart_bar_fill;
  static const IconData statisticsOutline = CupertinoIcons.chart_bar;
  static const IconData community = CupertinoIcons.person_2_fill;
  static const IconData communityOutline = CupertinoIcons.person_2;
  static const IconData profile = CupertinoIcons.person_circle_fill;
  static const IconData profileOutline = CupertinoIcons.person_circle;
  static const IconData settings = CupertinoIcons.gear_alt_fill;
  static const IconData settingsOutline = CupertinoIcons.gear_alt;

  // ==================== HEALTH & NUTRITION ====================
  static const IconData calories = CupertinoIcons.flame_fill;
  static const IconData caloriesOutline = CupertinoIcons.flame;
  static const IconData food = Icons.restaurant_rounded;
  static const IconData foodOutline = Icons.restaurant_outlined;
  static const IconData water = CupertinoIcons.drop_fill;
  static const IconData waterOutline = CupertinoIcons.drop;
  static const IconData heart = CupertinoIcons.heart_fill;
  static const IconData heartOutline = CupertinoIcons.heart;
  static const IconData sleep = CupertinoIcons.moon_fill;
  static const IconData sleepOutline = CupertinoIcons.moon;
  static const IconData weight = Icons.monitor_weight_rounded;
  static const IconData weightOutline = Icons.monitor_weight_outlined;
  static const IconData steps = Icons.directions_walk_rounded;
  static const IconData nutrition = CupertinoIcons.leaf_arrow_circlepath;

  // ==================== MEALS ====================
  static const IconData breakfast = Icons.wb_sunny_rounded;
  static const IconData lunch = Icons.light_mode_rounded;
  static const IconData dinner = Icons.nightlight_round;
  static const IconData snack = Icons.cookie_rounded;
  static const IconData meal = Icons.lunch_dining_rounded;

  // ==================== EXERCISE ====================
  static const IconData exercise = CupertinoIcons.sportscourt_fill;
  static const IconData exerciseOutline = CupertinoIcons.sportscourt;
  static const IconData running = Icons.directions_run_rounded;
  static const IconData gym = Icons.fitness_center_rounded;
  static const IconData yoga = Icons.self_improvement_rounded;
  static const IconData swimming = Icons.pool_rounded;
  static const IconData cycling = Icons.directions_bike_rounded;
  static const IconData timer = CupertinoIcons.timer;
  static const IconData timerFill = CupertinoIcons.timer_fill;
  static const IconData stopwatch = CupertinoIcons.stopwatch_fill;

  // ==================== ACTIONS ====================
  static const IconData add = CupertinoIcons.plus;
  static const IconData addCircle = CupertinoIcons.plus_circle_fill;
  static const IconData remove = CupertinoIcons.minus;
  static const IconData removeCircle = CupertinoIcons.minus_circle_fill;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData delete = CupertinoIcons.trash_fill;
  static const IconData deleteOutline = CupertinoIcons.trash;
  static const IconData share = CupertinoIcons.share;
  static const IconData shareFill = CupertinoIcons.share_solid;
  static const IconData save = CupertinoIcons.bookmark_fill;
  static const IconData saveOutline = CupertinoIcons.bookmark;
  static const IconData refresh = CupertinoIcons.refresh;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData closeCircle = CupertinoIcons.xmark_circle_fill;
  static const IconData check = CupertinoIcons.checkmark;
  static const IconData checkCircle = CupertinoIcons.checkmark_circle_fill;
  static const IconData checkCircleOutline = CupertinoIcons.checkmark_circle;

  // ==================== CAMERA & SCAN ====================
  static const IconData camera = CupertinoIcons.camera_fill;
  static const IconData cameraOutline = CupertinoIcons.camera;
  static const IconData scan = CupertinoIcons.qrcode_viewfinder;
  static const IconData barcode = CupertinoIcons.barcode_viewfinder;
  static const IconData photo = CupertinoIcons.photo_fill;
  static const IconData photoOutline = CupertinoIcons.photo;
  static const IconData gallery = CupertinoIcons.photo_on_rectangle;

  // ==================== SOCIAL ====================
  static const IconData like = CupertinoIcons.hand_thumbsup_fill;
  static const IconData likeOutline = CupertinoIcons.hand_thumbsup;
  static const IconData comment = CupertinoIcons.chat_bubble_fill;
  static const IconData commentOutline = CupertinoIcons.chat_bubble;
  static const IconData send = CupertinoIcons.paperplane_fill;
  static const IconData sendOutline = CupertinoIcons.paperplane;
  static const IconData notification = CupertinoIcons.bell_fill;
  static const IconData notificationOutline = CupertinoIcons.bell;
  static const IconData group = CupertinoIcons.person_3_fill;
  static const IconData addFriend = CupertinoIcons.person_badge_plus_fill;

  // ==================== NAVIGATION & UI ====================
  static const IconData back = CupertinoIcons.chevron_back;
  static const IconData forward = CupertinoIcons.chevron_forward;
  static const IconData up = CupertinoIcons.chevron_up;
  static const IconData down = CupertinoIcons.chevron_down;
  static const IconData menu = CupertinoIcons.line_horizontal_3;
  static const IconData more = CupertinoIcons.ellipsis;
  static const IconData moreCircle = CupertinoIcons.ellipsis_circle_fill;
  static const IconData search = CupertinoIcons.search;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData sort = CupertinoIcons.arrow_up_arrow_down;
  static const IconData info = CupertinoIcons.info_circle_fill;
  static const IconData infoOutline = CupertinoIcons.info_circle;
  static const IconData help = CupertinoIcons.question_circle_fill;
  static const IconData helpOutline = CupertinoIcons.question_circle;
  static const IconData warning = CupertinoIcons.exclamationmark_triangle_fill;
  static const IconData error = CupertinoIcons.xmark_octagon_fill;

  // ==================== CALENDAR & TIME ====================
  static const IconData calendar = CupertinoIcons.calendar;
  static const IconData calendarFill = CupertinoIcons.calendar_circle_fill;
  static const IconData clock = CupertinoIcons.clock_fill;
  static const IconData clockOutline = CupertinoIcons.clock;
  static const IconData alarm = CupertinoIcons.alarm_fill;
  static const IconData alarmOutline = CupertinoIcons.alarm;
  static const IconData history = CupertinoIcons.time;

  // ==================== ACHIEVEMENTS ====================
  static const IconData trophy = CupertinoIcons.rosette;
  static const IconData star = CupertinoIcons.star_fill;
  static const IconData starOutline = CupertinoIcons.star;
  static const IconData badge = Icons.military_tech_rounded;
  static const IconData crown = Icons.workspace_premium_rounded;
  static const IconData medal = Icons.emoji_events_rounded;
  static const IconData target = Icons.track_changes_rounded;
  static const IconData flag = CupertinoIcons.flag_fill;
  static const IconData flagOutline = CupertinoIcons.flag;
  static const IconData streak = CupertinoIcons.bolt_fill;
  static const IconData level = Icons.layers_rounded;

  // ==================== CHARTS & DATA ====================
  static const IconData chart = CupertinoIcons.chart_bar_alt_fill;
  static const IconData chartLine = CupertinoIcons.graph_circle_fill;
  static const IconData chartPie = CupertinoIcons.chart_pie_fill;
  static const IconData trend = CupertinoIcons.arrow_up_right;
  static const IconData trendDown = CupertinoIcons.arrow_down_right;
  static const IconData analytics = Icons.analytics_rounded;

  // ==================== SETTINGS & PREFERENCES ====================
  static const IconData theme = CupertinoIcons.paintbrush_fill;
  static const IconData darkMode = CupertinoIcons.moon_circle_fill;
  static const IconData lightMode = CupertinoIcons.sun_max_fill;
  static const IconData language = CupertinoIcons.globe;
  static const IconData privacy = CupertinoIcons.lock_fill;
  static const IconData privacyOutline = CupertinoIcons.lock;
  static const IconData security = CupertinoIcons.shield_fill;
  static const IconData sound = CupertinoIcons.speaker_2_fill;
  static const IconData soundOff = CupertinoIcons.speaker_slash_fill;
  static const IconData vibration = Icons.vibration_rounded;

  // ==================== CONNECTIVITY ====================
  static const IconData online = CupertinoIcons.globe;
  static const IconData offline = CupertinoIcons.antenna_radiowaves_left_right;
  static const IconData sync = CupertinoIcons.arrow_2_circlepath;
  static const IconData cloud = CupertinoIcons.cloud_fill;
  static const IconData cloudUpload = CupertinoIcons.cloud_upload_fill;
  static const IconData cloudDownload = CupertinoIcons.cloud_download_fill;

  // ==================== AUTH ====================
  static const IconData login = CupertinoIcons.arrow_right_to_line;
  static const IconData logout = CupertinoIcons.arrow_right_square;
  static const IconData user = CupertinoIcons.person_fill;
  static const IconData userOutline = CupertinoIcons.person;
  static const IconData email = CupertinoIcons.envelope_fill;
  static const IconData emailOutline = CupertinoIcons.envelope;
  static const IconData password = CupertinoIcons.lock_shield_fill;
  static const IconData eye = CupertinoIcons.eye_fill;
  static const IconData eyeSlash = CupertinoIcons.eye_slash_fill;
  static const IconData google = Icons.g_mobiledata_rounded;
  static const IconData apple = Icons.apple_rounded;
  static const IconData facebook = Icons.facebook_rounded;

  // ==================== MISC ====================
  static const IconData location = CupertinoIcons.location_fill;
  static const IconData locationOutline = CupertinoIcons.location;
  static const IconData phone = CupertinoIcons.phone_fill;
  static const IconData link = CupertinoIcons.link;
  static const IconData copy = CupertinoIcons.doc_on_doc;
  static const IconData paste = CupertinoIcons.doc_on_clipboard;
  static const IconData gift = CupertinoIcons.gift_fill;
  static const IconData sparkles = CupertinoIcons.sparkles;
  static const IconData bolt = CupertinoIcons.bolt_fill;
  static const IconData leaf = CupertinoIcons.leaf_arrow_circlepath;
  static const IconData ai = Icons.auto_awesome_rounded;
  static const IconData magic = Icons.auto_fix_high_rounded;
  static const IconData voice = CupertinoIcons.mic_fill;
  static const IconData voiceOutline = CupertinoIcons.mic;
}

/// Icon widget with consistent styling
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return Icon(icon, size: size, color: color ?? defaultColor);
  }
}

/// Gradient icon for premium feel
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            colors: colors,
            begin: begin,
            end: end,
          ).createShader(bounds),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

/// Animated icon with bounce effect
class AnimatedAppIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool animate;
  final Duration duration;

  const AnimatedAppIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.animate = true,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void bounce() {
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.animate ? bounce : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AppIcon(
          icon: widget.icon,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}
