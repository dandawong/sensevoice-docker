#!/bin/bash
echo "=== 代理健康檢查 ==="
curl -s http://localhost:10096/health | jq .

echo ""
echo "=== 模型列表 ==="
curl -s http://localhost:10096/v1/models | jq .

echo ""
echo "=== API 文檔 ==="
echo "http://localhost:10096/docs"
