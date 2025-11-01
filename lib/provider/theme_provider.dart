// lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 添加这一行导入

class ThemeProvider with ChangeNotifier {
  // 主题色key
  static const String PREF_KEY = 'selected_theme_color';
  // 主题背景key
  static const String PREF_BG_KEY = 'selected_background_image';
  // 文字样式key
  static const String PREF_FONT_KEY = 'selected_font';
  // 添加透明度key
  static const String PREF_BG_OPACITY_KEY = 'background_opacity';
  // 预定义的主题色选项
  static final List<Color> _availableColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.white,
    Colors.deepOrange,
    Colors.black26,
  ];

  bool _disposed = false;
  // 添加透明度属性
  double _backgroundOpacity = 0.45; // 默认透明度

  // 预定义背景图片
  static final List<String> _availableBackgrounds = [
    '', // 无背景
    'assets/bc/bg01.png', // 添加逗号分隔符
    'assets/bc/bg02.png',
    'assets/bc/bg01.jpg',
    'assets/bc/bg02.jpg',
    'assets/bc/bg03.jpg',
    'assets/bc/bg04.jpg',
  ];

  // 字体样式选项
  static final List<String> _fontStyles = [
    'auto', // 自动（根据背景样式自动调整）
    'light', // 浅色字体
    'dark', // 深色字体
  ];

  // 预定义的字体颜色

  Color _selectedColor = Colors.green;
  String _selectedBackground = '';
  String _fontStyle = 'auto';

  Color get selectedColor => _selectedColor;
  String get selectedBackground => _selectedBackground;
  String get fontStyle => _fontStyle;
  double get backgroundOpacity => _backgroundOpacity;
  List<Color> get availableColors => _availableColors;
  List<String> get availableBackgrounds => _availableBackgrounds;
  List<String> get fontStyles => _fontStyles;

  // 在构造函数中加载保存的主题设置
  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  void setThemeColor(Color color) {
    _selectedColor = color;
    _saveThemeToPreferences();
    notifyListeners();
  }

  void setBackgroundImage(String backgroundImage) {
    _selectedBackground = backgroundImage;

    // 如果是Web平台且选择了背景图片，设置透明度为0
    if (kIsWeb && backgroundImage.isNotEmpty) {
      _backgroundOpacity = 1.0;
    } else if (kIsWeb && backgroundImage.isEmpty) {
      // 如果是Web平台且没有选择背景图片，恢复默认透明度
      _backgroundOpacity = 0.45;
    }

    _saveThemeToPreferences();
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setFontStyle(String style) {
    _fontStyle = style;

    // 黑色字体，背景图片的透明度要修改
    if (style == 'light') {
      setBackgroundOpacity(0.45);
    } else {
      setBackgroundOpacity(1.0);
    }

    _saveThemeToPreferences();
    if (!_disposed) {
      notifyListeners();
    }
  }

  // 修改 setBackgroundOpacity 方法，添加 disposed 检查
  void setBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity;
    _saveThemeToPreferences();
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool shouldUseLightFont() {
    if (_fontStyle == 'light') return true;
    if (_fontStyle == 'dark') return false;

    // 自动模式
    if (_selectedBackground.isNotEmpty) {
      // 如果是Web平台，返回false表示不使用浅色字体（因为背景透明）
      if (kIsWeb) {
        return false;
      }
      return true;
    } else {
      // 根据背景颜色的亮度决定
      final brightness = ThemeData.estimateBrightnessForColor(_selectedColor);
      return brightness == Brightness.dark;
    }
  }

  // 在 getTheme 方法中使用透明度
  ThemeData getTheme() {
    final useLightFont = shouldUseLightFont();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _selectedColor.withValues(alpha: 0.05),
        brightness: useLightFont ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: _selectedColor.withValues(alpha: 0.05),
      textTheme: useLightFont
          ? TextTheme(
              bodyLarge: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              bodyMedium: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              bodySmall: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            )
          : null,
    );
  }

  // 修改 _saveThemeToPreferences 方法
  Future<void> _saveThemeToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_KEY, _selectedColor.toARGB32());
    await prefs.setString(PREF_BG_KEY, _selectedBackground);
    await prefs.setString(PREF_FONT_KEY, _fontStyle);
    await prefs.setDouble(PREF_BG_OPACITY_KEY, _backgroundOpacity); // 保存透明度
  }

  // 修改 _loadThemeFromPreferences 方法
  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(PREF_KEY);
    final backgroundValue = prefs.getString(PREF_BG_KEY);
    final fontStyleValue = prefs.getString(PREF_FONT_KEY);
    final opacityValue = prefs.getDouble(PREF_BG_OPACITY_KEY); // 加载透明度

    if (colorValue != null) {
      _selectedColor = Color(colorValue);
    }

    if (backgroundValue != null) {
      _selectedBackground = backgroundValue;
    }

    if (fontStyleValue != null) {
      _fontStyle = fontStyleValue;
    }

    if (opacityValue != null) {
      _backgroundOpacity = opacityValue;
    }

    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
