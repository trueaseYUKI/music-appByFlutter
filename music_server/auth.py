# auth.py
import smtplib
import random
import string
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from jose import jwt
from typing import Optional
import os
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor
import json
import redis

# 加载环境变量
load_dotenv()

# JWT配置
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 24 * 60  # Token存活24小时

# 邮箱配置
EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS", "your-email@qq.com")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "your-email-password")

# Redis配置
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

# 创建Redis连接
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB, decode_responses=True)

# 创建全局线程池
email_executor = ThreadPoolExecutor(max_workers=5)


def generate_verification_code(length: int = 6) -> str:
    """生成指定位数的验证码"""
    return ''.join(random.choices(string.digits, k=length))


def _send_email_sync(email: str, msg: MIMEMultipart) -> bool:
    """同步发送邮件的辅助函数"""
    try:
        server = smtplib.SMTP_SSL('smtp.qq.com', 465)
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        text = msg.as_string()
        server.sendmail(EMAIL_ADDRESS, email, text)
        server.quit()
        return True
    except Exception as e:
        print(f"发送邮件失败: {e}")
        return False

def send_verification_code(email: str) -> bool:
    """在线程池中发送验证码到指定邮箱"""
    try:
        # 生成验证码
        code = generate_verification_code()

        # 存储到Redis，设置5分钟过期时间
        redis_key = f"verification_code:{email}"
        redis_client.setex(redis_key, 2 * 60, code)  # 直接存储验证码，5分钟后自动过期

        # 创建邮件
        msg = MIMEMultipart()
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = email
        msg['Subject'] = "Yuki音乐验证码"

        body = f"您的验证码是: 【{code}】，2分钟内有效，请勿泄露给他人"
        msg.attach(MIMEText(body, 'plain', 'utf-8'))

        # 在线程池中执行发送邮件操作
        email_executor.submit(_send_email_sync, email, msg)

        return True
    except Exception as e:
        print(f"发送邮件失败: {e}")
        return False

def is_code_expired(email: str) -> bool:
    """检查验证码是否过期"""
    redis_key = f"verification_code:{email}"
    return not redis_client.exists(redis_key)


def verify_code(email: str, code: str) -> bool:
    """验证邮箱验证码"""
    redis_key = f"verification_code:{email}"
    stored_code = redis_client.get(redis_key)

    if not stored_code:
        return False

    # 检查验证码是否正确
    if stored_code != code:
        return False

    # 验证成功后删除验证码
    # redis_client.delete(redis_key)
    return True


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """创建访问令牌"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_token(token: str) -> Optional[dict]:
    """验证令牌"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None


def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None):
    """创建刷新令牌"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        # 刷新令牌默认7天有效期
        expire = datetime.utcnow() + timedelta(days=7)

    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_refresh_token(token: str) -> Optional[dict]:
    """验证刷新令牌"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # 检查令牌类型是否为refresh
        if payload.get("type") != "refresh":
            return None
        return payload
    except jwt.PyJWTError:
        return None
