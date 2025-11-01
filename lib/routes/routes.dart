// lib/routes/routes.dart
import '../pages/home.dart';
import '../pages/playing.dart';
import '../pages/search/search.dart';
import '../pages/settings/settings.dart';
import '../pages/upload.dart';
import '../pages/playlist_musics.dart';
import 'package:flutter/material.dart';

Map<String, Widget Function(BuildContext)> routes = {
  '/': (context) => HomePage(),
  '/settings': (context) => SettingsPage(),
  '/search': (context) => SearchPage(),
  '/play': (context) => PlayingPage(),
  '/upload': (context) => UploadPage(),
};

// 特殊处理需要参数的路由
var onGenerateRoute = (settings) {
  final String? name = settings.name;
  final Widget Function(BuildContext)? pageContentBuilder = routes[name];

  if (pageContentBuilder != null) {
    final Route route = MaterialPageRoute(
      builder: (context) => pageContentBuilder(context),
    );
    return route;
  } else if (name == '/playlist') {
    // 处理 playlist 路由
    final playlistId = settings.arguments is int
        ? settings.arguments as int
        : 0;
    final Route route = MaterialPageRoute(
      builder: (context) => PlaylistMusicsPage(playlistId: playlistId),
    );
    return route;
  }
  return null;
};
