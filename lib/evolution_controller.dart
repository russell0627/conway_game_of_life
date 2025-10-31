import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';

import 'evolution_state.dart';
import 'point.dart';

part 'evolution_controller.g.dart';

const int testGenerations = 200;

// Top-level function for the isolate
Future<Map<String, dynamic>> _runEvolutionLoop(Map<String, dynamic> args) async {
  final SendPort sendPort = args['sendPort'];
  List<Set<Point>> population = (args['population'] as List)
      .map((p) => (p as List).map((c) => Point(c['x'], c['y'])).toSet())
      .toList();
  double mutationRate = args['mutationRate'];
  final int totalGenerations = args['totalGenerations'];
  final double adaptationRate = args['adaptationRate'];
  final int populationSize = args['populationSize'];
  final int maxCellCount = args['maxCellCount']; // Get maxCellCount from args
  final int evolutionCycles = totalGenerations ~/ (populationSize * testGenerations);

  // Pass settings to the isolate
  final bool useMassConservation = args['useMassConservation'];
  final bool usePurityCheck = args['usePurityCheck'];
  final bool useSizeIncentive = args['useSizeIncentive'];
  final MutationStrategy mutationStrategy = args['mutationStrategy'];
  final CrossoverStrategy crossoverStrategy = args['crossoverStrategy'];

  Set<Point> bestPatternSoFar = {};
  double bestDistanceSoFar = 0;

  for (int i = 0; i < evolutionCycles; i++) {
    final List<MapEntry<Set<Point>, double>> fitnesses = [];
    for (final individual in population) {
      final fitness = await _testPattern(
        individual,
        useMassConservation,
        usePurityCheck,
        useSizeIncentive,
        maxCellCount, // Pass maxCellCount to _testPattern
      );
      fitnesses.add(MapEntry(individual, fitness));
    }

    fitnesses.sort((a, b) => b.value.compareTo(a.value));

    if (fitnesses[0].value > bestDistanceSoFar) {
      bestDistanceSoFar = fitnesses[0].value;
      bestPatternSoFar = fitnesses[0].key;
    }

    final List<Set<Point>> newPopulation = [];
    newPopulation.add(fitnesses[0].key);
    newPopulation.add(fitnesses[1].key);

    for (int j = 0; j < populationSize - 2; j++) {
      final parent1 = fitnesses[0].key;
      final parent2 = fitnesses[j % 5 + 1].key;
      final child = crossoverStrategy == CrossoverStrategy.randomMix
          ? _crossover(parent1, parent2)
          : await _crossoverCollision(parent1, parent2);
      newPopulation.add(_mutate(child, mutationRate, mutationStrategy));
    }

    population = newPopulation;

    if (i > 0 && i % 10 == 0) {
      if (fitnesses[0].value <= bestDistanceSoFar) {
        mutationRate *= adaptationRate;
      } else {
        mutationRate = 0.05;
      }
    }
    sendPort.send({
      'progress': (i + 1) / evolutionCycles,
      'generation': i + 1,
      'bestDistance': bestDistanceSoFar, // Send updated best distance
    });
  }

  return {
    'bestPattern': bestPatternSoFar.map((p) => {'x': p.x, 'y': p.y}).toList(),
    'bestDistance': bestDistanceSoFar,
    'mutationRate': mutationRate,
    'evolutionGeneration': evolutionCycles,
  };
}

Future<double> _testPattern(
  Set<Point> pattern,
  bool useMassConservation,
  bool usePurityCheck,
  bool useSizeIncentive,
  int maxCellCount, // New parameter
) async {
  if (pattern.isEmpty) return 0.0;

  final initialCoM = _getCenterOfMass(pattern);
  final initialCellCount = pattern.length;
  final initialNormalized = _normalize(pattern);

  Set<Point> currentLiveCells = pattern;
  List<Set<Point>> history = [];
  bool isStable = false;

  for (int i = 0; i < testGenerations; i++) {
    if (currentLiveCells.isEmpty) {
      isStable = true;
      break;
    }

    // Population cap check
    if (currentLiveCells.length > maxCellCount) {
      return 0.0; // Immediately disqualify patterns that grow too large
    }

    final normalized = _normalize(currentLiveCells);
    if (history.any((prev) => const SetEquality().equals(prev, normalized))) {
      isStable = true;
      break;
    }
    history.add(normalized);
    if (history.length > 12) history.removeAt(0);

    final Map<Point, int> neighborCounts = {};
    for (final cell in currentLiveCells) {
      for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
          if (x == 0 && y == 0) continue;
          final neighbor = Point(cell.x + x, cell.y + y);
          neighborCounts[neighbor] = (neighborCounts[neighbor] ?? 0) + 1;
        }
      }
    }

    final Set<Point> nextLiveCells = {};
    neighborCounts.forEach((cell, count) {
      final isAlive = currentLiveCells.contains(cell);
      if (isAlive && (count == 2 || count == 3)) {
        nextLiveCells.add(cell);
      } else if (!isAlive && count == 3) {
        nextLiveCells.add(cell);
      }
    });
    currentLiveCells = nextLiveCells;
  }

  final finalCoM = _getCenterOfMass(currentLiveCells);
  double distance = _calculateDistance(initialCoM, finalCoM);
  double score = distance;

  if (useMassConservation) {
    final massRatio = currentLiveCells.length / initialCellCount;
    score *= (massRatio > 1.0) ? 1.0 : massRatio; // Penalize for losing mass
  }

  if (usePurityCheck) {
    final isPure = const SetEquality().equals(_normalize(currentLiveCells), initialNormalized);
    if (isPure && isStable) {
      score *= 10; // Massive bonus for pure, stable spaceships
    }
  }

  if (useSizeIncentive) {
    score *= (1 + 0.01 * initialCellCount);
  }

  return score;
}

Set<Point> _crossover(Set<Point> p1, Set<Point> p2) {
  final random = Random();
  final child = <Point>{};
  final allPoints = p1.union(p2);

  for (final point in allPoints) {
    if (p1.contains(point) && p2.contains(point)) {
      child.add(point);
    } else if (p1.contains(point) || p2.contains(point)) {
      if (random.nextDouble() < 0.5) {
        child.add(point);
      }
    }
  }
  return child;
}

Future<Set<Point>> _crossoverCollision(Set<Point> p1, Set<Point> p2) async {
  // Offset one pattern and simulate for a few generations
  final offsetP2 = p2.map((p) => Point(p.x + 5, p.y)).toSet();
  Set<Point> currentLiveCells = p1.union(offsetP2);

  for (int i = 0; i < 15; i++) {
    final Map<Point, int> neighborCounts = {};
    for (final cell in currentLiveCells) {
      for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
          if (x == 0 && y == 0) continue;
          final neighbor = Point(cell.x + x, cell.y + y);
          neighborCounts[neighbor] = (neighborCounts[neighbor] ?? 0) + 1;
        }
      }
    }
    final Set<Point> nextLiveCells = {};
    neighborCounts.forEach((cell, count) {
      final isAlive = currentLiveCells.contains(cell);
      if (isAlive && (count == 2 || count == 3)) {
        nextLiveCells.add(cell);
      } else if (!isAlive && count == 3) {
        nextLiveCells.add(cell);
      }
    });
    currentLiveCells = nextLiveCells;
  }
  return currentLiveCells;
}

Set<Point> _mutate(Set<Point> pattern, double rate, MutationStrategy strategy) {
  if (strategy == MutationStrategy.randomBox) {
    return _mutateRandomBox(pattern, rate);
  } else {
    return _mutateGrowth(pattern, rate);
  }
}

Set<Point> _mutateRandomBox(Set<Point> pattern, double rate) {
  final newPattern = Set<Point>.from(pattern);
  final random = Random();
  final bounds = _getBounds(pattern);

  for (int x = bounds[0] - 2; x <= bounds[1] + 2; x++) {
    for (int y = bounds[2] - 2; y <= bounds[3] + 2; y++) {
      if (random.nextDouble() < rate) {
        final point = Point(x, y);
        if (newPattern.contains(point)) {
          newPattern.remove(point);
        } else {
          newPattern.add(point);
        }
      }
    }
  }
  return newPattern;
}

Set<Point> _mutateGrowth(Set<Point> pattern, double rate) {
  final newPattern = Set<Point>.from(pattern);
  final random = Random();
  final potentialCells = <Point>{};

  for (final cell in pattern) {
    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
        if (x == 0 && y == 0) continue;
        potentialCells.add(Point(cell.x + x, cell.y + y));
      }
    }
  }

  for (final point in potentialCells) {
    if (random.nextDouble() < rate) {
      if (newPattern.contains(point)) {
        newPattern.remove(point);
      } else {
        newPattern.add(point);
      }
    }
  }
  return newPattern;
}

Set<Point> _normalize(Set<Point> cells) {
  if (cells.isEmpty) return {};
  final minX = cells.map((p) => p.x).reduce(min);
  final minY = cells.map((p) => p.y).reduce(min);
  return cells.map((p) => Point(p.x - minX, p.y - minY)).toSet();
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

Point _getCenterOfMass(Set<Point> cells) {
  if (cells.isEmpty) return const Point(0, 0);
  double avgX = 0, avgY = 0;
  for (final cell in cells) {
    avgX += cell.x;
    avgY += cell.y;
  }
  return Point((avgX / cells.length).round(), (avgY / cells.length).round());
}

double _calculateDistance(Point p1, Point p2) {
  return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
}

@riverpod
class EvolutionController extends _$EvolutionController {
  @override
  EvolutionState build() {
    return EvolutionState();
  }

  void setTotalGenerations(int generations) {
    state = state.copyWith(totalEvolutionGenerations: generations, activePreset: EvolutionPreset.custom);
  }

  void setAdaptationRate(double rate) {
    state = state.copyWith(adaptationRate: rate, activePreset: EvolutionPreset.custom);
  }

  void setPopulationSize(int size) {
    state = state.copyWith(populationSize: size, activePreset: EvolutionPreset.custom);
  }

  void setMaxCellCount(int count) {
    state = state.copyWith(maxCellCount: count, activePreset: EvolutionPreset.custom);
  }

  void setUseMassConservation(bool value) {
    state = state.copyWith(useMassConservation: value, activePreset: EvolutionPreset.custom);
  }

  void setUsePurityCheck(bool value) {
    state = state.copyWith(usePurityCheck: value, activePreset: EvolutionPreset.custom);
  }

  void setUseSizeIncentive(bool value) {
    state = state.copyWith(useSizeIncentive: value, activePreset: EvolutionPreset.custom);
  }

  void setMutationStrategy(MutationStrategy strategy) {
    state = state.copyWith(mutationStrategy: strategy, activePreset: EvolutionPreset.custom);
  }

  void setCrossoverStrategy(CrossoverStrategy strategy) {
    state = state.copyWith(crossoverStrategy: strategy, activePreset: EvolutionPreset.custom);
  }

  void applyPreset(EvolutionPreset preset) {
    if (preset == EvolutionPreset.custom) {
      state = state.copyWith(activePreset: preset);
      return;
    }

    if (preset == EvolutionPreset.spaceshipHunter) {
      state = state.copyWith(
        useMassConservation: true,
        usePurityCheck: true,
        useSizeIncentive: true,
        mutationStrategy: MutationStrategy.growth,
        crossoverStrategy: CrossoverStrategy.simulatedCollision,
        adaptationRate: 1.2,
        populationSize: 30,
        maxCellCount: 200,
        activePreset: preset,
      );
    } else if (preset == EvolutionPreset.creativeExplorer) {
      state = state.copyWith(
        useMassConservation: false,
        usePurityCheck: false,
        useSizeIncentive: false,
        mutationStrategy: MutationStrategy.randomBox,
        crossoverStrategy: CrossoverStrategy.randomMix,
        adaptationRate: 2.0,
        populationSize: 20,
        maxCellCount: 500,
        activePreset: preset,
      );
    }
  }

  Future<void> startEvolution(Set<Point> initialPattern) async {
    final initialPopulation = List.generate(state.populationSize, (_) => _mutate(initialPattern, 0.1, state.mutationStrategy));
    state = state.copyWith(
      status: EvolutionStatus.running,
      population: initialPopulation,
      bestPatternSoFar: initialPattern,
      evolutionGeneration: 0,
      progress: 0.0,
      currentBestDistance: 0.0,
    );

    final receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is Map) {
        state = state.copyWith(
          progress: message['progress'],
          evolutionGeneration: message['generation'],
          currentBestDistance: message['bestDistance'],
        );
      }
    });

    final result = await compute(_runEvolutionLoop, {
      'population': initialPopulation.map((p) => p.map((c) => {'x': c.x, 'y': c.y}).toList()).toList(),
      'mutationRate': state.mutationRate,
      'totalGenerations': state.totalEvolutionGenerations,
      'sendPort': receivePort.sendPort,
      'useMassConservation': state.useMassConservation,
      'usePurityCheck': state.usePurityCheck,
      'useSizeIncentive': state.useSizeIncentive,
      'mutationStrategy': state.mutationStrategy,
      'crossoverStrategy': state.crossoverStrategy,
      'adaptationRate': state.adaptationRate,
      'populationSize': state.populationSize,
      'maxCellCount': state.maxCellCount,
    });

    receivePort.close();

    final Set<Point> bestPattern = (result['bestPattern'] as List).map((p) => Point(p['x'], p['y'])).toSet();

    state = state.copyWith(
      bestPatternSoFar: bestPattern,
      bestDistance: result['bestDistance'],
      mutationRate: result['mutationRate'],
      status: EvolutionStatus.finished,
      evolutionGeneration: result['evolutionGeneration'],
      progress: 1.0,
    );
  }
}
