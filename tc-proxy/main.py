"""
SenseVoice 繁體中文轉換代理

在 SenseVoice API 前加一層代理，自動將簡體中文識別結果轉換為香港繁體中文。
使用 OpenCC (s2hk) 轉換規則，針對澳門/香港用語優化。
"""

import os
import logging
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse, Response
import opencc

# 配置
SENSEVOICE_API_URL = os.getenv("SENSEVOICE_API_URL", "http://sensevoice-api:10095")
PROXY_PORT = int(os.getenv("PROXY_PORT", "10096"))
OPENCC_CONFIG = os.getenv("OPENCC_CONFIG", "s2hk")  # 簡體→香港繁體

# 日誌配置
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# OpenCC 轉換器
converter = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """應用生命週期管理"""
    global converter
    try:
        converter = opencc.OpenCC(OPENCC_CONFIG)
        logger.info(f"✅ OpenCC 轉換器已初始化: {OPENCC_CONFIG}")
    except Exception as e:
        logger.error(f"❌ OpenCC 初始化失敗: {e}")
        raise
    yield
    logger.info("🛑 代理服務關閉")


app = FastAPI(
    title="SenseVoice 繁體中文轉換代理",
    description="自動將 SenseVoice API 的簡體中文結果轉換為香港繁體中文",
    version="1.0.0",
    lifespan=lifespan,
)


def convert_to_traditional_chinese(text: str) -> str:
    """將簡體中文轉換為香港繁體中文"""
    if not text or not converter:
        return text
    try:
        return converter.convert(text)
    except Exception as e:
        logger.warning(f"轉換失敗: {e}")
        return text


def process_response(data: dict) -> dict:
    """處理 API 響應，轉換文本為繁體中文"""
    if not isinstance(data, dict):
        return data

    # 轉換主要文本字段
    if "text" in data:
        data["text"] = convert_to_traditional_chinese(data["text"])

    # 轉換 segments（如果有）
    if "segments" in data and isinstance(data["segments"], list):
        for segment in data["segments"]:
            if "text" in segment:
                segment["text"] = convert_to_traditional_chinese(segment["text"])

    # 轉換 words（如果有）
    if "words" in data and isinstance(data["words"], list):
        for word in data["words"]:
            if "word" in word:
                word["word"] = convert_to_traditional_chinese(word["word"])

    return data


@app.get("/")
async def root():
    """根路徑"""
    return {
        "service": "SenseVoice 繁體中文轉換代理",
        "status": "running",
        "upstream": SENSEVOICE_API_URL,
        "converter": OPENCC_CONFIG,
    }


@app.get("/health")
async def health():
    """健康檢查"""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{SENSEVOICE_API_URL}/health", timeout=5.0)
            upstream_status = resp.status_code == 200
    except Exception as e:
        upstream_status = False
        logger.warning(f"上游服務檢查失敗: {e}")

    return {
        "status": "ok" if upstream_status else "degraded",
        "proxy": "running",
        "upstream": "healthy" if upstream_status else "unhealthy",
        "converter": OPENCC_CONFIG,
    }


@app.get("/v1/models")
async def list_models():
    """代理模型列表（直接透傳）"""
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{SENSEVOICE_API_URL}/v1/models", timeout=10.0)
        return JSONResponse(content=resp.json(), status_code=resp.status_code)


@app.post("/v1/audio/transcriptions")
async def transcribe(
    file: UploadFile = File(...),
    model: str = Form(...),
    language: str = Form(None),
    prompt: str = Form(None),
    response_format: str = Form("json"),
    temperature: float = Form(0.0),
    timestamp_granularities: str = Form(None),
):
    """
    代理語音轉文字端點

    轉發請求到 SenseVoice API，並將結果轉換為繁體中文。
    """
    # 構建轉發的表單數據
    files = {"file": (file.filename, await file.read(), file.content_type)}
    data = {"model": model}

    if language:
        data["language"] = language
    if prompt:
        data["prompt"] = prompt
    if response_format:
        data["response_format"] = response_format
    if temperature:
        data["temperature"] = str(temperature)
    if timestamp_granularities:
        data["timestamp_granularities"] = timestamp_granularities

    # 轉發請求到上游 API
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{SENSEVOICE_API_URL}/v1/audio/transcriptions",
                files=files,
                data=data,
                timeout=60.0,
            )
    except httpx.RequestError as e:
        logger.error(f"轉發請求失敗: {e}")
        raise HTTPException(status_code=502, detail=f"上游服務請求失敗: {str(e)}")

    # 處理響應
    if resp.status_code != 200:
        return Response(content=resp.content, status_code=resp.status_code)

    # 根據 response_format 處理
    if response_format == "verbose_json":
        result = resp.json()
        result = process_response(result)
        return JSONResponse(content=result)
    elif response_format in ("text", "srt", "vtt"):
        # 純文本格式，直接轉換
        text = resp.text
        converted = convert_to_traditional_chinese(text)
        return Response(content=converted, media_type="text/plain")
    else:
        # 默認 json 格式
        result = resp.json()
        result = process_response(result)
        return JSONResponse(content=result)


# 透傳其他所有請求
@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def proxy_all(path: str, request: Request):
    """透傳其他所有請求"""
    url = f"{SENSEVOICE_API_URL}/{path}"

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.request(
                method=request.method,
                url=url,
                headers=dict(request.headers),
                content=await request.body(),
                timeout=30.0,
            )
    except httpx.RequestError as e:
        logger.error(f"代理請求失敗: {e}")
        raise HTTPException(status_code=502, detail=f"上游服務請求失敗: {str(e)}")

    return Response(content=resp.content, status_code=resp.status_code)


if __name__ == "__main__":
    import uvicorn

    logger.info(f"🚀 啟動繁體中文轉換代理 on port {PROXY_PORT}")
    logger.info(f"📡 上游 SenseVoice API: {SENSEVOICE_API_URL}")
    logger.info(f"🔄 轉換規則: {OPENCC_CONFIG}")

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=PROXY_PORT,
        reload=False,
        log_level="info",
    )
