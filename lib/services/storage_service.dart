import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Where each kind of upload lives in Cloud Storage.
///
/// `identity/` is deliberately separate: storage rules let only the owner
/// write there and only an admin read it, so an ID scan can never leak through
/// a public profile URL.
abstract final class StoragePaths {
  static String profilePhoto(String uid) => 'profiles/$uid/photo.jpg';
  static String portfolio(String uid, String itemId) =>
      'portfolio/$uid/$itemId.jpg';
  static String identity(String uid) => 'identity/$uid/id-document.jpg';
  static String certificate(String uid, String itemId) =>
      'identity/$uid/certificates/$itemId.pdf';
  static String jobPhoto(String jobId, String itemId) =>
      'jobs/$jobId/$itemId.jpg';
  static String chatImage(String conversationId, String itemId) =>
      'chats/$conversationId/$itemId.jpg';
}

abstract class StorageService {
  Future<String> upload(File file, String path, {String? contentType});

  Future<void> delete(String path);
}

class FirebaseStorageService implements StorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(File file, String path, {String? contentType}) async {
    final Reference ref = _storage.ref(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: contentType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> delete(String path) => _storage.ref(path).delete();
}

/// Demo mode has nowhere to put bytes, so it echoes a stable local URI. The
/// UI treats any non-http URL as a local file and renders it from disk.
class DemoStorageService implements StorageService {
  @override
  Future<String> upload(File file, String path, {String? contentType}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return file.path;
  }

  @override
  Future<void> delete(String path) async {}
}
