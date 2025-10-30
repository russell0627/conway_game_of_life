import 'dart:collection';

import 'package:conway_game_of_life/point.dart';

enum EvolutionStatus {
  idle,
  running,
  paused,
  finished,
}

class EvolutionState {
  final Set<Point> championPattern;
  final double bestDistance;
  final int evolutionGeneration;
  final double mutationRate;
  final EvolutionStatus status;
  final int totalEvolutionGenerations;

  EvolutionState({
    this.championPattern = const {},
    this.bestDistance = 0.0,
    this.evolutionGeneration = 0,
    this.mutationRate = 0.05, // Start with a 5% mutation rate
    this.status = EvolutionStatus.idle,
    this.totalEvolutionGenerations = 500000,
  });

  EvolutionState copyWith({
    Set<Point>? championPattern,
    double? bestDistance,
    int? evolutionGeneration,
    double? mutationRate,
    EvolutionStatus? status,
    int? totalEvolutionGenerations,
  }) {
    return EvolutionState(
      championPattern: championPattern ?? this.championPattern,
      bestDistance: bestDistance ?? this.bestDistance,
      evolutionGeneration: evolutionGeneration ?? this.evolutionGeneration,
      mutationRate: mutationRate ?? this.mutationRate,
      status: status ?? this.status,
      totalEvolutionGenerations: totalEvolutionGenerations ?? this.totalEvolutionGenerations,
    );
  }
}
