# SenseVoice Docker - Windows 快速啟動腳本
# 在 PowerShell 中運行

param(
    [switch]$Build,
    [switch]$Logs,
    [switch]$Stop,
    [switch]$Restart,
    [switch]$Status
)

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

if ($Stop) {
    Write-Host "停止服務..." -ForegroundColor Cyan
    docker compose down
    exit 0
}

if ($Restart) {
    Write-Host "重啟服務..." -ForegroundColor Cyan
    docker compose restart
    exit 0
}

if ($Logs) {
    Write-Host "查看日誌（按 Ctrl+C 退出）..." -ForegroundColor Cyan
    docker compose logs -f
    exit 0
}

if ($Status) {
    Write-Host "服務狀態：" -ForegroundColor Cyan
    docker compose ps
    Write-Host ""
    Write-Host "測試 API：" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:10096/health" -Method GET
        Write-Host "✓ API 正常" -ForegroundColor Green
        Write-Host "  狀態：$($response.status)" -ForegroundColor White
        Write-Host "  上游：$($response.upstream)" -ForegroundColor White
        Write-Host "  轉換器：$($response.converter)" -ForegroundColor White
    } catch {
        Write-Host "✗ API 未運行" -ForegroundColor Red
    }
    exit 0
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SenseVoice Docker - 啟動服務" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($Build) {
    Write-Host "構建並啟動服務..." -ForegroundColor Cyan
    docker compose up -d --build
} else {
    Write-Host "啟動服務..." -ForegroundColor Cyan
    docker compose up -d
}

Write-Host ""
Write-Host "等待服務啟動..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# 檢查狀態
docker compose ps

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "服務已啟動！" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "API 端點：" -ForegroundColor Cyan
Write-Host "  繁體中文版：http://localhost:10096" -ForegroundColor White
Write-Host "  API 文檔：http://localhost:10096/docs" -ForegroundColor White
Write-Host ""
Write-Host "常用命令：" -ForegroundColor Cyan
Write-Host "  .\start-windows.ps1 -Status    # 查看狀態" -ForegroundColor White
Write-Host "  .\start-windows.ps1 -Logs      # 查看日誌" -ForegroundColor White
Write-Host "  .\start-windows.ps1 -Stop      # 停止服務" -ForegroundColor White
Write-Host "  .\start-windows.ps1 -Restart   # 重啟服務" -ForegroundColor White
Write-Host "  .\start-windows.ps1 -Build     # 重新構建" -ForegroundColor White
Write-Host ""
