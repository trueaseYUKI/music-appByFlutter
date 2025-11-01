// lib/widget/player.dart
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/playlist_utils.dart'; // 修改导入
import 'package:music_app/provider/player_provider.dart';
import 'package:provider/provider.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/play');
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[600],
                    ),
                    child: _existCover(playerProvider),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerProvider.currentSongTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          // 歌曲名称过长就显示省略号
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 2),
                      Text(
                        playerProvider.currentArtist,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600], // 歌曲名称过长就显示省略号
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: playerProvider.nextSong,
                  icon: Icon(Icons.skip_next),
                ),
                IconButton(
                  onPressed: playerProvider.toggleMode,
                  icon: Icon(_getPlayModeIcon(playerProvider.playMode)),
                ),
                IconButton(
                  onPressed: playerProvider.togglePlayPause,
                  icon: Icon(
                    playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  onPressed: () => PlaylistUtils.showPlaylistModal(context),
                  icon: Icon(Icons.queue_music),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 根据是否存在封面图来决定是否显示对应的封面
  Widget _existCover(PlayerProvider playerProvider) {
    if (playerProvider.playlist.isEmpty ||
        playerProvider.currentIndex >= playerProvider.playlist.length) {
      return Icon(Icons.music_note);
    }

    Music song = playerProvider.playlist[playerProvider.currentIndex];

    // 检查是否有封面URL且不为空
    if (song.coverUrl != null && song.coverUrl!.isNotEmpty) {
      // 使用网络图片，如果加载失败则显示默认图标
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          ImageUtils.getFullImageUrl(song.coverUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.music_note);
          },
        ),
      );
    }

    // 没有封面URL时显示默认图标
    return Icon(Icons.music_note);
  }

  // 获取播放模式图标
  IconData _getPlayModeIcon(PlayMode playMode) {
    switch (playMode) {
      case PlayMode.sequential:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.single:
        return Icons.repeat_one;
    }
  }
}
