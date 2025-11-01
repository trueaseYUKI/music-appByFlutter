// lib/pages/search/widgets/search_result_items.dart
import 'package:flutter/material.dart';
import 'package:music_app/http/music_service.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/provider/player_provider.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:music_app/widget/add_to_playlist.dart';
import 'package:music_app/widget/toast_utils.dart';
import 'package:provider/provider.dart';

class SearchResultItems extends StatefulWidget {
  final List<Music> searchResults;
  final int currentPage;
  final int totalResults;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  const SearchResultItems({
    super.key,
    required this.searchResults,
    required this.currentPage,
    required this.totalResults,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  State<SearchResultItems> createState() => _SearchResultItemsState();
}

class _SearchResultItemsState extends State<SearchResultItems> {
  late List<Music> searchResults;
  late int totalResults;

  @override
  void initState() {
    super.initState();
    searchResults = List.from(widget.searchResults);
    totalResults = widget.totalResults;
  }

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      return Center(child: Text('未找到相关音乐', style: TextStyle(fontSize: 18)));
    }

    final totalPages = (totalResults / widget.itemsPerPage).ceil();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final Music song = searchResults[index];
              return Card(
                color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                        ? Image.network(
                            ImageUtils.getFullImageUrl(song.coverUrl!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.music_note, size: 50);
                            },
                          )
                        : Icon(Icons.music_note, size: 50),
                  ),
                  title: Text(
                    song.title ?? '未知歌曲',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  subtitle: Text(song.artist),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (BuildContext context) {
                              return AddToPlaylistModal(song: song);
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            final musicService = MusicService();
                            final response = await musicService.deleteMusic(
                              song.id,
                            );

                            if (response.statusCode == 200 &&
                                response.data!['code'] == 200) {
                              final playerProvider =
                                  Provider.of<PlayerProvider>(
                                    context,
                                    listen: false,
                                  );

                              for (
                                int i = playerProvider.playlist.length - 1;
                                i >= 0;
                                i--
                              ) {
                                if (playerProvider.playlist[i].id == song.id) {
                                  playerProvider.removeSong(i);
                                }
                              }

                              setState(() {
                                searchResults.removeAt(index);
                                totalResults--;
                              });

                              ToastUtils.showSuccess(context, "删除歌曲成功");
                            } else {
                              ToastUtils.showError(context, "删除歌曲失败");
                            }
                          } catch (e) {
                            ToastUtils.showError(context, "删除歌曲失败");
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    final playerProvider = Provider.of<PlayerProvider>(
                      context,
                      listen: false,
                    );
                    final fullUrlMusic = Music(
                      id: song.id,
                      title: song.title,
                      artist: song.artist,
                      coverUrl: song.coverUrl,
                      musicUrl: song.musicUrl,
                      lyricUrl: song.lyricUrl,
                      uploaderId: song.uploaderId,
                      createdAt: song.createdAt,
                      isDeleted: song.isDeleted,
                    );
                    playerProvider.addSong(fullUrlMusic);
                    playerProvider.playSong(playerProvider.playlist.length - 1);
                  },
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('共 $totalResults 首音乐'),
              if (totalPages > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: widget.currentPage > 1
                          ? () => widget.onPageChanged(widget.currentPage - 1)
                          : null,
                    ),
                    ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                      int pageNumber;
                      if (totalPages <= 5) {
                        pageNumber = index + 1;
                      } else if (widget.currentPage <= 3) {
                        pageNumber = index + 1;
                      } else if (widget.currentPage >= totalPages - 2) {
                        pageNumber = totalPages - 4 + index;
                      } else {
                        pageNumber = widget.currentPage - 2 + index;
                      }

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: TextButton(
                          onPressed: () => widget.onPageChanged(pageNumber),
                          style: TextButton.styleFrom(
                            backgroundColor: widget.currentPage == pageNumber
                                ? Theme.of(context).primaryColor
                                : null,
                            foregroundColor: widget.currentPage == pageNumber
                                ? Colors.white
                                : null,
                            padding: EdgeInsets.all(8),
                            minimumSize: Size(30, 30),
                          ),
                          child: Text('$pageNumber'),
                        ),
                      );
                    }),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: widget.currentPage < totalPages
                          ? () => widget.onPageChanged(widget.currentPage + 1)
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
