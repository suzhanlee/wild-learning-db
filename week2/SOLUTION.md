# Week 2 정답: EXPLAIN 실전 분석

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: type별 성능 차이 체감하기 - 정답

### 쿼리 A: PRIMARY KEY 조회

```sql
EXPLAIN SELECT * FROM orders WHERE id = 500000;
```

**결과:**
- `type`: **const** (최고 성능!)
- `rows`: **1** (1개만 읽음)
- `key`: PRIMARY
- `Extra`: -

**실행 시간:** ~0.001ms (1ms 미만)

**왜 빠른가?**
- PRIMARY KEY는 UNIQUE하므로 딱 1건만 조회
- B-Tree 인덱스를 타고 O(log N) 시간에 바로 찾음
- MySQL이 "상수처럼" 취급 (const)

---

### 쿼리 B: 인덱스 있는 컬럼 조회

```sql
EXPLAIN SELECT * FROM orders WHERE user_id = 12345;
```

**결과:**
- `type`: **ref** (좋은 성능)
- `rows`: **~100** (해당 사용자의 주문 건수)
- `key`: idx_user_id
- `Extra`: -

**실행 시간:** ~2ms

**분석:**
- user_id에 인덱스가 있어서 효율적
- 하지만 여러 건 반환 가능 (1:N 관계)
- ref는 인덱스 참조 방식

---

### 쿼리 C: 범위 조회

```sql
EXPLAIN SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
```

**결과 (인덱스 없는 경우):**
- `type`: **ALL** (전체 스캔)
- `rows`: **1,000,000**
- `key`: NULL
- `Extra`: Using where

**실행 시간:** ~2000ms

**문제점:**
created_at에 인덱스가 없어서 전체 테이블 스캔

**인덱스 생성 후:**
```sql
CREATE INDEX idx_created_at ON orders(created_at);
EXPLAIN SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
```

**결과 (After):**
- `type`: **range** (범위 스캔)
- `rows`: **~300,000** (1년치 데이터)
- `key`: idx_created_at
- `Extra`: Using index condition

**실행 시간:** ~150ms

**개선율:** 약 13배

---

### 쿼리 D: 인덱스 없는 컬럼 조회

```sql
EXPLAIN SELECT * FROM orders WHERE amount > 1000;
```

**결과:**
- `type`: **ALL** (전체 스캔)
- `rows`: **1,000,000**
- `key`: NULL
- `Extra`: Using where

**실행 시간:** ~2500ms

**문제점:**
amount 컬럼에 인덱스가 없음

**하지만!** 인덱스를 만들어도 효율적이지 않을 수 있음:
- amount > 1000 조건이 대부분의 행을 반환한다면
- MySQL이 인덱스보다 Full Scan이 빠르다고 판단할 수 있음
- **Cardinality와 선택도**를 고려해야 함

**확인 방법:**
```sql
-- 전체 건수 대비 조건 만족 비율
SELECT COUNT(*) FROM orders WHERE amount > 1000;
SELECT COUNT(*) FROM orders;

-- 30% 이상이면 인덱스보다 Full Scan이 나을 수 있음
```

---

### 쿼리 E: 전체 스캔

```sql
EXPLAIN SELECT * FROM orders WHERE status LIKE '%ing%';
```

**결과:**
- `type`: **ALL** (전체 스캔)
- `rows`: **1,000,000**
- `key`: NULL
- `Extra`: Using where

**실행 시간:** ~2800ms

**왜 느린가?**
1. **앞부분 와일드카드** (`%ing%`): 인덱스 사용 불가
2. 모든 행의 status를 검사해야 함
3. 문자열 패턴 매칭은 비용이 높음

**대안:**
```sql
-- 1. Full-Text Search (단어 검색)
ALTER TABLE orders ADD FULLTEXT INDEX ft_status (status);
SELECT * FROM orders WHERE MATCH(status) AGAINST('ing' IN BOOLEAN MODE);

-- 2. 고정된 값이라면 IN 사용
SELECT * FROM orders WHERE status IN ('pending', 'processing', 'shipping');

-- 3. 뒷부분 와일드카드로 변경 가능하다면
SELECT * FROM orders WHERE status LIKE 'pend%';  -- 인덱스 사용 가능
```

---

### 성능 순위표 정답

| 쿼리 | type | rows | 실행시간 | 순위 |
|------|------|------|---------|------|
| A (id = ?) | const | 1 | ~0.001ms | 1위 🥇 |
| B (user_id = ?) | ref | ~100 | ~2ms | 2위 🥈 |
| C (BETWEEN) | range | ~300K | ~150ms | 3위 🥉 |
| D (amount >) | ALL | 1M | ~2500ms | 4위 |
| E (LIKE %%) | ALL | 1M | ~2800ms | 5위 |

**핵심 교훈:**
- **type이 성능을 결정한다!**
- const > ref > range > ALL
- rows가 적을수록 빠르다
- 인덱스가 있어도 못 쓰는 경우가 있다 (함수, 와일드카드)

---

## 미션 2: Extra 컬럼 해석하기 - 정답

### 쿼리 A: 상태별 주문 조회

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

**결과 (인덱스 없는 경우):**
- `type`: ALL
- `rows`: 1,000,000
- `Extra`: **Using where; Using filesort**

**문제점:**
1. **Using filesort** 발생! (정렬을 별도로 수행)
2. 100만 건을 읽어서 필터링하고 정렬
3. 매우 느림 (~3000ms)

**Using filesort란?**
- ORDER BY를 인덱스로 처리 못할 때 발생
- 메모리(sort_buffer_size)나 디스크에서 정렬
- 큰 데이터셋에서는 매우 느림

---

### 쿼리 B: 사용자별 주문 집계

```sql
EXPLAIN SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 10;
```

**결과:**
- `type`: index 또는 ALL
- `rows`: 1,000,000
- `Extra`: **Using temporary; Using filesort**

**문제점:**
1. **Using temporary**: 임시 테이블 생성
2. **Using filesort**: 정렬 수행
3. 가장 나쁜 조합!

**왜 이런 일이?**
- GROUP BY와 ORDER BY가 다른 컬럼 (user_id vs order_count)
- 집계 후 정렬하려면 임시 테이블 필요
- 메모리 부족 시 디스크 사용 (더 느림)

**개선 방법:**
```sql
-- 방법 1: 서브쿼리 활용
SELECT user_id, cnt FROM (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
) sub
ORDER BY cnt DESC
LIMIT 10;

-- 방법 2: user_id 인덱스 활용
CREATE INDEX idx_user_id ON orders(user_id);
-- GROUP BY는 빨라지지만 ORDER BY는 여전히 filesort

-- 방법 3: 집계 테이블 별도 관리 (대용량이라면)
-- user_order_stats 테이블에 미리 집계
```

---

### 쿼리 C: 커버링 인덱스 확인

```sql
EXPLAIN SELECT id, user_id, status FROM orders
WHERE user_id = 12345 AND status = 'completed';
```

**현재 인덱스:**
```sql
-- 기존: idx_user_id (user_id)
```

**결과 (기존 인덱스):**
- `type`: ref
- `key`: idx_user_id
- `Extra`: **Using where**

**복합 인덱스 생성 후:**
```sql
CREATE INDEX idx_user_status ON orders(user_id, status);
EXPLAIN SELECT id, user_id, status FROM orders
WHERE user_id = 12345 AND status = 'completed';
```

**결과 (After):**
- `type`: ref
- `key`: idx_user_status
- `Extra`: **Using index** 🎉

**커버링 인덱스란?**
- 쿼리에 필요한 모든 컬럼이 인덱스에 있음
- 테이블 데이터를 읽지 않고 인덱스만으로 처리
- PRIMARY KEY(id)는 자동으로 인덱스에 포함됨 (InnoDB)
- 가장 빠른 방식!

**조건:**
- SELECT 컬럼이 모두 인덱스에 있어야 함
- 여기서는 (user_id, status, id) 모두 인덱스에 포함

---

### 쿼리 D: JOIN 쿼리

```sql
EXPLAIN SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'user12345@example.com';
```

**결과 (인덱스 없는 경우):**

**users 테이블:**
- `type`: ALL
- `rows`: 1,000,000
- `Extra`: Using where

**orders 테이블:**
- `type`: ref
- `key`: idx_user_id
- `rows`: ~100

**드라이빙 테이블:** users (먼저 읽는 테이블)

**문제점:**
- users 테이블에서 email 인덱스가 없어서 ALL
- 100만 건을 스캔하며 이메일 찾음
- 매우 비효율적

**개선:**
```sql
CREATE INDEX idx_email ON users(email);
EXPLAIN SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'user12345@example.com';
```

**결과 (After):**

**users 테이블:**
- `type`: **ref** (개선!)
- `key`: idx_email
- `rows`: **1**
- `Extra`: -

**orders 테이블:**
- `type`: ref
- `key`: idx_user_id
- `rows`: ~100

**실행 시간:** 2000ms → 2ms (1000배 개선!)

---

### Extra 패턴 정리

| Extra | 의미 | 성능 | 조치 |
|-------|------|------|------|
| **Using index** | 커버링 인덱스 | ⭐⭐⭐⭐⭐ | 최고! 유지 |
| **Using index condition** | 인덱스 조건 푸시다운 | ⭐⭐⭐⭐ | 좋음 |
| **Using where** | MySQL 엔진에서 필터링 | ⭐⭐⭐ | type과 함께 판단 |
| **Using filesort** | 별도 정렬 | ⭐⭐ | 인덱스로 정렬 해결 |
| **Using temporary** | 임시 테이블 생성 | ⭐ | 쿼리 재작성 필요 |
| **Using join buffer** | 조인 버퍼 사용 | ⭐ | 인덱스 추가 필요 |

---

## 미션 3: 느린 쿼리 최적화 - 정답

### 문제 쿼리 1: 상태별 최근 주문 조회

#### Before

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

**결과:**
- `type`: ALL
- `rows`: 1,000,000
- `Extra`: **Using where; Using filesort**
- **실행 시간:** ~3000ms

**문제점:**
1. status에 인덱스 없음 (전체 스캔)
2. ORDER BY created_at을 별도로 정렬 (filesort)
3. 100만 건을 읽고 → 필터링하고 → 정렬

---

#### 정답 인덱스

```sql
CREATE INDEX idx_status_created ON orders(status, created_at);
```

**컬럼 순서 이유:**
1. **status가 먼저**: WHERE 조건 (동등 조건)
2. **created_at이 나중**: ORDER BY 조건
3. 이 순서로 인덱스가 정렬되어 있음:
   - status='pending' 범위 내에서
   - created_at 순으로 정렬됨
   - 별도 정렬 불필요!

---

#### After

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

**결과:**
- `type`: **ref** (개선!)
- `rows`: **~20,000** (pending 상태만)
- `key`: idx_status_created
- `Extra`: **Using index condition** (filesort 사라짐!)
- **실행 시간:** ~2ms

**성능 개선:**
- 실행 시간: 3000ms → 2ms (**1500배 개선!** ✓)
- type: ALL → ref
- rows: 1,000,000 → 20,000
- filesort 제거!

---

### 문제 쿼리 2: 사용자별 주문 통계

#### Before

```sql
EXPLAIN SELECT user_id, COUNT(*) as cnt, SUM(amount) as total
FROM orders
WHERE status IN ('completed', 'shipped')
GROUP BY user_id
HAVING total > 10000
ORDER BY total DESC;
```

**결과:**
- `type`: ALL
- `rows`: 1,000,000
- `Extra`: **Using where; Using temporary; Using filesort**
- **실행 시간:** ~5000ms

**문제점:**
1. status 필터링이 전체 스캔
2. 임시 테이블 생성 (GROUP BY 결과 저장)
3. 정렬 수행 (ORDER BY total)

---

#### 정답 인덱스

```sql
CREATE INDEX idx_status_user ON orders(status, user_id);
```

**이유:**
1. **status 먼저**: WHERE 조건으로 먼저 필터링
2. **user_id 나중**: GROUP BY 대상
3. status로 좁히고 → user_id별로 묶기

**추가 최적화 (쿼리 개선):**
```sql
-- HAVING 조건을 서브쿼리로 분리
SELECT user_id, cnt, total FROM (
    SELECT user_id, COUNT(*) as cnt, SUM(amount) as total
    FROM orders
    WHERE status IN ('completed', 'shipped')
    GROUP BY user_id
) sub
WHERE total > 10000
ORDER BY total DESC;
```

---

#### After

**결과:**
- `type`: **range** (개선!)
- `rows`: **~600,000** (completed + shipped)
- `key`: idx_status_user
- `Extra`: **Using index condition; Using temporary; Using filesort**
- **실행 시간:** ~800ms

**성능 개선:**
- 실행 시간: 5000ms → 800ms (**6배 개선**)
- type: ALL → range
- rows: 1,000,000 → 600,000

**주의:**
- GROUP BY + ORDER BY(다른 컬럼)는 근본적으로 비효율적
- temporary와 filesort는 완전히 제거하기 어려움
- 대용량이라면 별도 집계 테이블 고려

---

### 문제 쿼리 3: 기간별 주문 집계

#### Before

```sql
EXPLAIN SELECT DATE(created_at) as order_date, COUNT(*) as cnt
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
GROUP BY DATE(created_at)
ORDER BY order_date;
```

**결과 (created_at 인덱스 있어도):**
- `type`: range 또는 index
- `rows`: ~300,000
- `Extra`: **Using index condition; Using temporary; Using filesort**
- **실행 시간:** ~1000ms

**문제점:**
1. **GROUP BY에 함수 사용** (DATE(created_at))
2. 인덱스 정렬을 활용 못함
3. 임시 테이블 + 정렬 필요

---

#### 해결 방법 1: 가상 컬럼 (MySQL 5.7+)

```sql
-- 가상 컬럼 추가
ALTER TABLE orders
ADD COLUMN order_date DATE AS (DATE(created_at)) STORED;

-- 가상 컬럼에 인덱스
CREATE INDEX idx_order_date ON orders(order_date);

-- 쿼리 개선
SELECT order_date, COUNT(*) as cnt
FROM orders
WHERE order_date >= '2024-01-01'
  AND order_date < '2025-01-01'
GROUP BY order_date
ORDER BY order_date;
```

**결과:**
- `type`: **range**
- `rows`: ~300,000
- `Extra`: **Using index condition**
- **실행 시간:** ~150ms

**개선율:** 1000ms → 150ms (**7배 개선!**)

---

#### 해결 방법 2: 쿼리 개선 (인덱스 활용)

```sql
-- created_at 인덱스 생성
CREATE INDEX idx_created_at ON orders(created_at);

-- 쿼리는 동일하지만 인덱스 사용
SELECT DATE(created_at) as order_date, COUNT(*) as cnt
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
GROUP BY DATE(created_at)
ORDER BY order_date;
```

**결과:**
- `type`: range
- `rows`: ~300,000
- `Extra`: Using index condition; Using temporary; Using filesort
- **실행 시간:** ~500ms

**개선율:** 1000ms → 500ms (2배)

---

#### 해결 방법 3: 애플리케이션 레벨 집계

```sql
-- 1. 범위 데이터만 가져오기
SELECT created_at, 1 as cnt
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 2. 애플리케이션에서 날짜별 집계
-- (대용량이면 비추천)
```

---

## 추가 학습: type 완벽 정리

### type 종류 (빠름 → 느림)

#### 1. system
```sql
-- 테이블에 행이 1개뿐인 경우
SELECT * FROM single_row_table;
```
- 거의 볼 일 없음
- 성능: ⭐⭐⭐⭐⭐

---

#### 2. const
```sql
-- PRIMARY KEY나 UNIQUE 인덱스로 1건 조회
SELECT * FROM orders WHERE id = 123;
```
- "상수처럼" 취급
- 최고 성능
- 성능: ⭐⭐⭐⭐⭐

---

#### 3. eq_ref
```sql
-- JOIN에서 PRIMARY KEY나 UNIQUE 사용
SELECT * FROM orders o
JOIN users u ON o.user_id = u.id;
```
- 조인마다 딱 1건씩
- JOIN에서 최고 성능
- 성능: ⭐⭐⭐⭐⭐

---

#### 4. ref
```sql
-- 인덱스 사용, 여러 건 반환
SELECT * FROM orders WHERE user_id = 123;
```
- 가장 흔한 좋은 타입
- 성능: ⭐⭐⭐⭐

---

#### 5. fulltext
```sql
-- FULLTEXT 인덱스 사용
SELECT * FROM articles
WHERE MATCH(content) AGAINST('keyword');
```
- Full-Text Search 전용
- 성능: ⭐⭐⭐⭐

---

#### 6. ref_or_null
```sql
-- ref + NULL 체크
SELECT * FROM orders
WHERE user_id = 123 OR user_id IS NULL;
```
- ref와 비슷하지만 NULL도 검색
- 성능: ⭐⭐⭐⭐

---

#### 7. index_merge
```sql
-- 여러 인덱스 동시 사용
SELECT * FROM orders
WHERE user_id = 123 OR status = 'pending';
```
- 여러 인덱스 결과를 병합
- 성능: ⭐⭐⭐

---

#### 8. range
```sql
-- 범위 스캔
SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
```
- >, <, BETWEEN, IN 등
- 범위가 좁으면 좋음, 넓으면 나쁨
- 성능: ⭐⭐⭐

---

#### 9. index
```sql
-- 인덱스 풀 스캔
SELECT id FROM orders;
```
- 인덱스 전체를 읽음
- 테이블보단 빠르지만 비효율적
- 성능: ⭐⭐

---

#### 10. ALL
```sql
-- 테이블 풀 스캔
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
```
- 최악의 성능
- 대용량 테이블에서 치명적
- 성능: ⭐

---

## 실전 EXPLAIN 체크리스트

### 1단계: type 확인

```
✅ const, eq_ref, ref → 좋음, 그대로 진행
⚠️ range → rows 확인 필요
❌ index, ALL → 개선 필수
```

### 2단계: rows 확인

```
✅ 100 이하 → 매우 좋음
⚠️ 100~10,000 → 괜찮음, 모니터링
❌ 10,000 이상 → 개선 검토
❌ 100,000 이상 → 즉시 개선
```

### 3단계: Extra 확인

```
✅ Using index → 최고! 유지
✅ Using index condition → 좋음
⚠️ Using where → type과 함께 판단
  - type=ref + Using where → 괜찮음
  - type=ALL + Using where → 나쁨
❌ Using filesort → 인덱스로 해결
❌ Using temporary → 쿼리 재작성
```

---

## 실무 적용 가이드

### 즉시 할 것

#### 1. 주요 API 쿼리 점검
```sql
-- Slow Query Log에서 상위 10개 쿼리 추출
-- 각각 EXPLAIN 실행

EXPLAIN [느린 쿼리];

-- type, rows, Extra 체크
-- 문제 있으면 인덱스 추가 계획
```

#### 2. type=ALL 쿼리 찾기
```bash
# 코드베이스에서 검색
grep -r "SELECT" . --include="*.java" | grep -i "WHERE"

# 각 쿼리 EXPLAIN 실행
# type=ALL인 것들 리스트업
```

#### 3. Using filesort 제거
```sql
-- ORDER BY 있는 쿼리 찾기
-- WHERE + ORDER BY 복합 인덱스 검토
-- Before/After 성능 측정
```

---

### 팀 공유 내용

**1. EXPLAIN 해석 가이드 작성**
```
type 순서: const > eq_ref > ref > range > index > ALL
rows 기준: 100 / 10,000 / 100,000
Extra 위험: Using filesort, Using temporary
```

**2. 코드 리뷰 체크리스트**
```
- [ ] 새 쿼리는 EXPLAIN 실행했는가?
- [ ] type이 ref 이상인가?
- [ ] rows가 10,000 이하인가?
- [ ] Using filesort가 없는가?
```

**3. 개선 사례 공유**
```
쿼리: [쿼리]
Before: type=ALL, rows=1M, 3000ms
After: type=ref, rows=100, 2ms
개선율: 1500배
방법: [인덱스 설계]
```

---

### 주의사항

#### 1. 인덱스 추가 시 고려사항
- **SELECT 성능 향상 vs INSERT/UPDATE 저하**
- 쓰기가 많은 테이블은 신중히
- 실제 사용 패턴 확인 후 추가

#### 2. EXPLAIN은 예측일 뿐
- **실제 실행 시간 측정 필수**
- EXPLAIN ANALYZE 활용 (MySQL 8.0.18+)
- 프로덕션 데이터와 개발 데이터 차이 고려

#### 3. 운영 DB 적용 절차
1. 개발 환경에서 테스트
2. 스테이징 환경에서 검증
3. 트래픽 적은 시간대 선택
4. 모니터링 철저히
5. 롤백 계획 준비

---

## 다음 주차 예고: Week 3 - 쿼리 성능 비용 감각

EXPLAIN을 마스터했으니, 이제는:
- 쿼리를 보고 3초 안에 "이거 느리겠다" 판단하기
- rows와 JOIN 순서로 비용 계산하기
- 복잡한 쿼리를 효율적으로 재작성하기

**실력 향상 포인트:**
- EXPLAIN 없이도 느린 쿼리 예측
- 쿼리 비용 감각 체득
- 최적화 전략 수립 능력

---

## 보너스: 자주 하는 실수 TOP 5

### 1. WHERE 절에 함수 사용
```sql
-- ❌ 나쁨
WHERE YEAR(created_at) = 2024

-- ✅ 좋음
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
```

### 2. 복합 인덱스 순서 잘못
```sql
-- ❌ 나쁨: ORDER BY 컬럼이 먼저
INDEX (created_at, status)

-- ✅ 좋음: WHERE 컬럼이 먼저
INDEX (status, created_at)
```

### 3. OR 조건 남발
```sql
-- ❌ 나쁨: 인덱스 못 탐
WHERE user_id = 123 OR user_id = 456

-- ✅ 좋음
WHERE user_id IN (123, 456)
```

### 4. SELECT * 사용
```sql
-- ❌ 나쁨: 불필요한 컬럼까지 읽음
SELECT * FROM orders WHERE user_id = 123

-- ✅ 좋음: 커버링 인덱스 가능
SELECT id, user_id, status FROM orders WHERE user_id = 123
```

### 5. LIMIT 없는 대용량 조회
```sql
-- ❌ 나쁨: 100만 건 다 가져옴
SELECT * FROM orders WHERE status = 'pending'

-- ✅ 좋음
SELECT * FROM orders WHERE status = 'pending' LIMIT 100
```

---

**완료 축하합니다!** 🎉

EXPLAIN 해석 능력을 마스터했습니다!
이제 쿼리를 보면 type, rows, Extra가 눈에 보일 겁니다.

**다음 액션:**
1. [ ] ANSWER.md와 SOLUTION.md 비교
2. [ ] 틀린 부분 복습
3. [ ] 회사 쿼리 10개 EXPLAIN 분석
4. [ ] 느린 쿼리 1개 이상 개선
5. [ ] Week 3 미션 시작

**실무 팁:**
- 모든 새 쿼리는 EXPLAIN부터
- 코드 리뷰 시 EXPLAIN 결과 첨부
- 슬로우 쿼리 발견 시 즉시 EXPLAIN
- 팀에 개선 사례 공유

**성장한 당신의 모습:**
- type 순서 완벽 암기 ✓
- rows로 성능 예측 ✓
- Extra로 문제 발견 ✓
- 인덱스 설계 자신감 ✓

**다음 단계로!** → Week 3: 쿼리 성능 비용 감각 🚀
