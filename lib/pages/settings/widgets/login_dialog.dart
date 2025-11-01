import 'package:flutter/material.dart';
import 'package:music_app/http/dio_client.dart';
import 'package:music_app/http/user_service.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final UserService _userService = UserService(); // 添加 UserService 实例

  // 添加倒计时相关变量
  int _countdown = 0;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  // 初始化倒计时
  _initCountdown() async {
    _prefs = await SharedPreferences.getInstance();
    final lastTimestamp = _prefs.getInt('verification_code_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 如果时间差小于120秒，则继续倒计时
    final difference = now - lastTimestamp;
    if (difference < 120000 && lastTimestamp > 0) {
      // 计算剩余时间并继续倒计时
      int remainingTime = 120 - (difference ~/ 1000);
      if (remainingTime > 0) {
        _startCountdown(remainingTime);
      } else {
        // 时间已过期，清除时间戳
        _prefs.remove('verification_code_timestamp');
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  // 开始倒计时
  // 开始倒计时
  _startCountdown(int seconds) {
    setState(() {
      _countdown = seconds;
    });

    // 只有当是新的120秒倒计时时才设置时间戳
    if (seconds == 120) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _prefs.setInt('verification_code_timestamp', timestamp);
    }

    // 倒计时循环
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 1 && mounted) {
        _startCountdown(_countdown - 1); // 每次减少1秒
      } else if (mounted) {
        setState(() {
          _countdown = 0;
        });
        // 不要在这里清除时间戳，保留到最后
      }
    });
  }

  // 发送验证码
  _sendVerificationCode() async {
    try {
      // 调用发送验证码API
      final response = await _userService.sendCode(emailController.text);

      // 打印发送验证码的结果
      print('发送验证码结果: ${response.data}');

      // 检查响应状态
      if (response.statusCode == 200) {
        // 开始120秒倒计时
        _startCountdown(120);
        ToastUtils.showSuccess(context, '验证码已发送');
      } else {
        ToastUtils.showError(
          context,
          '发送验证码失败: ${response.data?['detail'] ?? '未知错误'}',
        );
      }
    } catch (e) {
      print('发送验证码异常: $e');
      ToastUtils.showError(context, '发送验证码失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('用户登录'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: '邮箱地址',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱地址';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: '验证码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: TextButton(
                  onPressed: _countdown > 0
                      ? null
                      : () {
                          if (emailController.text.isNotEmpty &&
                              RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(emailController.text)) {
                            _sendVerificationCode();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请先输入有效的邮箱地址')),
                            );
                          }
                        },
                  child: _countdown > 0
                      ? Text('${_countdown}s后重新获取')
                      : Text('获取'),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入验证码';
                }
                if (value.length < 4) {
                  return '验证码至少4位';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              // 调用登录方法
              _handleLogin();
            }
          },
          child: Text('登录'),
        ),
      ],
    );
  }

  void _handleLogin() async {
    try {
      // 调用登录API
      final response = await _userService.login(
        emailController.text,
        codeController.text,
      );

      print('登录结果: ${response.data}');

      // 检查响应状态
      if (response.statusCode == 200 && response.data != null) {
        // 正确地从嵌套结构中获取用户数据
        final responseData = response.data!['data'];
        if (responseData == null) {
          throw Exception('登录响应数据为空');
        }

        final userData = responseData['user'];
        final accessToken = responseData['access_token'];

        // 添加空值检查
        if (userData == null) {
          throw Exception('用户数据为空');
        }

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('访问令牌为空');
        }

        // 创建用户对象，添加默认值处理
        final newUser = User(
          id: userData['id'] ?? 0,
          email: userData['email'] ?? '',
          nickname:
              userData['nickname'] ??
              (userData['email'] != null
                  ? userData['email'].split('@')[0]
                  : '未知用户'),
          avatarUrl: userData['avatar_url'] ?? 'assets/avatar/default.jpg',
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
          updatedAt: userData['updated_at'] != null
              ? DateTime.parse(userData['updated_at'])
              : DateTime.now(),
          isDeleted: userData['is_deleted'] ?? false,
          playlists:
              (userData['playlists'] as List<dynamic>?)
                  ?.map(
                    (e) => e != null
                        ? Playlist.fromJson(e as Map<String, dynamic>)
                        : Playlist.empty(),
                  )
                  .toList() ??
              [],
        );

        // 更新 UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(newUser, accessToken);

        // 设置 DioClient 的 access token
        DioClient.setAccessToken(accessToken);

        Navigator.of(context).pop();
        ToastUtils.showSuccess(context, '登录成功');
      } else {
        ToastUtils.showError(
          context,
          '登录失败: ${response.data?['detail'] ?? '未知错误'}',
        );
      }
    } catch (e) {
      print('登录异常: $e');
      ToastUtils.showError(context, '登录失败: $e');
    }
  }
}
