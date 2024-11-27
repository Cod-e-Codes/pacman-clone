// File: lib/main.dart

import 'package:flutter/material.dart';
import 'views/game_view.dart';

void main() {
  runApp(const PacmanApp());
}

class PacmanApp extends StatelessWidget {
  const PacmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pacman Flutter',
      theme: ThemeData.dark(),
      home: const GameView(),
    );
  }
}
