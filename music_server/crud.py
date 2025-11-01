from schemas import MusicUpdate
from sqlalchemy.orm import Session
from models import User, Music, Playlist, PlaylistMusic
from schemas import UserCreate, UserUpdate, MusicCreate, PlaylistCreate, PlaylistUpdate
from datetime import datetime
import random
import string
from typing import Optional, List
from sqlalchemy.exc import SQLAlchemyError



# ==================== 用户相关操作 ====================

def get_user(db: Session, user_id: int):
    """根据用户ID获取用户信息"""
    return db.query(User).filter(User.id == user_id, User.is_deleted == False).first()



def get_user(db: Session, user_id: int) -> Optional[User]:
    """根据用户ID获取用户信息"""
    return db.query(User).filter(User.id == user_id, User.is_deleted == False).first()

def get_users(db: Session, skip: int = 0, limit: int = 100) -> List[User]:
    """获取用户列表（分页）"""
    return db.query(User).filter(User.is_deleted == False).offset(skip).limit(limit).all()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """根据邮箱获取用户信息"""
    return db.query(User).filter(User.email == email, User.is_deleted == False).first()



def create_user(db: Session, user: UserCreate):
    """创建新用户，并生成默认歌单"""
    try:
        db_user = User(
            email=user.email,
            nickname=user.nickname or f"用户{''.join(random.choices(string.digits, k=6))}",
            avatar_url="/uploads/cover/default.jpg"  # 设置默认头像
        )
        db.add(db_user)
        db.flush()  # 使用flush而不是commit，以便获取ID但不提交事务

        # 创建默认歌单"我喜欢的歌曲"
        default_playlist = Playlist(
            name="我喜欢的歌曲",
            description="默认创建的歌单",
            creator_id=db_user.id,
            is_deleted=False,
            cover_url="/uploads/cover/loveSongs.png"
        )
        db.add(default_playlist)
        db.commit()  # 提交整个事务
        db.refresh(db_user)
        db.refresh(default_playlist)
        return db_user
    except SQLAlchemyError as e:
        db.rollback()  # 发生异常时回滚
        raise e
    except Exception as e:
        db.rollback()
        raise e



# 修改 update_user 函数以正确处理头像更新
def update_user(db: Session, user_id: int, user_update: UserUpdate):
    """更新用户信息"""
    try:
        db_user = db.query(User).filter(User.id == user_id, User.is_deleted == False).first()
        if db_user:
            if user_update.nickname is not None:
                db_user.nickname = user_update.nickname
            if user_update.avatar_url is not None:
                db_user.avatar_url = user_update.avatar_url
            db_user.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise e



def delete_user(db: Session, user_id: int):
    """逻辑删除用户及其相关内容"""
    try:
        # 逻辑删除用户上传的音乐
        db.query(Music).filter(Music.uploader_id == user_id).update({"is_deleted": True})

        # 逻辑删除用户创建的歌单
        db.query(Playlist).filter(Playlist.creator_id == user_id).update({"is_deleted": True})

        # 逻辑删除用户
        db_user = db.query(User).filter(User.id == user_id).first()
        if db_user:
            db_user.is_deleted = True
            db.commit()
            db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise e



# ==================== 音乐相关操作 ====================

def get_music(db: Session, music_id: int):
    """根据音乐ID获取音乐信息"""
    return db.query(Music).filter(Music.id == music_id, Music.is_deleted == False).first()


def get_musics(db: Session, skip: int = 0, limit: int = 100):
    """获取音乐列表（分页）"""
    return db.query(Music).filter(Music.is_deleted == False).offset(skip).limit(limit).all()


def get_musics_by_uploader(db: Session, uploader_id: int, skip: int = 0, limit: int = 100):
    """根据上传者ID获取音乐列表（分页）"""
    return db.query(Music).filter(Music.uploader_id == uploader_id, Music.is_deleted == False).offset(skip).limit(
        limit).all()


def search_musics(db: Session, keyword: str, skip: int = 0, limit: int = 100):
    """搜索音乐并返回分页信息"""
    # 查询符合条件的音乐总数
    total_count = db.query(Music).filter(
        (Music.title.contains(keyword)) | (Music.artist.contains(keyword)),
        Music.is_deleted == False
    ).count()

    # 计算总页数
    total_pages = (total_count + limit - 1) // limit if limit > 0 else 0

    # 查询当前页的音乐列表
    musics = db.query(Music).filter(
        (Music.title.contains(keyword)) | (Music.artist.contains(keyword)),
        Music.is_deleted == False
    ).offset(skip).limit(limit).all()

    # 返回搜索结果和分页信息
    return {
        "musics": musics if musics else [],
        "total_count": total_count,
        "total_page": total_pages,
        "current_page": skip // limit + 1 if limit > 0 else 1,
        "page_size": limit
    }


def create_music(db: Session, music: MusicCreate, music_url:str,cover_url:str,lyric_url:str,uploader_id: int):
    """创建新音乐"""
    try:
        db_music = Music(
            title=music.title,
            artist=music.artist,
            music_url=music_url,
            cover_url=cover_url,
            lyric_url=lyric_url,
            uploader_id=uploader_id
        )
        db.add(db_music)
        db.commit()
        db.refresh(db_music)
        return db_music
    except SQLAlchemyError as e:
        db.rollback()
        raise e
    except Exception as e:
        db.rollback()
        raise e


def update_music(db: Session, music_id: int, music_update: MusicUpdate):
    """更新音乐信息"""
    try:
        db_music = db.query(Music).filter(Music.id == music_id, Music.is_deleted == False).first()
        if db_music:
            if music_update.title is not None:
                db_music.title = music_update.title
            if music_update.artist is not None:
                db_music.artist = music_update.artist
            db.commit()
            db.refresh(db_music)
        return db_music
    except Exception as e:
        db.rollback()
        raise e


def delete_music(db: Session, music_id: int, user_id: int):
    """逻辑删除音乐（只有上传者才能删除）"""
    try:
        db_music = db.query(Music).filter(Music.id == music_id).first()
        if db_music and db_music.uploader_id == user_id:
            db_music.is_deleted = True

            # +++ 新增部分：同时逻辑删除该音乐在所有歌单中的关联 +++
            db.query(PlaylistMusic).filter(PlaylistMusic.music_id == music_id).update({"is_deleted": True})

            db.commit()
            db.refresh(db_music)
            return db_music
        return None
    except Exception as e:
        db.rollback()
        raise e



# ==================== 歌单相关操作 ====================

def get_playlist(db: Session, playlist_id: int):
    """根据歌单ID获取歌单信息"""
    return db.query(Playlist).filter(Playlist.id == playlist_id, Playlist.is_deleted == False).first()


def get_playlists(db: Session, skip: int = 0, limit: int = 100):
    """获取歌单列表（分页）"""
    return db.query(Playlist).filter(Playlist.is_deleted == False).offset(skip).limit(limit).all()


def get_playlists_by_creator(db: Session, creator_id: int, skip: int = 0, limit: int = 100):
    """根据创建者ID获取歌单列表（分页）"""
    return db.query(Playlist).filter(Playlist.creator_id == creator_id, Playlist.is_deleted == False).offset(
        skip).limit(limit).all()

def create_playlist(db: Session, playlist: PlaylistCreate, creator_id: int):
    """创建新歌单"""
    try:
        db_playlist = Playlist(
            name=playlist.name,
            description=playlist.description,
            cover_url=playlist.cover_url,
            creator_id=creator_id
        )
        db.add(db_playlist)
        db.commit()
        db.refresh(db_playlist)
        return db_playlist
    except Exception as e:
        db.rollback()
        raise e


def update_playlist(db: Session, playlist_id: int, playlist_update: PlaylistUpdate):
    """更新歌单信息"""
    try:
        db_playlist = db.query(Playlist).filter(Playlist.id == playlist_id, Playlist.is_deleted == False).first()
        if db_playlist:
            if playlist_update.name is not None:
                db_playlist.name = playlist_update.name
            if playlist_update.description is not None:
                db_playlist.description = playlist_update.description
            if playlist_update.cover_url is not None:
                db_playlist.cover_url = playlist_update.cover_url
            db_playlist.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(db_playlist)
        return db_playlist
    except Exception as e:
        db.rollback()
        raise e


def delete_playlist(db: Session, playlist_id: int, user_id: int):
    """逻辑删除歌单（只有创建者才能删除）"""
    try:
        # 在 delete_playlist 函数中有拼写错误
        db.query(PlaylistMusic).filter(PlaylistMusic.playlist_id == playlist_id).update({"is_deleted": True})

        # 再逻辑删除歌单
        db_playlist = db.query(Playlist).filter(Playlist.id == playlist_id).first()
        if db_playlist and db_playlist.creator_id == user_id:
            db_playlist.is_deleted = True
            db.commit()
            db.refresh(db_playlist)
            return db_playlist
        return None
    except Exception as e:
        db.rollback()
        raise e


def get_playlists_by_creator_with_pagination(db: Session, creator_id: int, skip: int = 0, limit: int = 100):
    """根据创建者ID获取歌单列表（分页）并返回分页信息"""
    # 查询符合条件的歌单总数
    total_count = db.query(Playlist).filter(
        Playlist.creator_id == creator_id,
        Playlist.is_deleted == False
    ).count()

    # 计算总页数
    total_pages = (total_count + limit - 1) // limit if limit > 0 else 0

    # 查询当前页的歌单列表
    playlists = db.query(Playlist).filter(
        Playlist.creator_id == creator_id,
        Playlist.is_deleted == False
    ).offset(skip).limit(limit).all()

    return {
        "playlists": playlists,
        "total_count": total_count,
        "total_pages": total_pages,
        "current_page": skip // limit + 1 if limit > 0 else 1,
        "page_size": limit
    }


# ==================== 歌单音乐关联操作 ====================
def add_music_to_playlist(db: Session, playlist_id: int, music_id: int):
    """向歌单添加音乐"""
    try:
        # 检查关联是否已存在且未被删除
        existing = db.query(PlaylistMusic).filter(
            PlaylistMusic.playlist_id == playlist_id,
            PlaylistMusic.music_id == music_id
        ).first()

        if existing and not existing.is_deleted:
            return existing

        if existing and existing.is_deleted:
            # 如果已存在但被标记为删除，则恢复
            existing.is_deleted = False
            # 增加歌单的歌曲计数
            db_playlist = db.query(Playlist).filter(Playlist.id == playlist_id, Playlist.is_deleted == False).first()
            if db_playlist:
                db_playlist.music_count += 1
            db.commit()
            db.refresh(existing)
            return existing

        db_playlist_music = PlaylistMusic(
            playlist_id=playlist_id,
            music_id=music_id
        )
        db.add(db_playlist_music)

        # 增加歌单的歌曲计数
        db_playlist = db.query(Playlist).filter(Playlist.id == playlist_id, Playlist.is_deleted == False).first()
        if db_playlist:
            db_playlist.music_count += 1

        db.commit()
        db.refresh(db_playlist_music)
        if db_playlist:
            db.refresh(db_playlist)
        return db_playlist_music
    except Exception as e:
        db.rollback()
        raise e


def remove_music_from_playlist(db: Session, playlist_id: int, music_id: int):
    """从歌单移除音乐（逻辑删除）"""
    try:
        db_playlist_music = db.query(PlaylistMusic).filter(
            PlaylistMusic.playlist_id == playlist_id,
            PlaylistMusic.music_id == music_id
        ).first()

        if db_playlist_music and not db_playlist_music.is_deleted:
            db_playlist_music.is_deleted = True
            # 减少歌单的歌曲计数
            db_playlist = db.query(Playlist).filter(Playlist.id == playlist_id, Playlist.is_deleted == False).first()
            if db_playlist and db_playlist.music_count > 0:
                db_playlist.music_count -= 1
            db.commit()
            db.refresh(db_playlist_music)
            if db_playlist:
                db.refresh(db_playlist)
        return db_playlist_music
    except Exception as e:
        db.rollback()
        raise e




def get_playlist_musics(db: Session, playlist_id: int, skip: int = 0, limit: int = 100):
    """获取歌单中的所有音乐（分页）"""
    return db.query(PlaylistMusic).filter(
        PlaylistMusic.playlist_id == playlist_id,
        PlaylistMusic.is_deleted == False
    ).offset(skip).limit(limit).all()


def get_music_playlists(db: Session, music_id: int, skip: int = 0, limit: int = 100):
    """获取包含指定音乐的所有歌单（分页）"""
    return db.query(PlaylistMusic).filter(
        PlaylistMusic.music_id == music_id,
        PlaylistMusic.is_deleted == False
    ).offset(skip).limit(limit).all()


