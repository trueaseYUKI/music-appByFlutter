# routes/playlist.py
from fastapi import APIRouter, Depends, HTTPException,Form, File, UploadFile
from sqlalchemy.orm import Session
from typing import List
from database import SessionLocal
from crud import (
    get_playlist, get_playlists, create_playlist, update_playlist, delete_playlist,
    add_music_to_playlist, remove_music_from_playlist, get_playlist_musics, get_music, get_user,
    get_playlists_by_creator_with_pagination
)
from middleware.auth_middleware import get_current_user_from_request
from models import User, Music, PlaylistMusic
from schemas import PlaylistCreate, PlaylistUpdate, Playlist, ResponseModel, PlaylistMusicInfo, \
    PlaylistPaginationResult, PlaylistMusicPaginationResult
import os
import uuid

router = APIRouter(prefix="/playlists", tags=["playlists"])

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 添加文件验证和保存函数（可复用 user.py 中的实现）
def validate_image_file(file: UploadFile) -> bool:
    """验证图片文件"""
    allowed_types = ["image/jpeg", "image/png", "image/gif"]
    max_size = 5 * 1024 * 1024  # 5MB

    if file.content_type not in allowed_types:
        return False

    if file.size > max_size:
        return False

    return True

def save_file(file: UploadFile, file_type: str) -> str:
    """保存文件到服务器"""
    # 创建目录
    upload_dir = f"uploads/{file_type}"
    os.makedirs(upload_dir, exist_ok=True)

    # 生成较短的 UUID 文件名（取前8位）
    short_uuid = str(uuid.uuid4())[:8]
    file_extension = file.filename.split(".")[-1] if "." in file.filename else ""
    filename = f"{short_uuid}.{file_extension}"
    file_path = os.path.join(upload_dir, filename)

    # 保存文件
    with open(file_path, "wb") as buffer:
        content = file.file.read()
        buffer.write(content)

    return filename


@router.post("/", response_model=ResponseModel[Playlist])
async def create_new_playlist_with_cover(
        name: str = Form(...),
        description: str = Form(None),
        cover_file: UploadFile = File(None),
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    # 验证歌单名称长度
    if len(name) > 25:
        return ResponseModel(code=400, msg="歌单名称长度不能超过25个字符", data=None)

    try:
        # 构造 PlaylistCreate 对象
        playlist_data = {
            "name": name,
            "description": description
        }

        # 处理封面文件
        cover_url = None
        if cover_file and cover_file.size > 0:
            if not validate_image_file(cover_file):
                return ResponseModel(code=400, msg="封面图片文件过大或格式不支持", data=None)
            cover_filename = save_file(cover_file, "cover")
            cover_url = f"/uploads/cover/{cover_filename}"
        else:
            cover_url = f"/uploads/cover/loveSongs.png"

        playlist_data["cover_url"] = cover_url

        # 创建歌单对象
        playlist = PlaylistCreate(**playlist_data)
        result = create_playlist(db=db, playlist=playlist, creator_id=current_user.id)
        return ResponseModel(code=200, msg="Playlist created successfully", data=result)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)


@router.get("/{playlist_id}", response_model=ResponseModel[Playlist])
def read_playlist(playlist_id: int, db: Session = Depends(get_db)):
    try:
        db_playlist = get_playlist(db, playlist_id=playlist_id)
        if db_playlist is None:
            return ResponseModel(code=404, msg="Playlist not found", data=None)
        return ResponseModel(code=200, msg="success", data=db_playlist)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)

@router.get("/", response_model=ResponseModel[List[Playlist]])
def read_playlists(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        playlists = get_playlists(db, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=playlists)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=[])



@router.put("/{playlist_id}", response_model=ResponseModel[Playlist])
async def update_playlist_info_with_cover(
        playlist_id: int,
        name: str = Form(None),
        description: str = Form(None),
        cover_file: UploadFile = File(None),
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    try:
        # 检查是否是歌单创建者
        db_playlist = get_playlist(db, playlist_id=playlist_id)
        if not db_playlist or db_playlist.creator_id != current_user.id:
            return ResponseModel(code=403, msg="只能修改自己创建的歌单", data=None)

        # 构造更新数据
        update_data = {}
        if name is not None:
            update_data["name"] = name
        if description is not None:
            update_data["description"] = description

        # 处理封面文件
        if cover_file and cover_file.size > 0:
            if not validate_image_file(cover_file):
                return ResponseModel(code=400, msg="封面图片文件过大或格式不支持", data=None)

            cover_filename = save_file(cover_file, "cover")
            cover_url = f"/uploads/cover/{cover_filename}"
            update_data["cover_url"] = cover_url

        # 如果没有任何更新内容
        if not update_data:
            return ResponseModel(code=400, msg="没有提供要更新的信息", data=None)

        playlist_update = PlaylistUpdate(**update_data)
        db_playlist = update_playlist(db, playlist_id=playlist_id, playlist_update=playlist_update)
        if db_playlist is None:
            return ResponseModel(code=404, msg="Playlist not found", data=None)
        return ResponseModel(code=200, msg="Playlist updated successfully", data=db_playlist)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)


@router.delete("/{playlist_id}", response_model=ResponseModel[Playlist])
def delete_playlist_info(
        playlist_id: int,
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    try:
        db_playlist = delete_playlist(db, playlist_id=playlist_id, user_id=current_user.id)
        if db_playlist is None:
            return ResponseModel(code=404, msg="Playlist not found or unauthorized", data=None)
        return ResponseModel(code=200, msg="Playlist deleted successfully", data=db_playlist)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)

@router.post("/{playlist_id}/musics/{music_id}", response_model=ResponseModel[dict])
def add_music_to_playlist_route(playlist_id: int, music_id: int, db: Session = Depends(get_db)):
    try:
        result = add_music_to_playlist(db, playlist_id=playlist_id, music_id=music_id)
        if result is None:
            return ResponseModel(code=404, msg="Failed to add music to playlist", data=None)
        return ResponseModel(code=200, msg="Music added to playlist successfully", data={"result": True})
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)

@router.delete("/{playlist_id}/musics/{music_id}", response_model=ResponseModel[dict])
def remove_music_from_playlist_route(playlist_id: int, music_id: int, db: Session = Depends(get_db)):
    try:
        result = remove_music_from_playlist(db, playlist_id=playlist_id, music_id=music_id)
        if result is None:
            return ResponseModel(code=404, msg="Failed to remove music from playlist", data=None)
        return ResponseModel(code=200, msg="Music removed from playlist successfully", data={"result": True})
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)



@router.get("/{playlist_id}/musics", response_model=ResponseModel[PlaylistMusicPaginationResult])
def get_playlist_musics_route(playlist_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        # 计算总记录数
        total_count = db.query(PlaylistMusic).join(
            Music, PlaylistMusic.music_id == Music.id
        ).filter(
            PlaylistMusic.playlist_id == playlist_id,
            PlaylistMusic.is_deleted == False,
            Music.is_deleted == False
        ).count()

        # 计算总页数
        total_pages = (total_count + limit - 1) // limit if limit > 0 else 0

        # 获取当前页数据
        query_result = db.query(PlaylistMusic, Music).join(
            Music, PlaylistMusic.music_id == Music.id
        ).filter(
            PlaylistMusic.playlist_id == playlist_id,
            PlaylistMusic.is_deleted == False,
            Music.is_deleted == False
        ).order_by(Music.id).offset(skip).limit(limit).all()

        # 构造音乐信息列表
        musics = []
        for pm, music in query_result:
            music_info = PlaylistMusicInfo(
                id=music.id,
                title=music.title,
                artist=music.artist,
                music_url=music.music_url,
                cover_url=music.cover_url,
                lyric_url=music.lyric_url,
                created_at=music.created_at,
            )
            musics.append(music_info)

        # 构造分页结果
        result = PlaylistMusicPaginationResult(
            musics=musics,
            total_count=total_count,
            total_pages=total_pages,
            current_page=skip // limit + 1 if limit > 0 else 1,
            page_size=limit
        )

        return ResponseModel(code=200, msg="success", data=result)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)








