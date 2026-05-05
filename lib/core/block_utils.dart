bool isBlockedByData(Map<String, dynamic>? myData, String otherUserId) {
  final blocked = List<String>.from(myData?["blockedUsers"] ?? []);
  return blocked.contains(otherUserId);
}