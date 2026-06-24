import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameModel _game = GameModel();
  Timer? _gameLoop;
  DateTime _lastUpdate = DateTime.now();

  String? _feedbackText;
  double _feedbackOpacity = 0.0;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _game.startGame();
    _startGameLoop();
  }

  void _startGameLoop() {
    _gameLoop?.cancel();
    _lastUpdate = DateTime.now();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
      _lastUpdate = now;
      if (!mounted) return;
      setState(() => _game.update(dt.clamp(0.0, 0.1)));
      if (_game.isGameOver) {
        _gameLoop?.cancel();
        _saveHighScore();
        _showGameOver();
      }
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('highScore') ?? 0;
    if (_game.score > saved) await prefs.setInt('highScore', _game.score);
  }

  void _onTap() {
    if (_game.state != GameState.playing) return;
    HapticFeedback.lightImpact();
    final result = _game.drop();
    _showFeedback(result);
    setState(() {});
  }

  void _showFeedback(String result) {
    _feedbackTimer?.cancel();
    String text;
    switch (result) {
      case 'perfect':
        text = '✨ PERFECT! +${10 + _game.combo * 2}';
        HapticFeedback.heavyImpact();
      case 'good':
        text = '👍 GOOD! +5';
      default:
        text = '💥 MISS!';
    }
    setState(() {
      _feedbackText = text;
      _feedbackOpacity = 1.0;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _feedbackOpacity = 0.0);
    });
  }

  void _showGameOver() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _GameOverDialog(
          score: _game.score,
          highScore: _game.highScore,
          blocks: _game.blocksPlaced,
          onRestart: () {
            Navigator.pop(ctx);
            setState(() => _game.startGame());
            _startGameLoop();
          },
          onHome: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0E05),
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(builder: (ctx, constraints) {
                      return CustomPaint(
                        painter: GamePainter(game: _game),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      );
                    }),
                    _buildFeedback(),
                    if (_game.blocksPlaced <= 2) _buildTapHint(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios,
                  color: Color(0xFFD4A017), size: 20),
            ),
          ),
          Column(children: [
            Text('${_game.score}',
                style: const TextStyle(
                    color: Color(0xFFE8C547),
                    fontSize: 36,
                    fontWeight: FontWeight.w900)),
            Text('LEVEL ${_game.level}',
                style: const TextStyle(
                    color: Color(0xFF8B6914), fontSize: 12, letterSpacing: 2)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('BEST',
                style: TextStyle(
                    color: Color(0xFF8B6914), fontSize: 11, letterSpacing: 1)),
            Text('${_game.highScore}',
                style: const TextStyle(
                    color: Color(0xFFD4A017),
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return AnimatedOpacity(
      opacity: _feedbackOpacity,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Text(
          _feedbackText ?? '',
          style: TextStyle(
            color: _feedbackText?.contains('PERFECT') == true
                ? const Color(0xFFFFD700)
                : _feedbackText?.contains('MISS') == true
                    ? const Color(0xFFFF4444)
                    : const Color(0xFF90EE90),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text('TAP TO DROP',
            style: TextStyle(
                color: const Color(0xFFD4A017).withOpacity(0.6),
                fontSize: 14,
                letterSpacing: 3)),
      ),
    );
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────────

class GamePainter extends CustomPainter {
  final GameModel game;
  static const double blockHeight = 36.0;
  static const double blockGap = 3.0;
  static const double blockRadius = 6.0;

  const GamePainter({required this.game});

  double _blockY(int row, Size size) {
    return size.height - 30 - blockHeight - row * (blockHeight + blockGap);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawStars(canvas, size);
    _drawSand(canvas, size);
    _drawPlacedBlocks(canvas, size);
    _drawMovingBlock(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    final positions = [
      Offset(size.width * 0.08, size.height * 0.04),
      Offset(size.width * 0.82, size.height * 0.03),
      Offset(size.width * 0.3, size.height * 0.09),
      Offset(size.width * 0.6, size.height * 0.13),
      Offset(size.width * 0.91, size.height * 0.06),
      Offset(size.width * 0.15, size.height * 0.16),
      Offset(size.width * 0.5, size.height * 0.02),
      Offset(size.width * 0.72, size.height * 0.19),
      Offset(size.width * 0.45, size.height * 0.07),
      Offset(size.width * 0.25, size.height * 0.01),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, 1.5, paint);
    }
  }

  void _drawSand(Canvas canvas, Size size) {
    final sandPaint = Paint()..color = const Color(0xFF6B3E0F);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 30, size.width, 30), sandPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF8B5E1A).withOpacity(0.5)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height - 25 + i * 6.0),
        Offset(size.width, size.height - 25 + i * 6.0),
        linePaint,
      );
    }
  }

  void _drawPlacedBlocks(Canvas canvas, Size size) {
    for (int i = 0; i < game.placedBlocks.length; i++) {
      _drawBlock(canvas, size, game.placedBlocks[i], _blockY(i, size), placed: true);
    }
  }

  void _drawMovingBlock(Canvas canvas, Size size) {
    final moving = game.movingBlock;
    if (moving == null) return;

    // Ghost guide
    if (game.placedBlocks.isNotEmpty) {
      final top = game.placedBlocks.last;
      final targetY = _blockY(top.y.toInt() + 1, size);
      final ghostPaint = Paint()
        ..color = moving.color.withOpacity(0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(moving.x * size.width, targetY,
              moving.width * size.width, blockHeight),
          const Radius.circular(blockRadius),
        ),
        ghostPaint,
      );
    }

    _drawBlock(canvas, size, moving, _blockY(moving.y.toInt(), size), placed: false);
  }

  void _drawBlock(Canvas canvas, Size size, Block block, double y,
      {required bool placed}) {
    final left = block.x * size.width;
    final width = block.width * size.width;
    final color = block.color;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 2, y + 4, width, blockHeight),
        const Radius.circular(blockRadius),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Block body
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, y, width, blockHeight),
      const Radius.circular(blockRadius),
    );
    canvas.drawRRect(rect, Paint()..color = color);

    // Shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 2, y + 2, width - 4, blockHeight * 0.35),
        const Radius.circular(blockRadius - 2),
      ),
      Paint()..color = Colors.white.withOpacity(placed ? 0.15 : 0.25),
    );

    // Perfect glow
    if (block.isPerfect) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Moving block border
    if (!placed) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}

// ─── Game Over Dialog ──────────────────────────────────────────────────────────

class _GameOverDialog extends StatelessWidget {
  final int score, highScore, blocks;
  final VoidCallback onRestart, onHome;

  const _GameOverDialog({
    required this.score,
    required this.highScore,
    required this.blocks,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= highScore && score > 0;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B0E), Color(0xFF1A0E05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4A017), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A017).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNewBest ? '🏆 NEW BEST!' : 'GAME OVER',
              style: TextStyle(
                color: isNewBest ? const Color(0xFFFFD700) : const Color(0xFFD4A017),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 24),
            _row('SCORE', '$score'),
            const SizedBox(height: 8),
            _row('BLOCKS', '$blocks'),
            const SizedBox(height: 8),
            _row('BEST', '$highScore'),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: _btn('HOME', Icons.home, true, onHome)),
              const SizedBox(width: 12),
              Expanded(child: _btn('RETRY', Icons.replay, false, onRestart)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8B6914), fontSize: 14, letterSpacing: 2)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFE8C547),
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _btn(String label, IconData icon, bool outlined, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: outlined
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFD4A017), Color(0xFFE8C547)]),
            border: outlined
                ? Border.all(color: const Color(0xFFD4A017))
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: outlined
                      ? const Color(0xFFD4A017)
                      : const Color(0xFF1A0E05),
                  size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: outlined
                          ? const Color(0xFFD4A017)
                          : const Color(0xFF1A0E05),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),
      );
}
