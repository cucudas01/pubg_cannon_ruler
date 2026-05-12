import 'package:flutter/material.dart';

class MortarPainter extends CustomPainter {
  final Offset? playerPos;
  final Offset? pingPos;
  final double distance;
  final Color teamColor;

  MortarPainter({this.playerPos, this.pingPos, required this.distance, required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (playerPos == null || pingPos == null) return;

    final paint = Paint()
      ..color = teamColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(playerPos!, 10, paint);
    canvas.drawCircle(pingPos!, 10, paint);
    canvas.drawLine(playerPos!, pingPos!, paint);

    final textSpan = TextSpan(
      text: " ${distance.toStringAsFixed(1)}m ",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black87,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset((playerPos!.dx + pingPos!.dx) / 2, (playerPos!.dy + pingPos!.dy) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}