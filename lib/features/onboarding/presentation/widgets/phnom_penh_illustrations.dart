import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Beautiful, clean vector-crafted illustrations of Phnom Penh landmarks
/// styled in the soft pastel pink and rose aesthetic of EduNest.

/// Illustration 1: Phnom Penh Skyline & Mekong Riverside
class PhnomPenhSkylineIllustration extends StatelessWidget {
  final double size;
  const PhnomPenhSkylineIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkylinePainter(),
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Soft glowing background sun/circle
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD1DC).withValues(alpha: 0.55),
          const Color(0xFFFFF0F3).withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.45));
    canvas.drawCircle(center, w * 0.45, bgPaint);

    // Soft morning sun
    final sunPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB6C1), Color(0xFFFF8DA1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.58, h * 0.18, 56, 56));
    canvas.drawCircle(Offset(w * 0.65, h * 0.25), 26, sunPaint);

    // Floating birds
    final birdPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    _drawBird(canvas, birdPaint, Offset(w * 0.25, h * 0.22), 12);
    _drawBird(canvas, birdPaint, Offset(w * 0.35, h * 0.18), 9);
    _drawBird(canvas, birdPaint, Offset(w * 0.42, h * 0.25), 14);

    // 2. Far Skyline Silhouette (Soft dusty rose)
    final farSkylinePaint = Paint()
      ..color = const Color(0xFFF3C5CF).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final farPath = Path();
    farPath.moveTo(0, h * 0.72);
    // Vattanac tower curve shape in background
    farPath.lineTo(w * 0.15, h * 0.72);
    farPath.lineTo(w * 0.15, h * 0.42);
    farPath.quadraticBezierTo(w * 0.18, h * 0.34, w * 0.22, h * 0.38);
    farPath.lineTo(w * 0.24, h * 0.72);
    // Middle buildings
    farPath.lineTo(w * 0.35, h * 0.72);
    farPath.lineTo(w * 0.35, h * 0.50);
    farPath.lineTo(w * 0.42, h * 0.50);
    farPath.lineTo(w * 0.42, h * 0.72);
    farPath.lineTo(w * 0.55, h * 0.72);
    farPath.lineTo(w * 0.55, h * 0.46);
    farPath.lineTo(w * 0.62, h * 0.46);
    farPath.lineTo(w * 0.62, h * 0.72);
    farPath.lineTo(w * 0.75, h * 0.72);
    farPath.lineTo(w * 0.75, h * 0.54);
    farPath.lineTo(w * 0.82, h * 0.54);
    farPath.lineTo(w * 0.82, h * 0.72);
    farPath.lineTo(w, h * 0.72);
    farPath.lineTo(w, h);
    farPath.lineTo(0, h);
    farPath.close();
    canvas.drawPath(farPath, farSkylinePaint);

    // 3. Near Cityscape & Riverside Architecture (Primary soft rose)
    final nearCityPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5879E), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.45));

    final nearPath = Path();
    nearPath.moveTo(0, h * 0.76);
    // Left highrise
    nearPath.lineTo(w * 0.08, h * 0.76);
    nearPath.lineTo(w * 0.08, h * 0.52);
    nearPath.lineTo(w * 0.14, h * 0.52);
    nearPath.lineTo(w * 0.14, h * 0.76);
    // Modern iconic curve tower (Vattanac style)
    nearPath.lineTo(w * 0.26, h * 0.76);
    nearPath.lineTo(w * 0.26, h * 0.38);
    nearPath.quadraticBezierTo(w * 0.30, h * 0.28, w * 0.35, h * 0.32);
    nearPath.lineTo(w * 0.36, h * 0.76);
    // Bridge pillar / Riverside tower
    nearPath.lineTo(w * 0.45, h * 0.76);
    nearPath.lineTo(w * 0.45, h * 0.44);
    nearPath.lineTo(w * 0.49, h * 0.39);
    nearPath.lineTo(w * 0.53, h * 0.44);
    nearPath.lineTo(w * 0.53, h * 0.76);
    // Modern commercial towers
    nearPath.lineTo(w * 0.64, h * 0.76);
    nearPath.lineTo(w * 0.64, h * 0.48);
    nearPath.lineTo(w * 0.72, h * 0.48);
    nearPath.lineTo(w * 0.72, h * 0.76);
    // Riverside quay building
    nearPath.lineTo(w * 0.82, h * 0.76);
    nearPath.lineTo(w * 0.82, h * 0.58);
    nearPath.lineTo(w * 0.90, h * 0.58);
    nearPath.lineTo(w * 0.90, h * 0.76);
    nearPath.lineTo(w, h * 0.76);
    nearPath.lineTo(w, h);
    nearPath.lineTo(0, h);
    nearPath.close();
    canvas.drawPath(nearPath, nearCityPaint);

    // Decorative windows on buildings
    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 2;
    for (double y = h * 0.42; y < h * 0.72; y += 9) {
      canvas.drawLine(Offset(w * 0.29, y), Offset(w * 0.33, y), windowPaint);
    }
    for (double y = h * 0.52; y < h * 0.72; y += 8) {
      canvas.drawLine(Offset(w * 0.66, y), Offset(w * 0.70, y), windowPaint);
    }

    // 4. Mekong River Waves (Gentle flowing water)
    final riverPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE99BB0), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.76, w, h * 0.24));

    final wavePath = Path();
    wavePath.moveTo(0, h * 0.78);
    wavePath.quadraticBezierTo(w * 0.25, h * 0.75, w * 0.5, h * 0.78);
    wavePath.quadraticBezierTo(w * 0.75, h * 0.81, w, h * 0.77);
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();
    canvas.drawPath(wavePath, riverPaint);

    // Front soft wave reflection
    final waveFrontPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final reflectionPath = Path();
    reflectionPath.moveTo(w * 0.15, h * 0.84);
    reflectionPath.quadraticBezierTo(w * 0.35, h * 0.82, w * 0.55, h * 0.85);
    reflectionPath.moveTo(w * 0.45, h * 0.90);
    reflectionPath.quadraticBezierTo(w * 0.65, h * 0.88, w * 0.85, h * 0.91);
    canvas.drawPath(reflectionPath, waveFrontPaint);
  }

  void _drawBird(Canvas canvas, Paint paint, Offset pos, double span) {
    final path = Path();
    path.moveTo(pos.dx - span, pos.dy + 3);
    path.quadraticBezierTo(pos.dx - span / 2, pos.dy - 3, pos.dx, pos.dy);
    path.quadraticBezierTo(pos.dx + span / 2, pos.dy - 3, pos.dx + span, pos.dy + 3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration 2: Independence Monument (Vimean Ekareach) & Learning
class IndependenceMonumentIllustration extends StatelessWidget {
  final double size;
  const IndependenceMonumentIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IndependenceMonumentPainter(),
      ),
    );
  }
}

class _IndependenceMonumentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Soft glowing background circle
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD1DC).withValues(alpha: 0.6),
          const Color(0xFFFFF0F3).withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.46));
    canvas.drawCircle(center, w * 0.46, bgPaint);

    // 2. Learning floating elements (Open books & graduation cap sparkles)
    _drawFloatingBook(canvas, Offset(w * 0.16, h * 0.32), 26);
    _drawFloatingCap(canvas, Offset(w * 0.82, h * 0.28), 24);
    _drawSparkle(canvas, Offset(w * 0.22, h * 0.18), 8);
    _drawSparkle(canvas, Offset(w * 0.78, h * 0.42), 6);
    _drawSparkle(canvas, Offset(w * 0.86, h * 0.16), 10);

    // 3. Independence Monument Pedestal & Steps
    final monumentPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2748F), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.7));

    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD85B7A), Color(0xFFB83D5D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.75, w * 0.7, h * 0.2));

    // Base steps
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.84, w * 0.72, 14),
        const Radius.circular(4),
      ),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.80, w * 0.60, 10),
        const Radius.circular(3),
      ),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.76, w * 0.48, 10),
        const Radius.circular(3),
      ),
      basePaint,
    );

    // Main 4-column arched pavilion structure of Vimean Ekareach
    final archPath = Path();
    archPath.moveTo(w * 0.30, h * 0.76);
    archPath.lineTo(w * 0.30, h * 0.54);
    archPath.lineTo(w * 0.36, h * 0.54);
    // Left arch cut
    archPath.lineTo(w * 0.36, h * 0.68);
    archPath.quadraticBezierTo(w * 0.50, h * 0.56, w * 0.64, h * 0.68);
    archPath.lineTo(w * 0.64, h * 0.54);
    archPath.lineTo(w * 0.70, h * 0.54);
    archPath.lineTo(w * 0.70, h * 0.76);
    archPath.close();
    canvas.drawPath(archPath, monumentPaint);

    // Inner eternal flame / golden light in the arch
    final flamePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F),
          const Color(0xFFFF8DA1).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.67), radius: 24));
    canvas.drawCircle(Offset(w * 0.5, h * 0.67), 20, flamePaint);

    // Tiered Lotus Bud Stupa (Iconic Khmer 5-tier lotus tiers)
    double tierY = h * 0.54;
    double tierWidth = w * 0.44;
    for (int i = 0; i < 5; i++) {
      final tierHeight = 12.0 - i * 1.0;
      tierY -= tierHeight;
      final tierRect = Rect.fromCenter(
        center: Offset(w * 0.5, tierY + tierHeight / 2),
        width: tierWidth,
        height: tierHeight,
      );
      // Lotus petals curve
      final tierPath = Path();
      tierPath.moveTo(tierRect.left, tierRect.bottom);
      tierPath.lineTo(tierRect.left + 4, tierRect.top);
      tierPath.quadraticBezierTo(w * 0.5, tierRect.top - 2, tierRect.right - 4, tierRect.top);
      tierPath.lineTo(tierRect.right, tierRect.bottom);
      tierPath.close();
      canvas.drawPath(tierPath, monumentPaint);

      // Lotus petal wing tips on each side
      final wingPaint = Paint()
        ..color = const Color(0xFFF39EB4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tierRect.left, tierRect.top + 2), 3.0, wingPaint);
      canvas.drawCircle(Offset(tierRect.right, tierRect.top + 2), 3.0, wingPaint);

      tierWidth -= 12.0;
    }

    // Top Stupa Spire / Kalasa
    final spirePath = Path();
    spirePath.moveTo(w * 0.48, tierY);
    spirePath.lineTo(w * 0.50, h * 0.22); // pointed top finial
    spirePath.lineTo(w * 0.52, tierY);
    spirePath.close();
    canvas.drawPath(spirePath, monumentPaint);

    // Gold tip accent
    final goldTipPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(w * 0.50, h * 0.22), 3.5, goldTipPaint);
  }

  void _drawFloatingBook(Canvas canvas, Offset pos, double size) {
    final bookPaint = Paint()
      ..color = const Color(0xFFD85B7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    final path = Path();
    path.moveTo(pos.dx, pos.dy + size * 0.3);
    path.quadraticBezierTo(pos.dx - size * 0.5, pos.dy + size * 0.2, pos.dx - size, pos.dy + size * 0.4);
    path.lineTo(pos.dx - size, pos.dy - size * 0.4);
    path.quadraticBezierTo(pos.dx - size * 0.5, pos.dy - size * 0.6, pos.dx, pos.dy - size * 0.5);
    path.quadraticBezierTo(pos.dx + size * 0.5, pos.dy - size * 0.6, pos.dx + size, pos.dy - size * 0.4);
    path.lineTo(pos.dx + size, pos.dy + size * 0.4);
    path.quadraticBezierTo(pos.dx + size * 0.5, pos.dy + size * 0.2, pos.dx, pos.dy + size * 0.3);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, bookPaint);
    // Center spine
    canvas.drawLine(Offset(pos.dx, pos.dy - size * 0.5), Offset(pos.dx, pos.dy + size * 0.3), bookPaint);
  }

  void _drawFloatingCap(Canvas canvas, Offset pos, double size) {
    final capPaint = Paint()
      ..color = const Color(0xFFD85B7A)
      ..style = PaintingStyle.fill;

    // Diamond cap top
    final capPath = Path();
    capPath.moveTo(pos.dx, pos.dy - size * 0.4);
    capPath.lineTo(pos.dx + size * 0.6, pos.dy);
    capPath.lineTo(pos.dx, pos.dy + size * 0.4);
    capPath.lineTo(pos.dx - size * 0.6, pos.dy);
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Tassel
    final tasselPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(pos.dx, pos.dy), Offset(pos.dx + size * 0.5, pos.dy + size * 0.5), tasselPaint);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double size) {
    final paint = Paint()
      ..color = const Color(0xFFF39EB4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(pos.dx, pos.dy - size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration 3: Royal Palace Phnom Penh Spires & Student Growth
class RoyalPalaceIllustration extends StatelessWidget {
  final double size;
  const RoyalPalaceIllustration({super.key, this.size = 280});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoyalPalacePainter(),
      ),
    );
  }
}

class _RoyalPalacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Soft glowing background circle
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD1DC).withValues(alpha: 0.6),
          const Color(0xFFFFF0F3).withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.46));
    canvas.drawCircle(center, w * 0.46, bgPaint);

    // 2. Growth / Collaboration Floating Badges (Chat, Calendar, Achievement)
    _drawAchievementBadge(canvas, Offset(w * 0.16, h * 0.28), 24);
    _drawCalendarBadge(canvas, Offset(w * 0.84, h * 0.32), 24);

    // 3. Royal Palace Throne Hall (Preah Thineang Tevea Vinichhay)
    final palacePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2748F), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.6));

    final roofPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF39EB4), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.3));

    // Base podium & balustrade
    final podiumPaint = Paint()..color = const Color(0xFFB83D5D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.82, w * 0.76, 14),
        const Radius.circular(4),
      ),
      podiumPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.78, w * 0.64, 8),
        const Radius.circular(3),
      ),
      podiumPaint,
    );

    // Hall Columns & Walls
    final wallRect = Rect.fromLTWH(w * 0.22, h * 0.60, w * 0.56, h * 0.18);
    canvas.drawRect(wallRect, palacePaint);

    // Columns
    final colPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (double x = w * 0.25; x <= w * 0.75; x += w * 0.08) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, h * 0.62, 4.5, h * 0.16),
          const Radius.circular(2),
        ),
        colPaint,
      );
    }

    // Traditional Khmer Multi-Tiered Roofs
    // Lower tiered roof
    _drawKhmerRoof(canvas, roofPaint, w * 0.5, h * 0.60, w * 0.78, 18, hasChofas: true);
    // Middle tiered roof
    _drawKhmerRoof(canvas, roofPaint, w * 0.5, h * 0.52, w * 0.62, 16, hasChofas: true);
    // Upper tiered roof
    _drawKhmerRoof(canvas, roofPaint, w * 0.5, h * 0.44, w * 0.48, 14, hasChofas: true);

    // Central Tower Spire (Prasat) soaring into the sky
    final spirePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFD85B7A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.45, h * 0.16, w * 0.1, h * 0.28));

    final spirePath = Path();
    spirePath.moveTo(w * 0.46, h * 0.44);
    spirePath.lineTo(w * 0.47, h * 0.30);
    // Tower mid section
    spirePath.lineTo(w * 0.48, h * 0.25);
    spirePath.lineTo(w * 0.50, h * 0.15); // Golden finial tip
    spirePath.lineTo(w * 0.52, h * 0.25);
    spirePath.lineTo(w * 0.53, h * 0.30);
    spirePath.lineTo(w * 0.54, h * 0.44);
    spirePath.close();
    canvas.drawPath(spirePath, spirePaint);

    // Golden tip sphere
    final goldPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 4, goldPaint);

    // Left and right smaller spires
    _drawSideSpire(canvas, spirePaint, Offset(w * 0.34, h * 0.44), 22);
    _drawSideSpire(canvas, spirePaint, Offset(w * 0.66, h * 0.44), 22);
  }

  void _drawKhmerRoof(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double width,
    double height, {
    required bool hasChofas,
  }) {
    final path = Path();
    final halfW = width / 2;

    path.moveTo(cx - halfW, cy);
    // Eaves curving up (traditional Khmer chofa / upward sweeping curve)
    path.quadraticBezierTo(cx - halfW + 12, cy - height * 0.4, cx, cy - height);
    path.quadraticBezierTo(cx + halfW - 12, cy - height * 0.4, cx + halfW, cy);
    path.close();
    canvas.drawPath(path, paint);

    if (hasChofas) {
      // Swept up roof ridge finials (Chofa)
      final chofaPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      // Left chofa horn
      final leftChofa = Path();
      leftChofa.moveTo(cx - halfW + 2, cy - 2);
      leftChofa.quadraticBezierTo(cx - halfW - 6, cy - 8, cx - halfW - 4, cy - 14);
      canvas.drawPath(leftChofa, chofaPaint);

      // Right chofa horn
      final rightChofa = Path();
      rightChofa.moveTo(cx + halfW - 2, cy - 2);
      rightChofa.quadraticBezierTo(cx + halfW + 6, cy - 8, cx + halfW + 4, cy - 14);
      canvas.drawPath(rightChofa, chofaPaint);
    }
  }

  void _drawSideSpire(Canvas canvas, Paint paint, Offset base, double height) {
    final path = Path();
    path.moveTo(base.dx - 5, base.dy);
    path.lineTo(base.dx, base.dy - height);
    path.lineTo(base.dx + 5, base.dy);
    path.close();
    canvas.drawPath(path, paint);

    final gold = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(base.dx, base.dy - height), 2.5, gold);
  }

  void _drawAchievementBadge(Canvas canvas, Offset pos, double size) {
    final bgPaint = Paint()..color = Colors.white;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.06);

    canvas.drawCircle(pos.translate(0, 3), size, shadowPaint);
    canvas.drawCircle(pos, size, bgPaint);

    final starPaint = Paint()
      ..color = const Color(0xFFD85B7A)
      ..style = PaintingStyle.fill;

    // Draw small star in badge
    _drawStar(canvas, pos, 5, size * 0.5, size * 0.25, starPaint);
  }

  void _drawCalendarBadge(Canvas canvas, Offset pos, double size) {
    final bgPaint = Paint()..color = Colors.white;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.06);

    canvas.drawCircle(pos.translate(0, 3), size, shadowPaint);
    canvas.drawCircle(pos, size, bgPaint);

    final iconPaint = Paint()
      ..color = const Color(0xFFD85B7A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final r = Rect.fromCenter(center: pos.translate(0, 2), width: size * 0.9, height: size * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), iconPaint);
    canvas.drawLine(Offset(r.left, r.top + 6), Offset(r.right, r.top + 6), iconPaint);
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    final double angle = math.pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final double r = (i % 2 == 0) ? outerRadius : innerRadius;
      final double currAngle = i * angle - math.pi / 2;
      final double x = center.dx + r * math.cos(currAngle);
      final double y = center.dy + r * math.sin(currAngle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
