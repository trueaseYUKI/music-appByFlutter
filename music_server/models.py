# models.py
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from database import Base
from datetime import datetime


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    nickname = Column(String, default="新用户")
    avatar_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)  # 逻辑删除标记


class Music(Base):
    __tablename__ = "musics"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    artist = Column(String)
    cover_url = Column(String)  # 封面图片URL
    music_url = Column(String)  # 歌曲文件URL
    lyric_url = Column(String)  # 歌词文件URL
    uploader_id = Column(Integer)  # 上传者ID
    created_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)  # 逻辑删除标记


class Playlist(Base):
    __tablename__ = "playlists"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    description = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    creator_id = Column(Integer)  # 创建者ID
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)  # 逻辑删除标记
    music_count = Column(Integer, default=0)  # 歌曲数量统计

class PlaylistMusic(Base):
    __tablename__ = "playlist_musics"

    id = Column(Integer, primary_key=True, index=True)
    playlist_id = Column(Integer)
    music_id = Column(Integer)
    added_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)  # 逻辑删除标记
