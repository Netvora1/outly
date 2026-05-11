import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../profile/user_profile_screen.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  String get myUid => FirebaseAuth.instance.currentUser!.uid;

  String get chatId {
    final ids = [myUid, widget.otherUserId]..sort();
    return ids.join("_");
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    final chatRef =
        FirebaseFirestore.instance.collection("privateChats").doc(chatId);

    final msgRef = chatRef.collection("messages").doc();

    final now = Timestamp.now();

    await chatRef.set({
      "participants": [myUid, widget.otherUserId],
      "updatedAt": now,
      "lastMessage": text,
      "lastMessageTime": now,
      "lastSenderId": myUid,
      "seenBy": [myUid],
    }, SetOptions(merge: true));

    await msgRef.set({
      "senderId": myUid,
      "receiverId": widget.otherUserId,
      "text": text,
      "createdAt": now,
      "seen": false,
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.otherUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection("privateChats")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      backgroundColor: C.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(color: C.cyan.withOpacity(0.18)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  GestureDetector(
                    onTap: openProfile,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: C.card,
                      child: Text(
                        widget.otherUsername.isNotEmpty
                            ? widget.otherUsername[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          color: C.cyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: openProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "@${widget.otherUsername}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            "Private Chat • Safety aktiv",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.cyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.cyan.withOpacity(0.18)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: C.cyan, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Safety aktiv: Teile keine privaten Daten, triff dich nur an sicheren Orten und melde verdächtige Nachrichten.",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: C.cyan),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Noch keine Nachrichten.\nSag einfach hi 👋",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data["senderId"] == myUid;
                      final text = (data["text"] ?? "").toString();

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [C.cyan, C.purple],
                                  )
                                : null,
                            color: isMe ? null : C.card,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            border: isMe
                                ? null
                                : Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isMe ? Colors.black : Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
                top: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Nachricht schreiben...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: C.card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [C.cyan, C.purple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.cyan.withOpacity(0.25),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}