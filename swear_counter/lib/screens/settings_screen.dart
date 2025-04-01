import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (val) => print("Mic auto-start: $val"),
            title: const Text("Enable mic auto-start"),
          ),
          SwitchListTile(
            value: false,
            onChanged: (val) => print("Notifications: $val"),
            title: const Text("Enable notifications"),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Toggle Dark Mode"),
            onTap: () => print("Dark mode toggle"),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text("Reset Data"),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset all data?"),
        content: const Text("This will erase your swear history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // TODO: Call reset from provider or storage service
              print("RESETTING...");
              Navigator.pop(context);
            },
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
