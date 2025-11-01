// lib/tab/tabs.dart
import 'package:music_app/models/page_cache.dart';
import 'package:music_app/pages/home.dart';
import 'package:music_app/pages/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:music_app/widget/player.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:provider/provider.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
  ];

  int _currentIndex = 0;
  final PageCacheManager _pageCache = PageCacheManager();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTapped(int index) {
    setState(() {
      _currentIndex = index;
      
      // 使用 animateToPage 实现平滑的页面切换动画
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    // 获取或创建页面
                    _pageCache.getOrCreatePage('home', () => HomePage()),
                    _pageCache.getOrCreatePage('settings', () => SettingsPage()),
                  ],
                ),
              ),
              BottomPlayer(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: _items,
            currentIndex: _currentIndex,
            onTap: _onTapped,
          ),
        );
      },
    );
  }
}