import 'package:flutter/material.dart';
import 'screens/auth/auth_wrapper.dart';

class OutlyApp extends StatelessWidget {
  const OutlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AuthWrapper(),
    );
  }
}