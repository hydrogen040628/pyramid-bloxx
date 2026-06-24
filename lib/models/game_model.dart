import 'dart:math';
import 'package:flutter/material.dart' show Color, Colors;

enum GameState { idle, playing, dropping, gameOver }

class Block {
  final double x;
  final double width;
  final int row; // row index in tower (0 = base)
  final Color color;
  final bool isPerfect;

  const Block({
    required this.x,
    required this.width,
    required this.row,
    required this.color,
    this.isPerfect = false,
  });

  double get right => x + width;
  double get center => x + width / 2;

  Block copyWith({
    double? x,
    double? width,
    int? row,
    Color? color,
    bool? isPerfect,
  }) {
    return Block(
      x: x ?? this.x,
      width: width ?? this.width,
      row: row ?? this.row,
      color: color ?? this.color,
      isPerfect: isPerfect ?? this.isPerfect,
    );
  }
}

class GameModel {
  static const double perfectThreshold = 0.03;
  static const double minBlockWidth = 0.12;
  static const double initialBlockWidth = 0.55;
  static const double swingSpeed = 1.8;

  List<Block> placedBlocks = [];
  Block? movingBlock;
  GameState state = GameState.idle;
  int score = 0;
  int combo = 0;
  int highScore = 0;
  double swingT = 0.0;
  int level = 1;
  String? lastDropResult;
  double lastOverhang = 0.0;

  static const List<Color> blockColors = [
    Color(0xFFD4A017),
    Color(0xFFE8C547),
    Color(0xFFC4891A),
    Color(0xFFB8860B),
    Color(0xFFDAA520),
    Color(0xFFFF8C00),
    Color(0xFFCD853F),
    Color(0xFFD2691E),
  ];

  Color get currentColor =>
      blockColors[(placedBlocks.length) % blockColors.length];

  double get currentSwingSpeed =>
      (swingSpeed - (level - 1) * 0.08).clamp(0.6, swingSpeed);

  void startGame() {
    placedBlocks = [];
    score = 0;
    combo = 0;
    level = 1;
    state = GameState.playing;
    swingT = 0.0;
    lastDropResult = null;

    placedBlocks.add(Block(
      x: 0.225,
      width: initialBlockWidth,
      row: 0,
      color: blockColors[0],
    ));

    _spawnMovingBlock();
  }

  void _spawnMovingBlock() {
    if (placedBlocks.isEmpty) return;
    final topBlock = placedBlocks.last;
    final newWidth = (topBlock.width - 0.02).clamp(minBlockWidth, 1.0);

    movingBlock = Block(
      x: 0.0,
      width: newWidth,
      row: topBlock.row + 1,
      color: currentColor,
    );
    swingT = 0.0;
    state = GameState.playing;
    lastDropResult = null;
  }

  void update(double dt) {
    if (state != GameState.playing || movingBlock == null) return;

    swingT += dt / currentSwingSpeed;
    if (swingT >= 1.0) swingT -= 1.0;

    final topBlock = placedBlocks.last;
    final maxX = (1.0 - movingBlock!.width).clamp(0.0, 1.0);
    final swingLeft = max(0.0, topBlock.x - 0.15);
    final swingRight = min(maxX, topBlock.right - movingBlock!.width + 0.15);
    final range = (swingRight - swingLeft).abs();

    final sinVal = sin(swingT * 2 * pi);
    final newX = (swingLeft + (range / 2) + (range / 2) * sinVal)
        .clamp(0.0, maxX);

    movingBlock = movingBlock!.copyWith(x: newX);
  }

  String drop() {
    if (state != GameState.playing || movingBlock == null) return "miss";

    state = GameState.dropping;
    final top = placedBlocks.last;
    final current = movingBlock!;

    final overlapLeft = max(current.x, top.x);
    final overlapRight = min(current.right, top.right);
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 0) {
      state = GameState.gameOver;
      lastDropResult = "miss";
      combo = 0;
      movingBlock = null;
      if (score > highScore) highScore = score;
      return "miss";
    }

    final centerDiff = (current.center - top.center).abs();
    final isPerfect = centerDiff <= perfectThreshold;

    if (isPerfect) {
      combo++;
      score += 10 + (combo * 2);
      lastDropResult = "perfect";
      lastOverhang = 0;

      placedBlocks.add(Block(
        x: top.x + (top.width - current.width) / 2,
        width: current.width,
        row: current.row,
        color: current.color,
        isPerfect: true,
      ));
    } else {
      combo = 0;
      final trimmedWidth = overlap;
      lastOverhang = current.width - trimmedWidth;
      score += 5;

      if (trimmedWidth < minBlockWidth) {
        state = GameState.gameOver;
        lastDropResult = "miss";
        movingBlock = null;
        if (score > highScore) highScore = score;
        return "miss";
      }

      lastDropResult = "good";
      placedBlocks.add(Block(
        x: overlapLeft,
        width: trimmedWidth,
        row: current.row,
        color: current.color,
      ));
    }

    movingBlock = null;
    level = (placedBlocks.length ~/ 5) + 1;
    if (score > highScore) highScore = score;
    _spawnMovingBlock();
    return lastDropResult!;
  }

  bool get isGameOver => state == GameState.gameOver;
  int get blocksPlaced => placedBlocks.length - 1;
  int get towerHeight => placedBlocks.length;
}
