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
    final evolutionController = ref.read(evolutionControllerProvider.notifier);
    final initialPattern = ref.watch(gameControllerProvider.select((state) => state.liveCells));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolution Chamber'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status: ${evolutionState.status.name}'),
                if (evolutionState.status == EvolutionStatus.running)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(value: evolutionState.progress),
                  ),
                Text('Evolution Generation: ${evolutionState.evolutionGeneration}'),
                Text('Best Distance: ${evolutionState.currentBestDistance.toStringAsFixed(2)}'),
                Text('Mutation Rate: ${(evolutionState.mutationRate * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 20),
                if (evolutionState.status != EvolutionStatus.running) ...[
                  ElevatedButton(
                    onPressed: initialPattern.isNotEmpty
                        ? () => evolutionController.startEvolution(initialPattern)
                        : null,
                    child: const Text('Start Evolution'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<EvolutionPreset>(
                    decoration: const InputDecoration(labelText: 'Evolution Preset'),
                    value: evolutionState.activePreset,
                    items: EvolutionPreset.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (val) => evolutionController.applyPreset(val!),
                  ),
                  ExpansionTile(
                    title: const Text('Advanced Settings'),
                    initiallyExpanded: evolutionState.activePreset == EvolutionPreset.custom,
                    children: [
                      _buildSettingsPanel(evolutionState, evolutionController),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (evolutionState.bestPatternSoFar.isNotEmpty) ...[
                  const Text('Best Pattern Found:'),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: CustomPaint(
                      painter: _PatternPainter(evolutionState.bestPatternSoFar),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final gameController = ref.read(gameControllerProvider.notifier);
                      gameController.reset();
                      gameController.state = gameController.state.copyWith(liveCells: evolutionState.bestPatternSoFar);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Load Best Pattern'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(EvolutionState evolutionState, EvolutionController evolutionController) {
    return Column(
      children: [
        Text('Total Generations: ${evolutionState.totalEvolutionGenerations}'),
        Slider(
          value: (evolutionState.totalEvolutionGenerations / 500000) - 1,
          min: 0,
          max: 3,
          divisions: 3,
          label: '${((evolutionState.totalEvolutionGenerations / 500000) * 0.5).toStringAsFixed(1)}M',
          onChanged: (value) {
            final generations = ((value + 1) * 500000).toInt();
            evolutionController.setTotalGenerations(generations);
          },
        ),
        const SizedBox(height: 16),
        Text('Population Size: ${evolutionState.populationSize}'),
        Slider(
          value: evolutionState.populationSize.toDouble(),
          min: 10,
          max: 50,
          divisions: 4,
          label: evolutionState.populationSize.toString(),
          onChanged: (value) => evolutionController.setPopulationSize(value.toInt()),
        ),
        const SizedBox(height: 16),
        Text('Max Cell Count: ${evolutionState.maxCellCount}'),
        Slider(
          value: evolutionState.maxCellCount.toDouble(),
          min: 10,
          max: 200,
          divisions: 19,
          label: evolutionState.maxCellCount.toString(),
          onChanged: (value) => evolutionController.setMaxCellCount(value.toInt()),
        ),
        const SizedBox(height: 16),
        Text('Test Generations per Pattern: ${evolutionState.testGenerationsPerPattern}'),
        Slider(
          value: evolutionState.testGenerationsPerPattern.toDouble(),
          min: 50,
          max: 1000,
          divisions: 19,
          label: evolutionState.testGenerationsPerPattern.toString(),
          onChanged: (value) => evolutionController.setTestGenerationsPerPattern(value.toInt()),
        ),
        const SizedBox(height: 16),
        Text('Adaptation Rate: ${evolutionState.adaptationRate.toStringAsFixed(1)}x'),
        Slider(
          value: evolutionState.adaptationRate,
          min: 1.1,
          max: 3.0,
          divisions: 19,
          label: '${evolutionState.adaptationRate.toStringAsFixed(1)}x',
          onChanged: (value) => evolutionController.setAdaptationRate(value),
        ),
        CheckboxListTile(
          title: const Text('Use Mass Conservation'),
          value: evolutionState.useMassConservation,
          onChanged: (val) => evolutionController.setUseMassConservation(val!),
        ),
        CheckboxListTile(
          title: const Text('Use Purity Check'),
          value: evolutionState.usePurityCheck,
          onChanged: (val) => evolutionController.setUsePurityCheck(val!),
        ),
        CheckboxListTile(
          title: const Text('Use Size Incentive'),
          value: evolutionState.useSizeIncentive,
          onChanged: (val) => evolutionController.setUseSizeIncentive(val!),
        ),
        DropdownButtonFormField<MutationStrategy>(
          decoration: const InputDecoration(labelText: 'Mutation Strategy'),
          value: evolutionState.mutationStrategy,
          items: MutationStrategy.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (val) => evolutionController.setMutationStrategy(val!),
        ),
        DropdownButtonFormField<CrossoverStrategy>(
          decoration: const InputDecoration(labelText: 'Crossover Strategy'),
          value: evolutionState.crossoverStrategy,
          items: CrossoverStrategy.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (val) => evolutionController.setCrossoverStrategy(val!),
        ),
      ],
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
