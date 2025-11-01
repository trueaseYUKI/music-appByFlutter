// lib/pages/home.dart
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: () {
                // 点击去搜索页面
                Navigator.pushNamed(context, '/search');
              },
              label: Text('搜索', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.search),
            ),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: 120,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: () {
                // 导航到上传页面
                Navigator.pushNamed(context, '/upload');
              },
              label: Text('上传', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.upload),
            ),
          ),
        ],
      ),
    );
  }
}