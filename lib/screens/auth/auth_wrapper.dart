import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

import '../../main.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (user == null) {
          return LoginScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        return const MainNavigation();
      },
    );
  }
}