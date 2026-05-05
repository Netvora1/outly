import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../../core/app_colors.dart';

import '../../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (user == null) return  LoginScreen();
        if (!user.emailVerified) return const VerifyEmailScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                backgroundColor: C.bg,
                body: Center(child: CircularProgressIndicator(color: C.cyan)),
              );
            }

            final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};

            if (data["isBanned"] == true) {
              return const BannedScreen();
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: Colors.redAccent, size: 80),
          const SizedBox(height: 18),
          const Text(
            "Account gesperrt",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dein Account wurde aus Sicherheitsgründen gesperrt.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: "Abmelden",
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}


class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool loading = false;
  String msg = "";

  Future<void> checkVerification() async {
    setState(() {
      loading = true;
      msg = "";
    });

    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    setState(() => loading = false);

    if (refreshedUser?.emailVerified == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
    } else {
      setState(() {
        msg = "Noch nicht bestätigt. Öffne den Link in deiner E-Mail und versuch es nochmal.";
      });
    }
  }

  Future<void> resendEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      msg = "Bestätigungs-Mail wurde erneut gesendet. Prüfe auch deinen Spam-Ordner.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OutlyLogo(big: true),
          const SizedBox(height: 26),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: C.cyan.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: C.cyan.withOpacity(0.18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: C.cyan, size: 62),
                const SizedBox(height: 16),
                const Text(
                  "E-Mail bestätigen",
                  style: TextStyle(
                    color: C.cyan,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Wir haben dir einen Bestätigungslink geschickt. Öffne die Mail, bestätige deine Adresse und komm dann zurück zu Outly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tipp: Schau auch im Spam-Ordner nach.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 22),

                GradientButton(
                  text: loading ? "Prüfe..." : "Ich habe bestätigt",
                  onPressed: loading ? () {} : checkVerification,
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: resendEmail,
                  child: const Text(
                    "E-Mail nochmal senden",
                    style: TextStyle(color: C.cyan),
                  ),
                ),

                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text(
                    "Zurück zum Login",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                if (msg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  final Widget child;
  final bool showBack;

  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: showBack ? AppBar(backgroundColor: C.bg, elevation: 0) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [C.purple.withOpacity(0.22), C.bg],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}