import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';
import 'patterns.dart';
import 'point.dart';
import 'simulation_stats.dart';

part 'game_controller.g.dart';

@riverpod
class GameController extends _$GameController {
  Timer? _timer;
  List<Set<Point>> _history = [];

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return GameState(liveCells: {}, generation: 0, isRunning: false);
  }

  void toggleCell(Point point) {
    if (state.isRunning) return;
    final newCells = Set<Point>.from(state.liveCells);
    if (newCells.contains(point)) {
      newCells.remove(point);
    } else {
      newCells.add(point);
    }
    state = state.copyWith(liveCells: newCells);
  }

  void tick() {
    final currentLiveCells = state.liveCells;

    // --- Start of Stats Logic ---
    if (state.stats != null) {
      // Died Out
      if (currentLiveCells.isEmpty) {
        stopChallenge(SimulationStatus.diedOut);
        return;
      }

      // Stabilized
      if (_history.any((prev) => const SetEquality().equals(prev, currentLiveCells))) {
        stopChallenge(SimulationStatus.stabilized);
        return;
      }
      _history.add(currentLiveCells);
      if (_history.length > 10) {
        _history.removeAt(0); // Keep history bounded
      }

      // Update Stats
      final peak = max(state.stats!.peakPopulation, currentLiveCells.length);
      final com = _getCenterOfMass(currentLiveCells);
      final distance = _calculateDistance(state.stats!.initialCenterOfMass, com);

      state = state.copyWith(stats: state.stats!.copyWith(
        peakPopulation: peak,
        distanceTraveled: distance,
      ));
    }
    // --- End of Stats Logic ---

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

    state = state.copyWith(liveCells: nextLiveCells, generation: state.generation + 1);
    if (state.followPattern) {
      _centerOnPattern();
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    if (state.isRunning) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    final durationMs = (1000 - (state.speed * 950)).toInt();
    _timer = Timer.periodic(Duration(milliseconds: durationMs), (timer) {
      tick();
    });
  }

  void togglePlayPause() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    } else {
      _startTimer();
      state = state.copyWith(isRunning: true);
    }
  }

  void toggleFollowPattern() {
    state = state.copyWith(followPattern: !state.followPattern);
  }

  void reset() {
    _timer?.cancel();
    _history.clear();
    state = GameState(liveCells: {}, generation: 0, isRunning: false, speed: state.speed, followPattern: state.followPattern);
  }

  void startChallenge() {
    final initialCoM = _getCenterOfMass(state.liveCells);
    final stats = SimulationStats(initialCenterOfMass: initialCoM, startGeneration: state.generation);
    state = state.copyWith(stats: stats);
    if (!state.isRunning) {
      togglePlayPause();
    }
  }

  void stopChallenge(SimulationStatus status) {
    if (state.isRunning) {
      togglePlayPause();
    }
    state = state.copyWith(stats: state.stats?.copyWith(status: status, endGeneration: state.generation));
  }

  void loadPattern(List<List<int>> pattern) {
    reset();
    final newCells = <Point>{};
    for (var point in pattern) {
      newCells.add(Point(point[0], point[1]));
    }
    state = state.copyWith(liveCells: newCells, generation: 0);
    if (state.followPattern) {
      _centerOnPattern(immediate: true);
    }
  }

  void panCamera(Point delta) {
    if (state.followPattern) return;
    state = state.copyWith(cameraOffset: Point(state.cameraOffset.x + delta.x, state.cameraOffset.y + delta.y));
  }

  Point _getCenterOfMass(Set<Point> cells) {
    if (cells.isEmpty) return const Point(0, 0);
    double avgX = 0;
    double avgY = 0;
    for (final cell in cells) {
      avgX += cell.x;
      avgY += cell.y;
    }
    return Point((avgX / cells.length).round(), (avgY / cells.length).round());
  }

  double _calculateDistance(Point p1, Point p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  void _centerOnPattern({bool immediate = false}) {
    state = state.copyWith(cameraOffset: _getCenterOfMass(state.liveCells));
  }

  Future<void> savePattern() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, int>> cellList = state.liveCells.map((p) => {'x': p.x, 'y': p.y}).toList();
    final gridJson = jsonEncode(cellList);
    await prefs.setString('saved_pattern', gridJson);
  }

  Future<void> loadSavedPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final gridJson = prefs.getString('saved_pattern');
    if (gridJson != null) {
      final decodedList = jsonDecode(gridJson) as List<dynamic>;
      final newCells = decodedList.map((item) {
        final map = item as Map<String, dynamic>;
        return Point(map['x'] as int, map['y'] as int);
      }).toSet();
      
      reset();
      state = state.copyWith(liveCells: newCells, generation: 0);
      if (state.followPattern) {
        _centerOnPattern(immediate: true);
      }
    }
  }
}
