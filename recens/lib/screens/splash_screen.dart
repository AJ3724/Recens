import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bounceCtrl;
  late final Animation<double>   _bounceAnim;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;
  late final AnimationController _scaleCtrl;
  late final Animation<double>   _scaleAnim;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bounceAnim = Tween<double>(begin: 0, end: -18).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _fadeCtrl.forward();
    _scaleCtrl.forward().then((_) {
      _bounceCtrl.repeat(reverse: true);
    });

    // ── Navigate using named route — no import of main.dart needed ────────────
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF062B18), Color(0xFF0A4A2A), Color(0xFF1A7A44)],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Radial glow ──────────────────────────────────────────────────
            Center(
              child: Container(
                width:  280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:        const Color(0xFF2ECC71).withOpacity(0.18),
                      blurRadius:   120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            // ── Logo + wordmark ──────────────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_bounceAnim, _scaleAnim]),
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _bounceAnim.value),
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: const _LogoMark(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) {
                        final sweep = _shimmerCtrl.value;
                        return ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            colors: const [
                              Color(0xFFADD8C0),
                              Colors.white,
                              Color(0xFF6EE0A0),
                              Color(0xFFADD8C0),
                            ],
                            stops: const [0.0, 0.4, 0.6, 1.0],
                            begin: Alignment(-2 + sweep * 4, 0),
                            end:   Alignment(-1 + sweep * 4, 0),
                          ).createShader(bounds),
                          child: const Text(
                            'RECENS',
                            style: TextStyle(
                              fontSize:      42,
                              fontWeight:    FontWeight.w900,
                              color:         Colors.white,
                              letterSpacing: 8,
                              height:        1,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Smart Fridge Management',
                      style: TextStyle(
                        fontSize:      13,
                        color:         Colors.white.withOpacity(0.55),
                        letterSpacing: 2.2,
                        fontWeight:    FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bouncing dots ────────────────────────────────────────────────
            Positioned(
              bottom: 60,
              left:   0,
              right:  0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: const _BouncingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo mark ─────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  140,
      height: 140,
      child: CustomPaint(painter: _RecensLogoPainter()),
    );
  }
}

class _RecensLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark green rounded square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.08, w * 0.78, h * 0.78),
          Radius.circular(w * 0.22)),
      Paint()..color = const Color(0xFF0A4A2A),
    );

    // White fridge body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.17, w * 0.48, h * 0.60),
          Radius.circular(w * 0.10)),
      Paint()..color = Colors.white,
    );

    // Fridge divider
    canvas.drawLine(
      Offset(w * 0.14, h * 0.42),
      Offset(w * 0.62, h * 0.42),
      Paint()
        ..color       = const Color(0xFF0A4A2A)
        ..strokeWidth = w * 0.025,
    );

    // Handles
    final handle = Paint()
      ..color       = const Color(0xFF0A4A2A)
      ..strokeWidth = w * 0.04
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.31, h * 0.24), Offset(w * 0.31, h * 0.36), handle);
    canvas.drawLine(Offset(w * 0.31, h * 0.48), Offset(w * 0.31, h * 0.65), handle);

    // Leaf
    final lx = w * 0.45;
    final ly = h * 0.10;
    final leafPath = Path()
      ..moveTo(lx + w * 0.05, ly + h * 0.05)
      ..cubicTo(lx + w * 0.28, ly,       lx + w * 0.32, ly + h * 0.18, lx + w * 0.18, ly + h * 0.26)
      ..cubicTo(lx + w * 0.05, ly + h * 0.32, lx - w * 0.04, ly + h * 0.20, lx + w * 0.05, ly + h * 0.05);
    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF2ECC71));

    // Leaf vein
    canvas.drawLine(
      Offset(lx + w * 0.06, ly + h * 0.06),
      Offset(lx + w * 0.20, ly + h * 0.22),
      Paint()
        ..color       = const Color(0xFF0A4A2A)
        ..strokeWidth = w * 0.022
        ..strokeCap   = StrokeCap.round,
    );

    // WiFi arcs
    final arcPaint = Paint()
      ..color       = const Color(0xFF2ECC71)
      ..strokeWidth = w * 0.035
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;
    for (int i = 0; i < 2; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.80, h * 0.10), radius: w * (0.08 + i * 0.10)),
        -math.pi * 0.85,
        math.pi * 0.50,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Three bouncing dots ───────────────────────────────────────────────────────
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      _ctrls.add(ctrl);
      _anims.add(Tween<double>(begin: 0, end: -8).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)));
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width:  7,
              height: 7,
              decoration: BoxDecoration(
                color:  Colors.white.withOpacity(0.4 + i * 0.15),
                shape:  BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}