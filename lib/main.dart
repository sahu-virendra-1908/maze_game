import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minecraft Maze Quest',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: MazeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum CellType { wall, path, game, player }

class Position {
  final int x, y;
  Position(this.x, this.y);
}

class MazeCell {
  CellType type;
  bool isGameNode;
  bool isDiscovered;
  bool hasPlayer;

  MazeCell({
    required this.type,
    this.isGameNode = false,
    this.isDiscovered = false,
    this.hasPlayer = false,
  });

  MazeCell copyWith({
    CellType? type,
    bool? isGameNode,
    bool? isDiscovered,
    bool? hasPlayer,
  }) {
    return MazeCell(
      type: type ?? this.type,
      isGameNode: isGameNode ?? this.isGameNode,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      hasPlayer: hasPlayer ?? this.hasPlayer,
    );
  }
}

class GameDiscovery {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  GameDiscovery({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class MazeGame extends StatefulWidget {
  @override
  _MazeGameState createState() => _MazeGameState();
}

class _MazeGameState extends State<MazeGame>
    with TickerProviderStateMixin {
  static const int GRID_SIZE = 15;

  Position playerPosition = Position(1, 1);
  List<List<MazeCell>> maze = [];
  int discoveredGames = 0;
  int totalGames = 0;
  bool showGameModal = false;
  Position? currentGameNode;

  late AnimationController _backgroundController;
  late AnimationController _modalController;
  
  // For responsive movement
  bool _isMoving = false;

  final List<GameDiscovery> gameDiscoveries = [
    GameDiscovery(
      icon: Icons.videogame_asset,
      title: "Secret Challenge Discovered!",
      description: "You've found a hidden arcade game! Test your skills and see if you can beat the high score.",
      color: Colors.purple.shade400,
    ),
    GameDiscovery(
      icon: Icons.casino,
      title: "Mystery Game Found!",
      description: "A dice-based puzzle awaits! Roll your way to victory in this game of chance and strategy.",
      color: Colors.blue.shade400,
    ),
    GameDiscovery(
      icon: Icons.flash_on,
      title: "Explosive Game Located!",
      description: "BOOM! You've triggered an explosive mini-game! Can you defuse the situation and claim victory?",
      color: Colors.red.shade400,
    ),
  ];

  final List<Color> wallColors = [
    Colors.grey.shade700, // Stone
    Colors.grey.shade800, // Cobblestone  
    Colors.grey.shade600, // Andesite
    Colors.grey.shade500, // Stone variant
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _modalController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeMaze();
    
    // Enable keyboard input
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _modalController.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && !showGameModal && !_isMoving) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          _movePlayer('up');
          break;
        case LogicalKeyboardKey.arrowDown:
          _movePlayer('down');
          break;
        case LogicalKeyboardKey.arrowLeft:
          _movePlayer('left');
          break;
        case LogicalKeyboardKey.arrowRight:
          _movePlayer('right');
          break;
      }
    }
  }

  void _initializeMaze() {
    // Initialize grid with walls
    maze = List.generate(GRID_SIZE, (i) =>
        List.generate(GRID_SIZE, (j) =>
            MazeCell(type: CellType.wall)));

    // Create paths using simple maze generation
    for (int i = 1; i < GRID_SIZE - 1; i += 2) {
      for (int j = 1; j < GRID_SIZE - 1; j += 2) {
        maze[i][j].type = CellType.path;
      }
    }

    // Add horizontal connections
    for (int i = 1; i < GRID_SIZE - 1; i += 2) {
      for (int j = 2; j < GRID_SIZE - 1; j += 2) {
        if (Random().nextDouble() > 0.3) {
          maze[i][j].type = CellType.path;
        }
      }
    }

    // Add vertical connections  
    for (int i = 2; i < GRID_SIZE - 1; i += 2) {
      for (int j = 1; j < GRID_SIZE - 1; j += 2) {
        if (Random().nextDouble() > 0.3) {
          maze[i][j].type = CellType.path;
        }
      }
    }

    // Place game nodes randomly on path cells
    List<Position> pathCells = [];
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (maze[i][j].type == CellType.path && !(i == 1 && j == 1)) {
          pathCells.add(Position(j, i));
        }
      }
    }

    // Randomly select 12 cells for game nodes
    int gameNodeCount = min(12, pathCells.length);
    pathCells.shuffle();

    for (int i = 0; i < gameNodeCount; i++) {
      Position pos = pathCells[i];
      maze[pos.y][pos.x].isGameNode = true;
    }

    // Set player starting position
    maze[1][1].hasPlayer = true;
    maze[1][1].type = CellType.path;

    totalGames = maze.expand((row) => row).where((cell) => cell.isGameNode).length;
  }

  void _movePlayer(String direction) async {
    if (_isMoving) return; // Prevent multiple rapid movements
    
    setState(() {
      _isMoving = true;
    });

    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();

    int newX = playerPosition.x;
    int newY = playerPosition.y;

    switch (direction) {
      case 'up':
        newY = max(0, playerPosition.y - 1);
        break;
      case 'down':
        newY = min(GRID_SIZE - 1, playerPosition.y + 1);
        break;
      case 'left':
        newX = max(0, playerPosition.x - 1);
        break;
      case 'right':
        newX = min(GRID_SIZE - 1, playerPosition.x + 1);
        break;
    }

    // Check if the new position is valid (not a wall)
    if (maze[newY][newX].type != CellType.wall) {
      setState(() {
        // Remove player from old position
        maze[playerPosition.y][playerPosition.x].hasPlayer = false;
        
        // Add player to new position
        maze[newY][newX].hasPlayer = true;
        playerPosition = Position(newX, newY);

        // Check if discovered a game node
        if (maze[newY][newX].isGameNode && !maze[newY][newX].isDiscovered) {
          maze[newY][newX].isDiscovered = true;
          discoveredGames++;
          showGameModal = true;
          currentGameNode = Position(newX, newY);
          _modalController.forward();
          
          // Strong haptic feedback for discovery
          HapticFeedback.mediumImpact();
        }
      });
    }

    // Small delay to prevent too rapid movement but keep it responsive
    await Future.delayed(Duration(milliseconds: 150));
    
    setState(() {
      _isMoving = false;
    });
  }

  void _closeGameModal() {
    _modalController.reverse().then((_) {
      setState(() {
        showGameModal = false;
        currentGameNode = null;
      });
    });
  }

  Widget _buildMazeCell(MazeCell cell, int x, int y) {
    Color cellColor;
    Widget? cellContent;

    if (cell.type == CellType.wall) {
      int colorIndex = (x + y) % wallColors.length;
      cellColor = wallColors[colorIndex];
    } else {
      cellColor = Colors.green.shade600;
    }

    if (cell.hasPlayer) {
      cellColor = Colors.blue.shade500;
      cellContent = Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade300,
          border: Border.all(color: Colors.orange.shade400),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            Positioned(top: 2, left: 2, child: Container(width: 2, height: 2, color: Colors.black)),
            Positioned(top: 2, right: 2, child: Container(width: 2, height: 2, color: Colors.black)),
            Positioned(
              bottom: 2, 
              left: 0, 
              right: 0,
              child: Center(child: Container(width: 8, height: 2, color: Colors.pink.shade400))
            ),
          ],
        ),
      );
    } else if (cell.isGameNode) {
      if (cell.isDiscovered) {
        cellColor = Colors.cyan.shade400;
        cellContent = AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.orange.shade500, Colors.yellow.shade400],
                  transform: GradientRotation(_backgroundController.value * 2 * pi),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                Icons.flash_on,
                size: 12,
                color: Colors.red.shade800,
              ),
            );
          },
        );
      } else {
        cellContent = AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.6 + 0.4 * sin(_backgroundController.value * 2 * pi),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade600,
                  border: Border.all(color: Colors.yellow.shade700),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          },
        );
      }
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(color: Colors.black26, width: 0.5),
        borderRadius: BorderRadius.circular(1),
        boxShadow: cell.type == CellType.wall ? [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(1, 1))
        ] : null,
      ),
      child: cellContent != null
          ? Center(child: cellContent)
          : (cell.type == CellType.path && !cell.hasPlayer && !cell.isGameNode
              ? Stack(
                  children: [
                    Positioned(top: 1, left: 1, child: Container(width: 2, height: 2, decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(1)))),
                    Positioned(top: 2, right: 2, child: Container(width: 2, height: 2, decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: BorderRadius.circular(1)))),
                    Positioned(bottom: 2, left: 2, child: Container(width: 2, height: 2, decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(1)))),
                    Positioned(bottom: 1, right: 1, child: Container(width: 2, height: 2, decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: BorderRadius.circular(1)))),
                  ],
                )
              : null),
    );
  }

  Widget _buildGameModal() {
    if (!showGameModal) return SizedBox.shrink();

    GameDiscovery discovery = gameDiscoveries[Random().nextInt(gameDiscoveries.length)];

    return AnimatedBuilder(
      animation: _modalController,
      builder: (context, child) {
        return Transform.scale(
          scale: _modalController.value,
          child: Opacity(
            opacity: _modalController.value,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(16),
                  constraints: BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade50, Colors.amber.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade800, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with icon
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.cyan.shade700, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.cyan.shade300, blurRadius: 8, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Icon(
                            discovery.icon,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Title
                        Text(
                          discovery.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Description
                        Text(
                          discovery.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.amber.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _closeGameModal,
                                icon: Icon(Icons.videogame_asset),
                                label: Text("Play Game", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade500,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 8,
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 12),
                            
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _closeGameModal,
                                icon: Icon(Icons.arrow_forward),
                                label: Text("Continue Mining", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade600, width: 2),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade900, Colors.grey.shade800],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Animated background elements
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 40 + 20 * sin(_backgroundController.value * 2 * pi),
                    left: 40,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80 + 15 * sin(_backgroundController.value * 2 * pi + 1),
                    right: 80,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Minecraft Maze Quest",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Score display
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.yellow.shade200, Colors.amber.shade100, Colors.green.shade200],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade600, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.cyan.shade400, Colors.cyan.shade600]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.cyan.shade700, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green.shade300,
                              border: Border.all(color: Colors.green.shade600),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "$discoveredGames",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan.shade700,
                        ),
                      ),
                      Text(
                        " / ",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade700, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              border: Border.all(color: Colors.green.shade500),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "$totalGames",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: min(MediaQuery.of(context).size.width * 0.95,
                                   MediaQuery.of(context).size.height * 0.6),
                        maxHeight: min(MediaQuery.of(context).size.width * 0.95,
                                    MediaQuery.of(context).size.height * 0.6),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: GRID_SIZE,
                              mainAxisSpacing: 1,
                              crossAxisSpacing: 1,
                            ),
                            itemCount: GRID_SIZE * GRID_SIZE,
                            itemBuilder: (context, index) {
                              int x = index % GRID_SIZE;
                              int y = index ~/ GRID_SIZE;
                              return _buildMazeCell(maze[y][x], x, y);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Control buttons
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Up button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(Icons.keyboard_arrow_up, () => _movePlayer('up')),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Left, Down, Right buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(Icons.keyboard_arrow_left, () => _movePlayer('left')),
                          _buildControlButton(Icons.keyboard_arrow_down, () => _movePlayer('down')),
                          _buildControlButton(Icons.keyboard_arrow_right, () => _movePlayer('right')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Instructions
                Container(
                  margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade600.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Use the stone buttons or keyboard arrow keys to move.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Find all the hidden diamond blocks in the world!",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Game modal
          if (showGameModal) _buildGameModal(),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: showGameModal || _isMoving ? null : onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: showGameModal || _isMoving
                ? [Colors.grey.shade500, Colors.grey.shade600]
                : [Colors.grey.shade600, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: showGameModal || _isMoving 
                ? Colors.grey.shade400 
                : Colors.grey.shade900,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}