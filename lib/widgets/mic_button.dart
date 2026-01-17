import 'package:flutter/material.dart';
import '../providers/voice_agent_provider.dart';

class MicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final VoiceAgentState state;

  const MicButton({
    super.key,
    required this.onPressed,
    required this.onReleased,
    required this.state,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getButtonColor() {
    switch (widget.state) {
      case VoiceAgentState.listening:
        return const Color(0xFFFF3B30); // Red when listening
      case VoiceAgentState.transcribing:
      case VoiceAgentState.thinking:
        return const Color(0xFFFF9500); // Orange when processing
      case VoiceAgentState.speaking:
        return const Color(0xFF00D9FF); // Cyan when speaking
      case VoiceAgentState.error:
        return const Color(0xFFFF3B30); // Red on error
      default:
        return const Color(0xFF2E5BFF); // Blue when idle
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case VoiceAgentState.listening:
        return Icons.mic;
      case VoiceAgentState.transcribing:
      case VoiceAgentState.thinking:
        return Icons.psychology;
      case VoiceAgentState.speaking:
        return Icons.volume_up;
      case VoiceAgentState.error:
        return Icons.error_outline;
      default:
        return Icons.mic_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == VoiceAgentState.listening;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressed();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onReleased();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onReleased();
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse rings (only when listening)
              if (isListening) ...[
                _buildPulseRing(
                  scale: _pulseAnimation.value * 1.3,
                  opacity: 1 - _pulseAnimation.value * 0.5,
                ),
                _buildPulseRing(
                  scale: _pulseAnimation.value * 1.5,
                  opacity: 1 - _pulseAnimation.value * 0.7,
                ),
              ],
              
              // Waveform ring
              if (isListening)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getButtonColor().withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              
              // Main button
              AnimatedScale(
                scale: _isPressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getButtonColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getButtonColor().withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIcon(),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPulseRing({
    required double scale,
    required double opacity,
  }) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getButtonColor().withOpacity(opacity * 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}