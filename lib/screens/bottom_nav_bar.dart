import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/free');
        break;
      case 1:
        context.go('/swap');
        break;
      case 2:
        context.go('/buy');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Free'),
        BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Buy'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
