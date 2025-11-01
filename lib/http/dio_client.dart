// lib/http/dio_client.dart
import 'package:dio/dio.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/res/config_manager.dart';

class DioClient {
  static String BASE_URL = ConfigManager.baseUrl; // 根据实际情况修改
  static const String PREF_TOKEN_KEY = 'access_token';

  late Dio _dio;
  static String? _accessToken;

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // 加载本地存储的token
    _loadTokenFromStorage();
  }

  // 请求拦截器
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 除了登录和发送验证码接口，其他接口都需要添加token
    final noAuthPaths = ['/users/login', '/users/send-code'];
    if (!noAuthPaths.contains(options.path) && _accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }

    print('请求: ${options.method} ${options.path}');
    return handler.next(options);
  }

  // 响应拦截器
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 检查响应头中是否有新的access token
    final newToken = response.headers.value('X-New-Access-Token');
    if (newToken != null && newToken.isNotEmpty) {
      setAccessToken(newToken);

      final userProvider = UserProvider();
      userProvider.setToken(newToken);
    }

    print('响应: ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  // 错误拦截器
  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    print('错误: ${e.message}');
    return handler.next(e);
  }

  // 从本地存储加载token
  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(PREF_TOKEN_KEY);
    } catch (e) {
      print('加载token失败: $e');
    }
  }

  // 设置并保存access token
  static void setAccessToken(String token) async {
    _accessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_TOKEN_KEY, token);
    } catch (e) {
      print('保存token失败: $e');
    }
  }

  // 清除access token
  Future<void> clearAccessToken() async {
    _accessToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PREF_TOKEN_KEY);
    } catch (e) {
      print('清除token失败: $e');
    }
  }

  // 获取当前access token
  String? get accessToken => _accessToken;

  // GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  // POST 请求
  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  // PUT 请求
  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  // DELETE 请求
  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }

  Future<Response<T>> upload<T>(String path, {required FormData formData}) {
    return _dio.post<T>(path, data: formData);
  }

  // 文件上传
  Future<Response<T>> uploadOptions<T>(
    String path, {
    required FormData formData,
    required Options options,
  }) {
    return _dio.post<T>(path, data: formData);
  }

  Future<Response<T>> uploadPut<T>(
    String path, {
    required FormData formData,
    Options? options,
  }) {
    final opts = options ?? Options();
    opts.method = 'PUT'; // 明确指定为 PUT 方法
    opts.contentType = 'multipart/form-data';

    return _dio.request<T>(path, data: formData, options: opts);
  }
}
