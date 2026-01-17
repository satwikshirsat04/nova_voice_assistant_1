import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveformVisualizer extends StatefulWidget {
  final Stream<double> audioLevelStream;
  final Color color;
  final double height;
  final int barCount;

  const WaveformVisualizer({
    super.key,
    required this.audioLevelStream,
    this.color = const Color(0xFF2E5BFF),
    this.height = 80,
    this.barCount = 40,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [];
  double _currentLevel = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize bar heights
    _barHeights.addAll(List.filled(widget.barCount, 0.0));
    
    // Animation controller for smooth transitions
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();

    // Listen to audio level stream
    widget.audioLevelStream.listen((level) {
      if (mounted) {
        setState(() {
          _currentLevel = level;
          _updateBarHeights(level);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateBarHeights(double level) {
    // Shift bars to the left
    for (int i = 0; i < _barHeights.length - 1; i++) {
      _barHeights[i] = _barHeights[i + 1];
    }
    
    // Add new random height based on audio level
    final random = math.Random();
    final newHeight = level * (0.8 + random.nextDouble() * 0.4);
    _barHeights[_barHeights.length - 1] = newHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveformPainter(
              barHeights: _barHeights,
              color: widget.color,
              animationValue: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> barHeights;
  final Color color;
  final double animationValue;

  _WaveformPainter({
    required this.barHeights,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barHeights.length;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barHeights.length; i++) {
      final barHeight = barHeights[i] * size.height;
      final x = i * barWidth;
      final centerY = size.height / 2;

      // Create gradient for each bar
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.8),
          color,
          color.withOpacity(0.8),
        ],
      );

      paint.shader = gradient.createShader(
        Rect.fromLTWH(x, centerY - barHeight / 2, barWidth - 2, barHeight),
      );

      // Draw the bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          centerY - barHeight / 2,
          barWidth - 2,
          math.max(barHeight, 2),
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return true;
  }
}

class AnimatedWaveform extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final bool isAnimating;
  final double animationValue;

  const AnimatedWaveform({
    super.key,
    required this.height,
    required this.width,
    required this.color,
    this.isAnimating = true,
    this.animationValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _AnimatedWavePainter(
          color: color,
          animationValue: animationValue,
          isAnimating: isAnimating,
        ),
      ),
    );
  }
}

class _AnimatedWavePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final bool isAnimating;

  _AnimatedWavePainter({
    required this.color,
    required this.animationValue,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final path = Path();

    // Draw multiple sine waves with different phases
    for (int wave = 0; wave < 3; wave++) {
      path.reset();
      
      final amplitude = size.height * (0.15 + wave * 0.05);
      final frequency = 2.0 + wave * 0.5;
      final phase = animationValue * 2 * math.pi + wave * math.pi / 3;
      
      for (double x = 0; x <= size.width; x++) {
        final y = centerY + 
                  amplitude * 
                  math.sin(frequency * (x / size.width) * 2 * math.pi + phase);
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      paint.color = color.withOpacity(0.3 + wave * 0.2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AnimatedWavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}