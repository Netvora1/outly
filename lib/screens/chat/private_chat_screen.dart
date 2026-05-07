import 'package:flutter/material.dart';

class PrivateChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUsername;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Text(
            "Chat mit @$otherUsername",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}