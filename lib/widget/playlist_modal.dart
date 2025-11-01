// lib/widget/playlist_modal.dart
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:provider/provider.dart';

class PlaylistModal extends StatefulWidget {
  final Function(int) onDelete;
  final Function(int) onPlay;

  const PlaylistModal({
    super.key,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  State<PlaylistModal> createState() => _PlaylistModalState();
}

// lib/widget/playlist_modal.dart
class _PlaylistModalState extends State<PlaylistModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '播放列表',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                if (playerProvider.playlist.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '播放列表为空',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '去搜索并添加音乐',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: playerProvider.playlist.length,
                  itemBuilder: (context, index) {
                    final Music song = playerProvider.playlist[index];
                    final bool isCurrent = index == playerProvider.currentIndex;

                    return ListTile(
                      title: Text(
                        song.title ?? '未知歌曲',
                        style: TextStyle(
                          color: isCurrent
                              ? Theme.of(context).primaryColor
                              : null,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        song.artist,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: IconButton(
                        onPressed: () => widget.onDelete(index),
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                      onTap: () => widget.onPlay(index),
                      selected: isCurrent,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
