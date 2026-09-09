import 'package:flutter/material.dart';
import 'app_state.dart';

/// Settings screen for ZIP_PUZZLE_GAME
/// Accessible from both Level Select screen and Puzzle screen AppBar.
///
/// NOTE: sound/music state lives in-memory on AppState (matches the rest
/// of the app's current pattern). When Firebase/persistence is added later,
/// swap the toggles here to read/write SharedPreferences or Firestore.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color tealPrimary = Color(0xFF00796B);
  static const Color goldAccent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance; // same singleton pattern as rest of app

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tealPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _sectionHeader('Audio'),
          _buildSwitchTile(
            icon: Icons.music_note_rounded,
            title: 'Background Music',
            subtitle: 'Play music while you solve puzzles',
            value: appState.musicEnabled,
            onChanged: (val) {
              setState(() => appState.musicEnabled = val);
              // TODO: hook into actual music player (mute/unmute) once added
            },
          ),
          _buildSwitchTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            subtitle: 'Connect, solve and wrong-move sounds',
            value: appState.soundEffectsEnabled,
            onChanged: (val) {
              setState(() => appState.soundEffectsEnabled = val);
            },
          ),
          const Divider(height: 32),
          _sectionHeader('Progress'),
          _buildActionTile(
            icon: Icons.restart_alt_rounded,
            iconColor: Colors.redAccent,
            title: 'Reset Progress',
            subtitle: 'Clears coins and unlocked levels',
            onTap: () => _confirmReset(context, appState),
          ),
          const Divider(height: 32),
          _sectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded, color: tealPrimary),
            title: Text('ZIP Puzzle'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: tealPrimary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: tealPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: goldAccent,
      activeTrackColor: tealPrimary,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will clear all your coins and unlocked levels. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      appState.resetProgress();
      if (context.mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset successfully')),
        );
      }
    }
  }
}

/// --- Icon button to drop into Level Select / Puzzle Screen AppBars ---
/// Usage: actions: [SettingsIconButton()]
class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_rounded),
      tooltip: 'Settings',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    );
  }
}