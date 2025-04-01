import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            activeColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.grey,
            value: true,
            onChanged: (val) => print("Mic auto-start: $val"),
            title: Text("Enable mic auto-start", style: GoogleFonts.poppins(color: Colors.white)),
          ),
          SwitchListTile(
            activeColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.grey,
            value: false,
            onChanged: (val) => print("Notifications: $val"),
            title: Text("Enable notifications", style: GoogleFonts.poppins(color: Colors.white)),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.brightness_6, color: Colors.orangeAccent),
            title: Text("Toggle Dark Mode", style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () => print("Dark mode toggle"),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.redAccent),
            title: Text("Reset Data", style: GoogleFonts.poppins(color: Colors.white)),
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
        backgroundColor: const Color(0xFF27293D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Reset all data?", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text("This will erase your swear history.", style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              print("RESETTING...");
              Navigator.pop(context);
            },
            child: const Text("Reset", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
