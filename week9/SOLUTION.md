# Week 9 정답: 슬로우 쿼리 로그 분석

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: 슬로우 쿼리 로그 활성화 - 정답

### 1-1. 현재 설정 확인

```sql
-- 슬로우 쿼리 로그 설정 확인
SHOW VARIABLES LIKE 'slow_query%';

-- 예상 결과 (기본값):
-- slow_query_log: OFF
-- slow_query_log_file: /var/log/mysql/slow-query.log
```

```sql
-- 임계값 확인
SHOW VARIABLES LIKE 'long_query_time';

-- 예상 결과: 10.000000 (10초)
```

**기본 상태:**
- 대부분의 MySQL은 기본적으로 슬로우 쿼리 로그가 **비활성화**
- 임계값은 **10초**로 설정되어 있음 (너무 길다!)

---

### 1-2. 올바른 활성화 방법

```sql
-- 정답: 슬로우 쿼리 로그 활성화
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1.0;
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- 확인
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'log_queries_not_using_indexes';
```

**설정값 설명:**

1. **slow_query_log = ON**
   - 슬로우 쿼리 로깅 활성화

2. **long_query_time = 1.0**
   - 1초 이상 걸리는 쿼리를 로깅
   - 프로덕션 권장값: 0.5 ~ 2초
   - 테스트용은 0.1초도 가능

3. **log_queries_not_using_indexes = ON**
   - 인덱스를 사용하지 않는 쿼리도 로깅
   - 중요! 빠른 쿼리라도 인덱스 없으면 기록

---

### 1-3. 영구 설정 (my.cnf)

```ini
# /etc/mysql/my.cnf 또는 /etc/my.cnf
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 1
log_queries_not_using_indexes = 1
min_examined_row_limit = 1000  # 1000행 이상 검사한 쿼리만
```

**영구 설정의 장점:**
- MySQL 재시작 후에도 유지됨
- 운영 환경에서는 필수

---

### 1-4. 테스트 쿼리

```sql
-- 테스트 1: 강제 지연
SELECT SLEEP(2);
-- 결과: 2초 소요 → 로그 기록됨 ✅

-- 테스트 2: 인덱스 미사용
SELECT * FROM users WHERE name = 'test';
-- name에 인덱스 없으면 로그 기록됨 ✅
```

**로그 확인:**
```bash
# Linux/Docker
tail -f /var/log/mysql/slow-query.log

# Docker 컨테이너
docker exec -it wild-learning-mysql tail -f /var/log/mysql/slow-query.log
```

---

## 미션 2: 느린 쿼리 발생시키기 - 정답 및 해설

### 쿼리 1: 인덱스 없는 LIKE 검색 ❌

```sql
SELECT * FROM users WHERE name LIKE '%김%';
```

**예상 성능:**
- 실행 시간: 500~2000ms (데이터 100만 건 기준)
- type: ALL (전체 테이블 스캔)
- rows: 1,000,000

**왜 느린가?**
1. `%`가 **앞에** 있어서 인덱스 못 씀
2. 모든 행의 name을 읽어서 '%김%' 패턴 매칭
3. 문자열 비교 연산이 매우 비쌈

**로그 기록 예시:**
```
# Time: 2025-10-23T10:30:45.123456Z
# User@Host: root[root] @ localhost []
# Query_time: 1.234567  Lock_time: 0.000001 Rows_sent: 5000  Rows_examined: 1000000
SET timestamp=1729677045;
SELECT * FROM users WHERE name LIKE '%김%';
```

**효율성:** 5000 / 1000000 = 0.5% (99.5% 버림!)

---

### 쿼리 2: 함수 사용으로 인덱스 못 탐 ❌

```sql
SELECT * FROM users WHERE YEAR(created_at) = 2024;
```

**예상 성능:**
- 실행 시간: 500~1500ms
- type: ALL
- rows: 1,000,000

**왜 느린가?**
1. `YEAR()` 함수를 모든 행에 적용해야 함
2. created_at에 인덱스가 있어도 못 씀
3. 함수 계산 비용 추가

**개선 방법:**
```sql
-- ✅ 범위 조건으로 변경
SELECT * FROM users
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 인덱스 사용 가능, type: range
```

---

### 쿼리 3: 대량 데이터 정렬 ❌

```sql
SELECT * FROM orders ORDER BY amount DESC LIMIT 100;
```

**예상 성능:**
- 실행 시간: 800~2000ms
- type: ALL
- Extra: **Using filesort** (문제!)

**왜 느린가?**
1. amount에 인덱스 없으면 모든 데이터를 읽어서 정렬
2. **filesort**는 메모리 또는 디스크에서 정렬 수행
3. 100만 건 정렬 후 100개만 반환 (비효율!)

**로그 기록 예시:**
```
# Query_time: 1.567890  Lock_time: 0.000002 Rows_sent: 100  Rows_examined: 1000000
# Rows_sent: 100개만 반환했지만 1000000개를 모두 읽어서 정렬!
```

**개선 방법:**
```sql
-- 인덱스 추가
CREATE INDEX idx_amount ON orders(amount DESC);

-- 결과: Using index, type: index
-- filesort 사라짐!
```

---

### 쿼리 4: 비효율적 JOIN ❌

```sql
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';
```

**예상 성능:**
- 실행 시간: 5000~10000ms (매우 느림!)
- type: ALL (양쪽 모두)
- Extra: Using where; Using join buffer

**왜 느린가?**
1. **JOIN 조건에 함수 사용** (CONCAT)
2. 인덱스를 전혀 못 씀
3. 모든 users × 모든 orders 조합 검사 (1M × 1M = 1조!)
4. 실제로는 중첩 루프 조인 (Nested Loop Join)으로 100만 × 100만번 비교

**문제의 핵심:**
- `CONCAT('user_', u.id)`를 매번 계산
- o.user_note에 인덱스가 있어도 못 씀

**개선 방법:**
```sql
-- ✅ 함수 제거, 직접 비교
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active';

-- 조건: orders 테이블의 user_id에 인덱스 필요
CREATE INDEX idx_user_id ON orders(user_id);

-- 결과: type: ref (orders 테이블)
-- 1000배 이상 빨라짐!
```

---

### 쿼리 5: 전체 테이블 스캔 ❌

```sql
SELECT COUNT(*) FROM orders WHERE status != 'cancelled';
```

**예상 성능:**
- 실행 시간: 300~800ms
- type: ALL 또는 index (인덱스 있어도 비효율)
- rows: 1,000,000

**왜 느린가?**
1. **부정 조건** (`!=`)은 인덱스 비효율적
2. "cancelled가 아닌 모든 것"을 찾으려면 대부분의 행 검사
3. MySQL은 인덱스보다 Full Scan이 빠르다고 판단

**EXPLAIN 결과:**
```
type: ALL (또는 index)
rows: 1000000
Extra: Using where
```

**개선 방법:**
```sql
-- ✅ 긍정 조건으로 변경
SELECT COUNT(*) FROM orders
WHERE status IN ('pending', 'completed', 'shipped', 'delivered');

-- 또는 상태가 2-3가지면
SELECT COUNT(*) FROM orders WHERE status = 'pending'
UNION ALL
SELECT COUNT(*) FROM orders WHERE status = 'completed';

-- 인덱스 추가
CREATE INDEX idx_status ON orders(status);

-- 결과: type: range, 훨씬 빠름
```

---

## 미션 3: 로그 분석 - 정답

### 3-1. mysqldumpslow 사용법

#### 가장 느린 쿼리 Top 3

```bash
mysqldumpslow -s t -t 3 /var/log/mysql/slow-query.log
```

**예상 결과:**

**1위: 비효율적 JOIN**
```
Count: 1  Time=7.5s (7.5s)  Lock=0.00s (0s)  Rows=100.0 (100)
  SELECT u.*, o.* FROM users u LEFT JOIN orders o
  ON CONCAT('S', u.id) = o.user_note WHERE u.status = 'S'
```
- 단 1번 실행으로도 7.5초 소요
- 함수 사용으로 인한 카타스트로피

**2위: 대량 데이터 정렬**
```
Count: 1  Time=1.8s (1.8s)  Lock=0.00s (0s)  Rows=100.0 (100)
  SELECT * FROM orders ORDER BY amount DESC LIMIT N
```
- filesort 발생
- 100만 건 정렬 후 100개만 반환

**3위: YEAR 함수 사용**
```
Count: 1  Time=1.3s (1.3s)  Lock=0.00s (0s)  Rows=200000.0 (200000)
  SELECT * FROM users WHERE YEAR(created_at) = N
```
- 모든 행에 함수 적용

---

#### 가장 많이 실행된 쿼리

미션 2에서는 각 쿼리를 1번씩만 실행했으므로 모두 Count: 1

**실제 프로덕션에서는:**
```
Count: 10000  Time=0.5s (5000s)  Lock=0.00s (0s)  Rows=100.0 (1000000)
  SELECT * FROM orders WHERE user_id=N
```
- 10,000번 실행
- 평균 0.5초
- **총 누적 시간: 5000초 (83분!)**
- 이런 쿼리가 우선순위 1위!

---

### 3-2. 로그 원본 해석

**대표 슬로우 쿼리 로그:**
```
# Time: 2025-10-23T10:35:20.123456Z
# User@Host: root[root] @ localhost []
# Query_time: 7.567890  Lock_time: 0.000003 Rows_sent: 1000  Rows_examined: 1000000000
SET timestamp=1729677320;
SELECT u.*, o.* FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';
```

**필드 해석:**

1. **Time:** 2025-10-23T10:35:20
   - 쿼리 실행 시각 (UTC)

2. **User@Host:** root[root] @ localhost
   - 실행 사용자 및 호스트

3. **Query_time: 7.567890**
   - 실행 시간: **7.57초** (매우 느림!)

4. **Lock_time: 0.000003**
   - 락 대기 시간: 0.003ms (무시 가능)

5. **Rows_sent: 1000**
   - 클라이언트로 반환한 행: 1,000개

6. **Rows_examined: 1000000000**
   - 검사한 행: **10억 개!** (1M users × 1M orders)
   - 효율성: 1000 / 1000000000 = 0.0001% (99.9999% 버림!)

**결론:** 이 쿼리는 즉시 개선 필요!

---

## 미션 4: 개선 우선순위 결정 - 정답

### 4-1. 우선순위 공식 적용

**공식:** 우선순위 점수 = 실행 횟수 × 평균 실행 시간

**미션 2 쿼리 우선순위 (1회씩 실행 가정):**

| 순위 | 쿼리 | 실행 | 평균 | 총 시간 | 점수 | Rows_examined |
|------|------|------|------|---------|------|--------------|
| 1 | 비효율적 JOIN | 1 | 7.5s | 7.5s | 7.5 | 1,000,000,000 |
| 2 | 대량 정렬 | 1 | 1.8s | 1.8s | 1.8 | 1,000,000 |
| 3 | YEAR 함수 | 1 | 1.3s | 1.3s | 1.3 | 1,000,000 |
| 4 | LIKE '%김%' | 1 | 1.2s | 1.2s | 1.2 | 1,000,000 |
| 5 | status != | 1 | 0.5s | 0.5s | 0.5 | 1,000,000 |

**우선순위 1위: 비효율적 JOIN**
- 가장 느림 (7.5초)
- Rows_examined가 압도적으로 많음 (10억!)
- 개선 여지가 매우 큼

---

### 4-2. 실제 프로덕션 시나리오

**현실적인 예시:**

| 순위 | 쿼리 | 실행 | 평균 | 총 시간 | 점수 |
|------|------|------|------|---------|------|
| 1 | 인덱스 없는 검색 | 10,000 | 0.5s | 5,000s | **5,000** |
| 2 | 복잡한 JOIN | 100 | 10s | 1,000s | **1,000** |
| 3 | 대량 집계 | 50 | 20s | 1,000s | **1,000** |
| 4 | 비효율 정렬 | 5,000 | 0.2s | 1,000s | **1,000** |
| 5 | LIKE 검색 | 1,000 | 0.8s | 800s | **800** |

**우선순위 1위: 인덱스 없는 검색**
- 점수가 압도적으로 높음 (5,000)
- 빈도가 높아서 조금만 개선해도 큰 효과
- 인덱스 하나로 0.5s → 0.001s (500배 개선)
- **일일 절감 시간: 4,995초 (83분!)**

**판단 기준:**
1. **총 누적 시간이 큰 것** 우선 (실행 횟수 × 평균 시간)
2. Rows_examined / Rows_sent 비율이 나쁜 것 (개선 여지)
3. 사용자가 자주 사용하는 기능

---

## 미션 5: 쿼리 개선 - 정답

### 5-1. 우선순위 1위 쿼리 개선

**원본 쿼리 (비효율적 JOIN):**
```sql
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';
```

---

### 5-2. EXPLAIN 분석 (Before)

```sql
EXPLAIN SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';
```

**결과:**
| id | table | type | rows | Extra |
|----|-------|------|------|-------|
| 1 | u | ALL | 1,000,000 | Using where |
| 1 | o | ALL | 1,000,000 | Using where; Using join buffer (hash join) |

**문제점:**
1. **type: ALL** (양쪽 모두 전체 스캔)
2. **rows: 1,000,000 × 1,000,000** (카르테시안 곱)
3. **JOIN 조건에 함수 사용** (CONCAT)
4. **인덱스를 전혀 못 씀**

---

### 5-3. 개선 방법

**방법 1: JOIN 조건 재설계 (권장)**

```sql
-- ✅ 정답: 함수 제거, 직접 조인
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active';

-- 필요한 인덱스
CREATE INDEX idx_user_id ON orders(user_id);
CREATE INDEX idx_status ON users(status);
```

**개선 이유:**
1. 함수 제거 → 인덱스 사용 가능
2. orders.user_id = users.id는 전형적인 FK 관계
3. 인덱스로 빠른 매칭

---

**방법 2: 역인덱스 사용 (user_note 구조 변경 필요한 경우)**

만약 o.user_note에 정말로 'user_123' 같은 값이 저장되어 있다면:

```sql
-- 1. 가상 컬럼 추가 (MySQL 5.7+)
ALTER TABLE orders
ADD COLUMN user_id_extracted INT AS (
  CAST(SUBSTRING(user_note, 6) AS UNSIGNED)
) STORED;

CREATE INDEX idx_user_id_extracted ON orders(user_id_extracted);

-- 2. 개선된 쿼리
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON o.user_id_extracted = u.id
WHERE u.status = 'active';
```

---

### 5-4. EXPLAIN 분석 (After)

```sql
EXPLAIN SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active';
```

**결과:**
| id | table | type | rows | Extra |
|----|-------|------|------|-------|
| 1 | u | ref | 200,000 | Using where |
| 1 | o | ref | 10 | Using index |

**개선 내용:**
1. **type: ref** (인덱스 참조)
2. **rows: 200,000 × 10** (status='active' 사용자의 주문만)
3. **인덱스 사용: idx_status, idx_user_id**
4. **Extra: Using index** (커버링 인덱스)

---

### 5-5. 성능 비교

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | 7,500ms | 50ms | **99.3%** (150배) |
| Rows_examined | 1,000,000,000 | 2,000,000 | **99.8%** (500배) |
| type | ALL | ref | ✓ |
| 인덱스 사용 | 없음 | idx_user_id | ✓ |

**성공!** 50% 이상 개선 달성 ✅

---

### 5-6. 추가 개선 사례

#### 쿼리 2: 대량 데이터 정렬

**Before:**
```sql
SELECT * FROM orders ORDER BY amount DESC LIMIT 100;
-- Query_time: 1.8s
-- Extra: Using filesort
```

**After:**
```sql
-- 인덱스 추가
CREATE INDEX idx_amount ON orders(amount DESC);

-- 동일 쿼리 실행
SELECT * FROM orders ORDER BY amount DESC LIMIT 100;
-- Query_time: 0.05s (36배 개선)
-- Extra: Using index
```

---

#### 쿼리 3: YEAR 함수 사용

**Before:**
```sql
SELECT * FROM users WHERE YEAR(created_at) = 2024;
-- Query_time: 1.3s
-- type: ALL
```

**After:**
```sql
-- 범위 조건으로 변경
SELECT * FROM users
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 인덱스 추가
CREATE INDEX idx_created ON users(created_at);

-- Query_time: 0.05s (26배 개선)
-- type: range
```

---

#### 쿼리 4: LIKE '%김%'

**Before:**
```sql
SELECT * FROM users WHERE name LIKE '%김%';
-- Query_time: 1.2s
-- type: ALL
```

**After (방법 1): Full-Text Search**
```sql
-- Full-Text 인덱스 추가
ALTER TABLE users ADD FULLTEXT INDEX ft_name (name);

-- 검색
SELECT * FROM users WHERE MATCH(name) AGAINST('김' IN NATURAL LANGUAGE MODE);

-- Query_time: 0.1s (12배 개선)
```

**After (방법 2): 앞부분 매칭으로 제한**
```sql
-- 검색 패턴 변경 (비즈니스 요구사항 허용 시)
SELECT * FROM users WHERE name LIKE '김%';

-- 인덱스 사용 가능
CREATE INDEX idx_name ON users(name);

-- Query_time: 0.05s (24배 개선)
-- type: range
```

---

#### 쿼리 5: 부정 조건

**Before:**
```sql
SELECT COUNT(*) FROM orders WHERE status != 'cancelled';
-- Query_time: 0.5s
-- type: ALL
```

**After:**
```sql
-- 긍정 조건으로 변경
SELECT COUNT(*) FROM orders
WHERE status IN ('pending', 'completed', 'shipped', 'delivered');

-- 인덱스 추가
CREATE INDEX idx_status ON orders(status);

-- Query_time: 0.05s (10배 개선)
-- type: range
```

---

## 미션 6: 모니터링 자동화 - 정답

### 6-1. 완성된 자동화 스크립트

**파일: slow-query-report.sh**

```bash
#!/bin/bash

#####################################
# 슬로우 쿼리 로그 일일 리포트 생성
# 작성자: Wild Learning DB
# 용도: 매일 슬로우 쿼리 분석 및 리포트
#####################################

# 설정
LOG_FILE="/var/log/mysql/slow-query.log"
REPORT_DIR="/var/log/mysql/reports"
REPORT_FILE="$REPORT_DIR/daily-report-$(date +%Y%m%d).txt"
EMAIL="admin@example.com"

# 색상 (선택)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 디렉토리 생성
mkdir -p $REPORT_DIR

# 리포트 헤더
cat <<EOF > $REPORT_FILE
====================================
MySQL 슬로우 쿼리 일일 리포트
====================================
생성일: $(date '+%Y-%m-%d %H:%M:%S')
로그 파일: $LOG_FILE
====================================

EOF

# 로그 파일 존재 확인
if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: 슬로우 쿼리 로그 파일이 없습니다: $LOG_FILE" | tee -a $REPORT_FILE
    exit 1
fi

# 로그 파일 크기
LOG_SIZE=$(du -h $LOG_FILE | cut -f1)
echo "로그 파일 크기: $LOG_SIZE" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 총 슬로우 쿼리 개수
SLOW_COUNT=$(grep -c "^# Query_time:" $LOG_FILE)
echo "오늘 슬로우 쿼리 개수: $SLOW_COUNT" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 1. 가장 느린 쿼리 Top 10
echo "=====================================" >> $REPORT_FILE
echo "1. 가장 느린 쿼리 Top 10 (실행 시간 순)" >> $REPORT_FILE
echo "=====================================" >> $REPORT_FILE
mysqldumpslow -s t -t 10 $LOG_FILE >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# 2. 가장 많이 실행된 쿼리 Top 10
echo "=====================================" >> $REPORT_FILE
echo "2. 가장 많이 실행된 쿼리 Top 10" >> $REPORT_FILE
echo "=====================================" >> $REPORT_FILE
mysqldumpslow -s c -t 10 $LOG_FILE >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# 3. 평균 시간이 긴 쿼리 Top 10
echo "=====================================" >> $REPORT_FILE
echo "3. 평균 시간이 긴 쿼리 Top 10" >> $REPORT_FILE
echo "=====================================" >> $REPORT_FILE
mysqldumpslow -s at -t 10 $LOG_FILE >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# 4. 가장 많은 Rows를 검사한 쿼리 Top 10
echo "=====================================" >> $REPORT_FILE
echo "4. 가장 많은 Rows를 검사한 쿼리 Top 10" >> $REPORT_FILE
echo "=====================================" >> $REPORT_FILE
mysqldumpslow -s r -t 10 $LOG_FILE >> $REPORT_FILE 2>&1
echo "" >> $REPORT_FILE

# 5. 권장 조치사항
echo "=====================================" >> $REPORT_FILE
echo "5. 권장 조치사항" >> $REPORT_FILE
echo "=====================================" >> $REPORT_FILE

if [ $SLOW_COUNT -gt 100 ]; then
    echo "⚠️  경고: 슬로우 쿼리가 ${SLOW_COUNT}개로 많습니다!" >> $REPORT_FILE
    echo "   → 우선순위 Top 3 쿼리 즉시 개선 필요" >> $REPORT_FILE
elif [ $SLOW_COUNT -gt 50 ]; then
    echo "⚠️  주의: 슬로우 쿼리가 ${SLOW_COUNT}개입니다." >> $REPORT_FILE
    echo "   → 주요 쿼리 개선 검토 필요" >> $REPORT_FILE
else
    echo "✓ 양호: 슬로우 쿼리가 ${SLOW_COUNT}개입니다." >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE
echo "리포트 생성 완료: $REPORT_FILE" >> $REPORT_FILE

# 로그 순환 (매주 월요일)
if [ $(date +%u) -eq 1 ]; then
    BACKUP_FILE="${LOG_FILE}.$(date +%Y%m%d)"
    cp $LOG_FILE $BACKUP_FILE
    echo "" > $LOG_FILE
    chown mysql:mysql $LOG_FILE
    echo "" >> $REPORT_FILE
    echo "=====================================" >> $REPORT_FILE
    echo "로그 순환 완료" >> $REPORT_FILE
    echo "=====================================" >> $REPORT_FILE
    echo "백업 파일: $BACKUP_FILE" >> $REPORT_FILE

    # 30일 지난 로그 삭제
    find $LOG_FILE.* -mtime +30 -delete
fi

# 콘솔 출력
echo -e "${GREEN}슬로우 쿼리 리포트 생성 완료${NC}"
echo "파일: $REPORT_FILE"
echo "슬로우 쿼리 개수: $SLOW_COUNT"

# 이메일 전송 (선택)
if [ $SLOW_COUNT -gt 100 ]; then
    # mail -s "[경고] MySQL 슬로우 쿼리 리포트 $(date +%Y-%m-%d)" $EMAIL < $REPORT_FILE
    echo -e "${RED}경고 이메일 전송 (슬로우 쿼리 ${SLOW_COUNT}개)${NC}"
fi

exit 0
```

---

### 6-2. 스크립트 설치 및 테스트

```bash
# 1. 파일 생성
vi /usr/local/bin/slow-query-report.sh
# 위 스크립트 붙여넣기

# 2. 실행 권한 부여
chmod +x /usr/local/bin/slow-query-report.sh

# 3. 테스트 실행
/usr/local/bin/slow-query-report.sh

# 4. 결과 확인
ls -lh /var/log/mysql/reports/
cat /var/log/mysql/reports/daily-report-$(date +%Y%m%d).txt
```

---

### 6-3. Cron 등록

```bash
# Cron 편집
crontab -e

# 매일 오전 9시 실행
0 9 * * * /usr/local/bin/slow-query-report.sh

# 또는 매일 자정 실행
0 0 * * * /usr/local/bin/slow-query-report.sh

# Cron 확인
crontab -l
```

---

### 6-4. 리포트 예시

**생성된 리포트 (daily-report-20251023.txt):**

```
====================================
MySQL 슬로우 쿼리 일일 리포트
====================================
생성일: 2025-10-23 09:00:00
로그 파일: /var/log/mysql/slow-query.log
====================================

로그 파일 크기: 12M
오늘 슬로우 쿼리 개수: 153

=====================================
1. 가장 느린 쿼리 Top 10 (실행 시간 순)
=====================================

Count: 50  Time=2.5s (125s)  Lock=0.00s (0s)  Rows=1000.0 (50000)
  SELECT * FROM orders WHERE user_id=N ORDER BY created_at DESC

Count: 30  Time=1.8s (54s)  Lock=0.00s (0s)  Rows=500.0 (15000)
  SELECT u.*, COUNT(o.id) FROM users u LEFT JOIN orders o ON u.id=o.user_id GROUP BY u.id

Count: 20  Time=1.5s (30s)  Lock=0.00s (0s)  Rows=100.0 (2000)
  SELECT * FROM products WHERE name LIKE 'S'

...

=====================================
5. 권장 조치사항
=====================================
⚠️  경고: 슬로우 쿼리가 153개로 많습니다!
   → 우선순위 Top 3 쿼리 즉시 개선 필요

리포트 생성 완료: /var/log/mysql/reports/daily-report-20251023.txt
```

---

## 추가 학습: pt-query-digest

### 고급 분석 도구

**설치:**
```bash
# Ubuntu/Debian
apt-get update
apt-get install percona-toolkit

# Docker 컨테이너에서
docker exec -it wild-learning-mysql bash
apt-get update && apt-get install -y percona-toolkit
```

**사용:**
```bash
# 상세 분석
pt-query-digest /var/log/mysql/slow-query.log > detailed-report.txt

# 특정 기간만 분석
pt-query-digest --since '1 day ago' /var/log/mysql/slow-query.log

# 파일로 출력
pt-query-digest /var/log/mysql/slow-query.log \
  --output slowlog \
  --output-file /tmp/top-queries.log
```

**출력 예시:**
```
# Profile
# Rank Query ID           Response time Calls R/Call V/M   Item
# ==== ================== ============= ===== ====== ===== ======
#    1 0x1234567890ABCDEF   125.0 45.2%    50 2.5000  0.10 SELECT orders
#    2 0xFEDCBA0987654321    54.0 19.5%    30 1.8000  0.05 SELECT users orders
# MISC 0xMISC               97.8 35.3%    73 1.3397   0.0 <20 ITEMS>

# Query 1: 0.01 QPS, 0.03x concurrency, ID 0x1234567890ABCDEF
# This item is included in the report because it matches --limit.
# Scores: V/M = 0.10
# Time range: 2025-10-23T00:00:00 to 2025-10-23T23:59:59
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count         32      50
# Exec time     45    125s      2s      4s   2.50s   2.80s   0.35s   2.45s
# Lock time      0   100us       0    10us     2us     3us     2us     2us
# Rows sent      5  50000    1000    1000    1000    1000       0    1000
# Rows examine  50   50M   1.0M    1.0M   1.0M    1.0M       0   1.0M
# Query size    10   2.5k      50      50      50      50       0      50
# String:
# Databases    mydb
# Hosts        localhost
# Users        root
# Query_time distribution
#   1us
#  10us
# 100us
#   1ms
#  10ms
# 100ms
#    1s  ################################################################
#  10s+
# Tables
#    SHOW TABLE STATUS FROM `mydb` LIKE 'orders'\G
#    SHOW CREATE TABLE `mydb`.`orders`\G
# EXPLAIN /*!50100 PARTITIONS*/
SELECT * FROM orders WHERE user_id=12345 ORDER BY created_at DESC\G
```

**mysqldumpslow vs pt-query-digest:**

| 기능 | mysqldumpslow | pt-query-digest |
|------|--------------|----------------|
| 설치 | 기본 포함 | 별도 설치 필요 |
| 속도 | 빠름 | 느림 (상세 분석) |
| 상세도 | 기본 통계 | 매우 상세 |
| 95 percentile | 없음 | **있음** ⭐ |
| 표준편차 | 없음 | **있음** ⭐ |
| EXPLAIN | 없음 | **자동 생성** ⭐ |
| 시간대별 분석 | 없음 | **있음** ⭐ |

**권장:**
- 일일 모니터링: mysqldumpslow (빠르고 간단)
- 심층 분석: pt-query-digest (상세하고 정확)

---

## 실전 팁 정리

### 슬로우 쿼리 로그 설정 Best Practice

**프로덕션 환경:**
```ini
[mysqld]
slow_query_log = 1
long_query_time = 1.0  # 1초 (서비스에 따라 0.5~2초)
log_queries_not_using_indexes = 1
min_examined_row_limit = 1000  # 1000행 이상만
log_slow_admin_statements = 1  # ALTER, ANALYZE 등도 로깅
log_output = FILE  # TABLE보다 성능 좋음
```

**개발/테스트 환경:**
```ini
[mysqld]
slow_query_log = 1
long_query_time = 0.1  # 0.1초 (민감하게)
log_queries_not_using_indexes = 1
```

---

### 개선 우선순위 결정 체크리스트

```
1. 총 누적 시간 (Total Time) 확인
   → 실행 횟수 × 평균 시간
   → 가장 큰 것 우선

2. Rows_examined / Rows_sent 비율
   → 높을수록 (= 버리는 데이터 많음) 개선 여지 큼
   → 비율이 10 이상이면 문제

3. 사용자 체감 성능
   → 사용자가 직접 기다리는 쿼리
   → 평균 시간이 2초 이상이면 우선 개선

4. 개선 용이성
   → 인덱스만 추가하면 되는가?
   → 쿼리 재작성 필요한가?
   → 쉬운 것부터 빠른 승리(Quick Win)
```

---

### 흔한 슬로우 쿼리 패턴과 해결책

| 패턴 | 증상 | 해결책 |
|------|------|--------|
| 인덱스 누락 | type: ALL | 인덱스 추가 |
| 함수 사용 | WHERE YEAR(date) | 함수 제거, 범위 조건 |
| 앞부분 와일드카드 | LIKE '%keyword' | Full-Text Search |
| 부정 조건 | WHERE status != | 긍정 조건으로 변경 |
| SELECT * | 불필요한 컬럼 조회 | 필요한 컬럼만 명시 |
| filesort | Extra: Using filesort | 정렬 컬럼에 인덱스 |
| 비효율적 JOIN | 함수 사용한 JOIN | 함수 제거, 직접 조인 |
| 서브쿼리 | Dependent subquery | JOIN으로 변경 |

---

### 자동화 모니터링 체계

**레벨 1: 일일 리포트**
- 매일 오전 9시 자동 생성
- Top 10 느린 쿼리
- 슬로우 쿼리 개수 추이

**레벨 2: 실시간 알림**
```bash
# 슬로우 쿼리가 100개 넘으면 즉시 알림
if [ $SLOW_COUNT -gt 100 ]; then
    # Slack Webhook
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"⚠️ 슬로우 쿼리 ${SLOW_COUNT}개!\"}" \
      https://hooks.slack.com/services/YOUR/WEBHOOK/URL
fi
```

**레벨 3: 대시보드 연동**
- Grafana + Prometheus
- PMM (Percona Monitoring and Management)
- Datadog, New Relic 등

---

## 9주 과정 완료 축하!

### 배운 전체 내용 요약

| 주차 | 주제 | 핵심 내용 | 실무 적용 |
|------|------|-----------|----------|
| 1 | 인덱스 | B-Tree 구조, 복합 인덱스 | WHERE, JOIN 최적화 |
| 2 | EXPLAIN | type, rows, Extra 해석 | 쿼리 분석 능력 |
| 3 | 쿼리 비용 | 비용 계산, 느린 쿼리 예측 | 코드 리뷰 시 판단 |
| 4 | 락/데드락 | 동시성 제어, 데드락 해결 | 트랜잭션 설계 |
| 5 | 트랜잭션 격리 | 격리 수준별 문제 | 데이터 일관성 보장 |
| 6 | 페이지네이션 | Offset 지옥 탈출 | 무한 스크롤 최적화 |
| 7 | N+1 | ORM 최적화, Eager Loading | API 성능 개선 |
| 8 | 커넥션 풀 | 커넥션 관리, 누수 방지 | 안정적인 서비스 |
| 9 | 슬로우 쿼리 | 로그 분석, 병목 발견 | **지속적 모니터링** |

---

### 당신이 이제 할 수 있는 것

✅ **인덱스 설계**
- 단일/복합 인덱스 컬럼 순서 결정
- 인덱스를 못 타는 패턴 발견
- Cardinality 고려한 최적화

✅ **쿼리 분석 및 최적화**
- EXPLAIN 완벽 해석
- 느린 쿼리 즉시 발견
- 50배 이상 성능 개선

✅ **동시성 문제 해결**
- 데드락 발견 및 해결
- 적절한 격리 수준 선택
- 락 대기 최소화

✅ **실전 최적화 기법**
- 페이지네이션 커서 기반 구현
- N+1 문제 해결 (Batch Loading)
- 커넥션 풀 튜닝

✅ **모니터링 및 유지보수**
- **슬로우 쿼리 로그 분석** ⭐
- **개선 우선순위 결정** ⭐
- **자동화 리포트 생성** ⭐

---

### 실무 적용 로드맵

**1개월 차: 기존 시스템 분석**
- [ ] 슬로우 쿼리 로그 활성화
- [ ] 주요 테이블 인덱스 현황 파악
- [ ] Top 10 느린 쿼리 리스트업
- [ ] 개선 우선순위 문서화

**2개월 차: Quick Wins**
- [ ] 인덱스 추가만으로 개선 가능한 쿼리 처리
- [ ] 함수 사용, 부정 조건 등 안티패턴 제거
- [ ] SELECT * → 필요한 컬럼만
- [ ] 성과 측정 및 공유

**3개월 차: 구조적 개선**
- [ ] N+1 문제 전면 해결
- [ ] 페이지네이션 커서 기반 전환
- [ ] 복잡한 JOIN 쿼리 재설계
- [ ] 커넥션 풀 튜닝

**6개월 차: 모니터링 체계 구축**
- [ ] 일일 슬로우 쿼리 리포트 자동화
- [ ] 대시보드 구축 (Grafana 등)
- [ ] 알림 시스템 연동
- [ ] 팀 성능 리뷰 문화 정착

---

### 다음 단계

**심화 학습:**
1. Real MySQL 8.0 완독
2. 샤딩/파티셔닝
3. Read Replica 전략
4. 캐시 전략 (Redis)

**커뮤니티 기여:**
1. 블로그 포스팅
2. 사내 발표
3. 오픈소스 기여
4. 멘토링

---

**축하합니다! 당신은 이제 DB 최적화 전문가입니다!** 🎉

9주간의 여정을 완주한 당신,
이제 어떤 느린 쿼리도 자신 있게 개선할 수 있습니다.

**배운 것을 실무에 적용하고, 팀과 공유하세요!**

**Keep learning, keep optimizing!** 🚀
