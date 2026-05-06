import 'package:firebase_auth/firebase_auth.dart';

const String ownerUid = "roduqZRk4GgXLCQIZGIFAWN0UUg1";

User? get currentUser => FirebaseAuth.instance.currentUser;
String get currentUid => currentUser?.uid ?? "";

bool isOwnerUid() => currentUid == ownerUid;

bool canAccessAdminPanelByRole(String? role) {
  return isOwnerUid() ||
      role == "owner" ||
      role == "admin" ||
      role == "moderator" ||
      role == "support";
}

bool canManageUsers(String? role) {
  return isOwnerUid() || role == "owner" || role == "admin";
}

bool canManageRoles(String? role) {
  return isOwnerUid() || role == "owner";
}

bool canModerate(String? role) {
  return isOwnerUid() ||
      role == "owner" ||
      role == "admin" ||
      role == "moderator";
}

bool canHandleSupport(String? role) {
  return isOwnerUid() ||
      role == "owner" ||
      role == "admin" ||
      role == "moderator" ||
      role == "support";
}