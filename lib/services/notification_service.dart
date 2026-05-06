import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendNotification({
  required String toUserId,
  required String fromUserId,
  required String type,
  required String text,
  String targetId = "",
}) async {
  if (toUserId.isEmpty) return;
  if (toUserId == fromUserId) return;

  await FirebaseFirestore.instance.collection("notifications").add({
    "toUserId": toUserId,
    "fromUserId": fromUserId,
    "type": type,
    "text": text,
    "targetId": targetId,
    "read": false,
    "createdAt": Timestamp.now(),
  });
}