import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_agent_provider.dart';
import '../widgets/animated_waveform.dart';
import 'chat_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final voiceAgent = context.read<VoiceAgentProvider>();
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(voiceAgent: voiceAgent),
    );
    
    try {
      await voiceAgent.initializeModels();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Navigate to chat screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A1128),
              const Color(0xFF1A2642),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Animated Waveform Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return AnimatedWaveform(
                      height: 200,
                      width: 200,
                      color: const Color(0xFF2E5BFF),
                      isAnimating: true,
                      animationValue: _controller.value,
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Your Smart Offline\nVoice Assistant',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Powered by AI, running entirely on your device',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                
                const Spacer(),
                
                // Feature List
                _FeatureItem(
                  icon: Icons.lock,
                  text: '100% Private & Offline',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.flash_on,
                  text: 'Fast & Accurate Responses',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.wifi_off,
                  text: 'Works Without Internet',
                ),
                
                const SizedBox(height: 60),
                
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initializeAndNavigate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E5BFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2E5BFF),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final VoiceAgentProvider voiceAgent;

  const _LoadingDialog({required this.voiceAgent});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A2642),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Loading AI Models',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<VoiceAgentProvider>(
              builder: (context, provider, _) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: provider.loadingProgress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2E5BFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(provider.loadingProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'This may take a minute...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}