import 'package:flutter/material.dart';
import 'package:music_app/pages/playlist_musics.dart';
import 'package:music_app/pages/settings/dialogs/create_playlist_dialog.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/info_card.dart';
import 'package:music_app/provider/user_provider.dart';
import 'package:music_app/models/music.dart';
import 'package:provider/provider.dart';
import 'package:music_app/pages/settings/dialogs/update_playlist_dialog.dart';

class PlaylistSection extends StatefulWidget {
  const PlaylistSection({super.key});

  @override
  State<PlaylistSection> createState() => _PlaylistSectionState();
}

class _PlaylistSectionState extends State<PlaylistSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final albums = user?.playlists ?? [];

        if (user == null) {
          return InfoCard(
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.queue_music, size: 60, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      '登录后查看您的歌单',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '创建和管理您的个人歌单',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return InfoCard(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 创建歌单按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCreatePlaylistDialog,
                      icon: Icon(Icons.add),
                      label: Text('创建歌单'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // 歌单列表或空状态
                  if (albums.isEmpty)
                    _buildEmptyState()
                  else ...[
                    for (int i = 0; i < albums.length; i++)
                      if (i == albums.length - 1)
                        _buildPlaylistItem(albums[i])
                      else
                        Column(
                          children: [
                            _buildPlaylistItem(albums[i]),
                            Divider(height: 20),
                          ],
                        ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.queue_music_outlined, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '暂无歌单',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '点击上方按钮创建您的第一个歌单',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(Playlist album) {
    return GestureDetector(
      onTap: () {
        // 使用路由跳转到歌单详情页，只传递playlistId
        Navigator.pushNamed(
          context,
          '/playlist',
          arguments: album.id, // 只传递id
        );
      },
      child: Row(
        children: [
          // 专辑封面图
          SizedBox(
            width: 45,
            height: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverUrl != null
                  ? Image.network(
                      ImageUtils.getFullImageUrl(album.coverUrl),
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/avatar/default.jpg', // 默认封面
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SizedBox(width: 20),
          // 专辑Info
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${album.songCount}首', // 使用 songCount 属性
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 专辑设置
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmationDialog(album);
              } else if (value == 'edit') {
                _showUpdatePlaylistDialog(album);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('修改歌单')),
              PopupMenuItem<String>(value: 'delete', child: Text('删除歌单')),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  // 添加显示修改歌单对话框的方法
  void _showUpdatePlaylistDialog(Playlist playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdatePlaylistDialog(playlist: playlist);
      },
    );
  }

  // 显示创建歌单对话框
  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return const CreatePlaylistDialog();
          },
        );
      },
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmationDialog(Playlist album) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除歌单"${album.name}"吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                userProvider.removePlaylist(album.id);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('歌单已删除')));
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
