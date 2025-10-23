# Docker로 MySQL 실습 환경 구축하기 🐳

> MySQL 9.x 최신 버전 + 200만 건 더미 데이터 자동 생성

## 📋 목차

- [사전 준비](#사전-준비)
- [빠른 시작](#빠른-시작)
- [상세 가이드](#상세-가이드)
- [데이터베이스 접속](#데이터베이스-접속)
- [트러블슈팅](#트러블슈팅)
- [환경 정리](#환경-정리)

---

## 🎯 사전 준비

### 필수 설치

1. **Docker Desktop** 설치
   - Windows: https://www.docker.com/products/docker-desktop/
   - 설치 후 Docker Desktop 실행 확인

2. **디스크 공간 확인**
   - 최소 5GB 이상 여유 공간 필요
   - MySQL 이미지 (~500MB) + 데이터 (~2GB)

---

## 🚀 빠른 시작

### 1. Docker 컨테이너 시작

프로젝트 루트 디렉토리에서 실행:

```bash
# Windows (PowerShell 또는 CMD)
cd C:\Users\USER\IdeaProjects\wild-learning-db

# Docker Compose로 MySQL 시작
docker-compose up -d
```

### 2. 초기화 진행 상황 확인

```bash
# 로그 실시간 확인 (데이터 생성 진행 상황)
docker-compose logs -f mysql
```

**예상 소요 시간**:
- MySQL 컨테이너 시작: ~30초
- 더미 데이터 생성 (200만 건): ~5-10분

로그에서 다음과 같은 메시지가 보이면 완료:
```
=== Data generation completed! ===
```

**Ctrl+C**를 눌러 로그 모니터링 종료 (컨테이너는 계속 실행됨)

### 3. MySQL 접속

```bash
# MySQL CLI로 접속
docker exec -it wild-learning-mysql mysql -u root -p
# 패스워드: wild123!@#
```

또는 **phpMyAdmin** 사용 (웹 GUI):
- 브라우저에서 http://localhost:8080 접속
- 사용자: root
- 패스워드: wild123!@#

---

## 📚 상세 가이드

### 환경 구성 상세

**docker-compose.yml** 구성:

| 서비스 | 포트 | 설명 |
|--------|------|------|
| mysql | 3306 | MySQL 9.x 데이터베이스 |
| phpmyadmin | 8080 | 웹 기반 DB 관리 도구 |

**생성되는 데이터**:

| 테이블 | 행 개수 | 설명 |
|--------|---------|------|
| users | 1,000,000 | 사용자 정보 (이메일, 이름, 전화번호 등) |
| orders | 1,000,000 | 주문 정보 (상태, 금액, 생성일 등) |

**데이터베이스 접속 정보**:

```
Host: localhost
Port: 3306
Database: wild_learning_db
Username: root
Password: wild123!@#

또는

Username: wilduser
Password: wild123!@#
```

---

## 🔌 데이터베이스 접속

### 방법 1: Docker CLI

```bash
# 컨테이너 내부 MySQL CLI 실행
docker exec -it wild-learning-mysql mysql -u root -pwild123!@# wild_learning_db

# 또는 패스워드 입력 프롬프트 사용
docker exec -it wild-learning-mysql mysql -u root -p wild_learning_db
```

접속 후 바로 실습 가능:

```sql
-- 데이터 확인
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders;

-- 실습 1: 인덱스 없이 조회 (느림!)
SELECT * FROM users WHERE email = 'user500000@example.com';
```

### 방법 2: phpMyAdmin (웹 GUI)

1. 브라우저에서 http://localhost:8080 접속
2. 로그인:
   - 서버: mysql
   - 사용자명: root
   - 암호: wild123!@#
3. 왼쪽 메뉴에서 `wild_learning_db` 선택
4. SQL 탭에서 쿼리 실행 가능

### 방법 3: 외부 클라이언트 (DBeaver, DataGrip 등)

```
Connection Type: MySQL
Host: localhost
Port: 3306
Database: wild_learning_db
Username: root
Password: wild123!@#
```

### 방법 4: MySQL Workbench

```
Connection Method: Standard (TCP/IP)
Hostname: localhost
Port: 3306
Username: root
Password: wild123!@#
Default Schema: wild_learning_db
```

---

## 🧪 실습 시작하기

### Week 1 실습 진행

Docker 환경이 준비되었으므로, 이제 실습 파일을 실행할 수 있습니다.

```bash
# MySQL CLI 접속
docker exec -it wild-learning-mysql mysql -u root -pwild123!@# wild_learning_db
```

접속 후 실습 파일 경로를 복사하여 실행:

```sql
-- 실습 1: 인덱스 성능 비교
SOURCE /docker-entrypoint-initdb.d/../../week1/practice1-index-performance.sql;
```

또는 호스트에서 직접 실행:

```bash
# 호스트 → 컨테이너로 SQL 파일 복사
docker cp week1/practice1-index-performance.sql wild-learning-mysql:/tmp/

# 컨테이너에서 SQL 실행
docker exec -it wild-learning-mysql mysql -u root -pwild123!@# wild_learning_db -e "SOURCE /tmp/practice1-index-performance.sql"
```

---

## 🐛 트러블슈팅

### 문제 1: 포트 3306이 이미 사용 중

**증상**:
```
Error: Bind for 0.0.0.0:3306 failed: port is already allocated
```

**해결**:

Option A - 로컬 MySQL 중지:
```bash
# Windows 서비스에서 MySQL 중지
net stop MySQL
```

Option B - 포트 변경:
```yaml
# docker-compose.yml 수정
ports:
  - "3307:3306"  # 3306 → 3307로 변경
```

### 문제 2: 데이터 생성이 너무 오래 걸림

**증상**: 10분 이상 초기화가 진행됨

**해결**:

Option A - 데이터 개수 줄이기:
```sql
-- docker/mysql/initdb/02-insert-dummy-data.sql 수정

-- 100만 건 → 10만 건으로 변경
CALL insert_users_batch(10000, 10);  -- 100 → 10
CALL insert_orders_batch(10000, 10);  -- 100 → 10
```

Option B - 데이터 생성 스크립트 비활성화:
```bash
# 파일명 변경하여 실행 안 되게 하기
mv docker/mysql/initdb/02-insert-dummy-data.sql docker/mysql/initdb/02-insert-dummy-data.sql.bak
```

### 문제 3: 컨테이너가 계속 재시작됨

**확인**:
```bash
docker-compose logs mysql
```

**일반적인 원인**:
- 메모리 부족: Docker Desktop 설정에서 메모리 할당량 증가 (최소 2GB)
- 디스크 공간 부족: 여유 공간 확보

### 문제 4: 한글이 깨짐

**확인**:
```sql
SHOW VARIABLES LIKE 'char%';
```

**해결**:
설정 파일(`docker/mysql/conf.d/my.cnf`)에서 이미 utf8mb4로 설정됨.
컨테이너 재시작:
```bash
docker-compose restart mysql
```

---

## 🔍 유용한 명령어

### Docker 컨테이너 관리

```bash
# 컨테이너 시작
docker-compose up -d

# 컨테이너 중지
docker-compose stop

# 컨테이너 중지 및 삭제
docker-compose down

# 컨테이너 + 볼륨 삭제 (데이터 완전 삭제)
docker-compose down -v

# 컨테이너 재시작
docker-compose restart

# 로그 확인
docker-compose logs -f mysql

# 컨테이너 상태 확인
docker-compose ps
```

### MySQL 컨테이너 내부 명령

```bash
# Bash 셸 접속
docker exec -it wild-learning-mysql bash

# MySQL 버전 확인
docker exec wild-learning-mysql mysql --version

# MySQL 프로세스 확인
docker exec wild-learning-mysql mysqladmin -u root -pwild123!@# processlist

# 데이터베이스 목록 확인
docker exec wild-learning-mysql mysql -u root -pwild123!@# -e "SHOW DATABASES;"
```

---

## 🧹 환경 정리

### 데이터 유지하며 컨테이너만 중지

```bash
docker-compose stop
```

재시작 시 데이터 그대로 유지됨:
```bash
docker-compose start
```

### 컨테이너 삭제 (데이터는 유지)

```bash
docker-compose down
```

다시 `docker-compose up -d` 실행 시 기존 데이터 사용

### 완전 삭제 (데이터 포함)

```bash
# 컨테이너 + 볼륨 완전 삭제
docker-compose down -v

# 이미지도 삭제
docker rmi mysql:9 phpmyadmin:latest
```

---

## 📊 데이터 구조

### users 테이블

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP(6),
    updated_at TIMESTAMP(6),
    status ENUM('active', 'inactive', 'pending'),
    phone VARCHAR(20)
);
```

**샘플 데이터**:
```
id: 1
email: user1@example.com
name: User1
status: active
phone: 010-1234-5678
created_at: 2022-05-15 14:23:45.123456
```

### orders 테이블

```sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    status ENUM('pending', 'completed', 'cancelled', 'shipped', 'refunded'),
    created_at TIMESTAMP(6),
    updated_at TIMESTAMP(6),
    amount DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**샘플 데이터**:
```
id: 1
user_id: 12345
status: completed
amount: 129.99
created_at: 2024-01-20 09:15:30.654321
```

---

## 💡 팁

### 1. 성능 모니터링

```sql
-- 실행 중인 쿼리 확인
SHOW PROCESSLIST;

-- 테이블 크기 확인
SELECT
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'wild_learning_db';
```

### 2. 인덱스 확인

```sql
-- 테이블의 인덱스 목록
SHOW INDEX FROM users;
SHOW INDEX FROM orders;
```

### 3. 슬로우 쿼리 로그 확인

```bash
# 컨테이너 내부에서
docker exec -it wild-learning-mysql cat /var/lib/mysql/slow-query.log
```

---

## ✅ 체크리스트

- [ ] Docker Desktop 설치 및 실행
- [ ] `docker-compose up -d` 실행 성공
- [ ] 데이터 생성 완료 확인 (로그)
- [ ] MySQL CLI 접속 성공
- [ ] phpMyAdmin 접속 성공 (http://localhost:8080)
- [ ] users 테이블 100만 건 확인
- [ ] orders 테이블 100만 건 확인

---

**환경 준비 완료!** 🎉

이제 `week1/practice1-index-performance.sql`부터 실습을 시작하세요!
