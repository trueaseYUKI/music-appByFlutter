# config/logging_config.py
import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path

# 创建日志目录
LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)


# 日志配置
def setup_logging():
    """设置日志配置"""
    # 创建格式器
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # 创建旋转文件处理器（500MB大小限制）
    file_handler = RotatingFileHandler(
        filename=os.path.join(LOG_DIR, "music_server.log"),
        maxBytes=500 * 1024 * 1024,  # 500MB
        backupCount=5,  # 保留5个备份文件
        encoding='utf-8'
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)

    # 创建控制台处理器
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    console_handler.setLevel(logging.WARNING)

    # 配置根日志记录器
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    root_logger.addHandler(file_handler)
    root_logger.addHandler(console_handler)

    # 配置特定模块的日志记录器
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    logging.getLogger("fastapi").setLevel(logging.INFO)
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
