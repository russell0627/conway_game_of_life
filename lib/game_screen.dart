import 'package:conway_game_of_life/evolution_screen.dart';
import 'package:conway_game_of_life/population_graph.dart';
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
          IconButton(
            icon: const Icon(Icons.biotech),
            tooltip: 'Evolution Chamber',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EvolutionScreen()),
              );
            },
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
                if (stats == null) ...[
                  PopulationGraph(history: gameState.populationHistory),
                  const SizedBox(height: 8),
                  _buildSetupUI(context, ref, isRunning),
                ] else
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

  Widget _buildSetupUI(BuildContext context, WidgetRef ref, bool isRunning) {
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
            Tooltip(
              message: isRunning ? 'Pause' : 'Play',
              child: IconButton(
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: () => ref.read(gameControllerProvider.notifier).togglePlayPause(),
              ),
            ),
            Tooltip(
              message: 'Next Generation',
              child: IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).tick(),
              ),
            ),
            Tooltip(
              message: 'Reset',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(gameControllerProvider.notifier).reset(),
              ),
            ),
            const VerticalDivider(),
            Tooltip(
              message: 'Save Pattern',
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: isRunning
                    ? null
                    : () {
                        ref.read(gameControllerProvider.notifier).savePattern();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pattern Saved!')),
                        );
                      },
              ),
            ),
            Tooltip(
              message: 'Load Pattern',
              child: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).loadSavedPattern(),
              ),
            ),
            const VerticalDivider(),
            Tooltip(
              message: 'Start Challenge',
              child: IconButton(
                icon: const Icon(Icons.flag),
                onPressed: isRunning ? null : () => ref.read(gameControllerProvider.notifier).startChallenge(),
              ),
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
