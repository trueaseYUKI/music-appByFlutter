// lib/pages/upload.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:music_app/http/music_service.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:music_app/models/music.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _artist = '';
  String _coverPath = '';
  String _audioPath = '';
  String _lyricPath = '';
  File? _coverFile;
  File? _audioFile;
  File? _lyricFile;
  bool _isUploading = false;
  Uint8List? _webAudioBytes;
  Uint8List? _webCoverBytes; // 添加这一行

  // 修改 _pickLyricFile 方法
  Future<void> _pickLyricFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc', 'txt'],
      withData: kIsWeb, // Web平台需要withData=true
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Web平台处理方式
          _lyricFile = null; // Web平台不使用File对象
          _lyricPath = result.files.single.name;
        } else {
          // 移动端处理方式
          _lyricFile = File(result.files.single.path!);
          _lyricPath = result.files.single.name;
        }
      });
    }
  }

  Future<void> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // 始终设置为true以支持预览
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Web平台处理方式
          _coverFile = null; // Web平台不使用File对象
          _coverPath = result.files.single.name;
          _webCoverBytes = result.files.single.bytes; // 保存字节数据用于预览和上传
        } else {
          // 移动端处理方式
          _coverFile = File(result.files.single.path!);
          _coverPath = result.files.single.name;
          _webCoverBytes = null; // 清除Web数据
        }
      });
    }
  }

  // 修改 _pickAudioFile 方法
  // 修改 _pickAudioFile 方法
  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: kIsWeb, // Web平台需要withData=true
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Web平台处理方式
          _audioFile = null; // Web平台不使用File对象
          _audioPath = result.files.single.name;
          _webAudioBytes = result.files.single.bytes; // 保存字节数据
        } else {
          // 移动端处理方式
          _audioFile = File(result.files.single.path!);
          _audioPath = result.files.single.name;
          _webAudioBytes = null; // 清除Web数据
        }
      });
    }
  }

  // 保存文件到应用目录
  /*Future<String> _saveFileToAppDir(File file, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/$subDir');

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final fileName = path.basename(file.path);
    final targetFile = File('${targetDir.path}/$fileName');

    await file.copy(targetFile.path);
    return targetFile.path;
  }*/

  // 修改 _submitForm 方法
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 修改验证条件以适配Web端
      if ((_audioFile == null && _webAudioBytes == null) &&
          _audioPath.isEmpty) {
        if (!mounted) return;
        ToastUtils.showInfo(context, "请选择音乐文件");
        return;
      }

      _formKey.currentState!.save();
      setState(() {
        _isUploading = true;
      });

      try {
        // 准备FormData
        final formData = FormData();

        // 添加基本字段
        formData.fields.add(MapEntry('title', _title));
        formData.fields.add(MapEntry('artist', _artist));

        // 添加音乐文件
        if (kIsWeb && _webAudioBytes != null) {
          // Web端使用字节数据上传
          final musicFile = MultipartFile.fromBytes(
            _webAudioBytes!,
            filename: _audioPath,
          );
          formData.files.add(MapEntry('music_file', musicFile));
        } else if (_audioFile != null) {
          // 移动端使用文件路径上传
          final musicFile = await MultipartFile.fromFile(
            _audioFile!.path,
            filename: _audioFile!.path.split('/').last,
          );
          formData.files.add(MapEntry('music_file', musicFile));
        }

        // 添加封面文件（如果有）
        if (kIsWeb && _webCoverBytes != null) {
          // Web端使用字节数据上传
          final coverFile = MultipartFile.fromBytes(
            _webCoverBytes!,
            filename: _coverPath,
          );
          formData.files.add(MapEntry('cover_file', coverFile));
        } else if (_coverFile != null) {
          // 移动端使用文件路径上传
          final coverFile = await MultipartFile.fromFile(
            _coverFile!.path,
            filename: _coverFile!.path.split('/').last,
          );
          formData.files.add(MapEntry('cover_file', coverFile));
        }

        // 添加歌词文件（如果有）
        if (_lyricFile != null) {
          final lyricFile = await MultipartFile.fromFile(
            _lyricFile!.path,
            filename: _lyricFile!.path.split('/').last,
          );
          formData.files.add(MapEntry('lyric_file', lyricFile));
        }

        // 调用后端API上传音乐
        final musicService = MusicService();
        final response = await musicService.createMusicWithFormData(formData);

        if (response.statusCode == 200 && response.data != null) {
          final musicData = response.data!['data'];

          if (!mounted) return;
          setState(() {
            _isUploading = false;
          });

          ToastUtils.showSuccess(context, '歌曲上传成功！');

          // 返回上一页
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          throw Exception(response.data?['msg'] ?? '上传失败');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
        });

        ToastUtils.showError(context, "上传失败:$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
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
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('上传歌曲'),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // 添加滚动视图
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '歌曲名称',
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.music_note),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入歌曲名称';
                          }
                          return null;
                        },
                        onSaved: (value) => _title = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '艺术家',
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入艺术家名称';
                          }
                          return null;
                        },
                        onSaved: (value) => _artist = value!,
                      ),
                      const SizedBox(height: 16),
                      // 封面上传区域
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '上传封面',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                tileColor: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.5),
                                title: const Text('选择封面图片'),
                                trailing: const Icon(Icons.image),
                                onTap: _pickCoverImage,
                              ),
                              if (_coverPath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('已选择: $_coverPath'),
                                ),
                              // 添加封面预览
                              if (_coverFile != null || _webCoverBytes != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _webCoverBytes != null
                                          ? Image.memory(
                                              _webCoverBytes!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                    );
                                                  },
                                            )
                                          : _coverFile != null
                                          ? Image.file(
                                              _coverFile!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                    );
                                                  },
                                            )
                                          : const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                            ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 音频文件上传区域
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '上传音频文件',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                tileColor: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.5),
                                title: const Text('选择音频文件'),
                                trailing: const Icon(Icons.audiotrack),
                                onTap: _pickAudioFile,
                              ),
                              if (_audioPath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('已选择: $_audioPath'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 歌词上传
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '上传歌词文件',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                tileColor: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.5),
                                title: const Text('选择歌词文件 (.lrc/.txt)'),
                                trailing: const Icon(Icons.text_snippet),
                                onTap: _pickLyricFile,
                              ),
                              if (_lyricPath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('已选择: $_lyricPath'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // 增加底部间距
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _submitForm,
                          child: _isUploading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  '上传歌曲',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20), // 额外的底部空间
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
