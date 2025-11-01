import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:music_app/http/user_service.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentNickname;
  final String? currentAvatarUrl;

  const EditProfileDialog({
    super.key,
    required this.currentNickname,
    this.currentAvatarUrl,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  File? _newAvatarFile;
  Uint8List? _webAvatarBytes; // 添加Web端头像字节数据
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // 确保获取数据
      );

      if (result != null) {
        if (kIsWeb) {
          // Web端处理
          setState(() {
            _webAvatarBytes = result.files.single.bytes;
            _newAvatarFile = null; // 清除文件对象
          });
        } else {
          // 移动端处理
          if (result.files.single.path != null) {
            setState(() {
              _newAvatarFile = File(result.files.single.path!);
              _webAvatarBytes = null; // 清除Web数据
            });
          }
        }
      }
    } catch (e) {
      ToastUtils.showError(context, '选择图片失败: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // 昵称长度验证（与后端保持一致）
    final nickname = _nicknameController.text.trim();
    if (nickname.length > 10) {
      ToastUtils.showError(context, '昵称不能超过10个字符');
      return;
    }

    // 昵称格式验证（与后端保持一致）
    if (nickname.isNotEmpty &&
        !RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$').hasMatch(nickname)) {
      ToastUtils.showError(context, '昵称只能包含中文、英文、数字和下划线');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user!.id;

      final hasNicknameChanged = nickname != widget.currentNickname;
      final hasAvatarChanged =
          _newAvatarFile != null || _webAvatarBytes != null;

      // 如果没有更改任何信息，则直接关闭对话框
      if (!hasNicknameChanged && !hasAvatarChanged) {
        Navigator.of(context).pop();
        return;
      }

      // 调用 API 更新用户信息，适配Web端
      final userService = UserService();
      final response = await userService.updateUserProfile(
        userId,
        nickname: hasNicknameChanged && nickname.isNotEmpty ? nickname : null,
        avatarPath: _newAvatarFile?.path, // 移动端使用文件路径
        avatarBytes: _webAvatarBytes, // Web端使用字节数据
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!['data'];

        final updatedUser = userProvider.user!.copyWith(
          nickname: userData['nickname'] ?? userProvider.user!.nickname,
          avatarUrl: userData['avatar_url'] ?? userProvider.user!.avatarUrl,
        );

        userProvider.setUser(updatedUser, userProvider.accessToken!);
        Navigator.of(context).pop();
        ToastUtils.showSuccess(context, '个人信息更新成功');
      } else {
        // 处理后端返回的错误信息
        final errorMsg = response.data?['detail'] ?? '更新失败';
        ToastUtils.showError(context, '更新失败: $errorMsg');
      }
    } catch (e) {
      ToastUtils.showError(context, '更新失败: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑个人信息'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头像选择区域
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: ClipOval(
                    child: _newAvatarFile != null
                        ? Image.file(
                            _newAvatarFile!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                        : _webAvatarBytes !=
                              null // 添加Web端图片预览
                        ? Image.memory(
                            _webAvatarBytes!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                        : widget.currentAvatarUrl != null
                        ? Image.network(
                            ImageUtils.getFullImageUrl(widget.currentAvatarUrl),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/avatar/default.jpg'),
                          )
                        : Image.asset('assets/avatar/default.jpg'),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '点击更换头像',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),

              // 昵称输入框
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入昵称';
                  }
                  if (value.length > 20) {
                    return '昵称不能超过20个字符';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _updateProfile,
          child: _isUploading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('保存'),
        ),
      ],
    );
  }
}
