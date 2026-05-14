import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_colors.dart';
import '../../widgets/auth/gradient_button.dart';

import 'register_screen.dart';

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
  bool rememberMe = true;
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

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.text.trim(),
    );

    if (!mounted) return;
    setState(() => msg = "Passwort-Link wurde gesendet");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const OutlyTextHero(),

                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              C.card.withOpacity(0.96),
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: C.pink.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: C.pink.withOpacity(0.30),
                              blurRadius: 42,
                              offset: const Offset(0, 18),
                            ),
                            BoxShadow(
                              color: C.purple.withOpacity(0.24),
                              blurRadius: 48,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                          child: Column(
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "WILLKOMMEN ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "ZURÜCK",
                                      style: TextStyle(
                                        color: C.pink,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 7),

                              const Text(
                                "Schön, dass du wieder da bist!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 22),

                              _PremiumField(
                                controller: email,
                                hint: "E-Mail",
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 13),

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
                                    color: C.pink.withOpacity(0.85),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        rememberMe = !rememberMe;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      width: 23,
                                      height: 23,
                                      decoration: BoxDecoration(
                                        color: rememberMe
                                            ? C.purple2
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: rememberMe
                                              ? C.purple2
                                              : Colors.white30,
                                        ),
                                        boxShadow: rememberMe
                                            ? [
                                                BoxShadow(
                                                  color: C.purple
                                                      .withOpacity(0.45),
                                                  blurRadius: 14,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: rememberMe
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 17,
                                            )
                                          : null,
                                    ),
                                  ),

                                  const SizedBox(width: 9),

                                  const Text(
                                    "Angemeldet bleiben",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const Spacer(),

                                  TextButton(
                                    onPressed: resetPassword,
                                    child: const Text(
                                      "Passwort vergessen?",
                                      style: TextStyle(
                                        color: C.pink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              GradientButton(
                                text: loading ? "Einloggen..." : "EINLOGGEN  →",
                                onPressed: loading ? () {} : login,
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      "NOCH KEIN KONTO?",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: C.pink.withOpacity(0.55),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: C.pink.withOpacity(0.14),
                                        blurRadius: 22,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: C.purple2,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "JETZT REGISTRIEREN",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (msg.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: msg.contains("gesendet")
                                          ? C.green.withOpacity(0.35)
                                          : Colors.redAccent.withOpacity(0.32),
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
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Echte Pläne. Echte Leute. Echte Momente.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Icon(
                        Icons.favorite_border_rounded,
                        color: C.pink,
                        size: 30,
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

class OutlyTextHero extends StatelessWidget {
  const OutlyTextHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Outly",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 58,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: "WENIGER SCROLLEN, ",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              TextSpan(
                text: "MEHR ERLEBEN.",
                style: TextStyle(
                  color: C.pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF03030A),
                  Color(0xFF120725),
                  Color(0xFF05040B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        Positioned(
          top: 120,
          left: -120,
          right: -120,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(300),
              border: Border.all(
                color: C.purple.withOpacity(0.16),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: C.purple.withOpacity(0.22),
                  blurRadius: 46,
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: -130,
          left: -90,
          child: _GlowOrb(
            size: 310,
            color: C.purple,
            opacity: 0.26,
          ),
        ),

        Positioned(
          top: 180,
          right: -130,
          child: _GlowOrb(
            size: 320,
            color: C.pink,
            opacity: 0.20,
          ),
        ),

        Positioned(
          bottom: -120,
          left: 20,
          child: _GlowOrb(
            size: 280,
            color: C.purple2,
            opacity: 0.17,
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
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: C.purple.withOpacity(0.10),
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
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.purple.withOpacity(0.20),
              boxShadow: [
                BoxShadow(
                  color: C.purple.withOpacity(0.25),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(icon, color: C.pink, size: 21),
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
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
      Offset(size.width * 0.12, size.height * 0.12),
      Offset(size.width * 0.30, size.height * 0.22),
      Offset(size.width * 0.67, size.height * 0.09),
      Offset(size.width * 0.88, size.height * 0.28),
      Offset(size.width * 0.18, size.height * 0.62),
      Offset(size.width * 0.58, size.height * 0.76),
      Offset(size.width * 0.91, size.height * 0.68),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}