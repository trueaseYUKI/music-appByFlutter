from sqlalchemy.orm import Session
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Header
import os
import uuid
from database import SessionLocal
from crud import (
    get_music, get_musics, create_music, update_music, delete_music,
    search_musics, get_musics_by_uploader
)
from models import User
from middleware.auth_middleware import get_current_user_from_request
from schemas import MusicCreate, MusicUpdate, Music, SearchRequest, ResponseModel, MusicResponse, MusicSearchResult

router = APIRouter(prefix="/musics", tags=["musics"])

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# 修改路由装饰器，添加认证依赖
@router.post("/", response_model=ResponseModel[Music])
def create_new_music(
        title: str = Form(...),
        artist: str = Form(...),
        music_file: UploadFile = File(...),
        cover_file: UploadFile = File(None),
        lyric_file: UploadFile = File(None),
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    # 验证标题和艺术家长度
    if len(title) > 64:
        return ResponseModel(code=400, msg="歌曲名称长度不能超过64个字符", data=None)

    if len(artist) > 128:
        return ResponseModel(code=400, msg="歌曲作者名称长度不能超过128个字符", data=None)

    try:
        # 验证音乐文件
        if not validate_music_file(music_file):
            return ResponseModel(code=400, msg="不支持的音乐文件格式或文件过大", data=None)

        # 验证封面文件（如果有）
        if cover_file and not validate_image_file(cover_file):
            return ResponseModel(code=400, msg="封面图片文件过大或格式不支持", data=None)

        # 保存音乐文件
        music_filename = save_file(music_file, "music")
        music_url = f"/uploads/music/{music_filename}"

        # 保存封面文件（如果有）
        cover_url = None
        if cover_file and cover_file.size > 0:
            cover_filename = save_file(cover_file, "cover")
            cover_url = f"/uploads/cover/{cover_filename}"

        # 保存歌词文件（如果有）
        lyric_url = None
        if lyric_file and lyric_file.size > 0:
            lyric_filename = save_file(lyric_file, "lyric")
            lyric_url = f"/uploads/lyric/{lyric_filename}"

        # 创建音乐记录
        music_create = MusicCreate(title=title, artist=artist)
        result = create_music(
            db=db,
            music=music_create,
            uploader_id=current_user.id,
            music_url=music_url,
            cover_url=cover_url,
            lyric_url=lyric_url
        )
        return ResponseModel(code=200, msg="Music created successfully", data=result)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)


def validate_music_file(file: UploadFile) -> bool:
    """验证音乐文件"""
    # 支持的音乐格式
    allowed_types = [
    "audio/mpeg",
    "audio/wav",
    "audio/flac",
    "audio/x-flac",
    "audio/ogg",
    "audio/x-wav",
    "audio/aac",
    "audio/mp4",
    "audio/x-m4a"
    ]
    max_size = 200 * 1024 * 1024  # 200MB

    if file.content_type not in allowed_types:
        return False

    if file.size > max_size:
        return False

    return True


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

@router.get("/{music_id}", response_model=ResponseModel[Music])
def read_music(music_id: int, db: Session = Depends(get_db)):
    try:
        db_music = get_music(db, music_id=music_id)
        if db_music is None:
            return ResponseModel(code=404, msg="Music not found", data=None)
        return ResponseModel(code=200, msg="success", data=db_music)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)

@router.get("/", response_model=ResponseModel[List[Music]])
def read_musics(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        musics = get_musics(db, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=musics)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=[])

@router.get("/uploader/{uploader_id}", response_model=ResponseModel[List[Music]])
def read_musics_by_uploader(uploader_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        musics = get_musics_by_uploader(db, uploader_id=uploader_id, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=musics)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=[])

@router.post("/search", response_model=ResponseModel[MusicSearchResult])
def search_music(request: SearchRequest, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        musics = search_musics(db, keyword=request.keyword, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=musics)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=[])

@router.put("/{music_id}", response_model=ResponseModel[Music])
def update_music_info(music_id: int, music_update: MusicUpdate, db: Session = Depends(get_db)):
    try:
        db_music = update_music(db, music_id=music_id, music_update=music_update)
        if db_music is None:
            return ResponseModel(code=404, msg="Music not found", data=None)
        return ResponseModel(code=200, msg="Music updated successfully", data=db_music)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)

@router.delete("/{music_id}", response_model=ResponseModel[Music])
def delete_music_info(
        music_id: int,
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    try:
        db_music = delete_music(db, music_id=music_id, user_id=current_user.id)
        if db_music is None:
            return ResponseModel(code=404, msg="你没有删除这首歌的权限", data=None)
        return ResponseModel(code=200, msg="歌曲删除成功", data=db_music)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)





