import 'dart:collection';

import 'package:conway_game_of_life/point.dart';

enum EvolutionStatus {
  idle,
  running,
  paused,
  finished,
}

enum MutationStrategy {
  randomBox,
  growth,
}

enum CrossoverStrategy {
  randomMix,
  simulatedCollision,
}

enum EvolutionPreset {
  custom,
  spaceshipHunter,
  creativeExplorer,
}

class EvolutionState {
  final List<Set<Point>> population;
  final Set<Point> bestPatternSoFar;
  final double bestDistance;
  final double currentBestDistance; // New property
  final int evolutionGeneration;
  final double mutationRate;
  final EvolutionStatus status;
  final int totalEvolutionGenerations;
  final double progress;

  // New Settings
  final bool useMassConservation;
  final bool usePurityCheck;
  final bool useSizeIncentive;
  final MutationStrategy mutationStrategy;
  final CrossoverStrategy crossoverStrategy;
  final double adaptationRate;
  final EvolutionPreset activePreset;
  final int populationSize;
  final int maxCellCount;
  final int testGenerationsPerPattern;

  EvolutionState({
    this.population = const [],
    this.bestPatternSoFar = const {},
    this.bestDistance = 0.0,
    this.currentBestDistance = 0.0, // Initialize new property
    this.evolutionGeneration = 0,
    this.mutationRate = 0.05,
    this.status = EvolutionStatus.idle,
    this.totalEvolutionGenerations = 500000,
    this.progress = 0.0,
    this.useMassConservation = true,
    this.usePurityCheck = true,
    this.useSizeIncentive = false,
    this.mutationStrategy = MutationStrategy.growth,
    this.crossoverStrategy = CrossoverStrategy.simulatedCollision,
    this.adaptationRate = 1.5,
    this.activePreset = EvolutionPreset.custom,
    this.populationSize = 20,
    this.maxCellCount = 200,
    this.testGenerationsPerPattern = 200,
  });

  EvolutionState copyWith({
    List<Set<Point>>? population,
    Set<Point>? bestPatternSoFar,
    double? bestDistance,
    double? currentBestDistance, // Add to copyWith
    int? evolutionGeneration,
    double? mutationRate,
    EvolutionStatus? status,
    int? totalEvolutionGenerations,
    double? progress,
    bool? useMassConservation,
    bool? usePurityCheck,
    bool? useSizeIncentive,
    MutationStrategy? mutationStrategy,
    CrossoverStrategy? crossoverStrategy,
    double? adaptationRate,
    EvolutionPreset? activePreset,
    int? populationSize,
    int? maxCellCount,
    int? testGenerationsPerPattern,
  }) {
    return EvolutionState(
      population: population ?? this.population,
      bestPatternSoFar: bestPatternSoFar ?? this.bestPatternSoFar,
      bestDistance: bestDistance ?? this.bestDistance,
      currentBestDistance: currentBestDistance ?? this.currentBestDistance, // Update in copyWith
      evolutionGeneration: evolutionGeneration ?? this.evolutionGeneration,
      mutationRate: mutationRate ?? this.mutationRate,
      status: status ?? this.status,
      totalEvolutionGenerations: totalEvolutionGenerations ?? this.totalEvolutionGenerations,
      progress: progress ?? this.progress,
      useMassConservation: useMassConservation ?? this.useMassConservation,
      usePurityCheck: usePurityCheck ?? this.usePurityCheck,
      useSizeIncentive: useSizeIncentive ?? this.useSizeIncentive,
      mutationStrategy: mutationStrategy ?? this.mutationStrategy,
      crossoverStrategy: crossoverStrategy ?? this.crossoverStrategy,
      adaptationRate: adaptationRate ?? this.adaptationRate,
      activePreset: activePreset ?? this.activePreset,
      populationSize: populationSize ?? this.populationSize,
      maxCellCount: maxCellCount ?? this.maxCellCount,
      testGenerationsPerPattern: testGenerationsPerPattern ?? this.testGenerationsPerPattern,
    );
  }
}
