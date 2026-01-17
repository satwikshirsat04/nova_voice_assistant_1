import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_agent_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mic_button.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/waveform_visualizer.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Chat Messages
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];
                        return Column(
                          children: [
                            ChatBubble(
                              message: message.userMessage,
                              isUser: true,
                            ),
                            const SizedBox(height: 12),
                            ChatBubble(
                              message: message.assistantMessage,
                              isUser: false,
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Voice Input Area
              _buildVoiceInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2E5BFF),
            child: const Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Consumer<VoiceAgentProvider>(
                  builder: (context, provider, _) {
                    String status = 'Offline Mode';
                    if (!provider.modelsLoaded) {
                      status = 'Loading...';
                    } else if (provider.isProcessing) {
                      status = _getProcessingStatus(provider.state);
                    }
                    return Text(
                      status,
                      style: TextStyle(
                        color: provider.modelsLoaded 
                            ? Colors.greenAccent 
                            : Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 80,
              color: Colors.white30,
            ),
            const SizedBox(height: 24),
            Text(
              'Tap and hold the microphone\nto start a conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1128).withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform Visualizer
          Consumer<VoiceAgentProvider>(
            builder: (context, provider, _) {
              if (provider.state == VoiceAgentState.listening) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: WaveformVisualizer(
                    audioLevelStream: provider.getAudioLevel(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Status Text
          Consumer<VoiceAgentProvider>(
            builder: (context, provider, _) {
              String statusText = '';
              if (provider.state == VoiceAgentState.listening) {
                statusText = 'Listening...';
              } else if (provider.state == VoiceAgentState.transcribing) {
                statusText = 'Transcribing...';
              } else if (provider.state == VoiceAgentState.thinking) {
                statusText = 'Thinking...';
              } else if (provider.state == VoiceAgentState.speaking) {
                statusText = 'Speaking...';
              } else if (provider.transcribedText.isNotEmpty && 
                         provider.state == VoiceAgentState.transcribing) {
                statusText = provider.transcribedText;
              }
              
              if (statusText.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Microphone Button
          Consumer2<VoiceAgentProvider, ChatProvider>(
            builder: (context, voiceProvider, chatProvider, _) {
              return MicButton(
                onPressed: () async {
                  await voiceProvider.startListening();
                },
                onReleased: () async {
                  final message = await voiceProvider.stopListening();
                  if (message != null) {
                    chatProvider.addMessage(message);
                  }
                },
                state: voiceProvider.state,
              );
            },
          ),
        ],
      ),
    );
  }

  String _getProcessingStatus(VoiceAgentState state) {
    switch (state) {
      case VoiceAgentState.listening:
        return 'Listening...';
      case VoiceAgentState.transcribing:
        return 'Processing...';
      case VoiceAgentState.thinking:
        return 'Thinking...';
      case VoiceAgentState.speaking:
        return 'Speaking...';
      case VoiceAgentState.error:
        return 'Error';
      default:
        return 'Ready';
    }
  }
}