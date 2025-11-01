import 'package:music_app/res/config_manager.dart';

class ImageUtils {
  // 处理图片URL，添加基地址前缀（如果需要）
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return ''; // 返回空字符串而不是默认图片路径
    }

    // 如果已经是完整URL，则直接返回
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // 如果是相对路径，添加基地址前缀
    final baseUrl = ConfigManager.baseUrl;
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    } else {
      return '$baseUrl/$imageUrl';
    }
  }

  // 处理音乐URL，添加基地址前缀（如果需要）
  static String getFullMusicUrl(String? musicUrl) {
    if (musicUrl == null || musicUrl.isEmpty) {
      return ''; // 返回空字符串
    }

    // 如果已经是完整URL，则直接返回
    if (musicUrl.startsWith('http://') || musicUrl.startsWith('https://')) {
      return musicUrl;
    }

    // 如果是相对路径，添加基地址前缀
    final baseUrl = ConfigManager.baseUrl;
    if (musicUrl.startsWith('/')) {
      return '$baseUrl$musicUrl';
    } else {
      return '$baseUrl/$musicUrl';
    }
  }
}
