import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Small decorative interlocking-rings + popping-flowers flourish used in
/// [WizardHeader]'s eyebrow row. Self-contained in a fixed-size box so it
/// never competes with or overflows into the real step copy next to it —
/// purely celebratory, not informational.
class RingFlourish extends StatefulWidget {
  final int step;
  const RingFlourish({super.key, required this.step});

  @override
  State<RingFlourish> createState() => _RingFlourishState();
}

class _RingFlourishState extends State<RingFlourish>
    with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reduceMotion = MediaQuery.of(context).disableAnimations;
      if (_reduceMotion) {
        _popController.value = 1;
        return;
      }
      _floatController.repeat(reverse: true);
      _popController.forward();
    });
  }

  @override
  void didUpdateWidget(RingFlourish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step && !_reduceMotion) {
      _popController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _popController.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _popController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );

  @override
  Widget build(BuildContext context) {
    final ringPop = _stagger(0.0, 0.55);
    final flower1 = _stagger(0.05, 0.65);
    final flower2 = _stagger(0.2, 0.8);
    final flower3 = _stagger(0.35, 0.95);

    return SizedBox(
      width: 58,
      height: 32,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatController, _popController]),
        builder: (context, _) {
          final bob = _reduceMotion ? 0.0 : (_floatController.value * 4) - 2;
          final ringScale = 1.0 + (_reduceMotion ? 0 : _floatController.value * 0.08);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 2 + bob,
                child: _Pop(animation: flower1, child: const _Flower(size: 10)),
              ),
              Positioned(
                left: 22,
                top: 0 - bob,
                child: _Pop(animation: flower2, child: const _Flower(size: 12)),
              ),
              Positioned(
                left: 42,
                top: 4 + bob,
                child: _Pop(animation: flower3, child: const _Flower(size: 10)),
              ),
              Positioned(
                left: 6,
                top: 10,
                child: _Pop(
                  animation: ringPop,
                  child: Transform.scale(
                    scale: ringScale,
                    child: const _Ring(),
                  ),
                ),
              ),
              Positioned(
                left: 15,
                top: 10,
                child: _Pop(
                  animation: ringPop,
                  child: Transform.scale(
                    scale: ringScale,
                    child: const _Ring(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Scale + fade entrance driven by [animation], which runs 0→1 once per pop.
///
/// [animation] is already curved with an overshooting curve (easeOutBack) for
/// the "pop" bounce, so its value legitimately exceeds 1.0 mid-animation —
/// never chain another Curve on top of it here. A Curve's transform() asserts
/// its input is within [0, 1], and that overshoot value would fail it.
class _Pop extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _Pop({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(190), width: 1.6),
      ),
    );
  }
}

class _Flower extends StatelessWidget {
  final double size;
  const _Flower({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.local_florist, size: size, color: AppColors.gold.withAlpha(220));
  }
}
