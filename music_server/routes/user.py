# routes/user.py
import os
import re
import uuid

from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
from database import SessionLocal
from crud import get_user, get_users, create_user, update_user, delete_user, get_user_by_email, \
    get_playlists_by_creator, get_playlists_by_creator_with_pagination
from schemas import UserCreate, UserUpdate, User, ResponseModel, LoginRequest, LoginResponse, \
    UserWithPlaylists, LoginRequestModel, PlaylistPaginationResult
from auth import send_verification_code, verify_code, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, is_code_expired
from middleware.auth_middleware import get_current_user_from_request
from models import User as UserModel
from datetime import timedelta


router = APIRouter(prefix="/users", tags=["users"])


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/send-code", response_model=ResponseModel[bool])
def send_code(request: LoginRequest):
    """发送验证码"""
    try:
        if not request.email.endswith("@qq.com"):
            return ResponseModel(code=400, msg="目前只支持QQ邮箱", data=False)

        # 这里要判断之前的验证码是否已经过期，没过期就不生成新的
        if not is_code_expired(request.email):
            return ResponseModel(code=400, msg="验证码已发送，请勿重复发送", data=False)

        if send_verification_code(request.email):
            return ResponseModel(code=200, msg="验证码发送成功", data=True)
        else:
            return ResponseModel(code=500, msg="验证码发送失败", data=False)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=False)



# 在 routes/user.py 中修改 login 接口
@router.post("/login", response_model=ResponseModel[LoginResponse])
def login(req:LoginRequestModel, db: Session = Depends(get_db)):
    """用户登录（验证码验证）"""
    try:
        # 验证验证码
        if not verify_code(req.email, req.code):
            return ResponseModel(code=400, msg="验证码错误或已过期", data=None)

        # 查找用户，如果不存在则创建
        user = get_user_by_email(db, email=req.email)
        if not user:
            # 创建新用户
            user_create = UserCreate(email=req.email)
            user = create_user(db=db, user=user_create)

        # 查询用户的所有歌单
        user_playlists = get_playlists_by_creator(db, creator_id=user.id, skip=0, limit=100)

        # 创建带歌单的用户信息
        user_with_playlists = UserWithPlaylists(
            id=user.id,
            email=user.email,
            nickname=user.nickname,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            playlists=user_playlists
        )

        # 创建访问令牌
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"user_id": user.id, "email": user.email},
            expires_delta=access_token_expires
        )

        login_response = LoginResponse(
            access_token=access_token,
            token_type="bearer",
            user=user_with_playlists  # 使用包含歌单的用户信息
        )

        return ResponseModel(code=200, msg="登录成功", data=login_response)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)



# 使用中间件认证，移除手动token验证
@router.get("/me", response_model=ResponseModel[UserWithPlaylists],
            dependencies=[Depends(get_current_user_from_request)])
def read_current_user(current_user: User = Depends(get_current_user_from_request), db: Session = Depends(get_db)):
    """获取当前用户信息及关联的歌单数据"""
    try:
        # 查询用户的所有歌单
        user_playlists = get_playlists_by_creator(db, creator_id=current_user.id, skip=0, limit=100)

        # 创建带歌单的用户信息
        user_with_playlists = UserWithPlaylists(
            id=current_user.id,
            email=current_user.email,
            nickname=current_user.nickname,
            avatar_url=current_user.avatar_url,
            created_at=current_user.created_at,
            playlists=user_playlists
        )

        return ResponseModel(code=200, msg="success", data=user_with_playlists)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)


@router.post("/", response_model=ResponseModel[User])
def create_new_user(user: UserCreate, db: Session = Depends(get_db)):
    try:
        db_user = get_user_by_email(db, email=user.email)
        if db_user:
            return ResponseModel(code=400, msg="Email already registered", data=None)
        result = create_user(db=db, user=user)
        return ResponseModel(code=200, msg="User created successfully", data=result)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)




@router.get("/{user_id}", response_model=ResponseModel[User])
def read_user(user_id: int, current_user: UserModel = Depends(get_current_user_from_request), db: Session = Depends(get_db)):
    try:
        db_user = get_user(db, user_id=user_id)
        if db_user is None:
            return ResponseModel(code=404, msg="User not found", data=None)
        return ResponseModel(code=200, msg="success", data=db_user)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)



@router.get("/", response_model=ResponseModel[List[User]])
def read_users(skip: int = 0, limit: int = 100, current_user: UserModel = Depends(get_current_user_from_request), db: Session = Depends(get_db)):
    try:
        users = get_users(db, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=users)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=[])



# 添加新的路由用于同时更新用户信息和头像
@router.put("/{user_id}/profile", response_model=ResponseModel[User])
def update_user_profile(
        user_id: int,
        nickname: str = Form(None),
        avatar_file: UploadFile = File(None),
        current_user: UserModel = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    try:
        # 只能更新自己的信息
        if current_user.id != user_id:
            return ResponseModel(code=403, msg="只能更新自己的信息", data=None)

        # 验证昵称长度
        if nickname is not None:
            if len(nickname) > 10:
                return ResponseModel(code=400, msg="昵称长度不能超过10个字符", data=None)
            if not re.match(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$', nickname):
                return ResponseModel(code=400, msg="昵称只能包含中文、英文、数字和下划线", data=None)

        # 构建更新数据
        update_data = {}
        if nickname is not None:
            update_data["nickname"] = nickname

        # 如果上传了头像文件，则保存并更新头像URL
        if avatar_file is not None and avatar_file.size > 0:
            if not validate_image_file(avatar_file):
                return ResponseModel(code=400, msg="头像图片文件过大或格式不支持", data=None)

            avatar_filename = save_file(avatar_file,"avatar")
            avatar_url = f"/uploads/avatar/{avatar_filename}"
            update_data["avatar_url"] = avatar_url

        # 如果没有提供任何更新数据，返回错误
        if not update_data:
            return ResponseModel(code=400, msg="没有提供要更新的信息", data=None)

        # 创建 UserUpdate 对象并更新用户信息
        user_update = UserUpdate(**update_data)
        db_user = update_user(db, user_id=user_id, user_update=user_update)
        if db_user is None:
            return ResponseModel(code=404, msg="User not found", data=None)

        return ResponseModel(code=200, msg="User updated successfully", data=db_user)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)


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


@router.delete("/{user_id}", response_model=ResponseModel[User])
def delete_user_info(
        user_id: int,
        current_user: UserModel = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    try:
        # 只能删除自己的账户
        if current_user.id != user_id:
            return ResponseModel(code=403, msg="只能删除自己的账户", data=None)

        db_user = delete_user(db, user_id=user_id)
        if db_user is None:
            return ResponseModel(code=404, msg="User not found", data=None)
        return ResponseModel(code=200, msg="User deleted successfully", data=db_user)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)



@router.get("/{user_id}/playlists", response_model=ResponseModel[PlaylistPaginationResult])
def read_user_playlists_pagination(
        user_id: int,
        skip: int = 0,
        limit: int = 10,
        current_user: User = Depends(get_current_user_from_request),
        db: Session = Depends(get_db)
):
    """分页获取用户创建的歌单列表，包含分页信息"""
    try:
        # 检查用户是否存在
        db_user = get_user(db, user_id=user_id)
        if db_user is None:
            return ResponseModel(code=404, msg="User not found", data=None)

        # 获取用户创建的歌单列表（分页）及分页信息
        result = get_playlists_by_creator_with_pagination(db, creator_id=user_id, skip=skip, limit=limit)
        return ResponseModel(code=200, msg="success", data=result)
    except Exception as e:
        return ResponseModel(code=500, msg=str(e), data=None)