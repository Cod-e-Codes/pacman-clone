// File: lib/models/ghost.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'game_grid.dart';
import 'pacman.dart';

enum GhostType { blinky, pinky, inky, clyde }

class Ghost {
  int row;
  int col;
  bool isVulnerable = false;
  bool isFlashing = false;
  Color color;
  GhostType type;

  Ghost({
    required this.row,
    required this.col,
    required this.color,
    required this.type,
  });

  void move(GameGrid grid, Pacman pacman, Ghost blinky, List<Ghost> ghosts) {
    if (isVulnerable) {
      _moveAwayFromPacman(grid, pacman, ghosts);
    } else {
      switch (type) {
        case GhostType.blinky:
          _chasePacman(grid, pacman, ghosts);
          break;
        case GhostType.pinky:
          _ambushPacman(grid, pacman, ghosts);
          break;
        case GhostType.inky:
          _randomMovement(grid, ghosts);
          break;
        case GhostType.clyde:
          _patrolArea(grid, pacman, ghosts);
          break;
      }
    }
  }

  void _chasePacman(GameGrid grid, Pacman pacman, List<Ghost> ghosts) {
    _moveTowardsTarget(grid, pacman.row, pacman.col, ghosts);
  }

  void _ambushPacman(GameGrid grid, Pacman pacman, List<Ghost> ghosts) {
    int targetRow = pacman.row;
    int targetCol = pacman.col;

    switch (pacman.direction) {
      case 'up':
        targetRow -= 4;
        break;
      case 'down':
        targetRow += 4;
        break;
      case 'left':
        targetCol -= 4;
        break;
      case 'right':
        targetCol += 4;
        break;
    }

    _moveTowardsTarget(grid, targetRow, targetCol, ghosts);
  }

  void _randomMovement(GameGrid grid, List<Ghost> ghosts) {
    List<String> possibleDirections = _getPossibleDirections(grid);

    if (possibleDirections.isNotEmpty) {
      String direction = possibleDirections[Random().nextInt(possibleDirections.length)];
      _moveInDirection(direction, grid, ghosts);
    }
  }

  void _patrolArea(GameGrid grid, Pacman pacman, List<Ghost> ghosts) {
    int distance = (row - pacman.row).abs() + (col - pacman.col).abs();
    if (distance > 8) {
      _moveTowardsTarget(grid, pacman.row, pacman.col, ghosts);
    } else {
      _randomMovement(grid, ghosts);
    }
  }

  void _moveAwayFromPacman(GameGrid grid, Pacman pacman, List<Ghost> ghosts) {
    List<String> possibleDirections = _getPossibleDirections(grid);

    List<String> bestDirections = [];
    int maxDistance = -1;

    for (var direction in possibleDirections) {
      int testRow = row;
      int testCol = col;

      if (direction == 'up') testRow--;
      if (direction == 'down') testRow++;
      if (direction == 'left') testCol--;
      if (direction == 'right') testCol++;

      int distance = (testRow - pacman.row).abs() + (testCol - pacman.col).abs();
      if (distance > maxDistance) {
        maxDistance = distance;
        bestDirections = [direction];
      } else if (distance == maxDistance) {
        bestDirections.add(direction);
      }
    }

    if (bestDirections.isNotEmpty) {
      String chosenDirection = bestDirections[Random().nextInt(bestDirections.length)];
      _moveInDirection(chosenDirection, grid, ghosts);
    }
  }

  void _moveTowardsTarget(GameGrid grid, int targetRow, int targetCol, List<Ghost> ghosts) {
    List<String> possibleDirections = _getPossibleDirections(grid);

    List<String> bestDirections = [];
    int minDistance = 9999;

    for (var direction in possibleDirections) {
      int testRow = row;
      int testCol = col;

      if (direction == 'up') testRow--;
      if (direction == 'down') testRow++;
      if (direction == 'left') testCol--;
      if (direction == 'right') testCol++;

      int distance = (testRow - targetRow).abs() + (testCol - targetCol).abs();
      if (distance < minDistance) {
        minDistance = distance;
        bestDirections = [direction];
      } else if (distance == minDistance) {
        bestDirections.add(direction);
      }
    }

    if (bestDirections.isNotEmpty) {
      String chosenDirection = bestDirections[Random().nextInt(bestDirections.length)];
      _moveInDirection(chosenDirection, grid, ghosts);
    }
  }

  List<String> _getPossibleDirections(GameGrid grid) {
    List<String> possibleDirections = [];

    if (row > 0 && !grid.isWall(row - 1, col)) possibleDirections.add('up');
    if (row < gridRows - 1 && !grid.isWall(row + 1, col)) possibleDirections.add('down');
    if (col > 0 && !grid.isWall(row, col - 1)) possibleDirections.add('left');
    if (col < gridColumns - 1 && !grid.isWall(row, col + 1)) possibleDirections.add('right');

    return possibleDirections;
  }

  void _moveInDirection(String? direction, GameGrid grid, List<Ghost> ghosts) {
    int newRow = row;
    int newCol = col;

    if (direction == 'up') newRow--;
    if (direction == 'down') newRow++;
    if (direction == 'left') newCol--;
    if (direction == 'right') newCol++;

    // Boundary and wall check
    if (newRow >= 0 &&
        newRow < gridRows &&
        newCol >= 0 &&
        newCol < gridColumns &&
        !grid.isWall(newRow, newCol) &&
        !_isCellOccupiedByOtherGhost(newRow, newCol, ghosts)) {
      row = newRow;
      col = newCol;
    }
  }

  bool _isCellOccupiedByOtherGhost(int newRow, int newCol, List<Ghost> ghosts) {
    for (var ghost in ghosts) {
      if (ghost != this && ghost.row == newRow && ghost.col == newCol) {
        return true;
      }
    }
    return false;
  }

  void setVulnerable(bool vulnerable) {
    isVulnerable = vulnerable;
    isFlashing = false; // Reset flashing state when vulnerability changes
  }

  void startFlashing() {
    isFlashing = true; // Set flashing to true when vulnerability is about to end
  }

  void stopFlashing() {
    isFlashing = false; // Stop flashing when vulnerability ends
  }
}
