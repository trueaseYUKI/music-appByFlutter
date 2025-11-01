// lib/provider/player_provider.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/models/music.dart';
import 'package:music_app/res/image_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 播放模式枚举
enum PlayMode {
  sequential, // 列表模式
  shuffle, // 随机播放
  single, // 单曲循环
}

/// 使用Provider 先继承 ChangeNotifier 对象
class PlayerProvider with ChangeNotifier {
  /// 音频播放器实例
  final AudioPlayer _player = AudioPlayer();

  /// 是否正在播放标志
  bool _isPlaying = false;

  /// 当前播放索引
  int _currentIndex = 0;

  /// 播放模式
  PlayMode _playMode = PlayMode.sequential;

  /// 播放列表
  List<Music> _playlist = [];

  /// 当前的播放位置
  Duration _position = Duration.zero;

  /// 歌曲总时长
  Duration _duration = Duration.zero;

  // Getters
  bool get isPlaying => _isPlaying;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  List<Music> get playlist => _playlist;
  Music? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  String get currentSongTitle => currentSong?.title ?? '未选择歌曲';
  String get currentArtist => currentSong?.artist ?? '未知艺术家';
  Duration get position => _position;
  Duration get duration => _duration;

  /// 构造函数中初始化播放器
  PlayerProvider() {
    _initPlayer();
  }

  /// 初始化音乐播放器
  void _initPlayer() {
    // 播放状态监听
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // 监听播放完成的事件
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });

    // 播放位置监听
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // 播放总时长监听
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Web端特殊处理：监听播放错误
    if (kIsWeb) {
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          print('Web端播放错误: $e');
        },
      );
    }
  }

  /// 处理播放完成事件
  void _handlePlaybackCompleted() {
    // 添加延迟确保状态正确更新
    Future.microtask(() {
      switch (_playMode) {
        case PlayMode.single:
          playSong(_currentIndex);
          break;
        case PlayMode.sequential:
          playSong((_currentIndex + 1) % _playlist.length);
          break;
        case PlayMode.shuffle:
          final randomIndex = (_playlist.length * Random().nextDouble())
              .floor();
          playSong(randomIndex);
          break;
      }
    });
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final song = _playlist[index];

    try {
      // 使用完整的音乐URL
      final fullMusicUrl = ImageUtils.getFullMusicUrl(song.musicUrl);

      // 先停止当前播放
      await _player.stop();

      // 设置新的音频源
      await _player.setAudioSource(AudioSource.uri(Uri.parse(fullMusicUrl)));

      // 开始播放
      await _player.play();
    } catch (e) {
      print('播放失败: $e');
    }
  }

  /// 控制播放/暂停
  void togglePlayPause() {
    print('播放状态：$_isPlaying');
    if (_isPlaying) {
      _player.pause();
    } else {
      print('播放列表：${_playlist.isNotEmpty}');
      if (_playlist.isNotEmpty) {
        if (currentSongTitle == '未选择歌曲') {
          playSong(0);
        } else {
          _player.play();
        }
      }
    }
  }

  /// 播放状态切换
  void toggleMode() {
    PlayMode nextMode;
    switch (playMode) {
      case PlayMode.sequential:
        nextMode = PlayMode.shuffle;
        break;
      case PlayMode.shuffle:
        nextMode = PlayMode.single;
        break;
      case PlayMode.single:
        nextMode = PlayMode.sequential;
        break;
    }
    _playMode = nextMode;
    notifyListeners();
  }

  /// 添加新歌曲到播放列表
  void addSong(Music song) {
    _playlist.add(song);
    notifyListeners();
  }

  /// 播放下一首
  void nextSong() {
    int nextIndex;
    if (_playMode == PlayMode.shuffle) {
      nextIndex = (_playlist.length * Random().nextDouble()).floor();
    } else {
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }

    // 直接调用playSong而不是递归调用
    playSong(nextIndex);
  }

  /// 播放上一首
  void previousSong() {
    if (_playMode == PlayMode.shuffle) {
      _currentIndex = (_playlist.length * Random().nextDouble()).floor();
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }
    playSong(_currentIndex);
  }

  /// 从播放列表中删除歌曲
  void removeSong(int index) {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);

    // 如果删除的是当前播放的音乐
    if (_currentIndex == index) {
      if (_playlist.isEmpty) {
        // 如果当前播放列表为空，则停止播放
        _player.stop();
        _currentIndex = 0;
      } else {
        playSong(index % _playlist.length);
      }
    } else if (index < _currentIndex) {
      // 如果删除的是当前播放歌曲之前的歌曲，调整索引
      _currentIndex--;
    }

    notifyListeners();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 设置播放列表
  void setPlaylist(List<Music> newPlaylist) {
    _playlist = newPlaylist;
    notifyListeners();
  }

  /// 释放资源
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
