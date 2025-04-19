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
  List<FriendModel> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final friends = await _firebaseService.getFriends();
      final requests = await _firebaseService.getIncomingFriendRequests();

      setState(() {
        _friends = friends;
        _friendRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friends data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> results = [];
      
      // First try exact email search
      if (query.contains('@')) {
        results = await _firebaseService.searchUsersByEmail(query);
      }

      // If no results or not an email, try username search
      if (results.isEmpty) {
        results = await _firebaseService.searchUsersByUsername(query);
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String uid) async {
    try {
      await _firebaseService.sendFriendRequest(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
      // Clear search
      _searchController.clear();
      setState(() {
        _searchResults = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _acceptRequest(String uid) async {
    try {
      await _firebaseService.acceptFriendRequest(uid);
      _loadData(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectRequest(String uid) async {
    try {
      await _firebaseService.rejectFriendRequest(uid);
      setState(() {
        _friendRequests.removeWhere((req) => req['uid'] == uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteFriend(String uid) async {
    try {
      await _firebaseService.deleteFriend(uid);
      setState(() {
        _friends.removeWhere((friend) => friend.uid == uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
          'Friends',
          style: GoogleFonts.poppins(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for friends by email or username',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFF27293D),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                
                // Search Results
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent,
                            backgroundImage: user['avatarUrl'] != null 
                                ? NetworkImage(user['avatarUrl'])
                                : null,
                            child: user['avatarUrl'] == null
                                ? Text(user['username'][0].toUpperCase(), 
                                    style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Text(user['username'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(user['email'], style: const TextStyle(color: Colors.grey)),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.person_add, color: Colors.deepPurpleAccent),
                            label: const Text('Add', style: TextStyle(color: Colors.deepPurpleAccent)),
                            onPressed: () => _sendFriendRequest(user['uid']),
                          ),
                        );
                      },
                    ),
                  ),
                
                if (_searchResults.isEmpty) ...[
                  // Friend Requests Section
                  if (_friendRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Friend Requests (${_friendRequests.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _friendRequests.length,
                      itemBuilder: (context, index) {
                        final request = _friendRequests[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent,
                            backgroundImage: request['avatarUrl'] != null 
                                ? NetworkImage(request['avatarUrl'])
                                : null,
                            child: request['avatarUrl'] == null
                                ? Text(request['username'][0].toUpperCase(), 
                                    style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Text(request['username'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(request['email'], style: const TextStyle(color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptRequest(request['uid']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectRequest(request['uid']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24),
                  ],
                  
                  // Friends List Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Friends (${_friends.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  _friends.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No friends yet. Search for users to add friends!',
                              style: GoogleFonts.poppins(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _friends.length,
                            itemBuilder: (context, index) {
                              final friend = _friends[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  backgroundImage: friend.avatarUrl != null 
                                      ? NetworkImage(friend.avatarUrl!)
                                      : null,
                                  child: friend.avatarUrl == null
                                      ? Text(friend.name[0].toUpperCase(), 
                                          style: const TextStyle(color: Colors.white))
                                      : null,
                                ),
                                title: Text(friend.name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Swear count: ${friend.swearCount}', 
                                    style: const TextStyle(color: Colors.grey)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _showDeleteFriendDialog(friend),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ],
            ),
    );
  }

  void _showDeleteFriendDialog(FriendModel friend) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF27293D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Remove Friend', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${friend.name} from your friends list?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFriend(friend.uid);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}