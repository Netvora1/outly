import 'package:firebase_auth/firebase_auth.dart';

const String adminUid = "roduqZRk4GgXLCQIZGIFAWN0UUg1";

bool isAdminUser() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  print("roduqZRk4GgXLCQIZGIFAWN0UUg1: $uid");
  return uid == adminUid;
}