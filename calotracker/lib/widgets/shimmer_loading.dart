// Shimmer Loading Widget
// Placeholder loading animations
import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer List Item
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const ShimmerLoading(width: 60, height: 60, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer Card
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 120, height: 20, borderRadius: 4),
          SizedBox(height: 16),
          ShimmerLoading(height: 80, borderRadius: 12),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerLoading(height: 60, borderRadius: 8)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 60, borderRadius: 8)),
              SizedBox(width: 12),
              Expanded(child: ShimmerLoading(height: 60, borderRadius: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer Meal Card
class ShimmerMealCard extends StatelessWidget {
  const ShimmerMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          ShimmerLoading(width: 50, height: 50, borderRadius: 25),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 150, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerLoading(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          ShimmerLoading(width: 60, height: 24, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Build a shimmer list
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  const ShimmerList({super.key, this.itemCount = 5, this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const ShimmerListItem(),
    );
  }
}
