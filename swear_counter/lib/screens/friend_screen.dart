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
  
  bool _isSearchingByEmail = true; // Default to email search
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<FriendModel> _friends = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _firebaseService.getFriends();
      // Sort by swear count in descending order (high to low)
      result.sort((a, b) => b.swearCount.compareTo(a.swearCount));
      
      setState(() => _friends = result);
    } catch (e) {
      _showErrorSnackBar('Failed to load friends: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() => _errorMessage = 'Please enter a search term');
      return;
    }
    
    setState(() {
      _errorMessage = '';
      _isLoading = true;
      _searchResults = [];
    });
    
    try {
      if (_isSearchingByEmail) {
        _searchResults = await _firebaseService.searchUsersByEmail(searchTerm);
      } else {
        _searchResults = await _firebaseService.searchUsersByUsername(searchTerm);
      }
      
      if (_searchResults.isEmpty) {
        setState(() => _errorMessage = 'No users found');
      }
    } catch (e) {
      _showErrorSnackBar('Search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    
    try {
      await _firebaseService.sendFriendRequest(user['uid']);
      _searchController.clear();
      Navigator.pop(context);
      _showSuccessSnackBar('Friend request sent to ${user['username']}');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await _firebaseService.getIncomingFriendRequests();
      setState(() => _incomingRequests = requests);
    } catch (e) {
      _showErrorSnackBar('Failed to load requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    
    try {
      await _firebaseService.acceptFriendRequest(user['uid']);
      
      // Remove from requests list and update UI
      setState(() => _incomingRequests.removeWhere((req) => req['uid'] == user['uid']));
      
      // Refresh friends list
      await _fetchFriends();
      
      _showSuccessSnackBar('${user['username']} is now your friend!');
      
      if (_incomingRequests.isEmpty && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to accept request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _rejectRequest(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    
    try {
      await _firebaseService.rejectFriendRequest(user['uid']);
      
      // Remove from requests list and update UI
      setState(() => _incomingRequests.removeWhere((req) => req['uid'] == user['uid']));
      
      _showSuccessSnackBar('Request rejected');
      
      if (_incomingRequests.isEmpty && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reject request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _removeFriend(FriendModel friend) async {
    final confirmed = await _showConfirmDialog(
      'Remove Friend', 
      'Are you sure you want to remove ${friend.name} from your friends?'
    );
    
    if (!confirmed) return;
    
    setState(() => _isLoading = true);
    
    try {
      int index = _friends.indexWhere((f) => f.uid == friend.uid);
      if (index != -1) {
        // Remove from Firebase
        await _firebaseService.deleteFriend(friend.uid);
        
        // Remove from local list with animation
        final removedItem = _friends.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildCard(removedItem, index + 1, animation),
          duration: const Duration(milliseconds: 300),
        );
        
        _showSuccessSnackBar('${friend.name} removed from friends');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to remove friend: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddFriendDialog() {
    _searchController.clear();
    _searchResults = [];
    _errorMessage = '';
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2B2D42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Add a Friend", style: GoogleFonts.poppins(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle between email and username search
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text("By Email", 
                            style: GoogleFonts.poppins(
                              color: _isSearchingByEmail ? Colors.white : Colors.white70,
                              fontWeight: _isSearchingByEmail ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: _isSearchingByEmail,
                          selectedColor: Colors.deepPurpleAccent,
                          backgroundColor: Colors.deepPurple.withOpacity(0.2),
                          onSelected: (selected) {
                            setDialogState(() {
                              _isSearchingByEmail = true;
                              _searchResults = [];
                              _errorMessage = '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text("By Username", 
                            style: GoogleFonts.poppins(
                              color: !_isSearchingByEmail ? Colors.white : Colors.white70,
                              fontWeight: !_isSearchingByEmail ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: !_isSearchingByEmail,
                          selectedColor: Colors.deepPurpleAccent,
                          backgroundColor: Colors.deepPurple.withOpacity(0.2),
                          onSelected: (selected) {
                            setDialogState(() {
                              _isSearchingByEmail = false;
                              _searchResults = [];
                              _errorMessage = '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _isSearchingByEmail ? "Enter email address" : "Enter username",
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                      prefixIcon: Icon(
                        _isSearchingByEmail ? Icons.email : Icons.person,
                        color: Colors.white70,
                      ),
                    ),
                    keyboardType: _isSearchingByEmail ? TextInputType.emailAddress : TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchUsers(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: const Icon(Icons.search),
                      label: Text("Search", style: GoogleFonts.poppins()),
                      onPressed: () async {
                        await _searchUsers();
                        setDialogState(() {}); // Update dialog state with new results
                      },
                    ),
                  ),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  // Loading indicator
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  
                  // Search results
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Results", 
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: user['avatarUrl'] != null
                            ? CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl']))
                            : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            user['username'], 
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Text(
                            user['email'], 
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add, color: Colors.greenAccent),
                            onPressed: () => _sendRequest(user),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", 
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRequestsDialog() async {
    setState(() => _isLoading = true);
    
    await _loadRequests();
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (_incomingRequests.isEmpty) {
      _showInfoSnackBar('No friend requests');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2B2D42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.white70),
                const SizedBox(width: 8),
                Text("Friend Requests", style: GoogleFonts.poppins(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _incomingRequests.isEmpty
                    ? [
                        Text(
                          "No pending requests",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      ]
                    : _incomingRequests.map((user) => Card(
                          color: const Color(0xFF373B44),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: user['avatarUrl'] != null
                                      ? CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl']))
                                      : const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(
                                    user['username'],
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    user['email'],
                                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.close, color: Colors.redAccent),
                                      label: Text("Decline", style: GoogleFonts.poppins(color: Colors.white70)),
                                      onPressed: () async {
                                        await _rejectRequest(user);
                                        setDialogState(() {}); // Update dialog state
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: Text("Accept", style: GoogleFonts.poppins()),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                                      onPressed: () async {
                                        await _acceptRequest(user);
                                        setDialogState(() {}); // Update dialog state
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close", style: GoogleFonts.poppins(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(FriendModel friend, int rank, Animation<double> animation) {
    Widget getRankBadge() {
      if (rank == 1) {
        return Stack(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 32),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.amberAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "1",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      } else if (rank == 2) {
        return Stack(
          children: [
            const Icon(Icons.emoji_events, color: Colors.grey, size: 28),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "2",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      } else if (rank == 3) {
        return Stack(
          children: [
            const Icon(Icons.emoji_events, color: Colors.brown, size: 24),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "3",
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      } else {
        return Text(
          "#$rank",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    return SizeTransition(
      sizeFactor: animation,
      child: Dismissible(
        key: Key(friend.uid),
        background: Container(
          color: Colors.redAccent,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async => _showConfirmDialog(
          'Remove Friend', 
          'Are you sure you want to remove ${friend.name} from your friends?'
        ),
        onDismissed: (_) => _removeFriend(friend),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rank <= 3 
                  ? const [Color(0xFF373B44), Color(0xFF4286f4)]  // Top 3 gradient
                  : const [Color(0xFF1F2937), Color(0xFF3C4A5F)], // Other gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFriendDetails(friend),
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white24,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Rank indicator
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: getRankBadge(),
                    ),
                    const SizedBox(width: 12),
                    
                    // Avatar
                    friend.avatarUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl!), radius: 24)
                        : CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 24,
                            child: Text(
                              friend.name.characters.first.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                          ),
                    const SizedBox(width: 16),
                    
                    // Friend info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.volume_up, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${friend.swearCount} swears",
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Action button
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onPressed: () => _showFriendOptions(friend),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showFriendDetails(FriendModel friend) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(friend.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            friend.avatarUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl!), radius: 50)
                : CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 50,
                    child: Text(
                      friend.name.characters.first.toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
            const SizedBox(height: 16),
            
            // Swear stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Swear Count",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${friend.swearCount}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
  
  void _showFriendOptions(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B2D42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blueAccent),
            title: Text("View Profile", style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showFriendDetails(friend);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: Text("Remove Friend", style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _removeFriend(friend);
            },
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm", style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
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
          IconButton(
            icon: Badge(
              isLabelVisible: _incomingRequests.isNotEmpty,
              label: Text(_incomingRequests.length.toString(), 
                style: GoogleFonts.poppins(fontSize: 10),
              ),
              child: const Icon(Icons.notifications),
            ),
            onPressed: _showRequestsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.person_add),
        onPressed: _showAddFriendDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFriends,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              "No friends yet",
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white54),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the + button to add friends",
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : AnimatedList(
                        key: _listKey,
                        initialItemCount: _friends.length,
                        itemBuilder: (context, index, animation) {
                          return _buildCard(_friends[index], index + 1, animation);
                        },
                      ),
              ),
            ),
    );
  }
}
