// Macro Bar Widget - Animated Progress Bar
// Shows macronutrient consumption with smooth animation
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class MacroBar extends StatefulWidget {
  final String label;
  final double value;
  final double max;
  final String unit;
  final Color color;
  final MacroBarSize size;
  final VoidCallback? onTap;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.unit = 'g',
    required this.color,
    this.size = MacroBarSize.small,
    this.onTap,
  });

  @override
  State<MacroBar> createState() => _MacroBarState();
}

class _MacroBarState extends State<MacroBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    // Delay animation slightly for staggered effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MacroBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.max != widget.max) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = (widget.value / widget.max).clamp(0.0, 1.0);
    final height = widget.size == MacroBarSize.small ? 6.0 : 10.0;

    final backgroundColor = isDark
        ? AppColors.darkMuted
        : AppColors.lightMuted;

    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Label
            SizedBox(
              width: 24,
              child: Text(
                widget.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textColor,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Progress bar
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage * _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Value
            SizedBox(
              width: 32,
              child: Text(
                '${widget.value.toInt()}${widget.unit}',
                textAlign: TextAlign.right,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MacroBarSize {
  small,
  medium,
}
