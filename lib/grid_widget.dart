import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'point.dart';

class GridWidget extends ConsumerWidget {
  const GridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);
    final double cellSize = 20.0 * gameState.zoomLevel;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleStart: (details) => gameController.onZoomStart(),
          onScaleUpdate: (details) {
            gameController.onZoomUpdate(details.scale);
            // Pan the camera by converting screen delta to world delta
            final delta = Point(-(details.focalPointDelta.dx / cellSize).round(), -(details.focalPointDelta.dy / cellSize).round());
            if (delta.x != 0 || delta.y != 0) {
              ref.read(gameControllerProvider.notifier).panCamera(delta);
            }
          },
          onTapUp: (details) {
            // Toggle a cell by converting screen tap to world coordinates
            final tapPosition = details.localPosition;
            final worldX = (tapPosition.dx / cellSize).floor() + gameState.cameraOffset.x - (constraints.maxWidth / (2 * cellSize)).floor();
            final worldY = (tapPosition.dy / cellSize).floor() + gameState.cameraOffset.y - (constraints.maxHeight / (2 * cellSize)).floor();
            ref.read(gameControllerProvider.notifier).toggleCell(Point(worldX, worldY));
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: GridPainter(gameState, cellSize, constraints, Theme.of(context).colorScheme),
          ),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final GameState gameState;
  final double cellSize;
  final BoxConstraints constraints;
  final ColorScheme colorScheme;

  GridPainter(this.gameState, this.cellSize, this.constraints, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..color = Colors.amber.shade300;
    final gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1;

    final bgPaint1 = Paint()..color = colorScheme.background;
    final bgPaint2 = Paint()..color = colorScheme.onBackground.withOpacity(0.05);

    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final screenCenterX = gameState.cameraOffset.x;
    final screenCenterY = gameState.cameraOffset.y;

    final startX = screenCenterX - (screenWidth / (2 * cellSize)).floor();
    final endX = screenCenterX + (screenWidth / (2 * cellSize)).ceil();
    final startY = screenCenterY - (screenHeight / (2 * cellSize)).floor();
    final endY = screenCenterY + (screenHeight / (2 * cellSize)).ceil();

    // Draw checkerboard background
    for (int i = startX; i <= endX; i++) {
      for (int j = startY; j <= endY; j++) {
        final screenX = (i - startX) * cellSize;
        final screenY = (j - startY) * cellSize;
        final paint = (i + j) % 2 == 0 ? bgPaint1 : bgPaint2;
        canvas.drawRect(Rect.fromLTWH(screenX, screenY, cellSize, cellSize), paint);
      }
    }

    // Draw grid lines
    for (int i = startX; i <= endX; i++) {
      final x = (i - startX) * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, screenHeight), gridPaint);
    }
    for (int i = startY; i <= endY; i++) {
      final y = (i - startY) * cellSize;
      canvas.drawLine(Offset(0, y), Offset(screenWidth, y), gridPaint);
    }

    // Draw the origin marker
    if (0 >= startX && 0 <= endX && 0 >= startY && 0 <= endY) {
      final originX = (0 - startX) * cellSize;
      final originY = (0 - startY) * cellSize;
      final originPaint = Paint()..color = Colors.red.withOpacity(0.5);
      canvas.drawCircle(Offset(originX + cellSize / 2, originY + cellSize / 2), cellSize / 4, originPaint);
    }

    // Draw live cells
    for (final cell in gameState.liveCells) {
      if (cell.x >= startX && cell.x <= endX && cell.y >= startY && cell.y <= endY) {
        final x = (cell.x - startX) * cellSize;
        final y = (cell.y - startY) * cellSize;
        canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), cellPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gameState != gameState ||
        oldDelegate.constraints != constraints ||
        oldDelegate.colorScheme != colorScheme;
  }
}
