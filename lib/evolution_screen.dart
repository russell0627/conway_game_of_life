import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conway_game_of_life/game_controller.dart';
import 'evolution_controller.dart';
import 'evolution_state.dart';
import 'point.dart';

class EvolutionScreen extends ConsumerWidget {
  const EvolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evolutionState = ref.watch(evolutionControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);
    final initialPattern = ref.watch(gameControllerProvider.select((state) => state.liveCells));

    final double sliderValue = (evolutionState.totalEvolutionGenerations / 500000) - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolution Chamber'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: ${evolutionState.status.name}'),
            Text('Evolution Generation: ${evolutionState.evolutionGeneration}'),
            Text('Best Distance: ${evolutionState.bestDistance.toStringAsFixed(2)}'),
            Text('Mutation Rate: ${(evolutionState.mutationRate * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 20),
            if (evolutionState.status == EvolutionStatus.running)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Text('Total Generations: ${evolutionState.totalEvolutionGenerations}'),
                  Slider(
                    value: sliderValue,
                    min: 0,
                    max: 3,
                    divisions: 3,
                    label: '${(sliderValue + 1) * 0.5}M',
                    onChanged: (value) {
                      final generations = ((value + 1) * 500000).toInt();
                      ref.read(evolutionControllerProvider.notifier).setTotalGenerations(generations);
                    },
                  ),
                  ElevatedButton(
                    onPressed: initialPattern.isNotEmpty
                        ? () {
                            ref.read(evolutionControllerProvider.notifier).startEvolution(initialPattern);
                          }
                        : null, // Disable button if there's no initial pattern
                    child: const Text('Start Evolution'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (evolutionState.championPattern.isNotEmpty)
              Column(
                children: [
                  const Text('Champion Pattern:'),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: CustomPaint(
                      painter: _PatternPainter(evolutionState.championPattern),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      gameController.reset();
                      gameController.state = gameController.state.copyWith(liveCells: evolutionState.championPattern);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Load Champion'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Set<Point> pattern;

  _PatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern.isEmpty) return;

    final paint = Paint()..color = Colors.amber.shade300;
    final bounds = _getBounds(pattern);
    final patternWidth = bounds[1] - bounds[0] + 1;
    final patternHeight = bounds[3] - bounds[2] + 1;
    final cellSize = size.width / max(patternWidth, patternHeight);

    for (final point in pattern) {
      final x = (point.x - bounds[0]) * cellSize;
      final y = (point.y - bounds[2]) * cellSize;
      canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern;
  }

  List<int> _getBounds(Set<Point> cells) {
    if (cells.isEmpty) return [0, 0, 0, 0];
    int minX = cells.first.x, maxX = cells.first.x, minY = cells.first.y, maxY = cells.first.y;
    for (var cell in cells) {
      if (cell.x < minX) minX = cell.x;
      if (cell.x > maxX) maxX = cell.x;
      if (cell.y < minY) minY = cell.y;
      if (cell.y > maxY) maxY = cell.y;
    }
    return [minX, maxX, minY, maxY];
  }
}
