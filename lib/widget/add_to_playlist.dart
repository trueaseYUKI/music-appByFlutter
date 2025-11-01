// lib/widget/add_to_playlist_modal.dart
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/models/page_cache.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/http/playlist_service.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';

class AddToPlaylistModal extends StatefulWidget {
  final Music song;

  const AddToPlaylistModal({super.key, required this.song});

  @override
  State<AddToPlaylistModal> createState() => _AddToPlaylistModalState();
}

class _AddToPlaylistModalState extends State<AddToPlaylistModal> {
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 0;
  final int _itemsPerPage = 10;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) return;

      final playlistService = PlaylistService();
      final skip = (_currentPage - 1) * _itemsPerPage;

      final response = await playlistService.getUserPlaylists(
        userProvider.user!.id,
        skip: skip,
        limit: _itemsPerPage,
      );

      if (response.statusCode == 200 && response.data != null && response.data!['code'] == 200) {
        final data = response.data!['data'];
        final List<dynamic> playlistList = data['playlists'];
        final int total = data['total_count'];

        setState(() {
          _playlists = playlistList
              .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
              .toList();
          
          _totalPages = (total / _itemsPerPage).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
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
    _loadPlaylists();
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    try {
      final playlistService = PlaylistService();
      final response = await playlistService.addMusicToPlaylist(
        playlist.id,
        widget.song.id,
      );

      if (response.statusCode == 200) {
        // 添加成功后更新 UserProvider 中的歌单歌曲数量
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.incrementPlaylistSongCount(playlist.id); // 使用新方法

        ToastUtils.showSuccess(context, '已添加到歌单"${playlist.name}"');
        Navigator.pop(context);
      } else {
        ToastUtils.showError(
          context,
          '添加失败: ${response.data?['msg'] ?? '未知错误'}',
        );
      }
    } catch (e) {
      ToastUtils.showError(context, '添加失败: $e');
    }
  }

  Future<void> _addToCurrentPlaylist() async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.addSong(widget.song);
    ToastUtils.showSuccess(context, '已添加到当前播放列表');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '添加到歌单',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            widget.song.title ?? '未知歌曲',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10),
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
                          onPressed: _loadPlaylists,
                          child: Text('重新加载'),
                        ),
                      ],
                    ),
                  )
                : _playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '暂无歌单',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '去创建一个歌单',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _playlists.length + 1, // +1 for current playlist
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 当前播放列表项
                        return Card(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(Icons.queue_music, size: 50),
                            ),
                            title: Text(
                              '当前播放列表',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('添加到当前播放列表'),
                            onTap: _addToCurrentPlaylist,
                          ),
                        );
                      } else {
                        final Playlist playlist = _playlists[index - 1];
                        return Card(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  playlist.coverUrl != null &&
                                      playlist.coverUrl!.isNotEmpty
                                  ? Image.network(
                                      ImageUtils.getFullImageUrl(
                                        playlist.coverUrl!,
                                      ),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(Icons.album, size: 50);
                                          },
                                    )
                                  : Icon(Icons.album, size: 50),
                            ),
                            title: Text(
                              playlist.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${playlist.songCount}首歌曲'),
                            onTap: () => _addToPlaylist(playlist),
                          ),
                        );
                      }
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
    );
  }
}
