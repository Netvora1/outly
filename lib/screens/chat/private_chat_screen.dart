import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../profile/user_profile_screen.dart';

import 'dart:io';

import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

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
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();
  final AudioRecorder recorder = AudioRecorder();

bool recording = false;
String? recordingPath;

  bool sending = false;

  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? "";

  String get chatId {
    final ids = [myUid, widget.otherUserId]..sort();
    return ids.join("_");
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    inputFocus.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);
    messageController.clear();

    try {
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
        "type": "text",
      });

      await _scrollToBottom();
    } catch (e) {
      debugPrint("Private Chat Send Error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nachricht konnte nicht gesendet werden.")),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

Future<void> toggleVoiceRecording() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || sending) return;

  try {
    if (!recording) {
      final dir = await getTemporaryDirectory();

      final path =
          "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      if (await recorder.hasPermission()) {
        await recorder.start(
          RecordConfig(),
          path: path,
        );

        setState(() {
          recording = true;
          recordingPath = path;
        });
      }
    } else {
      final path = await recorder.stop();

      setState(() {
        recording = false;
      });

      if (path == null) return;

      final chatRef = FirebaseFirestore.instance
          .collection("privateChats")
          .doc(chatId);

      final msgRef = chatRef.collection("messages").doc();

      final now = Timestamp.now();

      await chatRef.set({
        "participants": [myUid, widget.otherUserId],
        "updatedAt": now,
        "lastMessage": "🎙️ Sprachnachricht",
        "lastMessageTime": now,
        "lastSenderId": myUid,
      }, SetOptions(merge: true));

      await msgRef.set({
        "senderId": myUid,
        "receiverId": widget.otherUserId,
        "text": "",
        "createdAt": now,
        "seen": false,
        "type": "voice",
        "voicePath": path,
      });

      await _scrollToBottom();
    }
  } catch (e) {
    debugPrint("Voice Error: $e");

    setState(() {
      recording = false;
    });
  }
}

  Future<void> sendVoicePlaceholder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sending) return;

    FocusScope.of(context).unfocus();
    setState(() => sending = true);

    try {
      final chatRef =
          FirebaseFirestore.instance.collection("privateChats").doc(chatId);

      final msgRef = chatRef.collection("messages").doc();
      final now = Timestamp.now();

      await chatRef.set({
        "participants": [myUid, widget.otherUserId],
        "updatedAt": now,
        "lastMessage": "🎙️ Sprachnachricht",
        "lastMessageTime": now,
        "lastSenderId": myUid,
        "seenBy": [myUid],
      }, SetOptions(merge: true));

      await msgRef.set({
        "senderId": myUid,
        "receiverId": widget.otherUserId,
        "text": "",
        "createdAt": now,
        "seen": false,
        "type": "voice",
        "voiceUrl": "",
        "duration": 0,
      });

      await _scrollToBottom();
    } catch (e) {
      debugPrint("Voice Placeholder Error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sprachnachricht konnte nicht erstellt werden."),
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 80));

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void openProfile() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.otherUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (myUid.isEmpty) {
      return const Scaffold(
        backgroundColor: C.bg,
        body: Center(
          child: Text(
            "Nicht angemeldet.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    final messagesRef = FirebaseFirestore.instance
        .collection("privateChats")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt", descending: true);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: C.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -0.95),
                    radius: 1.2,
                    colors: [
                      C.purple.withOpacity(0.18),
                      C.bg,
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ChatHeader(
                    username: widget.otherUsername,
                    otherUserId: widget.otherUserId,
                    onBack: () => Navigator.pop(context),
                    onProfileTap: openProfile,
                  ),
                  const _SafetyBox(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: messagesRef.snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(
                            child: Text(
                              "Chat konnte nicht geladen werden.",
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: C.cyan),
                          );
                        }

                        final docs = snap.data!.docs;

                        if (docs.isEmpty) {
                          return const _EmptyChatState();
                        }

                        return ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            14,
                            10,
                            14,
                            18 + media.padding.bottom,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            final isMe = data["senderId"] == myUid;
                            final text = (data["text"] ?? "").toString();
                            final createdAt = data["createdAt"];
                            final type = (data["type"] ?? "text").toString();

                            return _ChatBubble(
                              text: text,
                              isMe: isMe,
                              createdAt: createdAt,
                              type: type,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: keyboard),
                    child: _ChatInput(
                      controller: messageController,
                      focusNode: inputFocus,
                      sending: sending,
                      onSend: sendMessage,
                      onVoice: toggleVoiceRecording,
                      bottomSafe: media.padding.bottom,
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

class _ChatHeader extends StatelessWidget {
  final String username;
  final String otherUserId;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  const _ChatHeader({
    required this.username,
    required this.otherUserId,
    required this.onBack,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : "?";

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        border: Border(
          bottom: BorderSide(color: C.cyan.withOpacity(0.18)),
        ),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [C.cyan, C.purple, C.pink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.28),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, snap) {
                  String photoUrl = "";

                  if (snap.hasData && snap.data!.data() != null) {
                    final data = snap.data!.data() as Map<String, dynamic>;
                    photoUrl = (data["photoUrl"] ?? "").toString().trim();
                  }

                  return Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: C.card2,
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                firstLetter,
                                style: const TextStyle(
                                  color: C.cyan,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: C.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: C.bg, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: C.green.withOpacity(0.55),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "@$username",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: C.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: C.green.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          "Online • Safety aktiv",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: "Profil",
            onPressed: onProfileTap,
            icon: const Icon(
              Icons.person_rounded,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBox extends StatelessWidget {
  const _SafetyBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: C.cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: C.cyan.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: C.cyan.withOpacity(0.07),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: C.cyan.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: C.cyan, size: 20),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              "Safety aktiv: Teile keine privaten Daten und melde verdächtige Nachrichten.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: C.card.withOpacity(0.78),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withOpacity(0.08),
              blurRadius: 22,
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_rounded, color: C.cyan, size: 40),
            SizedBox(height: 12),
            Text(
              "Noch keine Nachrichten",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Sag einfach hi 👋",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final dynamic createdAt;
  final String type;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.createdAt,
    required this.type,
  });

  String get timeText {
    if (createdAt is! Timestamp) return "";
    final date = (createdAt as Timestamp).toDate();
    final h = date.hour.toString().padLeft(2, "0");
    final m = date.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(isMe ? 24 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 24),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 54 : 0,
          right: isMe ? 0 : 54,
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [C.cyan, C.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : C.card,
          borderRadius: bubbleRadius,
          border: isMe ? null : Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color:
                  isMe ? C.cyan.withOpacity(0.18) : Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == "voice")
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: isMe ? Colors.black : C.cyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Sprachnachricht",
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 15.8,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (timeText.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                timeText,
                style: TextStyle(
                  color: isMe ? Colors.black54 : Colors.white38,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final double bottomSafe;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onVoice,
    required this.bottomSafe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 7, 12, bottomSafe + 10),
      decoration: BoxDecoration(
        color: C.bg.withOpacity(0.98),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 2),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!sending) onSend();
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: "Nachricht schreiben...",
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: C.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: C.cyan.withOpacity(0.42),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: sending
                      ? [Colors.white24, Colors.white10]
                      : [C.cyan, C.purple],
                ),
                boxShadow: sending
                    ? []
                    : [
                        BoxShadow(
                          color: C.cyan.withOpacity(0.35),
                          blurRadius: 22,
                        ),
                      ],
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}