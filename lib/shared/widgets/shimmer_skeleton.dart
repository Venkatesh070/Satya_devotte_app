import 'package:flutter/material.dart';

/// A reusable, lightweight, smooth shimmer effect for skeleton loaders.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: const [
                Color(0xFFEFE5D3),
                Color(0xFFFBF6ED),
                Color(0xFFEFE5D3),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// A shimmer placeholder box with customizable size and corner radius.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE5D3),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A skeleton card that mirrors the layout of Puja, Ritual, and Deity list cards.
class CatalogCardSkeleton extends StatelessWidget {
  const CatalogCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail skeleton
          const SkeletonBox(
            width: 70,
            height: 70,
            borderRadius: 10,
          ),
          const SizedBox(width: 16),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 2),
                // Title line
                SkeletonBox(
                  width: 170,
                  height: 16,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                // Subtitle line 1
                SkeletonBox(
                  height: 12,
                  borderRadius: 4,
                ),
                SizedBox(height: 6),
                // Subtitle line 2
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: SkeletonBox(
                    height: 12,
                    borderRadius: 4,
                  ),
                ),
                SizedBox(height: 8),
                // Badge / duration pill
                SkeletonBox(
                  width: 85,
                  height: 14,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A sliver that renders a list of shimmering catalog card skeletons.
class SliverCatalogListSkeleton extends StatelessWidget {
  const SliverCatalogListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0x14000000),
        ),
        itemBuilder: (_, __) => const ShimmerLoading(
          child: CatalogCardSkeleton(),
        ),
      ),
    );
  }
}

/// A skeleton list widget for history pages (puja & ritual history).
class HistoryListSkeleton extends StatelessWidget {
  const HistoryListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const ShimmerLoading(
        child: _HistoryCardSkeleton(),
      ),
    );
  }
}

class _HistoryCardSkeleton extends StatelessWidget {
  const _HistoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCBE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 180, height: 16, borderRadius: 4),
          SizedBox(height: 10),
          SkeletonBox(width: 120, height: 12, borderRadius: 4),
          SizedBox(height: 12),
          SkeletonBox(height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

/// A skeleton list widget for notifications screen.
class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE0D6C2),
      ),
      itemBuilder: (_, __) => const ShimmerLoading(
        child: _NotificationTileSkeleton(),
      ),
    );
  }
}

class _NotificationTileSkeleton extends StatelessWidget {
  const _NotificationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: 42,
            height: 42,
            borderRadius: 8,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 180,
                  height: 15,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                SkeletonBox(
                  height: 12,
                  borderRadius: 4,
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.65,
                  child: SkeletonBox(
                    height: 12,
                    borderRadius: 4,
                  ),
                ),
                SizedBox(height: 8),
                SkeletonBox(
                  width: 80,
                  height: 10,
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
