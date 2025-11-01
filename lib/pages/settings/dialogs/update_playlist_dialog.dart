import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/http/playlist_service.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:provider/provider.dart';

class UpdatePlaylistDialog extends StatefulWidget {
  final Playlist playlist;

  const UpdatePlaylistDialog({super.key, required this.playlist});

  @override
  State<UpdatePlaylistDialog> createState() => _UpdatePlaylistDialogState();
}

class _UpdatePlaylistDialogState extends State<UpdatePlaylistDialog> {
  late TextEditingController _nameController;
  File? _coverImage;
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;
  Uint8List? _webCoverImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('修改歌单'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
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
                  return '歌单名称不能超过25个字符';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            // 封面上传区域
            GestureDetector(
              onTap: _isUpdating
                  ? null
                  : () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.image,
                            withData: true, // 硞保这个是true，以便获取数据
                          );

                      if (result != null) {
                        if (kIsWeb) {
                          // Web平台处理方式：保存文件的字节数据用于预览
                          setState(() {
                            _coverImage = null; // 不创建File对象
                            _webCoverImage =
                                result.files.single.bytes; // 保存字节数据
                          });
                        } else {
                          // 移动端处理方式
                          setState(() {
                            _coverImage = File(result.files.single.path!);
                            _webCoverImage = null; // 清除Web数据
                          });
                        }
                      }
                    },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_coverImage!, fit: BoxFit.cover),
                      )
                    : _webCoverImage !=
                          null // 添加Web端图片预览
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_webCoverImage!, fit: BoxFit.cover),
                      )
                    : widget.playlist.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ImageUtils.getFullImageUrl(widget.playlist.coverUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  '上传封面',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
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
          onPressed: _isUpdating
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    await _updatePlaylist();
                  }
                },
          child: _isUpdating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('修改'),
        ),
      ],
    );
  }

  Future<void> _updatePlaylist() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final playlistService = PlaylistService();

      String? coverPath;
      Uint8List? coverBytes;

      if (kIsWeb) {
        // Web平台使用字节数据
        coverBytes = _webCoverImage;
      } else {
        // 移动端使用文件路径
        coverPath = _coverImage?.path;
      }

      // 调用网络请求更新歌单
      final response = await playlistService.updatePlaylist(
        widget.playlist.id,
        name: _nameController.text,
        coverPath: coverPath,
        coverBytes: coverBytes, // 传递字节数据给服务
      );

      if (response.statusCode == 200 && response.data != null) {
        final playlistData = response.data!['data'];

        // 创建更新后的 Playlist 对象
        final updatedPlaylist = Playlist.fromJson(playlistData);

        // 更新 UserProvider
        userProvider.updatePlaylist(updatedPlaylist);

        if (mounted) {
          Navigator.of(context).pop();
          ToastUtils.showSuccess(context, '歌单修改成功');
        }
      } else {
        if (mounted) {
          final errorMsg = response.data?['msg'] ?? '未知错误';
          ToastUtils.showError(context, '修改歌单失败: $errorMsg');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '修改歌单失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
