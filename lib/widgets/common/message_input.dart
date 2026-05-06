import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Nachricht schreiben...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: C.cyan),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}