import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/auth/loading_screen.dart';
import 'package:health_tracker/ui/screens/diary/diary_screen.dart';
import 'package:health_tracker/ui/screens/home/home_screen.dart';
import 'package:health_tracker/ui/screens/plans/plans_screen.dart';
import 'package:health_tracker/ui/screens/together/together_screen.dart';
import 'package:health_tracker/ui/widgets/appbar_widget.dart';
import 'package:health_tracker/ui/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 1;
  PageController pageController = PageController();
  bool isLoading = true;


  final List<Widget> _widgetOption = const <Widget>[
    PlansScreen(),
    HomeScreen(),
    DiaryScreen(),
    TogetherScreen(),
  ];

  final List<String> _screenTitles = const <String>[
    'Plans',
    'Health Tracker',
    'Diary',
    'My Tree',
  ];

  static const Color treePrimary = Color(0xFF5CE4D1);
  static const Color treeBackground = Color(0xFF1A3A2F);
  static const Color treeNavBackground = Color(0xFF162D25);

  @override
  void initState() {
    super.initState();
    addData();
    pageController = PageController(initialPage: 1);
  }

  Future<void> addData() async {
    setState(() {
      isLoading = true;
    });
    try {
      UserProvider userProvider =
          Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUser();
      if (mounted) {
        await Provider.of<TreeProvider>(context, listen: false).refresh();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoaded) {
          setState(() {
            isLoading = false;
          });
        } else {
          debugPrint('User not loaded yet, retrying...');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            addData();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenTitles = [
      l10n.plans,
      l10n.home,
      l10n.diary,
      l10n.together,
    ];

    final isTreeScreen = _selectedIndex == 3;

    return isLoading
        ? const LoadingScreen()
        : Scaffold(
            appBar: CustomAppBar(
              title: screenTitles[_selectedIndex],
              treeMode: isTreeScreen,
              treePrimary: treePrimary,
              treeBackground: treeBackground,
            ),
            drawer: isTreeScreen ? null : const NavDrawer(),
            body: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              children: _widgetOption,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            bottomNavigationBar: _TreeBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              treeMode: isTreeScreen,
              treePrimary: treePrimary,
              treeNavBackground: treeNavBackground,
            ),
          );
  }
}

class _TreeBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool treeMode;
  final Color treePrimary;
  final Color treeNavBackground;

  const _TreeBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.treeMode,
    required this.treePrimary,
    required this.treeNavBackground,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = treeMode
        ? treeNavBackground.withOpacity(0.95)
        : Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white;

    final selectedColor = treeMode ? treePrimary : Colors.red;
    final unselectedColor = treeMode ? Colors.white54 : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: treeMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.fitness_center, 'Plans', selectedColor, unselectedColor),
              _buildNavItem(1, Icons.home, 'Home', selectedColor, unselectedColor),
              _buildNavItem(2, Icons.leaderboard, 'Diary', selectedColor, unselectedColor),
              _buildNavItem(3, Icons.park, 'Tree', selectedColor, unselectedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color selectedColor, Color unselectedColor) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: selectedColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: isSelected ? 28 : 24,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
