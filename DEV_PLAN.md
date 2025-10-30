# Conway's Game of Life: Development Plan

This document outlines the development steps for the Conway's Game of Life application, based on the PRD.

## Technical Guidelines

1.  **State Management:** We will use Riverpod for state management.
2.  **Controller-based Architecture:** A central `GameController` will handle all business logic, state updates, and user interactions. We will avoid creating numerous small providers; the UI will primarily interact with the `gameControllerProvider`.
3.  **Code Generation:** We will use `riverpod_generator` to generate the provider for our `GameController`. We will **not** use `freezed` or similar packages to keep the models simple and dependency-light.

---

## Phase 1: Project Setup & Core Logic

*   [ ] **Initialize Flutter Project**
    *   [ ] Create a new Flutter project.
    *   [ ] Clean up the default counter app code.
*   [ ] **Add Dependencies**
    *   [ ] Add `flutter_riverpod` and `riverpod_annotation` to `pubspec.yaml`.
    *   [ ] Add `build_runner` and `riverpod_generator` as dev dependencies.
*   [ ] **Set Up Riverpod State & Controller**
    *   [ ] Create a `game_state.dart` file for the state model (e.g., a class `GameState` holding the grid, generation count, etc.).
    *   [ ] Create the `game_controller.dart` file.
    *   [ ] In `game_controller.dart`, define the `GameController` class as a `Notifier` using the `@riverpod` annotation.
    *   [ ] Run the build runner to generate the `*.g.dart` file for the provider.
*   [ ] **Implement Core Game Logic**
    *   [ ] Inside the `GameController`, create the data structure for the grid (e.g., `List<List<bool>>`).
    *   [ ] Implement the `tick()` or `nextGeneration()` method that calculates the grid state for the next generation based on Conway's rules.

## Phase 2: UI - Grid and Controls

*   [ ] **Build the Game Screen UI**
    *   [ ] Create a `GameScreen` widget that watches the `gameControllerProvider`.
    *   [ ] Lay out the main areas: the grid display and the control panel.
*   [ ] **Create the Interactive Grid Widget**
    *   [ ] Build a custom widget to render the grid based on the state from the controller.
    *   [ ] Use a `GestureDetector` to handle user input for toggling cells.
    *   [ ] Tapping a cell should call a method on the `GameController` (e.g., `toggleCell(row, col)`).
    *   [ ] (Optional) Implement panning and zooming for the grid.
*   [ ] **Implement Simulation Controls**
    *   [ ] Add Play/Pause, Step, and Reset buttons to the UI.
    *   [ ] The **Play/Pause** button will call a method on the `GameController` that starts/stops a `Timer` which calls the `tick()` method repeatedly.
    *   [ ] The **Step** button will call the `tick()` method once.
    *   [ ] The **Reset** button will call a method on the `GameController` to clear the grid.
*   [ ] **Add Speed Control**
    *   [ ] Add a `Slider` widget to the control panel.
    *   [ ] The slider's `onChanged` callback will update a `simulationSpeed` property in the `GameController`.
*   [ ] **Display Game State**
    *   [ ] Add a `Text` widget to display the current generation count from the `GameState`.

## Phase 3: Patterns

*   [ ] **Implement Preset Pattern Library**
    *   [ ] Create a data structure or service to hold a list of preset patterns (e.g., Glider, Pulsar).
    *   [ ] Build a UI element (like a dropdown or a modal) to show the list of presets.
    *   [ ] When a user selects a preset, call a method on the `GameController` (e.g., `loadPattern(pattern)`) to update the grid.
*   [ ] **Implement Custom Pattern Saving/Loading**
    *   [ ] Add "Save" and "Load" buttons to the UI.
    *   [ ] The "Save" button will trigger a method in the `GameController` to serialize the current grid state.
    *   [ ] The "Load" button will allow the user to select a previously saved state to load onto the grid.

## Phase 4: Refinement & Future Features

*   [ ] **Testing**
    *   [ ] Write unit tests for the core game logic in the `GameController`.
    *   [ ] Write widget tests for the UI components.
*   [ ] **UI/UX Polish**
    *   [ ] Refine animations and visual feedback.
    *   [ ] Ensure the app is responsive and works well on different screen sizes.
*   [ ] **Begin Exploration of Evolutionary Simulation**
    *   [ ] Brainstorm metrics for tracking a pattern's "success" (e.g., distance traveled for a glider).
    *   [ ] Design the data models and controller logic for a "challenge mode".
