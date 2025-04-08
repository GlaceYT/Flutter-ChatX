import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/tab1_friends_screen.dart';
import 'screens/tab2_search_screen.dart';
import 'screens/tab3_chat_screen.dart';
import 'screens/tab4_notifications_screen.dart';
import 'screens/tab5_profile_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedIndex = 0;
  String? userId;
  bool hasFriendRequests = false;

  final List<Widget> _tabs = const [
    Tab1FriendsScreen(),
    Tab2SearchScreen(),
    Tab3Screen(),
    Tab4NotificationsScreen(),
    Tab5Screen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndListenForRequests();
  }

  Future<void> _loadUserAndListenForRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('user_token');

    if (storedUserId == null) return;

    setState(() {
      userId = storedUserId;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(storedUserId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        final requests = (data['friendRequests'] as Map<String, dynamic>? ?? {});
        setState(() {
          hasFriendRequests = requests.isNotEmpty;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _tabs[_selectedIndex],
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: GNav(
                    gap: 8,
                    backgroundColor: Colors.transparent,
                    color: Colors.white70,
                    activeColor: Colors.deepPurpleAccent,
                    tabBackgroundColor: Colors.deepPurple.withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    tabs: [
                      const GButton(icon: Icons.home, text: 'Home'),
                      const GButton(icon: Icons.search, text: 'Search'),
                      const GButton(icon: Icons.favorite_border, text: 'Likes'),
                     GButton(
  icon: Icons.notifications_none,
  text: 'Alerts',
  leading: hasFriendRequests
      ? Stack(
          clipBehavior: Clip.none,
          children: const [
            Icon(Icons.notifications_none, color: Colors.white70), // 👈 white icon
            Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(
                radius: 5,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        )
      : null,
),

                      const GButton(icon: Icons.person_outline, text: 'Profile'),
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
