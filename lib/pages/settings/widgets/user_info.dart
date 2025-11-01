import 'package:flutter/material.dart';
import 'package:music_app/pages/settings/dialogs/edit_profile_dialog.dart';
import 'package:music_app/pages/settings/widgets/login_dialog.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/info_card.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:music_app/models/music.dart';

class UserCard extends StatefulWidget {
  const UserCard({super.key});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 检查用户是否已登录
        if (userProvider.user == null) {
          // 用户未登录状态
          return _buildLoginPrompt();
        } else {
          // 用户已登录状态
          return _buildUserInfo(userProvider.user!);
        }
      },
    );
  }

  // 构建未登录提示UI
  Widget _buildLoginPrompt() {
    return InfoCard(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 提示图标
            Icon(Icons.account_circle, size: 80, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              '登录后享受更多功能',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '登录后可同步歌单、收藏歌曲等',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // 登录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLoginDialog,
                icon: Icon(Icons.login),
                label: Text('立即登录'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
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

  // 构建用户信息UI
  Widget _buildUserInfo(User user) {
    return InfoCard(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 用户头像
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(
                            ImageUtils.getFullImageUrl(user.avatarUrl),
                          )
                        : AssetImage('assets/avatar/default.jpg'),
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 信息容器
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoRow(Icons.person, '昵称', user.nickname ?? '未知用户'),
                    Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.email, '邮箱', user.email),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // 编辑按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEditProfileDialog(user);
                },
                icon: Icon(Icons.edit),
                label: Text('编辑个人信息'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
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

  // 显示编辑个人信息对话框
  void _showEditProfileDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProfileDialog(
          currentNickname: user.nickname,
          currentAvatarUrl: user.avatarUrl,
        );
      },
    );
  }

  // 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 前面设置一个图标
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        SizedBox(width: 12),
        // 使用流式布局
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行标题
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              SizedBox(height: 4),
              // 行内容
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 显示登录对话框
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const LoginDialog();
      },
    );
  }
}
