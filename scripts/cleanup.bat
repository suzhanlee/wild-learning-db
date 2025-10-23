@echo off
REM Docker 환경 완전 삭제 스크립트 (Windows)

echo ==========================================
echo  Wild Learning DB - Docker 환경 완전 삭제
echo ==========================================
echo.
echo [경고] 이 작업은 다음을 삭제합니다:
echo   - Docker 컨테이너
echo   - 모든 데이터 (users, orders 테이블)
echo   - Docker 볼륨
echo.

set /p confirm="정말 삭제하시겠습니까? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo 취소되었습니다.
    pause
    exit /b 0
)

echo.
echo [1/2] 컨테이너 및 볼륨 삭제 중...
docker-compose down -v

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] 삭제 실패!
    pause
    exit /b 1
)

echo.
echo [2/2] 이미지 삭제 (선택사항)
set /p remove_images="Docker 이미지도 삭제하시겠습니까? (Y/N): "
if /i "%remove_images%"=="Y" (
    docker rmi mysql:9 phpmyadmin:latest 2>nul
    echo 이미지 삭제 완료 (없으면 스킵됨)
)

echo.
echo [완료] Docker 환경이 완전히 삭제되었습니다!
echo.
echo 재시작하려면: scripts\start.bat
echo.

pause
