@echo off
REM Docker 환경 중지 스크립트 (Windows)

echo ==========================================
echo  Wild Learning DB - Docker 환경 중지
echo ==========================================
echo.

echo Docker Compose 중지 중...
docker-compose stop

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Docker Compose 중지 실패!
    pause
    exit /b 1
)

echo.
echo [완료] Docker 환경이 중지되었습니다!
echo.
echo 재시작: scripts\start.bat
echo 완전 삭제: scripts\cleanup.bat
echo.

pause
