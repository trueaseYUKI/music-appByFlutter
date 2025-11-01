import 'package:flutter/material.dart';
import 'package:music_app/provider/theme_provider.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/playlist_utils.dart';
import 'package:provider/provider.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/models/music.dart';

class PlayingPage extends StatefulWidget {
  const PlayingPage({super.key});

  @override
  State<PlayingPage> createState() => _PlayingPageState();
}

class _PlayingPageState extends State<PlayingPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, PlayerProvider>(
      builder: (context, theme, playerProvider, child) {
        final Music? currentSong = playerProvider.currentSong;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '正在播放',
              style: TextStyle(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            // 添加返回按钮
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
            ),
          ),
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
                // 专辑封面
                _buildAlbumCover(currentSong),
                SizedBox(height: 30),

                // 歌曲信息
                _buildSongInfo(currentSong),
                SizedBox(height: 30),

                // 进度条
                _buildProgressIndicator(playerProvider),
                SizedBox(height: 30),

                // 歌曲控制
                _buildPlaybackControls(playerProvider),
                SizedBox(height: 15),

                _buildPlayModeAndList(playerProvider),
                SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建专辑封面
  Widget _buildAlbumCover(Music? song) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              // 阴影的偏移量
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: song?.coverUrl != null && song!.coverUrl!.isNotEmpty
              ? Image.network(
                  ImageUtils.getFullImageUrl(song.coverUrl!),
                  fit: BoxFit.cover,
                  // 加载图片出错，就加载图标
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.music_note, size: 100);
                  },
                )
              // 无图可以加载就加载图标
              : Icon(Icons.music_note, size: 100),
        ),
      ),
    );
  }

  // 构建歌曲信息
  Widget _buildSongInfo(Music? song) {
    return Column(
      children: [
        Text(
          song?.title ?? '未知歌曲',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 10),

        Text(
          song?.artist ?? '未知艺术家',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 构建播放控制按钮
  Widget _buildPlaybackControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // 上一首
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
          child: IconButton(
            onPressed: player.previousSong,
            iconSize: 40,
            icon: Icon(Icons.skip_previous),
          ),
        ),

        // 播放/暂停
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
          child: IconButton(
            onPressed: player.togglePlayPause,
            icon: Icon(
              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            iconSize: 50,
          ),
        ),

        // 下一首
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
          child: IconButton(
            iconSize: 40,
            onPressed: player.nextSong,
            icon: Icon(Icons.skip_next),
          ),
        ),
      ],
    );
  }

  // 构建播放模式切换和歌单按钮
  Widget _buildPlayModeAndList(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: player.toggleMode,
          icon: Icon(_getPlayModeIcon(player.playMode)),
          iconSize: 30,
        ),

        IconButton(
          onPressed: () => PlaylistUtils.showPlaylistModal(context),
          icon: Icon(Icons.queue_music),
          iconSize: 30,
        ),
      ],
    );
  }

  // 构建进度条
  Widget _buildProgressIndicator(PlayerProvider player) {
    return Column(
      children: [
        Slider(
          value: player.duration.inMilliseconds == 0
              ? 0
              // 设置当前的播放位置
              : (player.position.inMicroseconds /
                        player.duration.inMicroseconds)
                    .clamp(0.0, 1.0)
                    .toDouble(),
          onChanged: (value) {
            final duration = player.duration;
            final newPosition = duration * value;
            player.seek(newPosition);
          },
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(player.position)),
            Text(_formatDuration(player.duration)),
          ],
        ),
      ],
    );
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

  // 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
