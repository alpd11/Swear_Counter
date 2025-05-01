import 'dart:async'; // Added import for StreamSubscription
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
  final RealtimeDbService _realtimeDbService = RealtimeDbService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isDisposed = false; // Flag to track if widget is disposed

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = []; // Added for tracking sent requests
  List<FriendModel> _friends = [];

  // Stream subscription for friend requests
  StreamSubscription<List<Map<String, dynamic>>>? _friendRequestsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _outgoingRequestsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchFriends();

    // Set up subscription to incoming friend requests with better error handling
    _friendRequestsSubscription = _realtimeDbService.getIncomingFriendRequests().listen((requests) {
      if (!_isDisposed) {
        setState(() {
          _incomingRequests = requests;
        });
        print('📩 Received ${requests.length} incoming friend requests');
      }
    }, onError: (error) {
      if (!_isDisposed) {
        print('❌ Error loading friend requests: $error');
        // In release mode, show a more user-friendly message
        _showErrorSnackBar('Unable to load friend requests. Please try again later.');
      }
    });

    // Set up subscription to outgoing friend requests with better error handling
    _outgoingRequestsSubscription = _realtimeDbService.getOutgoingFriendRequests().listen((requests) {
      if (!_isDisposed) {
        setState(() {
          _outgoingRequests = requests;
        });
        print('📤 Tracking ${requests.length} outgoing friend requests');
      }
    }, onError: (error) {
      if (!_isDisposed) {
        print('❌ Error loading outgoing requests: $error');
        // In release mode, show a more user-friendly message
        _showErrorSnackBar('Unable to load sent requests. Please try again later.');
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _friendRequestsSubscription?.cancel();
    _outgoingRequestsSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      super.setState(fn);
    }
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);

    try {
      final result = await _realtimeDbService.getFriends();
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
      if (mounted) {
        setState(() => _errorMessage = 'Please enter a search term');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = '';
        _isLoading = true;
        _searchResults = [];
      });
    } else {
      return;
    }

    try {
      var resultsData = await _realtimeDbService.searchUsersByIdentifier(searchTerm);

      if (mounted) {
        List<dynamic> rawResults = resultsData['users'] as List<dynamic>;
        List<Map<String, dynamic>> typedResults = [];

        for (var user in rawResults) {
          if (user is Map<dynamic, dynamic>) {
            final convertedUser = Map<String, dynamic>.fromEntries(
              user.entries.map((e) => MapEntry(e.key.toString(), e.value)),
            );
            typedResults.add(convertedUser);
          }
        }

        setState(() => _searchResults = typedResults);
      }

      if (_searchResults.isEmpty && mounted) {
        setState(() => _errorMessage = 'No users found');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Search failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> user) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _realtimeDbService.sendFriendRequest(user['uid']);

      if (mounted) {
        _searchController.clear();
        Navigator.pop(context);
        _showSuccessSnackBar('Friend request sent to ${user['username']}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> user) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _realtimeDbService.acceptFriendRequest(user['uid']);

      if (!mounted) return;

      setState(() => _incomingRequests.removeWhere((req) => req['uid'] == user['uid']));

      if (mounted) {
        await _fetchFriends();

        _showSuccessSnackBar('${user['name']} is now your friend!');

        if (_incomingRequests.isEmpty && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to accept request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> user) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _realtimeDbService.rejectFriendRequest(user['uid']);

      if (mounted) {
        setState(() => _incomingRequests.removeWhere((req) => req['uid'] == user['uid']));

        _showSuccessSnackBar('Request rejected');

        if (_incomingRequests.isEmpty && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to reject request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final confirmed = await _showConfirmDialog(
      'Remove Friend',
      'Are you sure you want to remove ${friend.name} from your friends?',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      int index = _friends.indexWhere((f) => f.uid == friend.uid);
      if (index != -1) {
        await _realtimeDbService.deleteFriend(friend.uid);

        if (!mounted) return;
        final removedItem = _friends.removeAt(index);

        if (_listKey.currentState != null) {
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildCard(removedItem, index + 1, animation),
            duration: const Duration(milliseconds: 300),
          );
        }

        if (mounted) {
          _showSuccessSnackBar('${friend.name} removed from friends');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to remove friend: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRequestsDialog() async {
    if (!mounted || _isDisposed) return;
    setState(() => _isLoading = true);

    try {
      setState(() => _isLoading = false);

      if (_incomingRequests.isEmpty) {
        _showInfoSnackBar('No friend requests');
        return;
      }

      final localRequests = List<Map<String, dynamic>>.from(_incomingRequests);
      
      // Print debug info about requests
      print('📬 Showing ${localRequests.length} friend requests');
      for (var request in localRequests) {
        print('📝 Request from: ${request['username'] ?? request['name'] ?? 'Unknown'}, uid: ${request['uid']}');
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
                  children: localRequests.isEmpty
                      ? [
                          Text(
                            "No pending requests",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ]
                      : localRequests.map((user) => Card(
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
                                      // Use username first, then name as fallback
                                      user['username'] ?? user['name'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      user['email'] ?? 'No email',
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
                                          if (mounted && !_isDisposed) {
                                            await _rejectRequest(user);

                                            if (mounted && context.mounted) {
                                              setDialogState(() {
                                                localRequests.removeWhere(
                                                  (req) => req['uid'] == user['uid'],
                                                );
                                              });

                                              if (localRequests.isEmpty) {
                                                Navigator.of(context).pop();
                                              }
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: Text("Accept", style: GoogleFonts.poppins()),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                                        onPressed: () async {
                                          if (mounted && !_isDisposed) {
                                            await _acceptRequest(user);

                                            if (mounted && context.mounted) {
                                              setDialogState(() {
                                                localRequests.removeWhere(
                                                  (req) => req['uid'] == user['uid'],
                                                );
                                              });

                                              if (localRequests.isEmpty) {
                                                Navigator.of(context).pop();
                                              }
                                            }
                                          }
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
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading requests: $e');
    }
  }

  void _showSentRequestsDialog() {
    if (!mounted || _isDisposed) return;
    
    if (_outgoingRequests.isEmpty) {
      _showInfoSnackBar('No pending sent requests');
      return;
    }

    final localSentRequests = List<Map<String, dynamic>>.from(_outgoingRequests);

    // Print debug info about outgoing requests
    print('📤 Showing ${localSentRequests.length} sent requests');
    for (var request in localSentRequests) {
      print('📝 Request to: ${request['username'] ?? request['name'] ?? 'Unknown'}, uid: ${request['uid']}');
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
                const Icon(Icons.send, color: Colors.white70),
                const SizedBox(width: 8),
                Text("Sent Requests", style: GoogleFonts.poppins(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: localSentRequests.map((user) => Card(
                  color: const Color(0xFF373B44),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        user['avatarUrl'] != null
                          ? CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl']))
                          : const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username'] ?? user['name'] ?? 'Unknown',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              Text(
                                "Waiting for response",
                                style: GoogleFonts.poppins(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          label: Text("Cancel", 
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                          onPressed: () async {
                            if (mounted && !_isDisposed) {
                              try {
                                setDialogState(() => _isLoading = true);
                                
                                await _cancelRequest(user);
                                
                                if (mounted && context.mounted) {
                                  setDialogState(() {
                                    _isLoading = false;
                                    localSentRequests.removeWhere(
                                      (req) => req['uid'] == user['uid']
                                    );
                                  });
                                  
                                  if (localSentRequests.isEmpty) {
                                    Navigator.of(context).pop();
                                    _showInfoSnackBar('Request canceled');
                                  }
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  setDialogState(() => _isLoading = false);
                                  _showErrorSnackBar('Failed to cancel request: $e');
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 20, 
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text("Close", style: GoogleFonts.poppins(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancelRequest(Map<String, dynamic> user) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _realtimeDbService.cancelFriendRequest(user['uid']);

      if (mounted) {
        setState(() {
          _outgoingRequests.removeWhere((req) => req['uid'] == user['uid']);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to cancel request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          'Are you sure you want to remove ${friend.name} from your friends?',
        ),
        onDismissed: (_) => _removeFriend(friend),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rank <= 3
                  ? const [Color(0xFF373B44), Color(0xFF4286f4)]
                  : const [Color(0xFF1F2937), Color(0xFF3C4A5F)],
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
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: getRankBadge(),
                    ),
                    const SizedBox(width: 12),
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
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(friend.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  void _showAddFriendDialog() {
    if (!mounted || _isDisposed) return;
    
    _searchController.clear();
    _searchResults = [];
    _errorMessage = '';
    
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Handle search function with proper state management
          void handleSearch() async {
            setDialogState(() {
              _errorMessage = '';
              _isLoading = true;
            });
            
            try {
              await _searchUsers();
            } catch (e) {
              if (mounted && context.mounted) {
                setDialogState(() => _errorMessage = 'Search failed: $e');
              }
            } finally {
              if (mounted && context.mounted) {
                setDialogState(() => _isLoading = false);
              }
            }
          }
          
          // Handle send request with proper state management
          void handleSendRequest(Map<String, dynamic> user) async {
            try {
              setDialogState(() => _isLoading = true);
              
              // Send the friend request
              await _realtimeDbService.sendFriendRequest(user['uid']);
              
              if (!mounted || !context.mounted) return;
              
              // Create a properly formatted outgoing request object
              // This ensures consistency with the stream data format
              final requestObject = {
                'uid': user['uid'],
                'name': user['username'] ?? 'Unknown',
                'email': user['email'] ?? '',
                'avatarUrl': user['avatarUrl'],
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              };
              
              // Close the dialog first before modifying parent state
              Navigator.of(context).pop();
              
              // Update parent state safely after dialog is closed
              if (mounted) {
                setState(() {
                  _outgoingRequests = [..._outgoingRequests, requestObject];
                });
                _showSuccessSnackBar('Friend request sent to ${user['username'] ?? 'user'}');
              }
            } catch (e) {
              if (mounted && context.mounted) {
                setDialogState(() => _errorMessage = e.toString());
              }
            } finally {
              if (mounted && context.mounted) {
                setDialogState(() => _isLoading = false);
              }
            }
          }
          
          return AlertDialog(
            backgroundColor: const Color(0xFF2B2D42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Add a Friend", style: GoogleFonts.poppins(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simplified search field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Search by email or username",
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurpleAccent),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => handleSearch(),
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
                      onPressed: _isLoading ? null : handleSearch,
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
                  if (_searchResults.isNotEmpty && !_isLoading) ...[
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
                        final String userId = user['uid'] ?? '';
                        
                        // Check if request already sent to this user
                        final bool requestAlreadySent = _outgoingRequests
                            .any((request) => request['uid'] == userId);
                        
                        // Check if already friends with this user
                        final bool alreadyFriends = _friends
                            .any((friend) => friend.uid == userId);
                            
                        // Check if this is the current user
                        final bool isCurrentUser = userId == _realtimeDbService.currentUserId;

                        // Determine what button to show
                        Widget trailingButton;
                        if (isCurrentUser) {
                          trailingButton = TextButton(
                            onPressed: null,
                            child: Text("You", 
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          );
                        } else if (requestAlreadySent) {
                          trailingButton = TextButton(
                            onPressed: null,
                            child: Text("Request Sent", 
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          );
                        } else if (alreadyFriends) {
                          trailingButton = TextButton(
                            onPressed: null,
                            child: Text("Friends", 
                              style: GoogleFonts.poppins(color: Colors.greenAccent),
                            ),
                          );
                        } else {
                          trailingButton = IconButton(
                            icon: const Icon(Icons.person_add, color: Colors.greenAccent),
                            onPressed: () => handleSendRequest(user),
                          );
                        }
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: user['avatarUrl'] != null
                            ? CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl']))
                            : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            user['username'] ?? 'Unknown', 
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Text(
                            user['email'] ?? '', 
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: trailingButton,
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

  void _showFriendOptions(FriendModel friend) {
    if (!mounted) return;

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
              isLabelVisible: _outgoingRequests.isNotEmpty,
              label: Text(
                _outgoingRequests.length.toString(),
                style: GoogleFonts.poppins(fontSize: 10),
              ),
              child: const Icon(Icons.send),
            ),
            onPressed: _showSentRequestsDialog,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _incomingRequests.isNotEmpty,
              label: Text(
                _incomingRequests.length.toString(),
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
