# middleware/auth_middleware.py
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import time
from auth import verify_token, create_access_token, create_refresh_token
from datetime import timedelta
from crud import get_user
from database import SessionLocal
from auth import ACCESS_TOKEN_EXPIRE_MINUTES

class AuthenticationMiddleware(BaseHTTPMiddleware):
    """认证中间件，用于统一处理token验证"""

    # 不需要认证的路径
    SKIP_AUTH_PATHS = [
        "/users/send-code",
        "/users/login",
        "/users/refresh",
        "/health",
        "/",
        "/docs",
        "/openapi.json",
        "/redoc"
    ]

    async def dispatch(self, request: Request, call_next):
        # 检查是否需要跳过认证
        if self._should_skip_auth(request.url.path):
            return await call_next(request)

        # 获取并验证token
        try:
            payload = self._get_token_payload(request)
            request.state.user_payload = payload
        except HTTPException as e:
            return JSONResponse(
                status_code=e.status_code,
                content={"code": e.status_code, "msg": e.detail, "data": None}
            )
        except Exception as e:
            return JSONResponse(
                status_code=500,
                content={"code": 500, "msg": str(e), "data": None}
            )

        # 继续处理请求
        response = await call_next(request)
        return response

    def _should_skip_auth(self, path: str) -> bool:
        """判断是否需要跳过认证"""
        return any(path.startswith(skip_path) or path == skip_path for skip_path in self.SKIP_AUTH_PATHS) or \
            path.startswith("/uploads")

    def _get_token_payload(self, request: Request):
        """从请求头获取并验证token"""
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="未提供认证令牌")

        token = auth_header.split(" ")[1]
        payload = verify_token(token)
        if not payload:
            raise HTTPException(status_code=401, detail="无效的认证令牌")

        return payload


class TokenRefreshMiddleware(BaseHTTPMiddleware):
    """Token刷新中间件，用于在响应中添加新的token"""

    # 需要刷新token的路径前缀
    AUTH_REQUIRED_PATHS = ["/users/", "/musics/", "/playlists/"]

    async def dispatch(self, request: Request, call_next):

        response = await call_next(request)


        if not self._should_add_refresh_token(request.url.path):
            return response

        authorization = request.headers.get("Authorization")
        if not authorization or not authorization.startswith("Bearer "):
            return response  # 无 token，放行响应

        access_token = authorization.split(" ")[1]
        payload = verify_token(access_token)
        if not payload:
            return response  # token 无效，不刷新

        user_id = payload.get("user_id")
        if not user_id:
            return response


        db = SessionLocal()
        try:
            user = get_user(db, user_id)
            if user:
                new_payload = {"user_id": user.id, "email": user.email}
                new_token = create_access_token(
                    data=new_payload,
                    expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
                )
                response.headers["X-New-Access-Token"] = new_token
        finally:
            db.close()

        return response

    def _should_add_refresh_token(self, path: str) -> bool:
        skip_paths = ["/users/send-code", "/users/login", "/users/refresh"]
        if any(path.startswith(skip) for skip in skip_paths):
            return False
        return any(path.startswith(p) for p in self.AUTH_REQUIRED_PATHS)




def get_current_user_from_request(request: Request):
    """从请求中获取当前用户信息的依赖项"""
    # 从请求头获取认证信息
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="未提供认证令牌")

    # 解析token获取payload
    token = auth_header.split(" ")[1]
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="无效的认证令牌")

    # 从payload中解析用户ID
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="令牌中不包含用户信息")

    # 获取数据库会话并查询用户
    db = SessionLocal()
    try:
        user = get_user(db, user_id)
        if not user:
            raise HTTPException(status_code=401, detail="用户不存在")
        return user
    finally:
        db.close()

