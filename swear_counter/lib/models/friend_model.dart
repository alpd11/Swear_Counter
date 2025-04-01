class FriendModel {
  final String uid;
  final String name;
  final int swearCount;
  final String? avatarUrl; // ✅ New: optional profile image

  FriendModel({
    required this.uid,
    required this.name,
    required this.swearCount,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'swearCount': swearCount,
        'avatarUrl': avatarUrl,
      };

  static FriendModel fromMap(Map<String, dynamic> map) => FriendModel(
        uid: map['uid'],
        name: map['name'],
        swearCount: map['swearCount'],
        avatarUrl: map['avatarUrl'],
      );
}
