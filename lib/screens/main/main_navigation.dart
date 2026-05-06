import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../home/home_screen.dart';
import '../create/create_activity_screen.dart';
import '../map/explore_map_screen.dart';
import '../social/chats_friends_story_screen.dart';
import '../profile/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  final screens = [
    HomeScreen(),
    ExploreMapScreen(),
    CreateActivityScreen(),
    ChatsFriendsStoryScreen(),
    ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
  ];

  void changeTab(int i) {
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: screens[index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.cyan.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: C.purple.withOpacity(0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _OutlyNavItem(
                icon: Icons.home_rounded,
                label: "Home",
                active: index == 0,
                color: C.cyan,
                onTap: () => changeTab(0),
              ),
              _OutlyNavItem(
                icon: Icons.explore_rounded,
                label: "Map",
                active: index == 1,
                color: C.green,
                onTap: () => changeTab(1),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => changeTab(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [C.purple, C.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: C.cyan.withOpacity(index == 2 ? 0.55 : 0.30),
                          blurRadius: index == 2 ? 24 : 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      index == 2 ? Icons.add_circle : Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              _OutlyNavItem(
                icon: Icons.chat_bubble_rounded,
                label: "Chats",
                active: index == 3,
                color: C.pink,
                onTap: () => changeTab(3),
              ),
              _OutlyNavItem(
                icon: Icons.person_rounded,
                label: "Profil",
                active: index == 4,
                color: C.orange,
                onTap: () => changeTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlyNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _OutlyNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: active
                ? Border.all(color: color.withOpacity(0.35))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? color : Colors.white38,
                size: active ? 25 : 23,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? color : Colors.white38,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}