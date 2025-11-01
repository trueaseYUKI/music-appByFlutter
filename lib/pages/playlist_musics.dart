import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/http/playlist_service.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';
import 'package:music_app/provider/theme_provider.dart';

class PlaylistMusicsPage extends StatefulWidget {
  final int playlistId; // 修改为接收playlistId

  const PlaylistMusicsPage({super.key, required this.playlistId}); // 修改构造函数

  @override
  State<PlaylistMusicsPage> createState() => _PlaylistMusicsPageState();
}

class _PlaylistMusicsPageState extends State<PlaylistMusicsPage> {
  Playlist? _playlist; // 添加_playlist变量存储歌单信息
  List<Music> _musics = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 0;
  final int _itemsPerPage = 100;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylistInfo(); // 添加加载歌单信息的方法
    _loadPlaylistMusics();
  }

  // 添加加载歌单信息的方法
  Future<void> _loadPlaylistInfo() async {
    try {
      final playlistService = PlaylistService();
      final response = await playlistService.getPlaylist(widget.playlistId);

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data!['code'] == 200) {
        final playlistData = response.data!['data'];
        setState(() {
          _playlist = Playlist.fromJson(playlistData);
        });
      }
    } catch (e) {
      print('加载歌单信息失败: $e');
    }
  }

  Future<void> _loadPlaylistMusics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (widget.playlistId <= 0) return;
      final playlistService = PlaylistService();
      final skip = (_currentPage - 1) * _itemsPerPage;

      final response = await playlistService.getPlaylistMusics(
        widget.playlistId,
        skip: skip,
        limit: _itemsPerPage,
      );

      if (response.statusCode == 200 && response.data != null) {
        // 检查是否有code字段，如果没有可能是成功状态
        final code = response.data!['code'];
        if (code == 200 || code == null) {
          // 添加code为null的兼容处理
          final data = response.data!['data'] ?? response.data; // 兼容不同数据结构

          if (data != null) {
            // 根据后端API结构正确解析数据
            final List<dynamic> musicList = data['musics'] ?? data;
            final int total = data['total_count'] ?? musicList.length;

            setState(() {
              _musics = musicList
                  .map((item) => Music.fromJson(item as Map<String, dynamic>))
                  .toList();
              _totalPages = (total / _itemsPerPage).ceil();
              _isLoading = false;
              _hasError = false;
            });
            return;
          }
        }
      }

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    } catch (e) {
      print('加载歌单音乐异常: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadPlaylistMusics();
  }

  Future<void> _removeMusicFromPlaylist(Music music, int index) async {
    try {
      final playlistService = PlaylistService();
      final response = await playlistService.removeMusicFromPlaylist(
        widget.playlistId, // 使用playlistId
        music.id,
      );

      if (response.statusCode == 200) {
        setState(() {
          _musics.removeAt(index);
        });

        // 更新 UserProvider 中的歌单歌曲数量
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.decrementPlaylistSongCount(
          widget.playlistId,
        ); // 使用playlistId

        ToastUtils.showSuccess(context, '已从歌单中移除"${music.title}"');
      } else {
        ToastUtils.showError(
          context,
          '移除失败: ${response.data?['msg'] ?? '未知错误'}',
        );
      }
    } catch (e) {
      ToastUtils.showError(context, '移除失败: $e');
    }
  }

  Future<void> _playMusic(Music music) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.addSong(music);
    playerProvider.playSong(playerProvider.playlist.length - 1);
  }

  // 在 PlaylistMusicsPage 的 build 方法中修改 Scaffold 组件
  @override
  Widget build(BuildContext context) {
    // 添加对无效 playlistId 的检查
    if (widget.playlistId <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text('无效的歌单')),
        body: Center(child: Text('无法加载歌单信息')),
      );
    }

    // 原有的 build 逻辑...
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Scaffold(
          body: Container(
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
                AppBar(
                  title: Text(_playlist?.name ?? '歌单详情'),
                  backgroundColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadPlaylistMusics,
                    ),
                  ],
                ),
                // 歌单信息
                if (_playlist?.coverUrl != null) // 使用_playlist.coverUrl
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ImageUtils.getFullImageUrl(
                          _playlist!.coverUrl,
                        ), // 使用_playlist.coverUrl
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.album, size: 100);
                        },
                      ),
                    ),
                  ),
                // 歌曲列表或加载状态
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('加载失败'),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadPlaylistMusics,
                                child: Text('重新加载'),
                              ),
                            ],
                          ),
                        )
                      : _musics.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue_music,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '歌单为空',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '去添加一些音乐',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _musics.length,
                          itemBuilder: (context, index) {
                            final Music music = _musics[index];
                            return Card(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      music.coverUrl != null &&
                                          music.coverUrl!.isNotEmpty
                                      ? Image.network(
                                          ImageUtils.getFullImageUrl(
                                            music.coverUrl!,
                                          ),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.album,
                                                  size: 50,
                                                );
                                              },
                                        )
                                      : Icon(Icons.album, size: 50),
                                ),
                                title: Text(
                                  music.title ?? '未知歌曲',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(music.artist ?? '未知艺术家'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.play_arrow),
                                      onPressed: () => _playMusic(music),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeMusicFromPlaylist(
                                        music,
                                        index,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _playMusic(music),
                              ),
                            );
                          },
                        ),
                ),
                // 分页控件
                if (_totalPages > 1)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 上一页按钮
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1
                              ? () => _handlePageChanged(_currentPage - 1)
                              : null,
                        ),
                        // 页码按钮
                        ...List.generate(
                          _totalPages > 5 ? 5 : _totalPages, // 最多显示5个页码按钮
                          (index) {
                            int pageNumber;
                            if (_totalPages <= 5) {
                              pageNumber = index + 1;
                            } else if (_currentPage <= 3) {
                              pageNumber = index + 1;
                            } else if (_currentPage >= _totalPages - 2) {
                              pageNumber = _totalPages - 4 + index;
                            } else {
                              pageNumber = _currentPage - 2 + index;
                            }

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              child: TextButton(
                                onPressed: () => _handlePageChanged(pageNumber),
                                style: TextButton.styleFrom(
                                  backgroundColor: _currentPage == pageNumber
                                      ? Theme.of(context).primaryColor
                                      : null,
                                  foregroundColor: _currentPage == pageNumber
                                      ? Colors.white
                                      : null,
                                  padding: EdgeInsets.all(8),
                                  minimumSize: Size(30, 30),
                                ),
                                child: Text('$pageNumber'),
                              ),
                            );
                          },
                        ),
                        // 下一页按钮
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages
                              ? () => _handlePageChanged(_currentPage + 1)
                              : null,
                        ),
                      ],
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
