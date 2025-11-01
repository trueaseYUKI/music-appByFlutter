import 'package:dio/dio.dart';
import 'package:music_app/http/dio_client.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  final DioClient _dioClient = DioClient();

  // 发送验证码
  Future<Response<Map<String, dynamic>>> sendCode(String email) {
    return _dioClient.post<Map<String, dynamic>>(
      '/users/send-code',
      data: {'email': email},
    );
  }

  // 用户登录
  Future<Response<Map<String, dynamic>>> login(String email, String code) {
    return _dioClient.post<Map<String, dynamic>>(
      '/users/login',
      data: {'email': email, 'code': code},
    );
  }

  // 获取当前用户信息
  Future<Response<Map<String, dynamic>>> getCurrentUser() {
    return _dioClient.get<Map<String, dynamic>>('/users/me');
  }

  // 创建新用户
  Future<Response<Map<String, dynamic>>> createUser(
    Map<String, dynamic> userData,
  ) {
    return _dioClient.post<Map<String, dynamic>>('/users/', data: userData);
  }

  // 获取用户列表
  Future<Response<Map<String, dynamic>>> getUsers({
    int skip = 0,
    int limit = 100,
  }) {
    return _dioClient.get<Map<String, dynamic>>(
      '/users/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }

  // 获取指定用户信息
  Future<Response<Map<String, dynamic>>> getUser(int userId) {
    return _dioClient.get<Map<String, dynamic>>('/users/$userId');
  }

  // 删除用户
  Future<Response<Map<String, dynamic>>> deleteUser(int userId) {
    return _dioClient.delete<Map<String, dynamic>>('/users/$userId');
  }


  Future<Response<Map<String, dynamic>>> updateUserProfile(
    int userId, {
    String? nickname,
    String? avatarPath,
    Uint8List? avatarBytes, // 添加Web端字节数据参数
  }) async {
    final formData = FormData();

    if (nickname != null) {
      formData.fields.add(MapEntry('nickname', nickname));
    }

    // 处理头像上传，适配Web端
    if (avatarPath != null) {
      // 移动端处理
      final avatarFile = await MultipartFile.fromFile(
        avatarPath,
        filename: 'avatar.jpg',
      );
      formData.files.add(MapEntry('avatar_file', avatarFile));
    } else if (avatarBytes != null && kIsWeb) {
      // Web端处理
      final avatarFile = MultipartFile.fromBytes(
        avatarBytes,
        filename: 'avatar.jpg',
      );
      formData.files.add(MapEntry('avatar_file', avatarFile));
    }

    // 明确设置 Content-Type
    final options = Options(contentType: 'multipart/form-data');

    return _dioClient.uploadPut<Map<String, dynamic>>(
      '/users/$userId/profile',
      formData: formData,
      options: options,
    );
  }
}
