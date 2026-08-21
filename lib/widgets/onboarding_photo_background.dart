import 'dart:async';
import 'package:flutter/material.dart';

/// Slowly cross-fading, gently zooming photo backdrop used behind
/// [WizardHeader] (see wizard_widgets.dart). Each image holds for
/// [_holdDuration] with a slow Ken-Burns zoom, then cross-fades into the
/// next. A dark scrim sits on top so the header's white/gold text stays
/// legible regardless of which photo is showing.
class OnboardingPhotoBackground extends StatefulWidget {
  final List<String> assetPaths;
  const OnboardingPhotoBackground({super.key, required this.assetPaths});

  @override
  State<OnboardingPhotoBackground> createState() =>
      _OnboardingPhotoBackgroundState();
}

class _OnboardingPhotoBackgroundState extends State<OnboardingPhotoBackground> {
  static const _holdDuration = Duration(seconds: 5);
  static const _fadeDuration = Duration(milliseconds: 1200);

  int _index = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only start the slideshow once, and only when motion is welcome —
    // MediaQuery isn't available yet in initState.
    if (_timer == null &&
        widget.assetPaths.length > 1 &&
        !MediaQuery.of(context).disableAnimations) {
      _timer = Timer.periodic(_holdDuration, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.assetPaths.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: _fadeDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
          child: _KenBurnsImage(
            key: ValueKey(_index),
            assetPath: widget.assetPaths[_index],
            animate: !reduceMotion,
          ),
        ),
        // Scrim, not a flat tint: darker at the bottom where the step title
        // sits, lighter at the top so the photo still reads as a photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB30F2A1E), Color(0xE60B2118)],
            ),
          ),
        ),
      ],
    );
  }
}

class _KenBurnsImage extends StatefulWidget {
  final String assetPath;
  final bool animate;
  const _KenBurnsImage({
    super.key,
    required this.assetPath,
    required this.animate,
  });

  @override
  State<_KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<_KenBurnsImage>
    with SingleTickerProviderStateMixin {
  // Runs across this image's full time on screen (hold + the cross-fade that
  // follows), so the zoom never visibly resets or jumps mid-transition.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: Image.asset(widget.assetPath, fit: BoxFit.cover),
    );
  }
}
