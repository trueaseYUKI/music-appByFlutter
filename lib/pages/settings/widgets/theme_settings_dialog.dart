import 'package:flutter/material.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeSettingsDilog extends StatelessWidget {
  const ThemeSettingsDilog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('主题设置'),
      content: SizedBox(
        // 获取当前媒体的宽度去缩小原有20%
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择主题颜色',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: theme.availableColors.map((color) {
                  return GestureDetector(
                    // 设置主题色彩
                    onTap: () {
                      theme.setThemeColor(color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: theme.selectedColor == color
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),

              // 设置背景图片
              Text('选择背景图片', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    // 点击切换背景图片
                    onTap: () {
                      theme.setBackgroundImage('');
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.selectedBackground == ''
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('无')),
                    ),
                  ),
                  // 解构数组，跳过第一项
                  ...theme.availableBackgrounds.skip(1).map((bg) {
                    return GestureDetector(
                      onTap: () {
                        // 设置背景图片为选择的图片
                        theme.setBackgroundImage(bg);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(bg),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: theme.selectedBackground == bg
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: 10),
              // 设置字体样式
              const Text('字体样式', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // 新版 RadioGroup 用法
              RadioGroup<String>(
                groupValue: theme.fontStyle, // 当前选中的字体样式
                onChanged: (value) {
                  if (value != null) theme.setFontStyle(value);
                },
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('自动'),
                      leading: Radio<String>(value: 'auto'),
                      onTap: () => theme.setFontStyle('auto'),
                    ),
                    ListTile(
                      title: const Text('浅色'),
                      leading: Radio<String>(value: 'light'),
                      onTap: () => theme.setFontStyle('light'),
                    ),
                    ListTile(
                      title: const Text('深色'),
                      leading: Radio<String>(value: 'dark'),
                      onTap: () => theme.setFontStyle('dark'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
