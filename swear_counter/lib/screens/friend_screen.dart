import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/friend_model.dart';
import '../services/firebase_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _swearCountController = TextEditingController();
  List<FriendModel> friends = [];

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final result = await _firebaseService.getFriends();
    setState(() => friends = result);
  }

  Future<void> addFriend(String name, int swearCount) async {
    final newFriend = FriendModel(
      uid: DateTime.now().toString(),
      name: name,
      swearCount: swearCount,
    );
    await _firebaseService.addFriend(newFriend);
    fetchFriends();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Add a Friend", style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            TextField(
              controller: _swearCountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Swear Count",
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            onPressed: () {
              addFriend(_nameController.text, int.tryParse(_swearCountController.text) ?? 0);
              _nameController.clear();
              _swearCountController.clear();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Widget _buildCard(FriendModel friend) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF373B44), Color(0xFF4286f4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text("Swears: ${friend.swearCount}", style: GoogleFonts.poppins(color: Colors.white70)),
              ],
            ),
          ),
          Icon(
            friend.swearCount <= 3 ? Icons.star : Icons.warning,
            color: friend.swearCount <= 3 ? Colors.amberAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Friends",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddFriendDialog)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: friends.isEmpty
            ? Center(
                child: Text("No friends yet. Add some!",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.white54)),
              )
            : ListView(
                children: friends.map(_buildCard).toList(),
              ),
      ),
    );
  }
}
