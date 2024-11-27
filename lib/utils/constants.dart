// File: lib/utils/constants.dart

import 'package:flutter/material.dart';

const int gridRows = 20;
const int gridColumns = 15;
const double cellSize = 20.0;

const Color pacmanColor = Colors.yellow;

// Define colors for each ghost
const List<Color> ghostColors = [
  Colors.red,    // Blinky
  Colors.pink,   // Pinky
  Colors.cyan,   // Inky
  Colors.orange, // Clyde
];

const Color dotColor = Colors.white;

const Duration pacmanSpeed = Duration(milliseconds: 200);

// Ghost speed will be adjusted per level
Duration ghostSpeed = const Duration(milliseconds: 300);
