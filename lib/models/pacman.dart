// File: lib/models/pacman.dart

import '../utils/constants.dart';
import 'game_grid.dart';

class Pacman {
  int row;
  int col;
  String direction = ''; // Start with no movement
  String lastDirection = ''; // Track the last valid direction

  Pacman({required this.row, required this.col});

  void move(String newDirection, GameGrid grid) {
    int newRow = row;
    int newCol = col;

    // If no direction is set, Pacman doesn't move
    if (newDirection == '') {
      return;
    }

    // Determine the new direction's movement
    if (newDirection == 'left') {
      newCol--;
    } else if (newDirection == 'right') {
      newCol++;
    } else if (newDirection == 'up') {
      newRow--;
    } else if (newDirection == 'down') {
      newRow++;
    }

    // Check boundaries and walls for new direction
    bool canMoveNewDirection = newRow >= 0 &&
        newRow < gridRows &&
        newCol >= 0 &&
        newCol < gridColumns &&
        !grid.isWall(newRow, newCol);

    // Move Pacman if new direction is valid
    if (canMoveNewDirection) {
      row = newRow;
      col = newCol;
      lastDirection = newDirection; // Store the last valid direction
    } else if (lastDirection != newDirection) {
      // Try moving in the last valid direction, but no recursion
      // Reset newRow and newCol for lastDirection
      newRow = row;
      newCol = col;

      if (lastDirection == 'left') {
        newCol--;
      } else if (lastDirection == 'right') {
        newCol++;
      } else if (lastDirection == 'up') {
        newRow--;
      } else if (lastDirection == 'down') {
        newRow++;
      }

      // Check if the last direction is still valid
      bool canMoveLastDirection = newRow >= 0 &&
          newRow < gridRows &&
          newCol >= 0 &&
          newCol < gridColumns &&
          !grid.isWall(newRow, newCol);

      // Move Pacman in the last valid direction if possible
      if (canMoveLastDirection) {
        row = newRow;
        col = newCol;
      }
    }
  }
}
