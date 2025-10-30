import 'package:conway_game_of_life/point.dart';

enum SimulationStatus {
  running,
  diedOut,
  stabilized,
  stopped,
}

class SimulationStats {
  final int peakPopulation;
  final double distanceTraveled;
  final SimulationStatus status;
  final int startGeneration;
  final int endGeneration;
  final Point initialCenterOfMass;

  SimulationStats({
    this.peakPopulation = 0,
    this.distanceTraveled = 0.0,
    this.status = SimulationStatus.running,
    this.startGeneration = 0,
    this.endGeneration = 0,
    required this.initialCenterOfMass,
  });

  SimulationStats copyWith({
    int? peakPopulation,
    double? distanceTraveled,
    SimulationStatus? status,
    int? startGeneration,
    int? endGeneration,
    Point? initialCenterOfMass,
  }) {
    return SimulationStats(
      peakPopulation: peakPopulation ?? this.peakPopulation,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      status: status ?? this.status,
      startGeneration: startGeneration ?? this.startGeneration,
      endGeneration: endGeneration ?? this.endGeneration,
      initialCenterOfMass: initialCenterOfMass ?? this.initialCenterOfMass,
    );
  }
}
