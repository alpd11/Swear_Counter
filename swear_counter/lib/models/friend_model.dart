class FriendModel {
  final String uid;
  final String name;
  final int swearCount;
  final String? avatarUrl;

  FriendModel({
    required this.uid,
    required this.name,
    required this.swearCount,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'swearCount': swearCount,
      'avatarUrl': avatarUrl,
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'],
      name: map['name'],
      swearCount: map['swearCount'] ?? 0,
      avatarUrl: map['avatarUrl'],
    );
  }
}
