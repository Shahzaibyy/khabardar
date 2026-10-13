import 'package:flutter/material.dart';

import '../theme.dart';

/// The Khabardar mark: a shield with an alert stroke and an orange dot.
///
/// Drawn on a 64x64 grid, matching the SVG on the brand sheet.
class KhabardarLogo extends StatelessWidget {
  const KhabardarLogo({
    super.key,
    this.size = 64,
    this.shield = KColors.green,
    this.mark = Colors.white,
    this.dot = KColors.alertDot,
  });

  /// White shield for green or orange backgrounds.
  const KhabardarLogo.onColor({
    super.key,
    this.size = 64,
    this.mark = KColors.green,
    this.dot = KColors.alertDot,
  }) : shield = Colors.white;

  final double size;
  final Color shield;
  final Color mark;
  final Color dot;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Khabardar',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(shield, mark, dot),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.shield, this.mark, this.dot);

  final Color shield;
  final Color mark;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final path = Path()
      ..moveTo(32, 4)
      ..lineTo(54, 12)
      ..lineTo(54, 30)
      ..cubicTo(54, 45, 44, 55, 32, 60)
      ..cubicTo(20, 55, 10, 45, 10, 30)
      ..lineTo(10, 12)
      ..close();
    canvas.drawPath(path, Paint()..color = shield);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28.5, 17, 7, 23),
        const Radius.circular(3.5),
      ),
      Paint()..color = mark,
    );
    canvas.drawCircle(const Offset(32, 48), 4, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.shield != shield || old.mark != mark || old.dot != dot;
}

/// Logo plus the English and Urdu wordmarks.
class KhabardarWordmark extends StatelessWidget {
  const KhabardarWordmark({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : KColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        light
            ? const KhabardarLogo.onColor(size: 34)
            : const KhabardarLogo(size: 34),
        const SizedBox(width: 10),
        Text(
          'Khabardar',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
