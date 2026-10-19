# SenseVoice-Small Docker 部署計劃

## 📋 項目概述

部署 SenseVoice-Small 語音識別服務，使用 Docker + GPU 加速，提供 OpenAI 兼容 API。

---

## 🎯 目標

- ✅ 部署 SenseVoice-Small Docker 容器
- ✅ 使用 NVIDIA GPU 加速（RTX 4060）
- ✅ 提供 OpenAI 兼容 API（端口 10095）
- ✅ 連接 OpenWhispr 使用
- ✅ 所有文件存放在 `~/Projects/sensevoice-docker`

---

## 📁 項目結構

```
~/Projects/sensevoice-docker/
├── DEPLOYMENT_PLAN.md          # 本計劃文檔
├── docker-compose.yml          # Docker Compose 配置
├── .env                        # 環境變量配置
├── models/                     # 模型存儲目錄
│   └── (自動下載 ~900MB)
├── logs/                       # 日誌目錄
├── scripts/                    # 輔助腳本
│   ├── start.sh               # 啟動腳本
│   ├── stop.sh                # 停止腳本
│   ├── test.sh                # 測試腳本
│   └── logs.sh                # 查看日誌
└── README.md                   # 使用說明
```

---

## 🔧 部署步驟

### 階段 1：準備工作

1. **創建項目目錄結構**
   ```bash
   mkdir -p ~/Projects/sensevoice-docker/{models,logs,scripts}
   ```

2. **創建 Docker Compose 配置文件**
   - `docker-compose.yml`
   - `.env`

3. **創建輔助腳本**
   - `start.sh` - 啟動服務
   - `stop.sh` - 停止服務
   - `test.sh` - 測試 API
   - `logs.sh` - 查看日誌

---

### 階段 2：Docker 配置

#### docker-compose.yml

```yaml
version: '3.8'

services:
  sensevoice-api:
    image: ghcr.io/hsiang-han/sensevoice-api:latest
    container_name: sensevoice-api
    restart: unless-stopped
    ports:
      - "10095:10095"
    volumes:
      - ./models:/root/.cache/huggingface
      - ./logs:/var/log/sensevoice
    environment:
      - DEVICE=cuda
      - CUDA_VISIBLE_DEVICES=0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['0']
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:10095/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

#### .env

```bash
# SenseVoice 配置
DEVICE=cuda
CUDA_VISIBLE_DEVICES=0

# API 配置
API_PORT=10095

# 模型配置
MODEL_NAME=sensevoice-small
```

---

### 階段 3：輔助腳本

#### scripts/start.sh

```bash
#!/bin/bash
cd ~/Projects/sensevoice-docker
docker-compose up -d
echo "✅ SenseVoice API 已啟動"
echo "📊 查看日誌: docker logs -f sensevoice-api"
echo "🧪 測試 API: curl http://localhost:10095/health"
```

#### scripts/stop.sh

```bash
#!/bin/bash
cd ~/Projects/sensevoice-docker
docker-compose down
echo "✅ SenseVoice API 已停止"
```

#### scripts/test.sh

```bash
#!/bin/bash
echo "=== 健康檢查 ==="
curl -s http://localhost:10095/health | jq .

echo ""
echo "=== 模型列表 ==="
curl -s http://localhost:10095/v1/models | jq .

echo ""
echo "=== API 文檔 ==="
echo "http://localhost:10095/docs"
```

#### scripts/logs.sh

```bash
#!/bin/bash
docker logs -f sensevoice-api
```

---

### 階段 4：部署執行

1. **拉取 Docker 鏡像**
   ```bash
   docker pull ghcr.io/hsiang-han/sensevoice-api:latest
   ```
   - 鏡像大小：約 5-10GB
   - 首次下載需要時間

2. **啟動服務**
   ```bash
   cd ~/Projects/sensevoice-docker
   docker-compose up -d
   ```

3. **等待模型下載**
   - 首次啟動會自動下載模型（~900MB）
   - 查看進度：`docker logs -f sensevoice-api`
   - 等待看到 "Uvicorn running on http://0.0.0.0:10095"

4. **驗證服務**
   ```bash
   # 健康檢查
   curl http://localhost:10095/health
   
   # 查看模型
   curl http://localhost:10095/v1/models
   ```

---

### 階段 5：測試 API

#### 測試腳本

```bash
# 創建測試音頻（需要安裝 ffmpeg）
ffmpeg -f lavfi -t 5 -i "sine=frequency=440" test.wav

# 測試轉錄
curl -X POST "http://localhost:10095/v1/audio/transcriptions" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.wav" \
  -F "model=sensevoice-small"
```

#### Python 測試

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:10095/v1",
    api_key="none"
)

result = client.audio.transcriptions.create(
    model="sensevoice-small",
    file=open("test.wav", "rb")
)

print(result.text)
```

---

### 階段 6：連接 OpenWhispr

在 OpenWhispr 中配置：

1. 打開 **Settings** → **Speech-to-Text**
2. 選擇 **Custom Endpoint**
3. 配置：
   - **Server URL**: `http://localhost:10095/v1`
   - **Model**: `sensevoice-small`
   - **API Key**: 留空或填 `none`

---

## 📊 資源需求

| 資源 | 需求 |
|------|------|
| **磁盤空間** | ~10GB（鏡像 + 模型） |
| **內存** | ~2GB |
| **VRAM** | ~2GB（GPU） |
| **端口** | 10095 |

---

## 🔍 監控與維護

### 查看日誌

```bash
# 實時日誌
docker logs -f sensevoice-api

# 最近 100 行
docker logs --tail 100 sensevoice-api

# 使用腳本
~/Projects/sensevoice-docker/scripts/logs.sh
```

### 健康檢查

```bash
# API 健康
curl http://localhost:10095/health

# Docker 狀態
docker ps | grep sensevoice
```

### 更新模型

```bash
# 停止服務
docker-compose down

# 刪除舊模型
rm -rf ./models/*

# 重新啟動（會重新下載）
docker-compose up -d
```

### 備份

```bash
# 備份模型
tar -czf sensevoice-models-backup.tar.gz models/

# 恢復
tar -xzf sensevoice-models-backup.tar.gz
```

---

## ⚠️ 注意事項

1. **首次啟動較慢**
   - 需要下載鏡像（5-10GB）
   - 需要下載模型（~900MB）
   - 總計可能需要 10-30 分鐘

2. **GPU 內存**
   - SenseVoice-Small 需要 ~2GB VRAM
   - RTX 4060 (8GB) 完全足夠

3. **端口衝突**
   - 確保端口 10095 未被佔用
   - 如需更改，修改 `docker-compose.yml` 中的 `ports`

4. **防火牆**
   - 如果需要遠程訪問，需要開放端口 10095

---

## 🧪 驗證清單

部署完成後，請驗證以下項目：

- [ ] Docker 容器正常運行 (`docker ps`)
- [ ] 健康檢查通過 (`curl http://localhost:10095/health`)
- [ ] 模型列表可訪問 (`curl http://localhost:10095/v1/models`)
- [ ] API 文檔可訪問 (`http://localhost:10095/docs`)
- [ ] 音頻轉錄測試成功
- [ ] OpenWhispr 連接成功

---

## 📞 故障排除

### 問題 1：容器無法啟動

```bash
# 查看日誌
docker logs sensevoice-api

# 檢查 GPU
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### 問題 2：模型下載失敗

```bash
# 檢查網絡
docker exec sensevoice-api ping -c 3 huggingface.co

# 手動下載模型
# 參考：https://huggingface.co/FunAudioLLM/SenseVoiceSmall
```

### 問題 3：API 無法訪問

```bash
# 檢查端口
sudo netstat -tlnp | grep 10095

# 檢查防火牆
sudo ufw status
```

---

## 📝 下一步

部署完成後，可以：

1. **測試不同音頻**
   - 中文、英文、粵語、日文、韓文
   
2. **調整參數**
   - 批量處理
   - 時間戳
   - 情感識別

3. **集成到其他應用**
   - OpenWhispr
   - 自定義腳本
   - 會議轉錄

---

## ✅ 確認執行

請確認以下內容後，我會開始執行部署：

- [ ] 項目目錄：`~/Projects/sensevoice-docker`
- [ ] Docker Compose 配置
- [ ] 輔助腳本
- [ ] 端口：10095
- [ ] GPU 加速：啟用
- [ ] 模型存儲：`./models`

**準備好了嗎？請回覆「確認執行」開始部署。**
