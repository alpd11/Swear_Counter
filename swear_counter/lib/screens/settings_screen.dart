import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
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
            leading: const Icon(Icons.bug_report, color: Colors.purpleAccent),
            title: Text("Debug Tools", style: GoogleFonts.poppins(color: Colors.white)),
            subtitle: Text("Troubleshoot account issues", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const DebugScreen())
            ),
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
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF27293D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text("Are you sure you want to log out?", style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    
    if (shouldLogout != true) return;
    
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    
    try {
      await AuthService().signOut();
      // No need to navigate - the AuthGate will handle navigation based on auth state
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
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

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String _statusMessage = 'Ready to diagnose issues';
  int _userCount = 0;
  Map<String, dynamic>? _currentUserData;
  List<Map<String, dynamic>> _allUsers = [];
  
  @override
  void initState() {
    super.initState();
    _checkFirestoreStatus();
  }
  
  Future<void> _checkFirestoreStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking Firestore status...';
    });
    
    try {
      // Check if current user exists in Firestore
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _statusMessage = 'Error: No user is logged in';
          _isLoading = false;
        });
        return;
      }
      
      // Try to get the current user's data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserData = userDoc.data();
          _statusMessage = 'User exists in Firestore';
        });
      } else {
        setState(() {
          _statusMessage = 'User does NOT exist in Firestore!';
        });
      }
      
      // Count total users
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _userCount = snapshot.docs.length;
        _allUsers = snapshot.docs.map((doc) => doc.data()).toList();
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _forceCreateUser() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Forcing user creation...';
    });
    
    try {
      final success = await _firebaseService.forceCreateCurrentUser();
      if (success) {
        setState(() {
          _statusMessage = 'User created successfully!';
        });
        // Refresh status
        await _checkFirestoreStatus();
      } else {
        setState(() {
          _statusMessage = 'Failed to create user';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceCreateUsersCollection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating users collection...';
    });

    try {
      final success = await _firebaseService.forceCreateUsersCollection();
      if (success) {
        setState(() {
          _statusMessage = 'Users collection created successfully!';
        });
        // Refresh status
        await _checkFirestoreStatus();
      } else {
        setState(() {
          _statusMessage = 'Failed to create users collection';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating users collection: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Debug Tools', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current status
                Card(
                  color: const Color(0xFF27293D),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        )),
                        const SizedBox(height: 8),
                        Text(_statusMessage, style: GoogleFonts.poppins(
                          color: _statusMessage.contains('Error') || _statusMessage.contains('NOT') 
                            ? Colors.redAccent 
                            : Colors.greenAccent,
                        )),
                        const SizedBox(height: 16),
                        Text('Total users in Firestore: $_userCount', style: GoogleFonts.poppins(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current user info
                Card(
                  color: const Color(0xFF27293D),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current User', style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        )),
                        const SizedBox(height: 8),
                        
                        if (user != null) ...[
                          _infoRow('ID', user.uid),
                          _infoRow('Email', user.email ?? 'No email'),
                          _infoRow('Name', user.displayName ?? 'No name'),
                          _infoRow('Photo URL', user.photoURL ?? 'No photo'),
                        ] else
                          Text('No user logged in', style: GoogleFonts.poppins(color: Colors.redAccent)),
                          
                        const SizedBox(height: 16),
                        
                        Text('User in Firestore', style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        )),
                        const SizedBox(height: 8),
                        
                        if (_currentUserData != null) ...[
                          _infoRow('Username', _currentUserData!['username'] ?? 'Not found'),
                          _infoRow('Email', _currentUserData!['email'] ?? 'Not found'),
                          _infoRow('Swear Count', '${_currentUserData!['swearCount'] ?? 0}'),
                        ] else
                          Text('User not found in Firestore', style: GoogleFonts.poppins(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Text('Actions', style: GoogleFonts.poppins(
                  color: Colors.white, 
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 16),
                
                // First row of buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text('Refresh', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _checkFirestoreStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: Text('Force Create User', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _forceCreateUser,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Second row - collection creation button
                ElevatedButton.icon(
                  icon: const Icon(Icons.create_new_folder),
                  label: Text('Create Users Collection', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _forceCreateUsersCollection,
                ),
                
                const SizedBox(height: 24),
                
                // All users in database
                if (_userCount > 0) ...[
                  Text('All Users in Database', style: GoogleFonts.poppins(
                    color: Colors.white, 
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  )),
                  const SizedBox(height: 8),
                  
                  Card(
                    color: const Color(0xFF27293D),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final userData = _allUsers[index];
                        return ListTile(
                          title: Text(userData['username'] ?? 'No username', 
                            style: GoogleFonts.poppins(color: Colors.white)),
                          subtitle: Text(userData['email'] ?? 'No email', 
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          leading: userData['avatarUrl'] != null
                            ? CircleAvatar(backgroundImage: NetworkImage(userData['avatarUrl']))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            )),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
