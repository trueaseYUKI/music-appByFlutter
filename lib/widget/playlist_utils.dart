import 'package:flutter/material.dart';
import 'package:music_app/widget/playlist_modal.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:provider/provider.dart';


class PlaylistUtils {
  static void showPlaylistModal(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // 如果播放列表为空，显示提示信息而不是空列表
    if (playerProvider.playlist.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放列表为空')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return PlaylistModal(
          onDelete: (index) {
            final playerProvider = Provider.of<PlayerProvider>(
              context,
              listen: false,
            );
            playerProvider.removeSong(index);
          },
          onPlay: (index) {
            final playerProvider = Provider.of<PlayerProvider>(
              context,
              listen: false,
            );
            Navigator.pop(context);
            playerProvider.playSong(index);
          },
        );
      },
    );
  }
}
