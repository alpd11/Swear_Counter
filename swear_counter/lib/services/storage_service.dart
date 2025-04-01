import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Select and upload image
  Future<String?> uploadProfileImage(String uid) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    final File file = File(image.path);
    final ref = _storage.ref().child('avatars').child('$uid.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    return url;
  }
}
