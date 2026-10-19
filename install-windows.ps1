# SenseVoice Docker - Windows 安裝腳本
# 需要在 PowerShell (管理員) 中運行

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SenseVoice Docker - Windows 安裝程序" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 檢查管理員權限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "錯誤：需要以管理員身份運行此腳本" -ForegroundColor Red
    Write-Host "右鍵點擊 PowerShell，選擇「以管理員身份運行」" -ForegroundColor Yellow
    exit 1
}

# 檢查 Windows 版本
Write-Host "檢查 Windows 版本..." -ForegroundColor Cyan
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Build -lt 19041) {
    Write-Host "警告：Windows 版本過舊，建議 Windows 10 2004 或更高版本" -ForegroundColor Yellow
} else {
    Write-Host "✓ Windows 版本：$($osVersion.Build)" -ForegroundColor Green
}

# 檢查 WSL
Write-Host ""
Write-Host "檢查 WSL 狀態..." -ForegroundColor Cyan
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL 未安裝，正在安裝..." -ForegroundColor Yellow
    
    # 啟用 WSL 功能
    Write-Host "啟用 WSL 功能..." -ForegroundColor Cyan
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    
    # 啟用虛擬機平台
    Write-Host "啟用虛擬機平台..." -ForegroundColor Cyan
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    # 安裝 WSL
    Write-Host "安裝 WSL..." -ForegroundColor Cyan
    wsl --install
    
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host "WSL 安裝完成！需要重啟電腦。" -ForegroundColor Yellow
    Write-Host "重啟後，請再次運行此腳本。" -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✓ WSL 已安裝" -ForegroundColor Green
}

# 檢查 WSL 版本
Write-Host "檢查 WSL 版本..." -ForegroundColor Cyan
wsl --list --verbose
$wslVersion = wsl --status | Select-String "預設版本"
if ($wslVersion -match "2") {
    Write-Host "✓ WSL 2 已啟用" -ForegroundColor Green
} else {
    Write-Host "警告：建議使用 WSL 2" -ForegroundColor Yellow
    Write-Host "運行：wsl --set-default-version 2" -ForegroundColor Yellow
}

# 檢查 Docker Desktop
Write-Host ""
Write-Host "檢查 Docker Desktop..." -ForegroundColor Cyan
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerPath) {
    Write-Host "Docker Desktop 未安裝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "請手動安裝 Docker Desktop：" -ForegroundColor Cyan
    Write-Host "1. 下載：https://www.docker.com/products/docker-desktop/" -ForegroundColor White
    Write-Host "2. 安裝時選擇「Use WSL 2 instead of Hyper-V」" -ForegroundColor White
    Write-Host "3. 啟動 Docker Desktop" -ForegroundColor White
    Write-Host ""
    Write-Host "安裝完成後，再次運行此腳本。" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ Docker Desktop 已安裝" -ForegroundColor Green
    docker --version
}

# 檢查 NVIDIA 驅動
Write-Host ""
Write-Host "檢查 NVIDIA 驅動..." -ForegroundColor Cyan
$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if (-not $nvidiaSmi) {
    Write-Host "警告：未檢測到 NVIDIA 驅動" -ForegroundColor Yellow
    Write-Host "如果需要 GPU 加速，請安裝 NVIDIA 驅動程序：" -ForegroundColor Yellow
    Write-Host "https://www.nvidia.com/Download/index.aspx" -ForegroundColor White
} else {
    Write-Host "✓ NVIDIA 驅動已安裝" -ForegroundColor Green
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
}

# 檢查 Git
Write-Host ""
Write-Host "檢查 Git..." -ForegroundColor Cyan
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "Git 未安裝" -ForegroundColor Yellow
    Write-Host "請安裝 Git：https://git-scm.com/download/win" -ForegroundColor White
    exit 1
} else {
    Write-Host "✓ Git 已安裝" -ForegroundColor Green
    git --version
}

# 詢問安裝位置
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
$installPath = Read-Host "請輸入安裝路徑（默認：$env:USERPROFILE\sensevoice-docker）"
if ([string]::IsNullOrWhiteSpace($installPath)) {
    $installPath = "$env:USERPROFILE\sensevoice-docker"
}

# 克隆倉庫
Write-Host ""
Write-Host "克隆倉庫到 $installPath ..." -ForegroundColor Cyan
if (Test-Path $installPath) {
    Write-Host "目錄已存在，跳過克隆" -ForegroundColor Yellow
} else {
    $repoUrl = Read-Host "請輸入 GitHub 倉庫 URL（或按 Enter 使用默認）"
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        $repoUrl = "https://github.com/YOUR_USERNAME/sensevoice-docker.git"
    }
    git clone $repoUrl $installPath
}

# 進入目錄
Set-Location $installPath

# 配置環境變量
Write-Host ""
Write-Host "配置環境變量..." -ForegroundColor Cyan
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✓ 已創建 .env 文件" -ForegroundColor Green
} else {
    Write-Host "✓ .env 文件已存在" -ForegroundColor Green
}

# 啟動服務
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "準備啟動服務..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$startNow = Read-Host "是否現在啟動服務？(Y/n)"
if ($startNow -ne "n" -and $startNow -ne "N") {
    Write-Host "啟動服務（首次啟動需要構建鏡像）..." -ForegroundColor Cyan
    docker compose up -d --build
    
    Write-Host ""
    Write-Host "等待服務啟動..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    # 檢查服務狀態
    Write-Host ""
    Write-Host "檢查服務狀態..." -ForegroundColor Cyan
    docker compose ps
    
    # 測試 API
    Write-Host ""
    Write-Host "測試 API..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:10096/health" -Method GET
        Write-Host "✓ API 正常運行" -ForegroundColor Green
        Write-Host "  狀態：$($response.status)" -ForegroundColor White
        Write-Host "  上游：$($response.upstream)" -ForegroundColor White
    } catch {
        Write-Host "警告：API 尚未就緒，請稍後再試" -ForegroundColor Yellow
        Write-Host "運行：docker compose logs" -ForegroundColor White
    }
}

# 完成
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "安裝完成！" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "常用命令：" -ForegroundColor Cyan
Write-Host "  啟動服務：docker compose up -d" -ForegroundColor White
Write-Host "  停止服務：docker compose down" -ForegroundColor White
Write-Host "  查看日誌：docker compose logs -f" -ForegroundColor White
Write-Host "  測試 API：curl http://localhost:10096/health" -ForegroundColor White
Write-Host ""
Write-Host "API 端點：" -ForegroundColor Cyan
Write-Host "  繁體中文版：http://localhost:10096" -ForegroundColor White
Write-Host "  API 文檔：http://localhost:10096/docs" -ForegroundColor White
Write-Host ""
Write-Host "如需幫助，請查看 README.md" -ForegroundColor Yellow
Write-Host ""
