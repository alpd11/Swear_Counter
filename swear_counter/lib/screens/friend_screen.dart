import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    final newFriend = FriendModel(uid: DateTime.now().toString(), name: name, swearCount: swearCount);
    await _firebaseService.addFriend(newFriend);
    fetchFriends();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add a Friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _swearCountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Swear Count")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
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
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.deepPurple.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepPurple)),
        title: Text(friend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("Swears: ${friend.swearCount}", style: const TextStyle(color: Colors.white70)),
        trailing: Icon(
          friend.swearCount <= 3 ? Icons.star : Icons.warning,
          color: friend.swearCount <= 3 ? Colors.amberAccent : Colors.redAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Friends' Swearing Stats"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddFriendDialog)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: friends.isEmpty
            ? const Center(child: Text("No friends yet. Add some!", style: TextStyle(fontSize: 18)))
            : ListView(
                children: friends.map(_buildCard).toList(),
              ),
      ),
    );
  }
}
