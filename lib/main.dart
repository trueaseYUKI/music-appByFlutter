// lib/main.dart
import 'package:flutter/material.dart';
import 'package:music_app/http/user_service.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/tab/tabs.dart';
import 'package:music_app/routes/routes.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:music_app/res/config_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化配置
  await ConfigManager.init();

  // 初始化 UserProvider 并尝试加载用户信息
  final userProvider = UserProvider();

  // 添加短暂延迟，确保系统完全初始化
  await Future.delayed(Duration(milliseconds: 500));

  // 在这里调用 _initializeApp
  await initializeApp(userProvider); // 注意：由于在main函数中context不可用，所以传null

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PlayerProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // 使用已经实例化的用户Provider，而不是重新创建一个Provider
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> initializeApp(UserProvider userProvider) async {
  await userProvider.loadUserFromStorage();

  if (userProvider.accessToken != null && userProvider.user == null) {
    try {
      final userService = UserService();
      final response = await userService.getCurrentUser();

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!['data'];
        final user = User.fromJson(userData);
        userProvider.setUser(user, userProvider.accessToken!);
      }
    } catch (e) {
      print('自动登录失败: $e');
      userProvider.clearUser();
    }
  }
}

// 在 main.dart 中修改 MyApp 组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Yuki Music',
          debugShowCheckedModeBanner: false,
          // 控制主题
          theme: themeProvider.getTheme(),
          home: Container(
            decoration: BoxDecoration(
              image: themeProvider.selectedBackground.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(themeProvider.selectedBackground),
                      fit: BoxFit.cover,
                      opacity: themeProvider.backgroundOpacity,
                    )
                  : null,
              color: themeProvider.selectedBackground.isEmpty
                  ? (themeProvider.selectedColor.withValues(alpha: 0.15))
                  : null,
            ),
            child: Tabs(),
          ),
          initialRoute: '/',
          onGenerateRoute: onGenerateRoute,
        );
      },
    );
  }
}
