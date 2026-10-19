# SenseVoice-Small Docker 部署（繁體中文版）

## 📖 簡介

SenseVoice-Small 語音識別服務，使用 Docker + GPU 加速，提供 OpenAI 兼容 API。  
**自動將簡體中文識別結果轉換為香港繁體中文**。

## 🎯 功能特性

- ✅ 語音識別（支持中、英、日、韓、粵語）
- ✅ **自動簡體→繁體轉換**（香港繁體，OpenCC s2hk）
- ✅ 中英夾雜支持
- ✅ GPU 加速（NVIDIA CUDA）
- ✅ OpenAI 兼容 API
- ✅ 情感識別、事件檢測
- ✅ 可配置化（通過 .env 文件）

## 🚀 快速開始

### 1. 克隆倉庫

```bash
git clone https://github.com/YOUR_USERNAME/sensevoice-docker.git
cd sensevoice-docker
```

### 2. 配置環境變量

```bash
# 複製示例配置
cp .env.example .env

# 編輯配置（可選）
nano .env
```

### 3. 啟動服務

```bash
# 使用腳本
./scripts/start.sh

# 或手動
docker compose up -d
```

**首次啟動**會自動下載模型（~900MB），需要等待幾分鐘。

### 4. 驗證服務

```bash
# 檢查服務狀態
docker compose ps

# 測試 API
curl http://localhost:10096/health

# 或使用測試腳本
./scripts/test.sh
```

## 🚀 部署說明

### 首次部署

首次部署需要構建 tc-proxy 鏡像：

```bash
docker compose up -d --build
```

### 後續更新

**只修改配置**（.env、docker-compose.yml）：
```bash
docker compose up -d  # 不需要 --build
```

**修改了 tc-proxy 代碼**（main.py、Dockerfile、requirements.txt）：
```bash
docker compose up -d --build tc-proxy  # 只構建 tc-proxy
```

**更新所有鏡像**：
```bash
docker compose pull
docker compose up -d --build
```

### 什麼時候需要 `--build`？

| 場景 | 是否需要 `--build` | 說明 |
|------|-------------------|------|
| 首次部署 | ✅ 需要 | 需要構建 tc-proxy 鏡像 |
| 修改 `.env` | ❌ 不需要 | 配置變更，重啟即可 |
| 修改 `docker-compose.yml` | ❌ 不需要 | 重新創建容器即可 |
| 修改 `tc-proxy/main.py` | ✅ 需要 | 代碼變更，需要重新構建鏡像 |
| 修改 `tc-proxy/Dockerfile` | ✅ 需要 | 構建配置變更 |
| 修改 `tc-proxy/requirements.txt` | ✅ 需要 | 依賴變更 |
| 只是重啟服務 | ❌ 不需要 | 使用 `docker compose restart` |

### 快速參考

```bash
# 首次部署
docker compose up -d --build

# 只改配置
docker compose up -d

# 改了 tc-proxy 代碼
docker compose up -d --build tc-proxy

# 完全重建
docker compose down
docker compose up -d --build
```

## 📡 API 端點

**繁體中文版（推薦使用）**：`http://localhost:10096`

| 端點 | 方法 | 說明 |
|------|------|------|
| `/health` | GET | 健康檢查 |
| `/v1/models` | GET | 模型列表 |
| `/v1/audio/transcriptions` | POST | 語音轉文字（自動轉換繁體） |
| `/docs` | GET | API 文檔（Swagger UI） |

**原始 SenseVoice API**：`http://localhost:10095`（僅內部網絡訪問）

## 🔗 連接 OpenWhispr

在 OpenWhispr 中配置：
- **Server URL**: `http://localhost:10096/v1`
- **Model**: `sensevoice-small`
- **API Key**: 留空

## ⚙️ 配置說明

### 環境變量（.env 文件）

複製 `.env.example` 為 `.env`，然後根據需要修改：

```bash
# SenseVoice 配置
DEVICE=cuda                    # 設備類型：cuda（GPU）或 cpu
CUDA_VISIBLE_DEVICES=0         # GPU 設備 ID（0 = 第一張 GPU）
GPU_DEVICE_ID=0                # Docker GPU 直通設備 ID

# API 配置
API_PORT=10095                 # SenseVoice API 端口（內部網絡）

# 繁體轉換代理配置
PROXY_PORT=10096               # 代理端口（對外暴露）
OPENCC_CONFIG=s2hk             # 轉換規則（見下方說明）

# 模型配置
MODEL_NAME=sensevoice-small    # 模型名稱
```

### OpenCC 轉換規則

| 規則 | 說明 | 適用場景 |
|------|------|---------|
| `s2hk` | 簡體→香港繁體 | **推薦**，澳門/香港用戶 |
| `s2tw` | 簡體→台灣繁體 | 台灣用戶 |
| `s2t` | 簡體→繁體（通用） | 其他地區 |

修改後重啟服務：
```bash
docker compose restart tc-proxy
```

## 📊 資源需求

| 資源 | 需求 |
|------|------|
| **磁盤** | ~10GB（鏡像 + 模型） |
| **內存** | ~2GB |
| **VRAM** | ~2GB（GPU 模式） |
| **端口** | 10096（繁體版）、10095（原始版，內部） |
| **Docker** | 20.10+ |
| **Docker Compose** | 2.0+ |
| **NVIDIA Driver** | 515+（GPU 模式） |

## 📁 目錄結構

```
.
├── docker-compose.yml          # Docker Compose 配置
├── .env                        # 環境變量（不推送）
├── .env.example                # 環境變量示例（推送）
├── .gitignore                  # Git 忽略文件
├── tc-proxy/                   # 繁體中文轉換代理
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── models/                     # 模型存儲（自動下載，不推送）
├── logs/                       # 日誌（不推送）
├── scripts/                    # 輔助腳本
│   ├── start.sh
│   ├── stop.sh
│   ├── test.sh
│   └── logs.sh
├── sensevoice-api.service      # systemd 服務文件
└── README.md
```

## 🧪 測試示例

### curl 測試

```bash
curl -X POST "http://localhost:10096/v1/audio/transcriptions" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.wav" \
  -F "model=sensevoice-small" \
  -F "response_format=verbose_json"
```

### Python 測試

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:10096/v1",
    api_key="none"
)

result = client.audio.transcriptions.create(
    model="sensevoice-small",
    file=open("test.wav", "rb")
)

print(result.text)  # 繁體中文結果
```

## 🔧 架構

```
客戶端 (OpenWhispr)
    ↓ POST /v1/audio/transcriptions
[tc-proxy :10096] ← 繁體中文轉換代理
    ├─ 接收請求
    ├─ 轉發到 SenseVoice API :10095
    ├─ 接收簡體中文結果
    ├─ OpenCC 轉換 (s2hk)
    └─ 返回繁體中文結果
    ↓
[sensevoice-api :10095] ← 原始 API（僅內部網絡）
    └─ GPU 加速語音識別
```

## 🚀 系統服務（開機自啟）

### 安裝為 systemd 服務

```bash
# 複製服務文件
sudo cp sensevoice-api.service /etc/systemd/system/

# 重新載入 systemd
sudo systemctl daemon-reload

# 啟用並啟動
sudo systemctl enable sensevoice-api
sudo systemctl start sensevoice-api

# 查看狀態
sudo systemctl status sensevoice-api
```

### 管理命令

```bash
# 啟動
sudo systemctl start sensevoice-api

# 停止
sudo systemctl stop sensevoice-api

# 重啟
sudo systemctl restart sensevoice-api

# 查看日誌
sudo journalctl -u sensevoice-api -f
```

## 🐛 故障排除

### 查看日誌

```bash
# 所有服務
docker compose logs -f

# 僅 tc-proxy
docker compose logs -f tc-proxy

# 僅 sensevoice-api
docker compose logs -f sensevoice-api
```

### 常見問題

**問題 1：端口被佔用**
```bash
# 檢查端口
ss -tlnp | grep 10096

# 停止佔用進程或修改 .env 中的 PROXY_PORT
```

**問題 2：模型下載失敗**
```bash
# 手動下載模型
docker compose run --rm sensevoice-api python -c "from modelscope import snapshot_download; snapshot_download('iic/SenseVoiceSmall')"
```

**問題 3：GPU 不可用**
```bash
# 檢查 NVIDIA 驅動
nvidia-smi

# 檢查 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### 重啟服務

```bash
docker compose restart
```

### 更新鏡像

```bash
docker compose pull
docker compose up -d --build
```

### 檢查服務狀態

```bash
docker compose ps
```

## 📝 詳細文檔

查看 [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md) 獲取詳細部署信息。

## 📄 授權

本項目使用的開源組件：
- [SenseVoice](https://github.com/FunAudioLLM/SenseVoice) - Apache 2.0
- [OpenCC](https://github.com/BYVoid/OpenCC) - Apache 2.0

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 🙏 致謝

- [FunAudioLLM](https://github.com/FunAudioLLM) - SenseVoice 模型
- [OpenCC](https://github.com/BYVoid/OpenCC) - 簡繁轉換工具
