// 修改 lib/pages/settings/dialogs/create_playlist_dialog.dart 文件

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/http/playlist_service.dart'; // 添加导入
import 'package:music_app/widget/toast_utils.dart'; // 添加导入
import 'package:provider/provider.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final titleController = TextEditingController();
  File? coverImage;
  final formKey = GlobalKey<FormState>();
  bool _isCreating = false; // 添加状态变量

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('创建歌单'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '歌单名称',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入歌单名称';
                }
                if (value.length > 25) {
                  // 添加长度限制
                  return '歌单名称不能超过25个字符';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // 封面上传区域
            GestureDetector(
              onTap: _isCreating
                  ? null
                  : () async {
                      // 添加创建状态判断
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image, withData: true);

                      if (result != null) {
                        setState(() {
                          coverImage = File(result.files.single.path!);
                        });
                      }
                    },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(coverImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('上传封面', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating
              ? null
              : () {
                  // 添加创建状态判断
                  Navigator.of(context).pop();
                },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isCreating
              ? null
              : () async {
                  // 添加创建状态判断
                  if (formKey.currentState!.validate()) {
                    // 创建新歌单
                    await _createPlaylist(); // 调用创建方法
                  }
                },
          child:
              _isCreating // 根据状态显示不同内容
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('创建'),
        ),
      ],
    );
  }

  // 创建歌单的方法
  // 创建歌单的方法
  Future<void> _createPlaylist() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final playlistService = PlaylistService();

      // 使用 FormData 上传
      final formData = FormData();
      formData.fields.add(MapEntry('name', titleController.text));

      // 如果有封面图片，则添加到 FormData
      if (coverImage != null) {
        final coverFile = await MultipartFile.fromFile(
          coverImage!.path,
          filename: coverImage!.path.split('/').last,
        );
        formData.files.add(MapEntry('cover_file', coverFile));
      }

      // 调用网络请求创建歌单
      final response = await playlistService.createPlaylistWithFormData(
        formData: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final playlistData = response.data!['data'];

        // 创建 Playlist 对象
        final newPlaylist = Playlist.fromJson(playlistData);

        // 更新 UserProvider
        userProvider.addPlaylist(newPlaylist);

        if (mounted) {
          Navigator.of(context).pop();
          ToastUtils.showSuccess(context, '歌单创建成功');
        }
      } else {
        if (mounted) {
          // 使用后端返回的错误信息
          final errorMsg = response.data?['msg'] ?? '未知错误';
          ToastUtils.showError(context, '创建歌单失败: $errorMsg');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '创建歌单失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
