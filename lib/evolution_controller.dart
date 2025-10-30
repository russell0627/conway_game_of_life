import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';

import 'evolution_state.dart';
import 'point.dart';

part 'evolution_controller.g.dart';

// Top-level function for the isolate
Future<Map<String, dynamic>> _runEvolutionLoop(Map<String, dynamic> args) async {
  final Set<Point> initialPattern = (args['pattern'] as List).map((p) => Point(p['x'], p['y'])).toSet();
  double mutationRate = args['mutationRate'];
  final int totalGenerations = args['totalGenerations'];

  final int evolutionCycles = totalGenerations ~/ (10 * 500); // 10 candidates, 500 test generations
  
  Set<Point> championPattern = initialPattern;
  double bestDistance = await _testPattern(championPattern);

  for (int i = 0; i < evolutionCycles; i++) {
    final List<Set<Point>> candidates = List.generate(10, (_) => _mutate(championPattern, mutationRate));
    
    double bestCandidateDistance = 0;
    Set<Point> bestCandidate = {};

    for (final candidate in candidates) {
      final distance = await _testPattern(candidate);
      if (distance > bestCandidateDistance) {
        bestCandidateDistance = distance;
        bestCandidate = candidate;
      }
    }

    if (bestCandidateDistance > bestDistance) {
      bestDistance = bestCandidateDistance;
      championPattern = bestCandidate;
      mutationRate = 0.05; // Reset mutation rate
    } else {
      mutationRate *= 1.2; // Increase mutation rate
    }
  }

  return {
    'championPattern': championPattern.map((p) => {'x': p.x, 'y': p.y}).toList(),
    'bestDistance': bestDistance,
    'mutationRate': mutationRate,
    'evolutionGeneration': evolutionCycles,
  };
}

Future<double> _testPattern(Set<Point> pattern) async {
  if (pattern.isEmpty) return 0.0;

  final initialCoM = _getCenterOfMass(pattern);
  Set<Point> currentLiveCells = pattern;
  List<Set<Point>> history = [];

  for (int i = 0; i < 500; i++) { // Test for 500 generations
    if (currentLiveCells.isEmpty) break;
    if (history.any((prev) => const SetEquality().equals(prev, currentLiveCells))) break;
    history.add(currentLiveCells);
    if (history.length > 10) history.removeAt(0);

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
  return _calculateDistance(initialCoM, finalCoM);
}

Set<Point> _mutate(Set<Point> pattern, double rate) {
  final newPattern = Set<Point>.from(pattern);
  final random = Random();

  // Add or remove cells near the pattern
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
    state = state.copyWith(totalEvolutionGenerations: generations);
  }

  Future<void> startEvolution(Set<Point> initialPattern) async {
    state = state.copyWith(status: EvolutionStatus.running, championPattern: initialPattern, evolutionGeneration: 0);

    // Allow the UI to update before starting the heavy computation
    await Future.delayed(Duration.zero);

    final result = await compute(_runEvolutionLoop, {
      'pattern': initialPattern.map((p) => {'x': p.x, 'y': p.y}).toList(),
      'mutationRate': state.mutationRate,
      'totalGenerations': state.totalEvolutionGenerations,
    });

    final Set<Point> championPattern = (result['championPattern'] as List).map((p) => Point(p['x'], p['y'])).toSet();

    state = state.copyWith(
      championPattern: championPattern,
      bestDistance: result['bestDistance'],
      mutationRate: result['mutationRate'],
      status: EvolutionStatus.finished,
      evolutionGeneration: result['evolutionGeneration'],
    );
  }
}
