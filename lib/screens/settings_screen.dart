import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection('Assistant Voice', [
                      _buildVoiceSelector(context),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Wake Word', [
                      _buildWakeWordField(context),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('LFM-2 Model', [
                      _buildModelSelector(context),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Features', [
                      _buildOfflineModeToggle(context),
                      _buildAutoRemindersToggle(context),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Data', [
                      _buildClearHistoryButton(context),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('About', [
                      _buildAboutItems(context),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2642),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildVoiceOption(
                context,
                'Female',
                settings.assistantVoice == 'female',
                () => settings.setAssistantVoice('female'),
              ),
              const SizedBox(width: 12),
              _buildVoiceOption(
                context,
                'Male',
                settings.assistantVoice == 'male',
                () => settings.setAssistantVoice('male'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceOption(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF2E5BFF) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF2E5BFF)
                  : Colors.white30,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              if (isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWakeWordField(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: TextEditingController(text: settings.wakeWord),
                onChanged: settings.setWakeWord,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter wake word',
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E5BFF)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildModelOption(
              context,
              'LFM-2 1B',
              settings.llmModel == 'LFM-2 1B',
              () => settings.setLLMModel('LFM-2 1B'),
            ),
            _buildModelOption(
              context,
              'LFM-2 2B',
              settings.llmModel == 'LFM-2 2B',
              () => settings.setLLMModel('LFM-2 2B'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelOption(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2E5BFF) : Colors.white30,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineModeToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildToggleTile(
          'Offline Mode',
          settings.offlineMode,
          settings.setOfflineMode,
        );
      },
    );
  }

  Widget _buildAutoRemindersToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildToggleTile(
          'Auto-Reminders',
          settings.autoReminders,
          settings.setAutoReminders,
        );
      },
    );
  }

  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E5BFF),
          ),
        ],
      ),
    );
  }

  Widget _buildClearHistoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => _showClearHistoryDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Clear Chat History'),
      ),
    );
  }

  Widget _buildAboutItems(BuildContext context) {
    return Column(
      children: [
        _buildInfoTile('Help & Support'),
        const Divider(color: Colors.white10, height: 1),
        _buildInfoTile('About App'),
      ],
    );
  }

  Widget _buildInfoTile(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white30,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2642),
        title: const Text(
          'Clear Chat History?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your conversations.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}