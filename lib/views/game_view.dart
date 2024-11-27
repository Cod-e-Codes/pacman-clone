// File: lib/views/game_view.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_joystick/flutter_joystick.dart';
import '../models/game_grid.dart';
import '../models/pacman.dart';
import '../models/ghost.dart';
import '../utils/constants.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  GameViewState createState() => GameViewState();
}

class GameViewState extends State<GameView> with TickerProviderStateMixin {
  late GameGrid grid;
  late Pacman pacman;
  late List<Ghost> ghosts; // List of ghosts
  late Timer pacmanTimer;
  late Timer ghostTimer;

  late AnimationController _controller; // Pac-Man's mouth animation
  late Animation<double> _mouthAnimation;

  late AnimationController _pelletController; // Power pellet animation
  late Animation<double> _pelletAnimation;

  late AnimationController _ghostFlashingController; // Ghost flashing
  late Animation<Color?> _ghostFlashingAnimation;

  int score = 0;
  int highScore = 16440; // Example high score
  int lives = 3; // Initial lives
  String? countdownText; // Countdown text
  bool isCountingDown = false; // Countdown flag

  int currentLevel = 1; // Current game level

  // Joystick input
  double joystickX = 0;
  double joystickY = 0;

  // Define wall colors for different levels
  List<Color> wallColors = [
    Colors.green,   // Level 1
    Colors.blue,    // Level 2
    Colors.red,     // Level 3
    Colors.purple,  // Level 4
    Colors.orange,  // Level 5
    // Add more colors if you have more levels
  ];

  @override
  void initState() {
    super.initState();
    grid = GameGrid();
    grid.placeWallsForLevel(currentLevel);

    // Starting position for Pac-Man
    pacman = Pacman(row: 18, col: 7);

    // Initialize ghosts with different types
    ghosts = [
      Ghost(
        row: 10,
        col: 7,
        color: ghostColors[0],
        type: GhostType.blinky,
      ),
      Ghost(
        row: 9,
        col: 7,
        color: ghostColors[1],
        type: GhostType.pinky,
      ),
      Ghost(
        row: 10,
        col: 6,
        color: ghostColors[2],
        type: GhostType.inky,
      ),
      Ghost(
        row: 9,
        col: 6,
        color: ghostColors[3],
        type: GhostType.clyde,
      ),
    ];

    adjustSpeedForLevel();
    startGameLoop();

    // Pac-Man's mouth animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _mouthAnimation =
        Tween<double>(begin: pi / 6, end: pi / 3).animate(_controller);

    // Power pellet animation
    _pelletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pelletAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pelletController, curve: Curves.easeInOut),
    );

    // Ghost flashing animation
    _ghostFlashingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _ghostFlashingAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.white,
    ).animate(_ghostFlashingController);
  }

  void startGameLoop() {
    pacmanTimer = Timer.periodic(pacmanSpeed, (timer) {
      if (!isCountingDown) {
        setState(() {
          pacman.move(pacman.direction, grid);
          checkCollision();
          checkWinCondition();
        });
      }
    });

    ghostTimer = Timer.periodic(ghostSpeed, (timer) {
      if (!isCountingDown) {
        setState(() {
          for (var ghost in ghosts) {
            ghost.move(grid, pacman, ghosts[0], ghosts);
          }
          checkCollision();
          checkWinCondition();
        });
      }
    });
  }

  @override
  void dispose() {
    pacmanTimer.cancel();
    ghostTimer.cancel();
    _controller.dispose();
    _pelletController.dispose();
    _ghostFlashingController.dispose();
    super.dispose();
  }

  void checkCollision() {
    // Pac-Man eats dots
    if (grid.isDot(pacman.row, pacman.col)) {
      grid.consumeDot(pacman.row, pacman.col);
      score += 10;
    }
    // Pac-Man eats power pellets
    else if (grid.isPowerPellet(pacman.row, pacman.col)) {
      grid.consumePowerPellet(pacman.row, pacman.col);
      score += 50;
      activatePowerPelletMode();
    }

    // Check collision with ghosts
    for (var ghost in ghosts) {
      if (pacman.row == ghost.row && pacman.col == ghost.col) {
        if (ghost.isVulnerable) {
          ghostEaten(ghost);
        } else {
          pacmanCaught();
        }
      }
    }
  }

  void checkWinCondition() {
    if (!grid.anyDotsLeft()) {
      pacmanTimer.cancel();
      ghostTimer.cancel();
      currentLevel += 1; // Next level
      showLevelCompleteDialog();
    }
  }

  void activatePowerPelletMode() {
    setState(() {
      for (var ghost in ghosts) {
        ghost.setVulnerable(true);
      }
      _ghostFlashingController.stop();
      _ghostFlashingController.reset();
    });

    // Start ghost flashing after 7 seconds
    Timer(const Duration(seconds: 7), () {
      setState(() {
        for (var ghost in ghosts) {
          if (ghost.isVulnerable) {
            ghost.startFlashing();
          }
        }
      });
      _ghostFlashingController.repeat(reverse: true);
    });

    // End vulnerability after 10 seconds
    Duration vulnerableDuration = const Duration(seconds: 10);
    Timer(vulnerableDuration, () {
      _ghostFlashingController.stop();
      setState(() {
        for (var ghost in ghosts) {
          ghost.stopFlashing();
          ghost.setVulnerable(false);
        }
      });
    });
  }

  void ghostEaten(Ghost ghost) {
    setState(() {
      score += 200;
      ghost.setVulnerable(false);
      // Reset ghost's position
      ghost.row = 10;
      ghost.col = 7;
    });
  }

  void pacmanCaught() {
    pacmanTimer.cancel();
    ghostTimer.cancel();
    if (lives > 0) {
      setState(() {
        lives -= 1;
        startCountdown();
      });
    } else {
      showLosingDialog();
    }
  }

  void resetGame() {
    // Reset game state
    setState(() {
      lives = 3;
      score = 0;
      currentLevel = 1;
      grid = GameGrid();
      grid.placeWallsForLevel(currentLevel);
      resetPositions();
      adjustSpeedForLevel();
      startGameLoop();
    });
  }

  void startCountdown() {
    // Countdown sequence
    List<String> countdownSequence = ['3', '2', '1', 'Start'];

    int countdownIndex = 0;

    setState(() {
      isCountingDown = true;
      countdownText = countdownSequence[countdownIndex];
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      countdownIndex++;

      if (countdownIndex < countdownSequence.length) {
        setState(() {
          countdownText = countdownSequence[countdownIndex];
        });
      } else {
        timer.cancel();
        resetPositions();
        setState(() {
          isCountingDown = false;
          countdownText = null;
        });
        adjustSpeedForLevel();
        startGameLoop();
      }
    });
  }

  void resetPositions() {
    // Reset positions
    pacman = Pacman(row: 18, col: 7);

    ghosts = [
      Ghost(
        row: 10,
        col: 7,
        color: ghostColors[0],
        type: GhostType.blinky,
      ),
      Ghost(
        row: 9,
        col: 7,
        color: ghostColors[1],
        type: GhostType.pinky,
      ),
      Ghost(
        row: 10,
        col: 6,
        color: ghostColors[2],
        type: GhostType.inky,
      ),
      Ghost(
        row: 9,
        col: 6,
        color: ghostColors[3],
        type: GhostType.clyde,
      ),
    ];
  }

  void _updatePacmanDirection() {
    double angle = atan2(-joystickY, joystickX);

    if (joystickX == 0 && joystickY == 0) {
      return;
    } else if (angle >= -pi / 4 && angle <= pi / 4) {
      pacman.direction = 'right';
    } else if (angle >= pi / 4 && angle <= 3 * pi / 4) {
      pacman.direction = 'up';
    } else if (angle <= -pi / 4 && angle >= -3 * pi / 4) {
      pacman.direction = 'down';
    } else {
      pacman.direction = 'left';
    }
  }

  void adjustSpeedForLevel() {
    // Adjust ghost speeds
    if (currentLevel == 1) {
      ghostSpeed = const Duration(milliseconds: 400);
    } else if (currentLevel == 2) {
      ghostSpeed = const Duration(milliseconds: 350);
    } else if (currentLevel == 3) {
      ghostSpeed = const Duration(milliseconds: 300);
    } else if (currentLevel == 4) {
      ghostSpeed = const Duration(milliseconds: 250);
    } else if (currentLevel >= 5) {
      ghostSpeed = const Duration(milliseconds: 200);
    }
  }

  void startNewLevel() {
    adjustSpeedForLevel();
    grid = GameGrid();
    grid.placeWallsForLevel(currentLevel);
    resetPositions();
    startGameLoop();
  }

  // Method to get the wall color for the current level
  Color getWallColorForLevel(int level) {
    int index = (level - 1) % wallColors.length;
    return wallColors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Game Grid
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(gridRows, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gridColumns, (col) {
                      // Pac-Man
                      if (pacman.row == row && pacman.col == col) {
                        return _buildPacmanCell();
                      }
                      // Ghosts
                      List<Ghost> ghostsAtPosition = ghosts
                          .where((g) => g.row == row && g.col == col)
                          .toList();
                      if (ghostsAtPosition.isNotEmpty) {
                        return _buildGhostsCell(ghostsAtPosition);
                      }
                      // Walls, dots, power pellets
                      if (grid.isWall(row, col)) {
                        return _buildCell(getWallColorForLevel(currentLevel));
                      } else if (grid.isDot(row, col)) {
                        return _buildDotCell();
                      } else if (grid.isPowerPellet(row, col)) {
                        return _buildAnimatedPowerPelletCell();
                      } else {
                        return _buildCell(Colors.black);
                      }
                    }),
                  );
                }),
              ),
            ),

            // Score, Level, Lives
            Positioned(
              top: 20,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1UP',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        score.toString(),
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'LEVEL',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        currentLevel.toString(),
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Lives
                  Row(
                    children: List.generate(lives, (index) {
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 5.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter: PacmanPainter(
                                'right', _mouthAnimation.value),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Countdown Overlay
            if (isCountingDown)
              Center(
                child: Text(
                  countdownText ?? '',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 40,
                    color: Colors.white,
                  ),
                ),
              ),

            // Virtual Joystick
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Joystick(
                  mode: JoystickMode.all,
                  listener: (details) {
                    setState(() {
                      joystickX = details.x;
                      joystickY = details.y;
                      _updatePacmanDirection();
                    });
                  },
                  stick: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                  ),
                  base: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Pac-Man cell
  Widget _buildPacmanCell() {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter:
            PacmanPainter(pacman.direction, _mouthAnimation.value),
          );
        },
      ),
    );
  }

  // Build cell with multiple ghosts
  Widget _buildGhostsCell(List<Ghost> ghostsAtPosition) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: ghostsAtPosition.map((ghost) {
          return Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: _buildGhostIcon(ghost),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build ghost icon
  Widget _buildGhostIcon(Ghost ghost) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _ghostFlashingController,
        builder: (context, child) {
          return Center(
            child: FaIcon(
              FontAwesomeIcons.ghost,
              color: ghost.isVulnerable
                  ? (ghost.isFlashing
                  ? _ghostFlashingAnimation.value
                  : Colors.blue)
                  : ghost.color,
              size: cellSize,
            ),
          );
        },
      ),
    );
  }

  // Build dot cell
  Widget _buildDotCell() {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Center(
        child: Container(
          width: cellSize / 3,
          height: cellSize / 3,
          decoration: const BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // Build animated power pellet cell
  Widget _buildAnimatedPowerPelletCell() {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _pelletController,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _pelletAnimation.value,
              child: Container(
                width: cellSize * 0.75,
                height: cellSize * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build grid cell
  Widget _buildCell(Color color, {bool isPacman = false}) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: color,
        shape: isPacman ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(color: Colors.black, width: 1),
      ),
    );
  }

  // Show level complete dialog
  void showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            "Level ${currentLevel - 1} Complete!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 24,
              color: Colors.yellow,
            ),
          ),
          content: const Text(
            "Get ready for the next level.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text(
                  "NEXT LEVEL",
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  startNewLevel();
                },
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.yellow, width: 3),
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  // Show losing dialog
  void showLosingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "GAME OVER",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 24,
              color: Colors.redAccent,
            ),
          ),
          content: const Text(
            "You lost all your lives.\nTry again!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text(
                  "RESTART",
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  resetGame();
                },
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.redAccent, width: 3),
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
}

// Custom painter for Pac-Man
class PacmanPainter extends CustomPainter {
  final String direction;
  final double mouthAngle;
  PacmanPainter(this.direction, this.mouthAngle);

  @override
  void paint(Canvas canvas, Size size) {
    double rotationAngle = 0;

    // Set rotation based on direction
    switch (direction) {
      case 'right':
        rotationAngle = 0;
        break;
      case 'up':
        rotationAngle = -pi / 2;
        break;
      case 'left':
        rotationAngle = pi;
        break;
      case 'down':
        rotationAngle = pi / 2;
        break;
    }

    Paint paint = Paint()..color = Colors.yellow;

    // Draw Pac-Man
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationAngle);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: size.width / 2),
      mouthAngle,
      2 * pi - 2 * mouthAngle,
      true,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
