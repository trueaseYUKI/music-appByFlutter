// lib/res/config_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigManager {
  static const String CONFIG_FILE_NAME = 'app_config.json';
  static const String DEFAULT_BASE_URL = 'http://192.168.31.137:8000';

  static String _baseUrl = DEFAULT_BASE_URL;

  static String get baseUrl => _baseUrl;

  // 初始化配置
  static Future<void> init() async {
    try {
      // Web平台不支持本地文件存储，直接使用默认配置
      if (kIsWeb) {
        _baseUrl = DEFAULT_BASE_URL;
        return;
      }

      final config = await _loadConfigFromFile();
      _baseUrl = config['base_url'] ?? DEFAULT_BASE_URL;
    } catch (e) {
      print('配置加载失败，使用默认配置: $e');
      _baseUrl = DEFAULT_BASE_URL;
    }
  }

  // 从文件加载配置 (仅在非Web平台使用)
  static Future<Map<String, dynamic>> _loadConfigFromFile() async {
    if (kIsWeb) {
      return {'base_url': DEFAULT_BASE_URL};
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$CONFIG_FILE_NAME');

    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    }

    // 如果配置文件不存在，创建默认配置文件
    await _createDefaultConfigFile(file);
    return {'base_url': DEFAULT_BASE_URL};
  }

  // 创建默认配置文件 (仅在非Web平台使用)
  static Future<void> _createDefaultConfigFile(File file) async {
    if (kIsWeb) return;

    final defaultConfig = {'base_url': DEFAULT_BASE_URL};

    await file.writeAsString(json.encode(defaultConfig));
  }
}
