import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Warm cream gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.3,
                colors: [Color(0xFFFDF5ED), Color(0xFFF0E6D8)],
              ),
            ),
          ),

          // Top-left botanical flower accent
          Positioned(
            top: topInset + 58,
            left: 18,
            child: CustomPaint(
              size: const Size(54, 54),
              painter: _AccentFlowerPainter(color: const Color(0xFFEBA8BB)),
            ),
          ),

          // Top-right vine accent
          Positioned(
            top: topInset + 42,
            right: 14,
            child: const CustomPaint(
              size: Size(60, 60),
              painter: _AccentVinePainter(),
            ),
          ),

          // Bottom-right butterfly accent
          Positioned(
            bottom: sh * 0.25,
            right: 22,
            child: const CustomPaint(
              size: Size(30, 22),
              painter: _AccentButterflyPainter(),
            ),
          ),

          // Main content — scrollable so nothing overflows on small screens
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableH = constraints.maxHeight;
                final vGap = (availableH * 0.06).clamp(12.0, 40.0);

                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableH),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top bar — page dots (centred)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _PageDash(active: true),
                                const SizedBox(width: 5),
                                _PageDash(active: false),
                              ],
                            ),
                          ),

                          // Decorative heart emblem — at the top
                          SizedBox(height: vGap * 0.5),
                          CustomPaint(
                            size: const Size(64, 64),
                            painter: _HeartEmblemPainter(),
                          ),

                          const Spacer(),

                          // Headline
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              'Plan Your Wedding\nEvents Easily',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: const Color(0xFF2C1E0F),
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: vGap * 0.4),

                          // Subtitle
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 36),
                            child: Text(
                              'Plan your perfect day with ease. Everything\nyou need, all in one place.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const Spacer(),

                          // CTA button + sign-in link
                          Padding(
                            padding: EdgeInsets.fromLTRB(28, 0, 28, vGap),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => context.push('/register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF06292),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Get Started',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign in',
                                          style: AppTextStyles.caption.copyWith(
                                            color: const Color(0xFFF06292),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page progress dash ───────────────────────────────────────────────────────

class _PageDash extends StatelessWidget {
  final bool active;
  const _PageDash({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 22 : 13,
      height: 3,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFF06292)
            : const Color(0xFFF06292).withAlpha(55),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}


// ── Centre heart emblem ──────────────────────────────────────────────────────

class _HeartEmblemPainter extends CustomPainter {
  const _HeartEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Soft glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = const Color(0x30F8BBD9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = const Color(0x60F06292)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Heart
    final s = w * 0.24;
    final hc = Offset(cx, cy + s * 0.12);
    final heartPath = Path()
      ..moveTo(hc.dx, hc.dy + s * 0.74)
      ..cubicTo(hc.dx - s * 1.6, hc.dy, hc.dx - s * 1.6, hc.dy - s * 0.88,
          hc.dx, hc.dy - s * 0.14)
      ..cubicTo(hc.dx + s * 1.6, hc.dy - s * 0.88, hc.dx + s * 1.6, hc.dy,
          hc.dx, hc.dy + s * 0.74);
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = const Color(0xFFF06292)
        ..style = PaintingStyle.fill,
    );

    // Small decorative dots around ring
    final dotPaint = Paint()
      ..color = const Color(0xFFF06292).withAlpha(120)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = i * 2 * math.pi / 8;
      canvas.drawCircle(
        Offset(cx + w * 0.46 * math.cos(angle), cy + w * 0.46 * math.sin(angle)),
        2.0,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartEmblemPainter old) => false;
}

// ── Botanical accent — flower (top-left) ─────────────────────────────────────

class _AccentFlowerPainter extends CustomPainter {
  final Color color;
  const _AccentFlowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.width * 0.30;

    final petal = Paint()..color = color..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final px = c.dx + r * 0.75 * math.cos(angle);
      final py = c.dy + r * 0.75 * math.sin(angle);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 0.82, height: r * 1.55),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.38,
        Paint()..color = const Color(0xFFF06292)..style = PaintingStyle.fill);
    canvas.drawCircle(c, r * 0.18,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    final leafPaint = Paint()
      ..color = const Color(0xFF87A96B)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + math.pi / 6;
      final lx = c.dx + r * 1.30 * math.cos(angle);
      final ly = c.dy + r * 1.30 * math.sin(angle);
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle + math.pi / 2);
      final lp = Path()
        ..moveTo(0, -r * 0.48)
        ..quadraticBezierTo(r * 0.38, 0, 0, r * 0.48)
        ..quadraticBezierTo(-r * 0.38, 0, 0, -r * 0.48);
      canvas.drawPath(lp, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AccentFlowerPainter old) => old.color != color;
}

// ── Botanical accent — vine curl (top-right) ─────────────────────────────────

class _AccentVinePainter extends CustomPainter {
  const _AccentVinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vinePaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..cubicTo(w * 0.95, h * 0.0, w * 0.78, h * 0.48, w * 0.58, h * 0.58)
      ..cubicTo(w * 0.38, h * 0.68, w * 0.18, h * 0.90, w * 0.28, h * 1.0);
    canvas.drawPath(path, vinePaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..style = PaintingStyle.fill;
    final leaves = [
      (Offset(w * 0.74, h * 0.24), -0.80),
      (Offset(w * 0.64, h * 0.47), 0.42),
      (Offset(w * 0.44, h * 0.72), -0.52),
    ];
    for (final entry in leaves) {
      final pos = entry.$1;
      final angle = entry.$2;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final lp = Path()
        ..moveTo(0, -w * 0.10)
        ..quadraticBezierTo(w * 0.10, 0, 0, w * 0.10)
        ..quadraticBezierTo(-w * 0.10, 0, 0, -w * 0.10);
      canvas.drawPath(lp, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AccentVinePainter old) => false;
}

// ── Botanical accent — butterfly (bottom-right) ───────────────────────────────

class _AccentButterflyPainter extends CustomPainter {
  const _AccentButterflyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    final ul = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
          cx - w * 0.48, cy - h * 1.05, cx - w * 0.92, cy - h * 0.08)
      ..quadraticBezierTo(cx - w * 0.58, cy + h * 0.12, cx, cy);
    canvas.drawPath(
        ul,
        Paint()
          ..color = const Color(0xFFF48FB1)
          ..style = PaintingStyle.fill);

    final ur = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(
          cx + w * 0.48, cy - h * 1.05, cx + w * 0.92, cy - h * 0.08)
      ..quadraticBezierTo(cx + w * 0.58, cy + h * 0.12, cx, cy);
    canvas.drawPath(
        ur,
        Paint()
          ..color = const Color(0xFFF06292)
          ..style = PaintingStyle.fill);

    final ll = Path()
      ..moveTo(cx, cy + h * 0.08)
      ..quadraticBezierTo(
          cx - w * 0.42, cy + h * 0.75, cx - w * 0.52, cy + h * 0.32)
      ..quadraticBezierTo(cx - w * 0.20, cy + h * 0.40, cx, cy + h * 0.08);
    canvas.drawPath(
        ll,
        Paint()
          ..color = const Color(0xFFE91E63)
          ..style = PaintingStyle.fill);

    final lr = Path()
      ..moveTo(cx, cy + h * 0.08)
      ..quadraticBezierTo(
          cx + w * 0.42, cy + h * 0.75, cx + w * 0.52, cy + h * 0.32)
      ..quadraticBezierTo(cx + w * 0.20, cy + h * 0.40, cx, cy + h * 0.08);
    canvas.drawPath(
        lr,
        Paint()
          ..color = const Color(0xFFE91E63)
          ..style = PaintingStyle.fill);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.12, height: h * 0.75),
      Paint()
        ..color = const Color(0xFF2A1A10)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_AccentButterflyPainter old) => false;
}
