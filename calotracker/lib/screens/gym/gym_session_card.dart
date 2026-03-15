import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'premium_theme.dart';
import '../../models/gym_session.dart';

class GymSessionCard extends StatelessWidget {
  final GymSession session;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const GymSessionCard({
    super.key,
    required this.session,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: PremiumTheme.spacingM),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withValues(
            alpha: 0.05,
          ), // Nền mờ ~20% (sử dụng màu trắng trong suốt trên nền tối để tạo glassmorphism chuẩn)
          borderRadius: BorderRadius.circular(PremiumTheme.radiusLarge),
          border: Border.all(
            color:
                session.isCompleted
                    ? PremiumTheme.neonLime.withValues(alpha: 0.3)
                    : PremiumTheme.glassBorder,
          ),
          boxShadow: PremiumTheme.cardShadow(), // Đổ bóng mềm 20px
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(PremiumTheme.spacingM),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          session.isCompleted
                              ? PremiumTheme.neonLime.withValues(alpha: 0.15)
                              : PremiumTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        PremiumTheme.radiusMedium,
                      ),
                    ),
                    child: Icon(
                      LineIcons.dumbbell,
                      color:
                          session.isCompleted
                              ? PremiumTheme.neonLime
                              : PremiumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: PremiumTheme.spacingM),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.gymType.toUpperCase(),
                          style: PremiumTheme.titleLarge,
                        ), // Tiêu đề to, đậm, uppercase
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LineIcons.calendar,
                              size: 16,
                              color: PremiumTheme.neonLime,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd/MM HH:mm',
                              ).format(session.scheduledTime),
                              style: PremiumTheme.titleMedium.copyWith(
                                color: PremiumTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LineIcons.stopwatch,
                                  size: 16,
                                  color: PremiumTheme.electricBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.durationMinutes} PHÚT', // Uppercase
                                  style: PremiumTheme.titleSmall.copyWith(
                                    color: PremiumTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LineIcons.fire,
                                  size: 16,
                                  color: Colors.orange.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.estimatedCalories.toInt()} CALO', // Uppercase
                                  style: PremiumTheme.titleSmall.copyWith(
                                    color: PremiumTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  IconButton(
                    onPressed: session.isCompleted ? null : onComplete,
                    icon: Icon(
                      session.isCompleted
                          ? LineIcons.checkCircle
                          : LineIcons.circle,
                      color:
                          session.isCompleted
                              ? PremiumTheme.neonLime
                              : PremiumTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
