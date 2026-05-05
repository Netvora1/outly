import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/outly_logo.dart';

import 'register_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  String msg = "";

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (loading) return;

    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      setState(() => msg = "Bitte E-Mail und Passwort eingeben");
      return;
    }

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => msg = "Login fehlgeschlagen. Prüfe deine Daten.");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      setState(() => msg = "Gib zuerst deine E-Mail ein");
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());

    if (!mounted) return;
    setState(() => msg = "Passwort-Link wurde gesendet");
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            OutlyLogo(big: true),
            const SizedBox(height: 14),
            const Text(
              "Raus aus dem Scrollen.\nRein ins echte Leben.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                height: 1.35,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),

            const AuthHeroCard(),

            const SizedBox(height: 24),

            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: "E-Mail",
                prefixIcon: Icon(Icons.mail_outline, color: C.cyan),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: hidePassword,
              decoration: InputDecoration(
                hintText: "Passwort",
                prefixIcon: const Icon(Icons.lock_outline, color: C.cyan),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
              ),
            ),
            const SizedBox(height: 18),

            GradientButton(
              text: loading ? "Einloggen..." : "Einloggen",
              onPressed: loading ? () {} : login,
            ),

            TextButton(
              onPressed: resetPassword,
              child: const Text(
                "Passwort vergessen?",
                style: TextStyle(color: C.cyan),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Noch kein Konto?",
                  style: TextStyle(color: Colors.white54),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Registrieren",
                    style: TextStyle(color: C.cyan, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            if (msg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}