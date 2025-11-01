import logging
import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("music_server.request")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """请求日志记录中间件"""

    async def dispatch(self, request: Request, call_next):
        # 记录请求开始时间
        start_time = time.time()

        # 记录请求信息
        logger.info(f"Request: {request.method} {request.url} - Client: {request.client.host}")

        try:
            # 处理请求
            response = await call_next(request)

            # 计算处理时间
            process_time = time.time() - start_time

            # 记录响应信息
            logger.info(
                f"Response: {response.status_code} - "
                f"Process time: {process_time:.4f}s - "
                f"Method: {request.method} - "
                f"Path: {request.url.path}"
            )

            return response

        except Exception as e:
            # 记录异常信息
            process_time = time.time() - start_time
            logger.error(
                f"Error processing request: {str(e)} - "
                f"Process time: {process_time:.4f}s - "
                f"Method: {request.method} - "
                f"Path: {request.url.path}",
                exc_info=True
            )
            raise
