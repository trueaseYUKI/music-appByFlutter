import 'package:flutter/material.dart';
import 'package:music_app/http/dio_client.dart';
import 'package:music_app/pages/settings/widgets/theme_settings_dialog.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/widget/info_card.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';

class SettingSection extends StatelessWidget {
  const SettingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showThemeSettings(context);
                },
                label: const Text('主题设置'),
                icon: const Icon(Icons.color_lens),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                label: const Text('退出登录'),
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    // 导入theme的Provider
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      // 给予其上下文
      context: context,
      builder: (BuildContext context) {
        return ThemeSettingsDilog();
      },
    );
  }

  // 退出登录功能
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认退出'),
          content: Text('您确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 添加退出登录的逻辑
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                userProvider.logout(); // 调用 UserProvider 中的 logout 方法

                // 清除 DioClient 中的 access token
                DioClient.setAccessToken('');

                ToastUtils.showSuccess(context, "已退出登录");
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
