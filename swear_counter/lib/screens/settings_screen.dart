import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.image_outlined, color: Colors.blueAccent),
            title: Text("Upload Profile Picture", style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () => _uploadProfilePicture(context),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _uploadProfilePicture(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final url = await StorageService().uploadProfileImage(user.uid);
    if (url != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'avatarUrl': url});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile picture updated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Upload cancelled or failed")),
      );
    }
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
