@echo off
REM MySQL 접속 스크립트 (Windows)

echo ==========================================
echo  Wild Learning DB - MySQL 접속
echo ==========================================
echo.

echo MySQL CLI에 접속합니다...
echo (패스워드: wild123!@#)
echo.

docker exec -it wild-learning-mysql mysql -u root -pwild123!@# wild_learning_db

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] MySQL 접속 실패!
    echo Docker 컨테이너가 실행 중인지 확인하세요: docker-compose ps
    pause
    exit /b 1
)
