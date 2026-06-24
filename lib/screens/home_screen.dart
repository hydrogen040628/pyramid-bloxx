import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _titleAnim;
  late Animation<double> _pyramidAnim;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _titleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pyramidAnim = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E05),
              Color(0xFF2D1B0E),
              Color(0xFF4A2C0A),
              Color(0xFF6B3E0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stars decoration
                const _StarsDecoration(),
                const SizedBox(height: 20),

                // Pyramid illustration
                AnimatedBuilder(
                  animation: _pyramidAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_pyramidAnim.value),
                      child: const _PyramidIllustration(),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Title
                AnimatedBuilder(
                  animation: _titleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _titleAnim.value,
                      child: const _TitleText(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // High score
                if (_highScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4A017)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Color(0xFFD4A017), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'BEST: $_highScore',
                          style: const TextStyle(
                            color: Color(0xFFD4A017),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 50),

                // Play button
                _PlayButton(onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GameScreen()),
                  );
                  _loadHighScore();
                }),

                const SizedBox(height: 30),

                // How to play
                const Text(
                  'TAP TO STACK • PERFECT TIMING = BONUS',
                  style: TextStyle(
                    color: Color(0xFF8B6914),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarsDecoration extends StatelessWidget {
  const _StarsDecoration();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.star,
            color: const Color(0xFFD4A017).withOpacity(0.3 + i * 0.1),
            size: 16 + i * 2.0,
          ),
        ),
      ),
    );
  }
}

class _PyramidIllustration extends StatelessWidget {
  const _PyramidIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: CustomPaint(
        painter: _PyramidPainter(),
      ),
    );
  }
}

class _PyramidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final layers = [
      // (relativeWidth, color)
      (1.0, const Color(0xFFD4A017)),
      (0.82, const Color(0xFFE8C547)),
      (0.64, const Color(0xFFD4A017)),
      (0.46, const Color(0xFFE8C547)),
      (0.28, const Color(0xFFD4A017)),
      (0.12, const Color(0xFFFFD700)),
    ];

    const blockHeight = 20.0;
    const gap = 2.0;

    for (int i = 0; i < layers.length; i++) {
      final (relW, color) = layers[i];
      final blockW = size.width * relW;
      final left = (size.width - blockW) / 2;
      final top = size.height - (i + 1) * (blockHeight + gap);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, blockW, blockHeight),
        const Radius.circular(4),
      );

      final paint = Paint()..color = color;
      canvas.drawRRect(rect, paint);

      // Shine effect
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      final shineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, blockW, blockHeight / 2.5),
        const Radius.circular(4),
      );
      canvas.drawRRect(shineRect, shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TitleText extends StatelessWidget {
  const _TitleText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PYRAMID',
          style: TextStyle(
            color: const Color(0xFFD4A017),
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: const Color(0xFFD4A017).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Text(
          'BLOXX',
          style: TextStyle(
            color: const Color(0xFFE8C547),
            fontSize: 56,
            fontWeight: FontWeight.w900,
            letterSpacing: 12,
            shadows: [
              Shadow(
                color: const Color(0xFFE8C547).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 200,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A017), Color(0xFFE8C547)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A017).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'PLAY',
                style: TextStyle(
                  color: Color(0xFF1A0E05),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
