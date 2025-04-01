class FriendModel {
  final String uid;
  final String name;
  final int swearCount;

  FriendModel({required this.uid, required this.name, required this.swearCount});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'swearCount': swearCount,
      };

  static FriendModel fromMap(Map<String, dynamic> map) => FriendModel(
        uid: map['uid'],
        name: map['name'],
        swearCount: map['swearCount'],
      );
}

