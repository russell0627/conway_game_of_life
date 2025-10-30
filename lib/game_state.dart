import 'dart:collection';

import 'package:conway_game_of_life/simulation_stats.dart';

import 'point.dart';

class GameState {
  final Set<Point> liveCells;
  final int generation;
  final bool isRunning;
  final double speed;
  final Point cameraOffset;
  final bool followPattern;
  final SimulationStats? stats;

  GameState({
    required this.liveCells,
    required this.generation,
    this.isRunning = false,
    this.speed = 0.5,
    this.cameraOffset = const Point(0, 0),
    this.followPattern = true,
    this.stats,
  });

  GameState copyWith({
    Set<Point>? liveCells,
    int? generation,
    bool? isRunning,
    double? speed,
    Point? cameraOffset,
    bool? followPattern,
    SimulationStats? stats,
  }) {
    return GameState(
      liveCells: liveCells ?? this.liveCells,
      generation: generation ?? this.generation,
      isRunning: isRunning ?? this.isRunning,
      speed: speed ?? this.speed,
      cameraOffset: cameraOffset ?? this.cameraOffset,
      followPattern: followPattern ?? this.followPattern,
      stats: stats ?? this.stats,
    );
  }
}
