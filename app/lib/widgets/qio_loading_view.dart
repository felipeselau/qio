import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QioLoadingView extends StatefulWidget {
  const QioLoadingView({super.key});

  static const background = Color(0xFF2563EB);

  @override
  State<QioLoadingView> createState() => _QioLoadingViewState();
}

class _QioLoadingViewState extends State<QioLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.stop();
      _controller.value = 1;
      _started = false;
    } else if (!_started) {
      _started = true;
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
    return Semantics(
      label: 'Qio',
      child: ColoredBox(
        color: QioLoadingView.background,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Opacity(
                opacity: 0.75 + 0.25 * t,
                child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
              );
            },
            child: SvgPicture.asset(
              'assets/brand/symbol-white.svg',
              width: 96,
              height: 96,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
