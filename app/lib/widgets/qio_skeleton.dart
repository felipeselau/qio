import 'package:flutter/material.dart';

import '../theme/qio_colors.dart';
import 'qio_card.dart';

class QioSkeleton extends StatefulWidget {
  const QioSkeleton({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<QioSkeleton> createState() => _QioSkeletonState();
}

class _QioSkeletonState extends State<QioSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
      _running = false;
    } else if (!_running) {
      _running = true;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Color.lerp(QioColors.gray200, QioColors.gray300, t),
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          );
        },
      ),
    );
  }
}

class QioSkeletonCard extends StatelessWidget {
  const QioSkeletonCard({super.key, this.lines = 2});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return QioCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: QioSkeleton(height: 18, radius: 6)),
              SizedBox(width: 48),
              QioSkeleton(width: 56, height: 22, radius: 11),
            ],
          ),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: 12),
            QioSkeleton(width: i == 0 ? 160 : 110, height: 12, radius: 6),
          ],
        ],
      ),
    );
  }
}

class QioSkeletonList extends StatelessWidget {
  const QioSkeletonList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.all(20),
  });

  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: false,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [
          for (var i = 0; i < count; i++) ...[
            const QioSkeletonCard(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
