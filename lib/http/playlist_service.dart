import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:music_app/http/dio_client.dart';

class PlaylistService {
  final DioClient _dioClient = DioClient();

  // 创建新歌单
  Future<Response<Map<String, dynamic>>> createPlaylist({
    required String name,
    String? description,
    String? coverPath,
  }) async {
    final formData = FormData();

    formData.fields.add(MapEntry('name', name));

    if (description != null) {
      formData.fields.add(MapEntry('description', description));
    }

    if (coverPath != null) {
      final coverFile = await MultipartFile.fromFile(
        coverPath,
        filename: 'cover.jpg',
      );
      formData.files.add(MapEntry('cover_file', coverFile));
    }

    return _dioClient.upload<Map<String, dynamic>>(
      '/playlists/',
      formData: formData,
    );
  }

  // 新增方法：使用 FormData 创建歌单
  Future<Response> createPlaylistWithFormData({
    required FormData formData,
  }) async {
    final response = await _dioClient.post('/playlists/create', data: formData);
    return response;
  }

  // 获取歌单列表
  Future<Response<Map<String, dynamic>>> getPlaylists({
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.get<Map<String, dynamic>>(
      '/playlists/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }

  // 获取指定歌单
  Future<Response<Map<String, dynamic>>> getPlaylist(int playlistId) {
    return _dioClient.get<Map<String, dynamic>>('/playlists/$playlistId');
  }

  // 更新歌单信息
  Future<Response<Map<String, dynamic>>> updatePlaylist(
    int playlistId, {
    String? name,
    String? description,
    String? coverPath,
    Uint8List? coverBytes, // 添加这个参数
  }) async {
    final formData = FormData();

    if (name != null) {
      formData.fields.add(MapEntry('name', name));
    }

    if (description != null) {
      formData.fields.add(MapEntry('description', description));
    }

    // 处理封面图片上传
    if (coverPath != null) {
      // 移动端处理
      final coverFile = await MultipartFile.fromFile(
        coverPath,
        filename: 'cover.jpg',
      );
      formData.files.add(MapEntry('cover_file', coverFile));
    } else if (coverBytes != null && kIsWeb) {
      // Web端处理
      final coverFile = MultipartFile.fromBytes(
        coverBytes,
        filename: 'cover.jpg',
      );
      formData.files.add(MapEntry('cover_file', coverFile));
    }

    return _dioClient.uploadPut<Map<String, dynamic>>(
      '/playlists/$playlistId',
      formData: formData,
    );
  }

  Future<Response> updatePlaylistWithFormData(
    int playlistId, {
    required FormData formData,
  }) async {
    try {
      final response = await _dioClient.put(
        '/playlists/$playlistId',
        data: formData,
      );
      return response;
    } on DioException catch (e) {
      throw Exception('更新歌单失败: ${e.message}');
    }
  }

  // 删除歌单
  Future<Response<Map<String, dynamic>>> deletePlaylist(int playlistId) {
    return _dioClient.delete<Map<String, dynamic>>('/playlists/$playlistId');
  }

  // 向歌单添加音乐
  Future<Response<Map<String, dynamic>>> addMusicToPlaylist(
    int playlistId,
    int musicId,
  ) {
    return _dioClient.post<Map<String, dynamic>>(
      '/playlists/$playlistId/musics/$musicId',
    );
  }

  // 从歌单移除音乐
  Future<Response<Map<String, dynamic>>> removeMusicFromPlaylist(
    int playlistId,
    int musicId,
  ) {
    return _dioClient.delete<Map<String, dynamic>>(
      '/playlists/$playlistId/musics/$musicId',
    );
  }

  // 获取歌单中的音乐列表
  Future<Response<Map<String, dynamic>>> getPlaylistMusics(
    int playlistId, {
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.get<Map<String, dynamic>>(
      '/playlists/$playlistId/musics',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }

  // 获取指定用户的歌单列表（分页）
  Future<Response<Map<String, dynamic>>> getUserPlaylists(
    int userId, {
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.get<Map<String, dynamic>>(
      '/users/$userId/playlists',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }
}
