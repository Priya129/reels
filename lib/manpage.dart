import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reelsapp/profile/profile_screen.dart';
import 'package:reelsapp/profile/profile_shimmer.dart';
import 'video_screen/add_screen.dart';
import 'global/app_colors.dart';
import 'video_screen/homepage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  String? currentUserId;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;

    final List<Widget> screens = [
      VideoFeedScreen(),
      UploadRecipeVideoScreen(),
      if (currentUserId != null)
        ProfileScreen(userId: currentUserId!, currentUserId: currentUserId!)
      else
        Center(child: ShimmerProfileScreen()),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (selectedIndex == 1 && index != 1) {
            // Handle video pause logic if necessary
          }
          setState(() {
            selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: AppColors.mainColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[300],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: isWideScreen ? 30 : 26),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: isWideScreen ? 30 : 26),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: isWideScreen ? 30 : 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
