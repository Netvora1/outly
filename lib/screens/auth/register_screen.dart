import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_colors.dart';
import '../../core/date_helpers.dart';
import '../../core/legal_texts.dart';
import '../../widgets/auth/gradient_button.dart';

import '../legal/legal_text_page.dart';
import 'auth_wrapper.dart';

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

      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .set({
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

  void openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalTextPage(
          title: "Nutzungsbedingungen",
          text: termsText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          const _RegisterBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [C.purple, C.purple2, C.pink],
                        ).createShader(bounds),
                        child: const Text(
                          "JOIN OUTLY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            height: 1,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        "Erstell dein Profil.\nFinde echte Pläne.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            colors: [
                              C.purple.withOpacity(0.34),
                              C.card.withOpacity(0.96),
                              C.pink.withOpacity(0.16),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: C.purple.withOpacity(0.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: C.purple.withOpacity(0.22),
                              blurRadius: 42,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: C.pink.withOpacity(0.12),
                              blurRadius: 34,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Column(
                            children: [
                              const _RegisterHeroStrip(),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    _PremiumField(
                                      controller: username,
                                      hint: "Benutzername",
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _PremiumField(
                                      controller: email,
                                      hint: "E-Mail",
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _PremiumField(
                                      controller: password,
                                      hint: "Passwort",
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: hidePassword,
                                      suffix: IconButton(
                                        icon: Icon(
                                          hidePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white38,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            hidePassword = !hidePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PremiumField(
                                            controller: city,
                                            hint: "Stadt",
                                            icon: Icons.location_on_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _PremiumField(
                                            controller: birthDate,
                                            hint: "Geburtsdatum",
                                            icon: Icons.cake_outlined,
                                            keyboardType: TextInputType.datetime,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _PremiumCheckTile(
                                      value: ageAccepted,
                                      color: C.purple,
                                      icon: Icons.verified_user_outlined,
                                      title:
                                          "Ich bestätige, dass ich mindestens 14 Jahre alt bin.",
                                      onTap: () {
                                        setState(() {
                                          ageAccepted = !ageAccepted;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _PremiumCheckTile(
                                      value: legalAccepted,
                                      color: C.pink,
                                      icon: Icons.description_outlined,
                                      title:
                                          "Ich akzeptiere AGB und Datenschutz.",
                                      onTap: () {
                                        setState(() {
                                          legalAccepted = !legalAccepted;
                                        });
                                      },
                                      textTap: openTerms,
                                    ),
                                    const SizedBox(height: 18),
                                    GradientButton(
                                      text: loading
                                          ? "Konto wird erstellt..."
                                          : "Konto erstellen 🔥",
                                      onPressed: loading ? () {} : register,
                                    ),
                                    if (msg.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.07),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: Colors.redAccent
                                                .withOpacity(0.28),
                                          ),
                                        ),
                                        child: Text(
                                          msg,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF05040B),
                  Color(0xFF16082E),
                  Color(0xFF05040B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: -130,
          left: -90,
          child: _GlowOrb(
            size: 310,
            color: C.purple,
            opacity: 0.28,
          ),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: _GlowOrb(
            size: 330,
            color: C.purple2,
            opacity: 0.18,
          ),
        ),
        Positioned(
          bottom: -130,
          left: 40,
          child: _GlowOrb(
            size: 300,
            color: C.pink,
            opacity: 0.18,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StarsPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: C.purple.withOpacity(0.26)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RegisterHeroStrip extends StatelessWidget {
  const _RegisterHeroStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.purple.withOpacity(0.42),
            Colors.black.withOpacity(0.30),
            C.pink.withOpacity(0.22),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: C.purple.withOpacity(0.20)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [C.purple, C.pink],
              ),
              boxShadow: [
                BoxShadow(
                  color: C.purple.withOpacity(0.28),
                  blurRadius: 22,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dein echtes Social-Profil.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Sicher registrieren und echte Leute treffen.",
                  style: TextStyle(
                    color: Colors.white60,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }
}

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _PremiumField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(icon, color: C.purple2),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}

class _PremiumCheckTile extends StatelessWidget {
  final bool value;
  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final VoidCallback? textTap;

  const _PremiumCheckTile({
    required this.value,
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: textTap ?? onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color:
              value ? color.withOpacity(0.13) : Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                value ? color.withOpacity(0.55) : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value ? color : Colors.white30,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 17,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08);

    final points = <Offset>[
      Offset(size.width * 0.14, size.height * 0.16),
      Offset(size.width * 0.28, size.height * 0.28),
      Offset(size.width * 0.70, size.height * 0.14),
      Offset(size.width * 0.86, size.height * 0.32),
      Offset(size.width * 0.18, size.height * 0.72),
      Offset(size.width * 0.62, size.height * 0.78),
      Offset(size.width * 0.91, size.height * 0.68),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}