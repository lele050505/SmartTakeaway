# SmartTakeaway 后端启动脚本
$Host.UI.RawUI.WindowTitle = "SmartTakeaway 比价服务"
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " 🚀 正在启动 SmartTakeaway 跨平台比价服务 (0.0.0.0:8000)..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Set-Location -Path "$PSScriptRoot\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
