import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../services/firebase_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<FriendModel> friends = [];

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final result = await _firebaseService.getFriends();
    result.sort((a, b) => a.swearCount.compareTo(b.swearCount));
    setState(() => friends = result);
  }

  Future<void> _searchUsername() async {
    final results = await _firebaseService.searchUsersByUsername(_searchController.text.trim());
    setState(() => _searchResults = results);
  }

  Future<void> _sendRequest(Map<String, dynamic> user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await _firebaseService.sendFriendRequest(currentUser.uid, user['uid']);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent!")),
    );
    _searchController.clear();
    Navigator.pop(context);
  }

  Future<void> _loadRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final requests = await _firebaseService.getIncomingRequests(currentUser.uid);
    setState(() => _incomingRequests = requests);
  }

  Future<void> _approveRequest(Map<String, dynamic> user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await _firebaseService.approveFriendRequest(currentUser.uid, user['uid'], user['username']);
    fetchFriends();
    Navigator.pop(context);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Add Friend by Username", style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Username",
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              onPressed: _searchUsername,
              child: const Text("Search"),
            ),
            const SizedBox(height: 10),
            ..._searchResults.map((user) => ListTile(
                  title: Text(user['username'], style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text(user['email'], style: GoogleFonts.poppins(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendRequest(user),
                  ),
                ))
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog() async {
    await _loadRequests();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Friend Requests", style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _incomingRequests.map((user) => ListTile(
                title: Text(user['username'], style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text(user['email'], style: GoogleFonts.poppins(color: Colors.white54)),
                trailing: ElevatedButton(
                  onPressed: () => _approveRequest(user),
                  child: const Text("Accept"),
                ),
              )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(FriendModel friend, int rank, Animation<double> animation) {
    Icon badge;
    if (rank == 1) {
      badge = const Icon(Icons.emoji_events, color: Colors.amberAccent);
    } else if (rank == 2) {
      badge = const Icon(Icons.emoji_events, color: Colors.grey);
    } else if (rank == 3) {
      badge = const Icon(Icons.emoji_events, color: Colors.brown);
    } else {
      badge = const Icon(Icons.person, color: Colors.deepPurple);
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF373B44), Color(0xFF4286f4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            friend.avatarUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl!))
                : CircleAvatar(backgroundColor: Colors.white, child: badge),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("Swears: ${friend.swearCount}", style: GoogleFonts.poppins(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
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
        title: Text("Friends", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showSearchDialog),
          IconButton(icon: const Icon(Icons.inbox), onPressed: _showRequestDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: friends.isEmpty
            ? Center(
                child: Text("No friends yet. Add some!",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.white54)),
              )
            : AnimatedList(
                key: _listKey,
                initialItemCount: friends.length,
                itemBuilder: (context, index, animation) {
                  return _buildCard(friends[index], index + 1, animation);
                },
              ),
      ),
    );
  }
}
