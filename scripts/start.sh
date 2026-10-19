#!/bin/bash
cd ~/Projects/sensevoice-docker
docker compose up -d
echo "✅ SenseVoice API 已啟動"
echo "📡 繁體中文版: http://localhost:10096"
echo "📊 查看日誌: docker compose logs -f"
echo "🧪 測試 API: curl http://localhost:10096/health"
