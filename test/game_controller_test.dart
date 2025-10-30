import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conway_game_of_life/game_controller.dart';
import 'package:conway_game_of_life/point.dart';

void main() {
  group('GameController', () {
    test('initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final gameState = container.read(gameControllerProvider);

      expect(gameState.generation, 0);
      expect(gameState.isRunning, false);
      expect(gameState.liveCells, isEmpty);
    });

    test('toggleCell updates the liveCells set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameControllerProvider.notifier);
      const point = Point(5, 5);

      controller.toggleCell(point);
      expect(container.read(gameControllerProvider).liveCells, contains(point));

      controller.toggleCell(point);
      expect(container.read(gameControllerProvider).liveCells, isNot(contains(point)));
    });

    test('reset clears the liveCells and resets generation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameControllerProvider.notifier);
      const point = Point(5, 5);

      controller.toggleCell(point);
      controller.tick();
      controller.reset();

      final gameState = container.read(gameControllerProvider);
      expect(gameState.generation, 0);
      expect(gameState.liveCells, isEmpty);
    });

    test('tick method correctly evolves a blinker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameControllerProvider.notifier);

      // Create a horizontal blinker
      controller.toggleCell(const Point(0, 1));
      controller.toggleCell(const Point(1, 1));
      controller.toggleCell(const Point(2, 1));

      // First tick, should become a vertical blinker
      controller.tick();
      var liveCells = container.read(gameControllerProvider).liveCells;
      expect(liveCells, containsAll({const Point(1, 0), const Point(1, 1), const Point(1, 2)}));
      expect(liveCells, hasLength(3));
      expect(container.read(gameControllerProvider).generation, 1);

      // Second tick, should become a horizontal blinker again
      controller.tick();
      liveCells = container.read(gameControllerProvider).liveCells;
      expect(liveCells, containsAll({const Point(0, 1), const Point(1, 1), const Point(2, 1)}));
      expect(liveCells, hasLength(3));
      expect(container.read(gameControllerProvider).generation, 2);
    });

    test('loadPattern loads a pattern correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameControllerProvider.notifier);

      // Glider pattern data
      final gliderData = [
        [1, 0],
        [2, 1],
        [0, 2], [1, 2], [2, 2],
      ];

      controller.loadPattern(gliderData);

      final liveCells = container.read(gameControllerProvider).liveCells;

      // Check that the glider points are in the liveCells set
      final expectedGliderPoints = {
        const Point(1, 0),
        const Point(2, 1),
        const Point(0, 2),
        const Point(1, 2),
        const Point(2, 2),
      };

      expect(liveCells, equals(expectedGliderPoints));
    });
  });
}
