from urllib.request import Request

import uvicorn
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.responses import JSONResponse

# 导入中间件
from middleware.auth_middleware import AuthenticationMiddleware, TokenRefreshMiddleware
from middleware.logging_middleware import RequestLoggingMiddleware

# 导入数据库初始化函数
from database import init_db

# 导入路由
from routes import user, music, playlist

# 导入日志配置
from config import logging_config



@asynccontextmanager
async def lifespan(app: FastAPI):
    # 应用启动时的初始化操作
    logging_config.setup_logging()
    init_db()
    # 设置安全方案
    app.openapi_schema = app.openapi()
    app.openapi_schema["components"] = app.openapi_schema.get("components", {})
    app.openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
    }
    yield
    # 应用关闭时的清理操作（如果需要）

def create_app():
    # 创建FastAPI应用实例，使用 lifespan 参数
    app = FastAPI(
        title="Music Server API",
        description="音乐服务器API",
        version="1.0.0",
        lifespan=lifespan
    )

    # 注册中间件
    app.add_middleware(RequestLoggingMiddleware)  # 日志中间件
    app.add_middleware(AuthenticationMiddleware)  # 认证中间件
    app.add_middleware(TokenRefreshMiddleware)  # Token刷新中间件

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["Authorization", "Content-Type"],  # 明确指定允许的头部
    )

    # 挂载静态文件目录
    os.makedirs("uploads/music", exist_ok=True)
    os.makedirs("uploads/cover", exist_ok=True)
    os.makedirs("uploads/lyrics", exist_ok=True)
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

    # 注册路由
    app.include_router(user.router)
    app.include_router(music.router)
    app.include_router(playlist.router)

    # 根路径
    @app.get("/")
    def read_root():
        return {"message": "Welcome to Music Server API"}

    # 健康检查端点
    @app.get("/health")
    def health_check():
        return {"status": "healthy"}

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        """全局异常处理器"""
        return JSONResponse(
            status_code=200,
            content={
                "code": 500,
                "msg": str(exc),
                "data": None
            }
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        """HTTP 异常处理器"""
        return JSONResponse(
            status_code=200,
            content={
                "code": exc.status_code,
                "msg": exc.detail,
                "data": None
            }
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        """请求验证异常处理器"""
        return JSONResponse(
            status_code=200,
            content={
                "code": 422,
                "msg": "请求参数验证失败",
                "data": exc.errors()
            }
        )

    return app


# 创建应用实例
app = create_app()

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="192.168.31.137",
        port=8000,
        reload=True,  # 开发环境下启用热重载
        log_level="info"
    )
