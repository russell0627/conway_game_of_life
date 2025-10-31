import 'dart:math';

import 'package:flutter/material.dart';

class PopulationGraph extends StatelessWidget {
  final List<int> history;

  const PopulationGraph({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _GraphPainter(history, Theme.of(context).colorScheme),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<int> history;
  final ColorScheme colorScheme;

  _GraphPainter(this.history, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = Colors.amber.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final maxPopulation = history.reduce(max);
    final path = Path();

    for (int i = 0; i < history.length; i++) {
      final x = (i / (history.length - 1)) * size.width;
      final y = size.height - (history[i] / maxPopulation) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
