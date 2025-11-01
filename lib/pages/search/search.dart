// lib/pages/search/search.dart
import 'package:flutter/material.dart';
import 'package:music_app/pages/search/widgets/search_result_items.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/http/music_service.dart'; // 新增导入
import 'package:provider/provider.dart';
import 'package:music_app/provider/player_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Music> _searchResults = [];
  bool _isSearching = false;
  int _currentPage = 1; // 修改：默认页码为1
  int _totalResults = 0; // 新增：总结果数
  final int _itemsPerPage = 50; // 每页显示条目数
  bool _hasError = false; // 新增：错误状态

  // 实际搜索功能（对接后端）
  // 实际搜索功能（对接后端）
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _totalResults = 0;
        _currentPage = 1;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasError = false;
    });

    try {
      final musicService = MusicService();
      final skip = (_currentPage - 1) * _itemsPerPage; // 计算offset
      final response = await musicService.searchMusic(
        query,
        skip: skip,
        limit: _itemsPerPage,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'];
        final List<dynamic> musicList = data['musics'];
        final int total = data['total_count']; // 使用 total_count 字段
        // 可以选择性使用 total_page, current_page, page_size 字段

        setState(() {
          _searchResults = musicList
              .map((item) => Music.fromJson(item as Map<String, dynamic>))
              .toList();
          _totalResults = total;
          _isSearching = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isSearching = false;
      });
    }
  }

  // 处理页码变化
  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // 重新执行搜索以获取新页面的数据
    _performSearch(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, PlayerProvider>(
      builder: (context, theme, playerProvider, child) {
        return Scaffold(
          body: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26.withValues(alpha: 0.2),
              image: theme.selectedBackground.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(theme.selectedBackground),
                      fit: BoxFit.cover,
                      opacity: theme.backgroundOpacity,
                    )
                  : null,
            ),
            child: Column(
              children: [
                SizedBox(height: 50),
                // 搜索框
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索音乐...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.8),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _totalResults = 0;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      // 重置到第一页并执行搜索
                      setState(() {
                        _currentPage = 1;
                      });
                      _performSearch(value);
                    },
                  ),
                ),
                SizedBox(height: 20),
                // 搜索结果区域
                Expanded(
                  child: _isSearching
                      ? Center(child: CircularProgressIndicator())
                      : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '搜索出错，请稍后重试',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _performSearch(_searchController.text);
                                },
                                child: Text('重新搜索'),
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty &&
                            _searchController.text.isNotEmpty
                      ? Center(
                          child: Text(
                            '未找到相关音乐',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : SearchResultItems(
                          searchResults: _searchResults,
                          currentPage: _currentPage,
                          totalResults: _totalResults,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: _handlePageChanged,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
