@echo off
chcp 65001 >nul
echo ========================================================
echo  🚀 启动 SmartTakeaway 外卖与闪购智能比价后端服务...
echo ========================================================
cd /d "%~dp0backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
