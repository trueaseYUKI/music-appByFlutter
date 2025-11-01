import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/pages/settings/widgets/playlist.dart';
import 'package:music_app/pages/settings/widgets/setting.dart';
import 'package:music_app/pages/settings/widgets/user_Info.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import './widgets/setting_header.dart';
import 'package:music_app/widget/info_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  // wantKeepAlive 为 true 时，组件的状态会保持，即使组件在视觉上不可见也不会被销毁
  @override
  bool get wantKeepAlive => true;

  // 用户信息模拟数据
  String nickname = '用户名';
  String email = 'user@example.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingHeader('用户信息'),
            const UserCard(),
            const SettingHeader('用户歌单'),
            const PlaylistSection(),
            const SettingHeader('设置'),
            const SettingSection(),
          ],
        ),
      ),
    );
  }

  
}
