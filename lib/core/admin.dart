import 'package:firebase_auth/firebase_auth.dart';

/// =======================================
/// OUTLY ADMIN SYSTEM
/// =======================================

/// SUPER ADMIN
/// Hat ALLE Rechte
const String superAdminUid = "roduqZRk4GgXLCQIZGIFAWN0UUg1";

/// MODERATOREN
/// Können moderieren & supporten
const List<String> moderatorUids = [
  // "uid_here",
];

/// SUPPORT TEAM
const List<String> supportUids = [
  // "uid_here",
];

/// =======================================
/// USER
/// =======================================

User? get currentUser => FirebaseAuth.instance.currentUser;

String get currentUid => currentUser?.uid ?? "";

bool isSignedIn() {
  return currentUser != null;
}

/// =======================================
/// ROLES
/// =======================================

bool isSuperAdmin() {
  return currentUid == superAdminUid;
}

bool isModerator() {
  return moderatorUids.contains(currentUid);
}

bool isSupporter() {
  return supportUids.contains(currentUid);
}

bool isStaff() {
  return isSuperAdmin() ||
      isModerator() ||
      isSupporter();
}

/// =======================================
/// FULL ACCESS
/// =======================================

bool hasFullAdminAccess() {
  return isSuperAdmin();
}

/// =======================================
/// USER CONTROL
/// =======================================

bool canBanUsers() {
  return isSuperAdmin() || isModerator();
}

bool canDeleteUsers() {
  return isSuperAdmin();
}

bool canEditUsers() {
  return isSuperAdmin() || isModerator();
}

bool canVerifyUsers() {
  return isSuperAdmin() || isModerator();
}

bool canResetUserProfiles() {
  return isSuperAdmin();
}

/// =======================================
/// EVENT CONTROL
/// =======================================

bool canEditEvents() {
  return isSuperAdmin() || isModerator();
}

bool canDeleteEvents() {
  return isSuperAdmin() || isModerator();
}

bool canFeatureEvents() {
  return isSuperAdmin();
}

bool canCloseEvents() {
  return isSuperAdmin() || isModerator();
}

/// =======================================
/// STORY CONTROL
/// =======================================

bool canModerateStories() {
  return isSuperAdmin() || isModerator();
}

/// =======================================
/// CHAT CONTROL
/// =======================================

bool canModerateChats() {
  return isSuperAdmin() || isModerator();
}

bool canDeleteMessages() {
  return isSuperAdmin() || isModerator();
}

/// =======================================
/// REPORTS
/// =======================================

bool canHandleReports() {
  return isSuperAdmin() || isModerator();
}

/// =======================================
/// SUPPORT
/// =======================================

bool canHandleSupport() {
  return isSuperAdmin() ||
      isModerator() ||
      isSupporter();
}

bool canReplySupport() {
  return canHandleSupport();
}

bool canCloseSupportTickets() {
  return isSuperAdmin() || isModerator();
}

/// =======================================
/// NOTIFICATIONS
/// =======================================

bool canSendGlobalNotifications() {
  return isSuperAdmin();
}

/// =======================================
/// SAFETY
/// =======================================

bool canBlacklistUsers() {
  return isSuperAdmin();
}

bool canViewModerationLogs() {
  return isSuperAdmin();
}

/// =======================================
/// DATABASE CONTROL
/// =======================================

bool canAccessAdminPanel() {
  return isStaff();
}