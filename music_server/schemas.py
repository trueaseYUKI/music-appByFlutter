from pydantic import BaseModel, EmailStr
from datetime import datetime
from pydantic import field_validator
import re
# 在文件开头的导入部分添加 TypeVar 的导入
from typing import Optional, List, TypeVar, Generic  # 确保包含 TypeVar 和 Generic

T = TypeVar("T")
# ==================== 用户相关模型 ====================

# 用户基础模型 - 定义用户的基本信息字段
class UserBase(BaseModel):
    email: EmailStr  # 用户邮箱，使用EmailStr进行邮箱格式验证
    avatar_url: Optional[str] = None # 用户头像
    nickname: Optional[str] = None  # 用户昵称，可选字段


# 用户创建模型 - 用于用户注册/创建时的数据结构
class UserCreate(UserBase):
    @field_validator('email')
    def validate_qq_email(cls, v):
        if not re.match(r'^[a-zA-Z0-9._%+-]+@qq\.com$', v):
            raise ValueError('邮箱必须是有效的QQ邮箱')
        return v


# 用户信息更新模型 - 用于更新用户信息时的数据结构
class UserUpdate(BaseModel):
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None

    @field_validator('nickname')
    def validate_nickname(cls, v):
        if v is not None:
            if len(v) > 10:
                raise ValueError('昵称长度不能超过10个字符')
            if not re.match(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$', v):
                raise ValueError('昵称只能包含中文、英文、数字和下划线')
        return v


# 用户数据库基础模型 - 从数据库读取用户信息时的结构
class UserInDBBase(UserBase):
    id: int  # 用户唯一标识符
    avatar_url: Optional[str] = None  # 用户头像URL
    created_at: datetime  # 用户创建时间

    # Pydantic配置项，允许从ORM模型中读取数据
    class Config:
        from_attributes = True


# 用户响应模型 - 返回给前端的用户完整信息
class User(UserInDBBase):
    pass


# 带歌单信息的用户模型 - 包含用户创建的歌单列表
class UserWithPlaylists(UserInDBBase):
    playlists: List['Playlist'] = []  # 用户创建的歌单列表


# ==================== 认证相关模型 ====================

# 登录请求模型 - 用户登录时提交的邮箱信息
class LoginRequest(BaseModel):
    email: EmailStr  # 用户邮箱


# 验证码验证请求模型 - 验证邮箱验证码时的数据结构
class LoginRequestModel(BaseModel):
    email: str
    code: str



# ==================== 音乐相关模型 ====================

# 音乐基础模型 - 定义音乐的基本信息字段
class MusicBase(BaseModel):
    title: str
    artist: str

    @field_validator('title')
    def validate_title(cls, v):
        if len(v) > 64:
            raise ValueError('歌曲名称长度不能超过64个字符')
        return v

    @field_validator('artist')
    def validate_artist(cls, v):
        if len(v) > 128:
            raise ValueError('歌曲作者名称长度不能超过128个字符')
        return v


# 音乐创建模型 - 上传音乐时的数据结构
class MusicCreate(MusicBase):
    pass  # 继承MusicBase的所有字段


# 音乐更新模型 - 更新音乐信息时的数据结构
class MusicUpdate(BaseModel):
    title: Optional[str] = None  # 可选的音乐标题更新
    artist: Optional[str] = None  # 可选的艺术家更新


# 音乐数据库基础模型 - 从数据库读取音乐信息时的结构
class MusicInDBBase(MusicBase):
    id: int  # 音乐唯一标识符
    cover_url: Optional[str] = None  # 音乐封面图片URL
    music_url: str  # 音乐文件URL
    lyric_url: Optional[str] = None  # 歌词文件URL
    uploader_id: int  # 上传者用户ID
    created_at: datetime  # 音乐上传时间

    # Pydantic配置项，允许从ORM模型中读取数据
    class Config:
        from_attributes = True


# 音乐响应模型 - 返回给前端的音乐完整信息
class Music(MusicInDBBase):
    pass

class MusicResponse(BaseModel):
    id: int
    title: str
    artist: str
    music_url: str
    cover_url: Optional[str]
    lyric_url: Optional[str]
    uploader_id: int

    class Config:
        orm_mode = True


class MusicSearchResult(BaseModel):
    musics: List[Music]
    total_count: int
    total_page: int
    current_page: int
    page_size: int


# ==================== 歌单相关模型 ====================

# 歌单基础模型 - 定义歌单的基本信息字段

class PlaylistBase(BaseModel):
    name: str
    description: Optional[str] = None
    cover_url: Optional[str] = None

    @field_validator('name')
    def validate_name(cls, v):
        if len(v) > 25:
            raise ValueError('歌单名称长度不能超过25个字符')
        return v

class PlaylistCreate(PlaylistBase):
    @field_validator('name')
    def validate_name(cls, v):
        if len(v) > 25:
            raise ValueError('歌单名称长度不能超过25个字符')
        return v


# 修改 PlaylistUpdate 类
class PlaylistUpdate(BaseModel):
    name: Optional[str] = None  # 可选的歌单名称更新
    description: Optional[str] = None  # 可选的歌单描述更新
    cover_url: Optional[str] = None  # 可选的歌单封面URL更新

    @field_validator('name')
    def validate_name(cls, v):
        if v is not None:
            if len(v) > 25:
                raise ValueError('歌单名称长度不能超过25个字符')
        return v


# 歌单数据库基础模型 - 从数据库读取歌单信息时的结构
# schemas.py
# ...其他导入...

class PlaylistBase(BaseModel):
    name: str
    description: Optional[str] = None
    cover_url: Optional[str] = None
    music_count: int = 0  # 添加歌曲计数字段

    @field_validator('name')
    def validate_name(cls, v):
        if len(v) > 25:
            raise ValueError('歌单名称长度不能超过25个字符')
        return v

# ...其他类定义...

class PlaylistInDBBase(PlaylistBase):
    id: int  # 歌单唯一标识符
    cover_url: Optional[str] = None  # 歌单封面URL
    creator_id: int  # 创建者用户ID
    created_at: datetime  # 歌单创建时间
    updated_at: datetime  # 歌单最后更新时间

    # Pydantic配置项，允许从ORM模型中读取数据
    class Config:
        from_attributes = True




# 歌单响应模型 - 返回给前端的歌单完整信息（包含音乐列表）
class Playlist(PlaylistInDBBase):
    musics: List[Music] = []  # 歌单中的音乐列表


class PlaylistPaginationResult(BaseModel):
    playlists: List[Playlist]
    total_count: int
    total_pages: int
    current_page: int
    page_size: int

    class Config:
        from_attributes = True


# ==================== 歌单音乐关联模型 ====================

# 歌单音乐关联基础模型 - 定义歌单与音乐关联的基本字段
class PlaylistMusicBase(BaseModel):
    playlist_id: int  # 歌单ID
    music_id: int  # 音乐ID


# 歌单音乐关联创建模型 - 向歌单添加音乐时的数据结构
class PlaylistMusicCreate(PlaylistMusicBase):
    pass  # 继承PlaylistMusicBase的所有字段


# 歌单音乐关联数据库模型 - 从数据库读取关联信息时的结构
class PlaylistMusicInDB(PlaylistMusicBase):
    id: int  # 关联记录唯一标识符
    added_at: datetime  # 音乐添加到歌单的时间

    # Pydantic配置项，允许从ORM模型中读取数据
    class Config:
        from_attributes = True



class PlaylistMusicInfo(BaseModel):
    id: int
    title: str
    artist: str
    music_url: str
    cover_url: Optional[str] = None
    lyric_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class PlaylistMusicPaginationResult(BaseModel):
    musics: List[PlaylistMusicInfo]
    total_count: int
    total_pages: int
    current_page: int
    page_size: int

    class Config:
        from_attributes = True


# ==================== 其他功能模型 ====================

# 搜索请求模型 - 用户搜索音乐时的数据结构
class SearchRequest(BaseModel):
    keyword: str  # 搜索关键词


# JWT令牌响应模型 - 用户认证成功后返回的令牌信息
class Token(BaseModel):
    access_token: str  # 访问令牌
    token_type: str  # 令牌类型（通常是bearer）


# JWT令牌数据模型 - 令牌中包含的用户信息
class TokenData(BaseModel):
    email: Optional[str] = None  # 用户邮箱，可选字段







# 添加文件上传相关模型
class MusicUploadRequest(BaseModel):
    title: str
    artist: str

    @field_validator('title')
    def validate_title(cls, v):
        if len(v) > 64:
            raise ValueError('歌曲名称长度不能超过64个字符')
        return v


# 添加认证相关模型
class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserWithPlaylists  # 修改为包含歌单的用户模型




# 替换重复的 ResponseModel 定义为：
class ResponseModel(BaseModel, Generic[T]):
    code: int = 200
    msg: str = "success"
    data: T = None

    class Config:
        from_attributes = True
