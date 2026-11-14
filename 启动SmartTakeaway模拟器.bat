@echo off
chcp 65001 >nul
echo 正在检查后端服务...
powershell -NoProfile -Command "try { Invoke-RestMethod http://127.0.0.1:8000/api/v1/health | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo 正在启动 SmartTakeaway 后端...
    start "SmartTakeaway Backend" /min cmd /c "cd /d C:\Users\巨乐\.gemini\antigravity\scratch\SmartTakeaway\backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
)

echo 正在启动 Android 模拟器窗口 (SmartTakeaway_Pixel)...
start "" "D:\dev\Android\Sdk\emulator\emulator.exe" -avd SmartTakeaway_Pixel -gpu auto -no-metrics

echo 等待模拟器就绪并自动打开 SmartTakeaway...
D:\dev\Android\Sdk\platform-tools\adb.exe wait-for-device
:wait_boot
for /f "delims=" %%i in ('D:\dev\Android\Sdk\platform-tools\adb.exe shell getprop sys.boot_completed 2^>nul') do set BOOT=%%i
if not "%BOOT%"=="1" (
    timeout /t 2 /nobreak >nul
    goto wait_boot
)
D:\dev\Android\Sdk\platform-tools\adb.exe shell am start -a android.intent.action.VIEW -d "smarttakeaway://compare?q=生椰拿铁"
echo 已启动！
timeout /t 3 /nobreak >nul
