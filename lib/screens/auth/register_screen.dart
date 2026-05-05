import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/auth/auth_hero_card.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/outly_logo.dart';
import '../../main.dart';
import '../../widgets/auth/auth_check_tile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final city = TextEditingController();
  final birthDate = TextEditingController();

  bool ageAccepted = false;
  bool legalAccepted = false;
  bool hidePassword = true;
  bool loading = false;
  String msg = "";

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    city.dispose();
    birthDate.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (loading) return;

    final parsedBirthDate = parseBirthDate(birthDate.text.trim());

    if (username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        city.text.trim().isEmpty ||
        birthDate.text.trim().isEmpty) {
      setState(() => msg = "Bitte alle Felder ausfüllen");
      return;
    }

    if (password.text.trim().length < 6) {
      setState(() => msg = "Passwort muss mindestens 6 Zeichen haben");
      return;
    }

    if (parsedBirthDate == null) {
      setState(() => msg = "Bitte gültiges Geburtsdatum eingeben");
      return;
    }

    final age = calculateAge(parsedBirthDate);

    if (age < 14) {
      setState(() => msg = "Du musst mindestens 14 Jahre alt sein");
      return;
    }

    if (!ageAccepted) {
      setState(() => msg = "Bitte bestätige, dass du mindestens 14 bist");
      return;
    }

    if (!legalAccepted) {
      setState(() => msg = "Bitte akzeptiere AGB und Datenschutz");
      return;
    }

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "username": username.text.trim(),
        "email": email.text.trim(),
        "city": city.text.trim(),
        "birthDate": birthDate.text.trim(),
        "age": age,
        "isMinor": age < 18,
        "bio": "Ich bin neu bei Outly 🔥",
        "photoUrl": "",
        "coverUrl": "",
        "verified": false,
        "identityVerified": false,
        "ageVerified": false,
        "creator": false,
        "creatorPending": false,
        "creatorLevel": "none",
        "creatorEarnings": 0,
        "creatorReferralCode": "",
        "creatorViews": 0,
        "creatorClicks": 0,
        "creatorPayoutEnabled": false,
        "verificationPending": false,
        "followers": [],
        "following": [],
        "blockedUsers": [],
        "blockedBy": [],
        "interests": ["Sport", "Chill", "Gaming"],
        "trustScore": 100,
        "riskFlags": [],
        "reportedCount": 0,
        "isBanned": false,
        "createdAt": Timestamp.now(),
        "updatedAt": Timestamp.now(),
      });

      await cred.user!.sendEmailVerification();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => msg = "Registrierung fehlgeschlagen");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            OutlyLogo(big: true),
            const SizedBox(height: 12),
            const Text(
              "Erstell dein Profil.\nFinde echte Pläne.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 22),

            const AuthHeroCard(compact: true),

            const SizedBox(height: 22),

            TextField(
              controller: username,
              decoration: const InputDecoration(
                hintText: "Benutzername",
                prefixIcon: Icon(Icons.person_outline, color: C.cyan),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextField(
              controller: city,
              decoration: const InputDecoration(
                hintText: "Stadt z.B. Wien",
                prefixIcon: Icon(Icons.location_on_outlined, color: C.cyan),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: birthDate,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                hintText: "Geburtsdatum z.B. 01.01.2005",
                prefixIcon: Icon(Icons.cake_outlined, color: C.cyan),
              ),
            ),

            const SizedBox(height: 14),

            AuthCheckTile(
              value: ageAccepted,
              color: C.purple,
              icon: Icons.verified_user_outlined,
              title: "Ich bestätige, dass ich mindestens 14 Jahre alt bin.",
              onChanged: (v) => setState(() => ageAccepted = v),
            ),

            const SizedBox(height: 10),

            AuthCheckTile(
              value: legalAccepted,
              color: C.cyan,
              icon: Icons.description_outlined,
              title: "Ich akzeptiere AGB und Datenschutz.",
              onChanged: (v) => setState(() => legalAccepted = v),
              onTapText: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalTextPage(
                      title: "Nutzungsbedingungen",
                      text: termsText,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            GradientButton(
              text: loading ? "Konto wird erstellt..." : "Konto erstellen 🔥",
              onPressed: loading ? () {} : register,
            ),

            if (msg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}