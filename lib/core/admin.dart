import 'package:firebase_auth/firebase_auth.dart';

const String adminUid = "roduqZRk4GgXLCQIZGIFAWN0UUg1";

bool isAdminUser() {
  return FirebaseAuth.instance.currentUser?.uid == adminUid;
}