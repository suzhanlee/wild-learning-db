@echo off
REM Docker 환경 시작 스크립트 (Windows)

echo ==========================================
echo  Wild Learning DB - Docker 환경 시작
echo ==========================================
echo.

echo [1/3] Docker Compose 실행 중...
docker-compose up -d

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Docker Compose 실행 실패!
    echo Docker Desktop이 실행 중인지 확인하세요.
    pause
    exit /b 1
)

echo.
echo [2/3] MySQL 컨테이너 헬스 체크...
timeout /t 5 /nobreak > nul

docker exec wild-learning-mysql mysqladmin -u root -pwild123!@# ping > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo MySQL이 아직 시작 중입니다. 30초 대기...
    timeout /t 30 /nobreak > nul
)

echo.
echo [3/3] 연결 정보
echo ==========================================
echo MySQL Host: localhost
echo MySQL Port: 3306
echo Database: wild_learning_db
echo Username: root
echo Password: wild123!@#
echo.
echo phpMyAdmin: http://localhost:8080
echo ==========================================
echo.

echo [완료] Docker 환경이 시작되었습니다!
echo.
echo 데이터 생성 진행 상황 확인:
echo   docker-compose logs -f mysql
echo.
echo MySQL 접속:
echo   docker exec -it wild-learning-mysql mysql -u root -pwild123!@# wild_learning_db
echo.

pause
