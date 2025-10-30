import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';
import 'grid_widget.dart';
import 'patterns.dart';
import 'simulation_stats.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final isRunning = gameState.isRunning;
    final speed = gameState.speed;
    final generation = gameState.generation;
    final followPattern = gameState.followPattern;
    final stats = gameState.stats;

    return Scaffold(
      appBar: AppBar(
        title: Text("Conway's Game of Life (Gen: $generation)"),
        actions: [
          IconButton(
            icon: Icon(followPattern ? Icons.location_searching : Icons.location_disabled),
            tooltip: 'Follow Pattern',
            onPressed: () => ref.read(gameControllerProvider.notifier).toggleFollowPattern(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Expanded(
            child: GridWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (stats == null)
                  _buildSetupUI(ref, isRunning)
                else
                  _buildChallengeUI(ref, stats, isRunning),
                Slider(
                  value: speed,
                  onChanged: (newSpeed) {
                    ref.read(gameControllerProvider.notifier).setSpeed(newSpeed);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupUI(WidgetRef ref, bool isRunning) {
    return Column(
      children: [
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select a Preset Pattern'),
          value: null,
          items: presetPatterns.keys.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(key),
            );
          }).toList(),
          onChanged: isRunning
              ? null
              : (String? newPatternKey) {
                  if (newPatternKey != null) {
                    final pattern = presetPatterns[newPatternKey];
                    if (pattern != null) {
                      ref.read(gameControllerProvider.notifier).loadPattern(pattern);
                    }
                  }
                },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => ref.read(gameControllerProvider.notifier).togglePlayPause(),
              child: Text(isRunning ? 'Pause' : 'Play'),
            ),
            ElevatedButton(
              onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).tick(),
              child: const Text('Step'),
            ),
            ElevatedButton(
              onPressed: () => ref.read(gameControllerProvider.notifier).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).savePattern(),
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).loadSavedPattern(),
              child: const Text('Load'),
            ),
            ElevatedButton(
              onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).startChallenge(),
              child: const Text('Start Challenge'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChallengeUI(WidgetRef ref, SimulationStats stats, bool isRunning) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Status: ${stats.status.name}'),
            ElevatedButton(
              onPressed: () => ref.read(gameControllerProvider.notifier).stopChallenge(SimulationStatus.stopped),
              child: const Text('Stop Challenge'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Peak Population: ${stats.peakPopulation}'),
        Text('Distance Traveled: ${stats.distanceTraveled.toStringAsFixed(2)}'),
        if (stats.status != SimulationStatus.running)
          Text('Duration: ${stats.endGeneration - stats.startGeneration} generations'),
      ],
    );
  }
}
