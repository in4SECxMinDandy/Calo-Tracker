// Online Indicator Widget
// Shows green dot when online, gray dot when offline (Facebook-like)
import 'package:flutter/material.dart';
import '../models/user_presence.dart';

class OnlineIndicator extends StatelessWidget {
  final UserPresence? presence;
  final double size;
  final bool showBorder;

  const OnlineIndicator({
    super.key,
    required this.presence,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (presence == null) return const SizedBox.shrink();

    final isOnline = presence!.isOnline;
    final color = isOnline ? Colors.green : Colors.grey;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: size > 10 ? 2 : 1,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}

/// Wrapper for CircleAvatar with online indicator overlay
class AvatarWithPresence extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final UserPresence? presence;
  final double radius;

  const AvatarWithPresence({
    super.key,
    required this.imageUrl,
    required this.displayName,
    this.presence,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: radius * 0.8),
                )
              : null,
        ),
        if (presence != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: OnlineIndicator(
              presence: presence,
              size: radius * 0.35,
            ),
          ),
      ],
    );
  }
}
