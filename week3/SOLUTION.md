# Week 3 정답: 쿼리 비용 예측

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 예측하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: WHERE 비용 계산 - 정답

### 예측 정답

| 순위 | 쿼리 | 시간복잡도 | 예상 시간 | type | 이유 |
|------|------|------------|-----------|------|------|
| 1 (빠름) | A: PRIMARY KEY | O(1) | < 1ms | const | 해시/트리 1번 탐색 |
| 2 | E: 범위 조건 | O(log N) | 1-10ms | range | 인덱스 범위 검색 |
| 3 | B: 인덱스 사용 | O(log N) | 1-10ms | ref | 인덱스로 필터링 |
| 4 | D: 함수 사용 | O(N) | 100-500ms | ALL | 전체 스캔 + 함수 |
| 5 (느림) | C: LIKE '%' | O(N) | 100-1000ms | ALL | 전체 스캔 |

---

### 각 쿼리 상세 분석

#### 쿼리 A: PRIMARY KEY 조회 ✅

```sql
SELECT * FROM products WHERE id = 50000;
```

**EXPLAIN 결과:**
- `type`: **const** (최적화된 상수)
- `rows`: **1**
- `key`: **PRIMARY**

**실제 성능:**
- 실행 시간: **< 1ms**
- 비용: O(1)

**이유:**
- PRIMARY KEY는 클러스터드 인덱스
- B-Tree에서 직접 위치 파악
- 단 1번의 탐색으로 즉시 조회

---

#### 쿼리 B: 인덱스 사용 ✅

```sql
SELECT * FROM products WHERE category = 'electronics';
```

**EXPLAIN 결과:**
- `type`: **ref** (인덱스 참조)
- `rows`: **~50,000** (카테고리별 약 5%)
- `key`: **idx_category**

**실제 성능:**
- 실행 시간: **10-50ms**
- 비용: O(log N) + 결과 행 읽기

**이유:**
- idx_category 인덱스 사용
- B-Tree 탐색: log₂(1,000,000) ≈ 20번
- 매칭되는 행들 순차 읽기

---

#### 쿼리 C: 부분 문자열 검색 ❌

```sql
SELECT * FROM products WHERE name LIKE '%phone%';
```

**EXPLAIN 결과:**
- `type`: **ALL** (전체 테이블 스캔)
- `rows`: **1,000,000**
- `key`: **NULL** (인덱스 미사용)
- `Extra`: **Using where**

**실제 성능:**
- 실행 시간: **500-1500ms**
- 비용: O(N)

**문제점:**
- **앞부분 와일드카드** (`%`로 시작)
- B-Tree는 앞에서부터 정렬되어 있어서 사용 불가
- 모든 행의 name 컬럼을 하나씩 확인해야 함

**개선 방법:**

1. **뒷부분 와일드카드로 변경** (가능하다면)
```sql
-- ✅ 인덱스 사용 가능
SELECT * FROM products WHERE name LIKE 'phone%';
```

2. **Full-Text Search 사용**
```sql
ALTER TABLE products ADD FULLTEXT INDEX ft_name (name);
SELECT * FROM products WHERE MATCH(name) AGAINST('phone' IN BOOLEAN MODE);
-- 실행 시간: 10-50ms
```

3. **Elasticsearch 등 검색 엔진 사용** (대규모 서비스)

---

#### 쿼리 D: 함수 사용 ❌

```sql
SELECT * FROM products WHERE YEAR(created_at) = 2024;
```

**EXPLAIN 결과:**
- `type`: **ALL** (전체 테이블 스캔)
- `rows`: **1,000,000**
- `key`: **NULL** (인덱스 있지만 못 씀)
- `Extra`: **Using where**

**실제 성능:**
- 실행 시간: **300-800ms**
- 비용: O(N)

**문제점:**
- **컬럼에 함수 적용** (YEAR)
- created_at에 인덱스가 있어도 사용 불가
- 모든 행에 YEAR() 함수를 실행한 후 비교

**개선 방법:**

```sql
-- ✅ 범위 조건으로 변경
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- EXPLAIN 결과:
-- type: range
-- rows: ~200,000 (2024년 데이터만)
-- key: idx_created_at
-- 실행 시간: 50-150ms
```

**개선율:** 약 5~10배

---

#### 쿼리 E: 범위 조건 ✅

```sql
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**EXPLAIN 결과:**
- `type`: **range** (범위 검색)
- `rows`: **~200,000** (전체의 약 20%)
- `key`: **idx_created_at**

**실제 성능:**
- 실행 시간: **50-150ms**
- 비용: O(log N) + 결과 행 읽기

**이유:**
- 인덱스를 사용한 범위 검색
- B-Tree에서 시작점과 끝점 찾기: O(log N)
- 해당 범위의 행들 순차 읽기: O(M) (M은 결과 행 수)

---

### 성능 비교 요약

| 쿼리 | 실행 시간 | 비용 | 검사 행 수 | 배속 |
|------|-----------|------|-----------|------|
| A: PRIMARY KEY | < 1ms | O(1) | 1 | 1x |
| E: 범위 조건 | 50-150ms | O(log N + M) | ~200,000 | 100x |
| B: 인덱스 | 10-50ms | O(log N + M) | ~50,000 | 50x |
| D: 함수 | 300-800ms | O(N) | 1,000,000 | 500x |
| C: LIKE | 500-1500ms | O(N) | 1,000,000 | 1000x |

**핵심 교훈:**
- 인덱스를 못 타면 O(N): 100~1000배 느림
- 함수나 앞부분 와일드카드는 인덱스 무용지물
- 범위 조건이라도 인덱스를 타면 충분히 빠름

---

## 미션 2: JOIN 비용 비교 - 정답

### 예측 정답

**테이블 크기:**
- users: 100,000 건
- orders: 1,000,000 건

#### 방법 1: 인덱스 없음 ❌

**비용 계산:**
```
Nested Loop Join (최악의 경우):
- users 각 행마다 orders 전체를 스캔
- 100,000 × 1,000,000 = 1,000억 번 비교
- 비용: O(N × M)
```

**예상 시간:** 수 분 ~ 수십 분 (실행 불가능 수준)

**EXPLAIN 결과:**
- users: type = ALL, rows = 100,000
- orders: type = ALL, rows = 1,000,000 (user 하나당)

---

#### 방법 2: 인덱스 있음 ✅

```sql
CREATE INDEX idx_user_id ON orders(user_id);
```

**비용 계산:**
```
Nested Loop Join + Index:
- users 각 행마다 orders에서 인덱스 검색
- 100,000 × log₂(1,000,000)
- 100,000 × 20 = 2,000,000 번 비교
- 비용: O(N × log M)
```

**예상 시간:** 3-10초

**EXPLAIN 결과:**
- users: type = ALL, rows = 100,000
- orders: type = ref, rows = ~10 (user당 평균)
- key = idx_user_id

**개선율:** 방법 1 대비 **약 50,000배**

---

#### 방법 3: WHERE로 선필터 ✅✅

```sql
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
  AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id;
```

**비용 계산:**
```
1단계: orders 필터링
  - status = 'completed': 전체의 약 40% (400,000건)
  - 최근 30일: 전체의 약 8% (80,000건)
  - 교집합: 약 32,000건

2단계: 필터된 orders와 users JOIN
  - 32,000 × log₂(100,000)
  - 32,000 × 17 ≈ 544,000 번

비용: O(N × log M) (N이 대폭 감소)
```

**예상 시간:** 200-500ms

**EXPLAIN 결과:**
- orders: type = range, rows = ~32,000
- users: type = eq_ref, rows = 1
- key = idx_user_id (orders), PRIMARY (users)

**개선율:** 방법 2 대비 **약 10-20배**

---

### 실제 성능 비교

| 방법 | 실행 시간 | type (orders) | rows | 개선율 |
|------|-----------|---------------|------|--------|
| 1. 인덱스 없음 | 수 분 이상 | ALL | 1,000,000 | - |
| 2. 인덱스 있음 | 3-10초 | ref | ~10 | 50,000배 |
| 3. WHERE 필터 | 200-500ms | range → ref | ~32,000 | 15배 추가 |

**핵심 교훈:**
1. **JOIN 조건에 인덱스는 필수** - 없으면 재앙 수준
2. **WHERE로 먼저 필터링** - JOIN 전에 데이터를 줄여라
3. **큰 테이블부터 필터링** - orders를 먼저 줄이는 것이 효과적

---

### 추가 최적화 팁

#### 최적 인덱스 설계

```sql
-- 더 나은 인덱스 (WHERE 절 고려)
CREATE INDEX idx_status_date_user ON orders(status, created_at, user_id);
```

**효과:**
- WHERE 조건을 인덱스로 직접 필터링
- JOIN 조건도 인덱스에 포함
- 실행 시간: 50-100ms (추가 2~4배 개선)

---

## 미션 3: 서브쿼리 vs JOIN 성능 대결 - 정답

### 예측 정답

#### 방법 A: 상관 서브쿼리 ❌❌❌

```sql
SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;
```

**비용 계산:**
```
상관 서브쿼리 (Correlated Subquery):
- users 각 행(100,000건)마다 서브쿼리 실행
- 각 서브쿼리: orders 전체 스캔 또는 인덱스 검색

인덱스 없으면:
  100,000 × 1,000,000 = 1,000억 번
  비용: O(N × M)

인덱스 있어도:
  100,000 × log₂(1,000,000) = 2,000,000번
  비용: O(N × log M)
```

**예상 시간:**
- 인덱스 없으면: 실행 불가능 (수십 분)
- 인덱스 있어도: 5-15초

**EXPLAIN 결과:**
- id = 1: users, type = ALL
- id = 2: orders, select_type = **DEPENDENT SUBQUERY**

**문제점:**
- `DEPENDENT SUBQUERY`: 외부 쿼리에 의존
- users 행마다 서브쿼리가 **독립적으로 실행**
- 결과를 캐싱하거나 최적화할 수 없음

---

#### 방법 B: JOIN + GROUP BY ✅

```sql
SELECT u.*
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
    HAVING cnt > 10
) o ON u.id = o.user_id;
```

**비용 계산:**
```
1단계: orders GROUP BY
  - 전체 orders 스캔: 1,000,000건
  - GROUP BY 처리: O(N)
  - 비용: O(N)

2단계: HAVING 필터
  - 10개 이상인 user만 추출
  - 결과: 약 30,000명 (30%)

3단계: users와 JOIN
  - 30,000 × log₂(100,000)
  - 30,000 × 17 ≈ 510,000번
  - 비용: O(M × log N)

총 비용: O(N) + O(M × log N) ≈ O(N)
(N = orders, M = 필터된 user 수)
```

**예상 시간:** 500-1500ms

**EXPLAIN 결과:**
- id = 2: orders, type = ALL (GROUP BY 위해 전체 스캔 필요)
  - Extra: Using temporary; Using filesort
- id = 1: users, type = eq_ref (PRIMARY KEY로 조인)

---

### 실제 성능 비교

| 방법 | 실행 시간 | 비용 | 방식 | 결과 행 |
|------|-----------|------|------|---------|
| A. 상관 서브쿼리 | 5-15초 | O(N × log M) | 100,000번 서브쿼리 | 30,000 |
| B. JOIN | 500-1500ms | O(N) | 1번 GROUP BY + JOIN | 30,000 |

**개선율:** 약 **10-30배**

---

### 왜 이렇게 차이가 나는가?

#### 상관 서브쿼리의 문제

```sql
-- MySQL이 실제로 하는 일:

FOR each row in users (100,000번):
    COUNT orders WHERE user_id = current_user.id
    IF count > 10:
        return this user
```

- **루프 안에서 쿼리 실행**: 비효율의 핵심
- **매번 독립적으로 실행**: 최적화 불가
- **결과 재사용 불가**: 캐싱 불가

#### JOIN의 장점

```sql
-- MySQL이 실제로 하는 일:

1. orders 전체를 한 번만 스캔하여 GROUP BY (1번)
2. 결과를 임시 테이블에 저장 (메모리)
3. users와 효율적으로 JOIN (인덱스 사용)
```

- **한 번만 처리**: orders를 1번만 읽음
- **결과 재사용**: 임시 테이블에 저장
- **최적화 가능**: MySQL이 실행 계획 최적화

---

### 추가 최적화

#### 최적 인덱스 추가

```sql
-- user_id로 orders를 빠르게 그룹핑
CREATE INDEX idx_user_id ON orders(user_id);
```

**효과:**
- GROUP BY가 인덱스 순서대로 처리
- 임시 테이블 크기 감소
- 실행 시간: 200-500ms (추가 2~3배 개선)

---

### 실전 적용 규칙

**상관 서브쿼리를 절대 쓰지 말아야 할 때:**
- [ ] 외부 테이블이 크다 (수만 건 이상)
- [ ] 서브쿼리가 복잡한 집계를 한다 (COUNT, SUM 등)
- [ ] 서브쿼리가 큰 테이블을 스캔한다

**상관 서브쿼리를 써도 되는 경우:**
- [ ] 외부 테이블이 매우 작다 (수백 건)
- [ ] 서브쿼리가 인덱스를 완벽히 탄다 (type = const/eq_ref)
- [ ] 서브쿼리가 EXISTS/NOT EXISTS 형태 (일찍 종료 가능)

**일반 원칙:**
> 상관 서브쿼리는 피하고, JOIN이나 스칼라 서브쿼리로 변환하라!

---

## 미션 4: ORDER BY 비용 감각 - 정답

### 각 케이스 분석

#### 케이스 1: 인덱스 없음 ❌

```sql
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN 결과:**
- type: **ALL**
- rows: **1,000,000**
- Extra: **Using filesort**

**비용 계산:**
```
1. 전체 테이블 스캔: 1,000,000건
2. 정렬: O(N log N)
   - 1,000,000 × log₂(1,000,000)
   - 1,000,000 × 20 = 20,000,000번 비교
3. 상위 10건 반환
```

**실제 성능:**
- 실행 시간: **1-3초**
- 비용: O(N log N)

**문제:**
- `Using filesort`: 메모리 또는 디스크에서 정렬
- 전체 데이터를 읽고 정렬해야 함

---

#### 케이스 2: created_at 인덱스 있음 ✅

```sql
CREATE INDEX idx_created_at ON orders(created_at);

SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN 결과:**
- type: **index**
- rows: **10** (LIMIT만큼만)
- key: **idx_created_at**
- Extra: **Using index** (커버링 인덱스) 또는 Extra 없음

**비용 계산:**
```
1. 인덱스 끝에서부터 10건만 읽기
   - B-Tree 끝 찾기: O(log N)
   - 10건 순차 읽기: O(10) = O(1)
2. 정렬 불필요 (인덱스가 이미 정렬됨)

총 비용: O(log N) + O(1) ≈ O(1)
```

**실제 성능:**
- 실행 시간: **< 1ms**
- 비용: O(1) (실질적으로)

**개선율:** 케이스 1 대비 **1000~3000배**

---

#### 케이스 3: 복합 조건 (단일 인덱스) ⚠️

```sql
SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
-- 인덱스: idx_created_at만 있음
```

**EXPLAIN 결과:**
- type: **ALL** 또는 **range**
- rows: **수십만 ~ 100만**
- key: idx_created_at 또는 NULL
- Extra: **Using where; Using filesort**

**비용 계산:**
```
옵션 A: 인덱스를 타지 않음
  1. 전체 스캔: 1,000,000건
  2. WHERE 필터: status 체크
  3. 정렬: O(N log N)

옵션 B: 인덱스를 탐 (MySQL 판단)
  1. idx_created_at으로 정렬된 순서대로 읽기
  2. 각 행마다 status 체크
  3. completed 10건 찾을 때까지 계속

MySQL은 보통 옵션 A를 선택
```

**실제 성능:**
- 실행 시간: **500-1500ms**
- 비용: O(N) 또는 O(N log N)

**문제:**
- WHERE와 ORDER BY가 다른 컬럼
- 하나의 단일 인덱스로는 둘 다 최적화 불가

---

#### 케이스 4: 최적 인덱스 ✅✅

```sql
CREATE INDEX idx_status_created ON orders(status, created_at);

SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN 결과:**
- type: **ref**
- rows: **10~수십**
- key: **idx_status_created**
- Extra: **Using index condition** (filesort 없음!)

**비용 계산:**
```
1. 인덱스에서 status = 'completed' 시작점 찾기
   - O(log N)

2. 해당 범위 내에서 created_at 역순으로 10건 읽기
   - 인덱스가 (status, created_at)로 정렬되어 있음
   - O(10) = O(1)

3. 정렬 불필요

총 비용: O(log N) + O(1) ≈ O(1)
```

**실제 성능:**
- 실행 시간: **< 1ms**
- 비용: O(1) (실질적으로)

**개선율:** 케이스 3 대비 **1000~1500배**

---

### 성능 비교 요약

| 케이스 | filesort | 실행 시간 | rows | 개선율 |
|--------|----------|-----------|------|--------|
| 1. 인덱스 없음 | ✓ | 1-3초 | 1,000,000 | - |
| 2. 단일 인덱스 | ✗ | < 1ms | 10 | 2000배 |
| 3. 복합 조건 | ✓ | 0.5-1.5초 | 수십만 | 1.5배 |
| 4. 최적 인덱스 | ✗ | < 1ms | 10 | 2000배 |

---

### 핵심 교훈

#### 1. LIMIT이 있어도 ORDER BY가 느릴 수 있다

```sql
-- ❌ 인덱스 없으면 전체를 정렬 후 10건 반환
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;

-- 1,000,000건 정렬 → 10건 선택
-- 시간: 1-3초
```

#### 2. 복합 인덱스 순서가 중요

```sql
-- ✅ 좋음: WHERE 조건 먼저, ORDER BY 나중
CREATE INDEX idx_status_created ON orders(status, created_at);

-- ❌ 나쁨: 순서 바뀌면 효과 없음
CREATE INDEX idx_created_status ON orders(created_at, status);
```

#### 3. Using filesort = 위험 신호

```sql
-- EXPLAIN에서 Extra 확인
Extra: Using filesort  -- 느림!
Extra: Using where     -- 보통 괜찮음
Extra: 없음 또는 Using index  -- 빠름!
```

---

## 비용 계산 공식 총정리

### WHERE 절 비용

| 패턴 | 비용 | 예시 | 100만 건 기준 시간 |
|------|------|------|-------------------|
| PRIMARY KEY | O(1) | `WHERE id = 123` | < 1ms |
| UNIQUE 인덱스 | O(1) | `WHERE email = '...'` | < 1ms |
| 인덱스 (동등) | O(log N) | `WHERE status = 'active'` | 1-10ms |
| 인덱스 (범위) | O(log N + M) | `WHERE created_at > '...'` | 10-100ms |
| 인덱스 못 탐 | O(N) | `LIKE '%keyword'` | 100-1000ms |
| 함수 사용 | O(N) | `WHERE YEAR(date) = 2024` | 100-1000ms |

---

### JOIN 비용

| 패턴 | 비용 | 100만 × 10만 JOIN | 시간 |
|------|------|-------------------|------|
| 인덱스 없음 | O(N × M) | 1000억 번 | 수 분 ~ 수 시간 |
| 인덱스 있음 | O(N × log M) | 2000만 번 | 수 초 |
| WHERE 선필터 | O(N' × log M) | 수십만 번 | 수백 ms |
| 양쪽 인덱스 | O(log N + log M) | 수십 번 | < 1ms |

---

### ORDER BY/GROUP BY 비용

| 패턴 | 비용 | 100만 건 기준 | 시간 |
|------|------|---------------|------|
| 인덱스 사용 | O(log N + M) | log N + LIMIT | < 1ms |
| filesort (메모리) | O(N log N) | 2000만 번 | 1-3초 |
| filesort (디스크) | O(N log N) + I/O | 2000만 번 + I/O | 5-30초 |
| GROUP BY (인덱스) | O(N) | 100만 번 | 100-500ms |
| GROUP BY (임시테이블) | O(N log N) | 2000만 번 | 1-5초 |

---

### 서브쿼리 비용

| 패턴 | 비용 | 예시 | 위험도 |
|------|------|------|--------|
| 스칼라 서브쿼리 (1회) | O(N) | `(SELECT COUNT(*) FROM ...)` | 낮음 |
| 상관 서브쿼리 | O(N × M) | `WHERE (SELECT ... WHERE t.id = ...)` | 매우 높음 |
| IN 서브쿼리 | O(N × M) | `WHERE id IN (SELECT ...)` | 높음 |
| EXISTS | O(N × log M) | `WHERE EXISTS (...)` | 중간 (일찍 종료) |

---

## 실전 예측 체크리스트

### 코드 리뷰 시 즉시 체크

#### 빨간불 (즉시 수정) 🔴

- [ ] 상관 서브쿼리 (WHERE 절에 서브쿼리)
- [ ] JOIN 조건에 인덱스 없음
- [ ] `WHERE FUNCTION(column)`
- [ ] `LIKE '%keyword'` (앞부분 와일드카드)
- [ ] `!=`, `NOT IN` (대규모 데이터)
- [ ] ORDER BY에 filesort (EXPLAIN 확인)
- [ ] 큰 테이블 JOIN을 WHERE 없이

#### 노란불 (검토 필요) 🟡

- [ ] 범위 조건 + ORDER BY
- [ ] 여러 테이블 JOIN (3개 이상)
- [ ] GROUP BY + ORDER BY
- [ ] LIMIT이 크다 (OFFSET 1000 이상)
- [ ] OR 조건 여러 개
- [ ] IN (...)에 값이 많음 (100개 이상)

#### 초록불 (OK) 🟢

- [ ] PRIMARY KEY 또는 UNIQUE 조회
- [ ] 인덱스 사용 (type = ref/range)
- [ ] WHERE로 먼저 필터링
- [ ] LIMIT이 작다 (< 100)
- [ ] JOIN 조건에 모두 인덱스
- [ ] Extra에 filesort 없음

---

## 비용 예측 연습 문제

### 문제 1: 다음 중 가장 느린 쿼리는?

```sql
-- A
SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5);

-- B
SELECT * FROM users WHERE name LIKE 'John%';

-- C
SELECT * FROM users WHERE LOWER(email) = 'test@example.com';

-- D
SELECT * FROM users WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
```

<details>
<summary>정답 보기</summary>

**정답: C**

- A: O(1) × 5번 = 매우 빠름
- B: O(log N) (뒷부분 와일드카드, 인덱스 사용) = 빠름
- C: O(N) (함수 사용, 인덱스 못 탐) = 느림
- D: O(log N + M) (인덱스 범위 검색) = 보통

</details>

---

### 문제 2: 100만 건 테이블에서 다음 쿼리의 예상 실행 시간은?

```sql
SELECT * FROM orders
WHERE status IN ('pending', 'processing')
ORDER BY created_at DESC
LIMIT 20;

-- 인덱스: (status, created_at)
```

<details>
<summary>정답 보기</summary>

**예상 시간: < 10ms**

**이유:**
1. (status, created_at) 복합 인덱스가 완벽히 매칭
2. status IN (...)으로 필터링 후 created_at으로 정렬
3. 정렬 없이 인덱스에서 20건만 읽기
4. type = range, rows = 20, filesort 없음

</details>

---

### 문제 3: 다음 중 개선율이 가장 큰 것은?

```sql
-- Before (100만 건 테이블)
SELECT * FROM products ORDER BY created_at DESC LIMIT 10;
-- 인덱스 없음, 실행 시간: 2초

-- After 옵션들
-- A: created_at 인덱스 추가
-- B: 캐싱 적용 (Redis)
-- C: LIMIT 10 → LIMIT 5로 줄임
```

<details>
<summary>정답 보기</summary>

**정답: A (created_at 인덱스 추가)**

- A: 2000배 개선 (2초 → 1ms)
- B: 매우 빠르지만 데이터 최신성 문제
- C: 거의 개선 없음 (전체 정렬은 동일)

**교훈:** 인덱스 최적화가 가장 근본적인 해결책

</details>

---

## 실무 적용 가이드

### 1주일 실천 계획

#### Day 1-2: 현황 파악
- [ ] 주요 API의 쿼리 목록 작성
- [ ] 각 쿼리에 EXPLAIN 실행
- [ ] type, rows, Extra 기록

#### Day 3-4: 비용 예측
- [ ] 각 쿼리의 시간복잡도 계산
- [ ] 느린 쿼리 TOP 10 선정
- [ ] 예상 개선율 계산

#### Day 5-6: 개선 실행
- [ ] 빨간불 쿼리부터 개선
- [ ] 인덱스 추가 (개발 환경)
- [ ] 성능 측정 (Before/After)

#### Day 7: 팀 공유
- [ ] 개선 사례 발표
- [ ] 코드 리뷰 체크리스트 공유
- [ ] 다음 개선 계획 수립

---

### 팀 공유 자료 예시

#### "쿼리 비용 예측 5분 가이드"

**1. 위험 신호 3가지**
- 상관 서브쿼리
- 함수 사용 (WHERE 절)
- 앞부분 와일드카드 (LIKE)

**2. EXPLAIN 3초 판단법**
- type = ALL → 위험
- rows > 10000 → 주의
- Extra = Using filesort → 검토

**3. 즉시 적용 3가지**
- JOIN 조건에 인덱스
- WHERE + ORDER BY 복합 인덱스
- 상관 서브쿼리 → JOIN 변환

---

## 다음 주차 예고: Week 4 - 락과 데드락 처리

이번 주차에서 쿼리 비용을 예측하는 감각을 익혔다면,
다음 주차에서는 동시성 문제를 다룹니다!

**배울 내용:**
- 락(Lock)이 발생하는 상황 이해
- 데드락(Deadlock) 원인과 해결
- 트랜잭션 격리 수준
- 실전 동시성 제어 패턴

---

**완료 축하합니다!** 🎉

쿼리 비용 예측 능력을 갖추었습니다!
이제 코드 리뷰에서 느린 쿼리를 1초 만에 찾을 수 있습니다.

**다음 액션:**
1. [ ] ANSWER.md와 이 SOLUTION.md 비교
2. [ ] 예측이 틀린 이유 분석
3. [ ] 회사 쿼리 3개 이상 비용 분석
4. [ ] 느린 쿼리 1개 이상 개선
5. [ ] Week 4 미션 시작

**실무 꿀팁:**
> "EXPLAIN만 보지 말고, 쿼리 코드만 보고 예측하는 연습을 하세요.
> 그래야 코드 리뷰에서 즉시 발견할 수 있습니다!"
