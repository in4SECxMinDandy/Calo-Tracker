// Water Intake Widget - Simple & Stable Layout
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/water_record.dart';
import '../../../services/water_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/app_icons.dart';

class WaterIntakeWidget extends StatefulWidget {
  final VoidCallback? onWaterAdded;

  const WaterIntakeWidget({super.key, this.onWaterAdded});

  @override
  State<WaterIntakeWidget> createState() => _WaterIntakeWidgetState();
}

class _WaterIntakeWidgetState extends State<WaterIntakeWidget> {
  DailyWaterSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await WaterService.getTodaySummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int amountMl) async {
    await WaterService.addWaterIntake(amountMl);
    await _loadData();
    widget.onWaterAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${amountMl}ml 💧'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }

  void _showCustomDialog() {
    int amount = 250;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.drop_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Thêm nước',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount display
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  amount.toString(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'ml',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getWaterDescription(amount),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF2196F3),
                          inactiveTrackColor:
                              isDark ? Colors.white12 : Colors.grey.shade200,
                          thumbColor: const Color(0xFF1976D2),
                          overlayColor: const Color(
                            0xFF2196F3,
                          ).withValues(alpha: 0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: amount.toDouble(),
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          onChanged: (v) => setState(() => amount = v.round()),
                        ),
                      ),

                      // Quick amount buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAmountBtn(
                              100,
                              amount,
                              (v) => setState(() => amount = v),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickAmountBtn(
                              250,
                              amount,
                              (v) => setState(() => amount = v),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickAmountBtn(
                              500,
                              amount,
                              (v) => setState(() => amount = v),
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Hủy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _addWater(amount);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.add, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Thêm nước',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildQuickAmountBtn(
    int value,
    int currentValue,
    Function(int) onTap,
    bool isDark,
  ) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF2196F3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF1976D2)
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          '${value}ml',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  String _getWaterDescription(int amount) {
    if (amount <= 100) return '~ 1/2 cốc';
    if (amount <= 250) return '~ 1 cốc';
    if (amount <= 500) return '~ 1 chai nhỏ';
    if (amount <= 750) return '~ 1 chai lớn';
    return '~ 1 lít';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary =
        _summary ?? DailyWaterSummary.empty(DateTime.now().toString());
    final progress = (summary.progressPercent / 100).clamp(0.0, 1.0);
    final progressColor = _getProgressColor(summary.progressPercent);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child:
          _isLoading
              ? const SizedBox(
                height: 160,
                child: Center(child: CupertinoActivityIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        AppIcons.water,
                        color: const Color(0xFF2196F3),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nước',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${summary.progressPercent.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.totalAmount}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '/${summary.targetAmount}ml',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Remaining
                  Text(
                    summary.remainingAmount > 0
                        ? 'Còn ${summary.remainingAmount}ml'
                        : '✅ Hoàn thành!',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          summary.remainingAmount > 0
                              ? (isDark ? Colors.white54 : Colors.black45)
                              : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button Grid 2x2
                  Row(
                    children: [
                      Expanded(child: _buildBtn(100, isDark)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildBtn(250, isDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildBtn(500, isDark)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildMoreBtn(isDark)),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildBtn(int amount, bool isDark) {
    return _AnimatedWaterButton(
      amount: amount,
      isDark: isDark,
      onTap: () => _addWater(amount),
    );
  }

  Widget _buildMoreBtn(bool isDark) {
    return _AnimatedWaterButton(
      amount: null,
      isDark: isDark,
      isGradient: true,
      onTap: _showCustomDialog,
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 30) return Colors.red;
    if (progress < 60) return Colors.orange;
    if (progress < 100) return const Color(0xFF2196F3);
    return Colors.green;
  }
}

/// Animated water button with scale animation and haptic feedback
class _AnimatedWaterButton extends StatefulWidget {
  final int? amount;
  final bool isDark;
  final bool isGradient;
  final VoidCallback onTap;

  const _AnimatedWaterButton({
    this.amount,
    required this.isDark,
    this.isGradient = false,
    required this.onTap,
  });

  @override
  State<_AnimatedWaterButton> createState() => _AnimatedWaterButtonState();
}

class _AnimatedWaterButtonState extends State<_AnimatedWaterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _triggerAction() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (mounted) setState(() => _isPressed = false);
    _triggerAction();
  }

  void _onTapCancel() {
    _controller.reverse();
    if (mounted) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // claim hit area before ScrollView
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _triggerAction, // reliable fallback
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 36,
              decoration: BoxDecoration(
                color:
                    widget.isGradient
                        ? null
                        : (_isPressed
                            ? const Color(0xFF1976D2).withValues(alpha: 0.25)
                            : (widget.isDark
                                ? const Color(
                                  0xFF2196F3,
                                ).withValues(alpha: 0.15)
                                : const Color(0xFFE3F2FD))),
                gradient:
                    widget.isGradient
                        ? LinearGradient(
                          colors:
                              _isPressed
                                  ? [
                                    const Color(0xFF1E88E5),
                                    const Color(0xFF1565C0),
                                  ]
                                  : [
                                    const Color(0xFF42A5F5),
                                    const Color(0xFF1E88E5),
                                  ],
                        )
                        : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    _isPressed
                        ? []
                        : [
                          BoxShadow(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              alignment: Alignment.center,
              child:
                  widget.amount != null
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.drop_fill,
                            color: Color(0xFF1976D2),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.amount}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      )
                      : const Icon(
                        CupertinoIcons.ellipsis,
                        color: Colors.white,
                        size: 18,
                      ),
            ),
          );
        },
      ),
    );
  }
}
