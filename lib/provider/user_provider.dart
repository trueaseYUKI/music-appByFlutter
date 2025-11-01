import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:music_app/models/music.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static const String _USER_DATA_KEY = 'user_data';
  static const String _ACCESS_TOKEN_KEY = 'access_token';

  User? _user;
  String? _accessToken;

  User? get user => _user;
  String? get accessToken => _accessToken;

  // 从本地存储加载用户信息和token
  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_USER_DATA_KEY);
      final token = prefs.getString(_ACCESS_TOKEN_KEY);

      if (userDataString != null && token != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;

        _user = User.fromJson(userData);
        _accessToken = token;
        notifyListeners();
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
  }

  // 保存用户信息到本地存储
  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        final userDataString = jsonEncode(_user!.toJson());
        await prefs.setString(_USER_DATA_KEY, userDataString);
      }
      if (_accessToken != null) {
        await prefs.setString(_ACCESS_TOKEN_KEY, _accessToken!);
      }
    } catch (e) {
      print('保存用户信息失败: $e');
    }
  }

  // 清除本地存储的用户信息
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_USER_DATA_KEY);
      await prefs.remove(_ACCESS_TOKEN_KEY);
    } catch (e) {
      print('清除用户信息失败: $e');
    }
  }

  void setUser(User newUser, String token) {
    _user = newUser;
    _accessToken = token;
    notifyListeners();
    _saveUserToStorage();
  }

  void setToken(String token) {
    _accessToken = token;
    notifyListeners();
    _saveUserToStorage();
  }

  void clearUser() {
    _user = null;
    _accessToken = null;
    notifyListeners();
    _clearUserFromStorage();
  }

  void updateNickname(String newNickname) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nickname: newNickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: _user!.playlists,
      );
      notifyListeners();
      _saveUserToStorage();
    }
  }

  void updateAvatar(String newAvatar) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: newAvatar,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: _user!.playlists,
      );
      notifyListeners();
      _saveUserToStorage();
    }
  }

  // 歌单相关方法也需要添加保存操作
  void addPlaylist(Playlist newPlaylist) {
    if (_user != null) {
      final updatedPlaylists = [...?_user!.playlists, newPlaylist];
      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: updatedPlaylists,
      );
      notifyListeners();
      _saveUserToStorage();
    }
  }

  void updatePlaylist(Playlist updatedPlaylist) {
    if (_user != null && _user!.playlists != null) {
      final updatedPlaylists = _user!.playlists!.map((playlist) {
        if (playlist.id == updatedPlaylist.id) {
          return updatedPlaylist;
        }
        return playlist;
      }).toList();

      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: updatedPlaylists,
      );
      notifyListeners();
      _saveUserToStorage();
    }
  }

  void removePlaylist(int playlistId) {
    if (_user != null && _user!.playlists != null) {
      final updatedPlaylists = _user!.playlists!
          .where((playlist) => playlist.id != playlistId)
          .toList();

      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: updatedPlaylists,
      );
      notifyListeners();
      _saveUserToStorage();
    }
  }

  void incrementPlaylistSongCount(int playlistId) {
    if (_user != null && _user!.playlists != null) {
      final updatedPlaylists = _user!.playlists!.map((playlist) {
        if (playlist.id == playlistId) {
          // 只增加歌曲数量，不修改实际歌曲列表
          return Playlist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            coverUrl: playlist.coverUrl,
            creatorId: playlist.creatorId,
            musics: playlist.musics,
            songCount: playlist.songCount + 1, // 增加歌曲数量
            createdAt: playlist.createdAt,
            updatedAt: DateTime.now(),
            isDeleted: playlist.isDeleted,
          );
        }
        return playlist;
      }).toList();

      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: updatedPlaylists,
      );

      notifyListeners();
      _saveUserToStorage();
    }
  }

  // 在 UserProvider 类中添加以下方法
  void decrementPlaylistSongCount(int playlistId) {
    if (_user != null && _user!.playlists != null) {
      final updatedPlaylists = _user!.playlists!.map((playlist) {
        if (playlist.id == playlistId) {
          // 只减少歌曲数量，不修改实际歌曲列表
          return Playlist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            coverUrl: playlist.coverUrl,
            creatorId: playlist.creatorId,
            musics: playlist.musics,
            songCount: playlist.songCount > 0
                ? playlist.songCount - 1
                : 0, // 减少歌曲数量
            createdAt: playlist.createdAt,
            updatedAt: DateTime.now(),
            isDeleted: playlist.isDeleted,
          );
        }
        return playlist;
      }).toList();

      _user = User(
        id: _user!.id,
        nickname: _user!.nickname,
        email: _user!.email,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        isDeleted: _user!.isDeleted,
        playlists: updatedPlaylists,
      );

      notifyListeners();
      _saveUserToStorage();
    }
  }

  void logout() {
    _user = null;
    _accessToken = null;
    notifyListeners();
    _clearUserFromStorage();
  }
}
