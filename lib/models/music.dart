// models/user.dart
class User {
  final int id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final List<Playlist>? playlists; // 添加 playlists 属性

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.playlists, // 添加 playlists 参数
  });

  // 从 JSON 创建 User 实例
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'] ?? '新用户',
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
      playlists: (json['playlists'] as List<dynamic>?)
          ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(), // 解析 playlists
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'playlists': playlists?.map((e) => e.toJson()).toList(), // 序列化 playlists
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    List<Playlist>? playlists,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, nickname: $nickname, avatarUrl: $avatarUrl,playlists:$playlists)';
  }
}

// models/music.dart
class Music {
  final int id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String musicUrl;
  final String? lyricUrl;
  final int uploaderId;
  final DateTime createdAt;
  final bool isDeleted;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.musicUrl,
    this.lyricUrl,
    required this.uploaderId,
    required this.createdAt,
    required this.isDeleted,
  });

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      coverUrl: json['cover_url'],
      musicUrl: json['music_url'] ?? '',
      lyricUrl: json['lyric_url'],
      uploaderId: json['uploader_id'] is int ? json['uploader_id'] : 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Music(id: $id, title: $title, artist: $artist, coverUrl: $coverUrl,musicUrl:$musicUrl,lyricUrl:$lyricUrl,uploaderId:$uploaderId)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'cover_url': coverUrl,
      'music_url': musicUrl,
      'lyric_url': lyricUrl,
      'uploader_id': uploaderId,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}

class Playlist {
  final int id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int creatorId;
  final List<Music> musics;
  final int songCount; // 添加歌曲数量属性
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.musics = const [],
    required this.creatorId,
    required this.songCount, // 添加 songCount 参数，默认为 0
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  Playlist.empty()
    : id = 0,
      name = '',
      description = null,
      coverUrl = null,
      creatorId = 0,
      musics = const [],
      songCount = 0, // 初始化为 0
      createdAt = DateTime(0),
      updatedAt = DateTime(0),
      isDeleted = false;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverUrl: json['cover_url'],
      creatorId: json['creator_id'],
      musics:
          (json['musics'] as List<dynamic>?)
              ?.map((e) => Music.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      songCount:
          json['music_count'] ??
          json['song_count'] ??
          json['musics']?.length ??
          0, // 修改这一行
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_url': coverUrl,
      'creator_id': creatorId,
      'musics': musics.map((e) => e.toJson()).toList(),
      'song_count': songCount, // 确保这一行存在
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, song_count: $songCount, cover_url: $coverUrl)';
  }
}

// models/playlist_music.dart
class PlaylistMusic {
  final int id;
  final int playlistId;
  final int musicId;
  final DateTime addedAt;
  final bool isDeleted;

  PlaylistMusic({
    required this.id,
    required this.playlistId,
    required this.musicId,
    required this.addedAt,
    required this.isDeleted,
  });

  factory PlaylistMusic.fromJson(Map<String, dynamic> json) {
    return PlaylistMusic(
      id: json['id'],
      playlistId: json['playlist_id'],
      musicId: json['music_id'],
      addedAt: DateTime.parse(json['added_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'music_id': musicId,
      'added_at': addedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
