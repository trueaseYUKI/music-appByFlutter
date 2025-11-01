import 'package:dio/dio.dart';
import 'package:music_app/http/dio_client.dart';

class MusicService {
  final DioClient _dioClient = DioClient();

  // 创建新音乐
  // 在 MusicService 类中添加此方法
  Future<Response<Map<String, dynamic>>> createMusicWithFormData(
    FormData formData,
  ) {
    return _dioClient.upload<Map<String, dynamic>>(
      '/musics/',
      formData: formData,
    );
  }

  // 获取音乐列表
  Future<Response<Map<String, dynamic>>> getMusics({
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.get<Map<String, dynamic>>(
      '/musics/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }

  // 获取指定音乐
  Future<Response<Map<String, dynamic>>> getMusic(int musicId) {
    return _dioClient.get<Map<String, dynamic>>('/musics/$musicId');
  }

  // 更新音乐信息
  Future<Response<Map<String, dynamic>>> updateMusic(
    int musicId,
    Map<String, dynamic> data,
  ) {
    return _dioClient.put<Map<String, dynamic>>('/musics/$musicId', data: data);
  }

  // 删除音乐
  Future<Response<Map<String, dynamic>>> deleteMusic(int musicId) {
    return _dioClient.delete<Map<String, dynamic>>('/musics/$musicId');
  }

  // 根据上传者获取音乐列表
  Future<Response<Map<String, dynamic>>> getMusicsByUploader(
    int uploaderId, {
    int skip = 0,
    int limit = 100,
  }) {
    final uri = Uri(
      path: '/musics/uploader/$uploaderId',
      queryParameters: {'skip': '$skip', 'limit': '$limit'},
    );
    return _dioClient.get<Map<String, dynamic>>(uri.toString());
  }

  // 搜索音乐
  Future<Response<Map<String, dynamic>>> searchMusic(
    String keyword, {
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.post<Map<String, dynamic>>(
      '/musics/search',
      data: {'keyword': keyword},
    );
  }
}
