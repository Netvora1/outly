import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class UploadMomentBox extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;

  const UploadMomentBox({
    super.key,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              C.cyan.withOpacity(0.18),
              C.purple.withOpacity(0.14),
              C.card,
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: C.cyan.withOpacity(0.26)),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withOpacity(0.13),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [C.cyan, C.purple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: C.cyan.withOpacity(0.25),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: uploading
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.black,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploading ? "Moment wird hochgeladen..." : "Neuen Moment teilen",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Zeig echte Highlights aus deinem Leben.",
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              uploading
                  ? Icons.cloud_upload_rounded
                  : Icons.add_photo_alternate_rounded,
              color: C.cyan,
            ),
          ],
        ),
      ),
    );
  }
}