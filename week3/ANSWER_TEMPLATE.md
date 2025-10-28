# Week 3 답안: 쿼리 비용 예측

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: WHERE 비용 계산

### 예측 단계 (실행 전!)

각 쿼리를 실행하기 **전에** 먼저 예측하세요.

#### 쿼리 A: PRIMARY KEY 조회
```sql
SELECT * FROM products WHERE id = 50000;
```

**예상 시간복잡도:** O(_____)

**예상 실행 시간:** _____ms

**예상 type:** _____

**예상 rows:** _____

**이유:**

---

#### 쿼리 B: 인덱스 사용
```sql
SELECT * FROM products WHERE category = 'electronics';
```

**예상 시간복잡도:** O(_____)

**예상 실행 시간:** _____ms

**예상 type:** _____

**예상 rows:** _____

**이유:**

---

#### 쿼리 C: 부분 문자열 검색
```sql
SELECT * FROM products WHERE name LIKE '%phone%';
```

**예상 시간복잡도:** O(_____)

**예상 실행 시간:** _____ms

**예상 type:** _____

**예상 rows:** _____

**이유:**

---

#### 쿼리 D: 함수 사용
```sql
SELECT * FROM products WHERE YEAR(created_at) = 2024;
```

**예상 시간복잡도:** O(_____)

**예상 실행 시간:** _____ms

**예상 type:** _____

**예상 rows:** _____

**이유:**

---

#### 쿼리 E: 범위 조건
```sql
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**예상 시간복잡도:** O(_____)

**예상 실행 시간:** _____ms

**예상 type:** _____

**예상 rows:** _____

**이유:**

---

### 예측 순위
| 순위 | 쿼리 | 예상 시간 | 시간복잡도 |
|------|------|-----------|------------|
| 1 (가장 빠름) | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 (가장 느림) | | | |

---

### 실제 측정

#### 쿼리 A 실행
```sql
-- EXPLAIN 실행
EXPLAIN SELECT * FROM products WHERE id = 50000;

-- 결과:
```

| type | rows | Extra | key |
|------|------|-------|-----|
| | | | |

```sql
-- 실제 실행
SELECT * FROM products WHERE id = 50000;

-- 실행 시간: _____ms
```

**예측과 비교:**
- 시간복잡도: 예측 O(_____) → 실제 O(_____)
- 실행 시간: 예측 _____ms → 실제 _____ms
- 맞았는가? [ ] 예 [ ] 아니오
- 틀렸다면 왜?

---

#### 쿼리 B 실행
```sql
EXPLAIN SELECT * FROM products WHERE category = 'electronics';

-- 결과:
```

| type | rows | Extra | key |
|------|------|-------|-----|
| | | | |

```sql
SELECT * FROM products WHERE category = 'electronics';

-- 실행 시간: _____ms
```

**예측과 비교:**
- 시간복잡도: 예측 O(_____) → 실제 O(_____)
- 실행 시간: 예측 _____ms → 실제 _____ms
- 맞았는가? [ ] 예 [ ] 아니오
- 틀렸다면 왜?

---

#### 쿼리 C 실행
```sql
EXPLAIN SELECT * FROM products WHERE name LIKE '%phone%';

-- 결과:
```

| type | rows | Extra | key |
|------|------|-------|-----|
| | | | |

```sql
SELECT * FROM products WHERE name LIKE '%phone%';

-- 실행 시간: _____ms
```

**예측과 비교:**
- 시간복잡도: 예측 O(_____) → 실제 O(_____)
- 실행 시간: 예측 _____ms → 실제 _____ms
- 맞았는가? [ ] 예 [ ] 아니오

---

#### 쿼리 D 실행
```sql
EXPLAIN SELECT * FROM products WHERE YEAR(created_at) = 2024;

-- 결과:
```

| type | rows | Extra | key |
|------|------|-------|-----|
| | | | |

```sql
SELECT * FROM products WHERE YEAR(created_at) = 2024;

-- 실행 시간: _____ms
```

**예측과 비교:**
- 시간복잡도: 예측 O(_____) → 실제 O(_____)
- 실행 시간: 예측 _____ms → 실제 _____ms
- 맞았는가? [ ] 예 [ ] 아니오

---

#### 쿼리 E 실행
```sql
EXPLAIN SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 결과:
```

| type | rows | Extra | key |
|------|------|-------|-----|
| | | | |

```sql
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 실행 시간: _____ms
```

**예측과 비교:**
- 시간복잡도: 예측 O(_____) → 실제 O(_____)
- 실행 시간: 예측 _____ms → 실제 _____ms
- 맞았는가? [ ] 예 [ ] 아니오

---

### 최종 순위 비교

| 순위 | 예측 쿼리 | 실제 쿼리 | 실제 시간 | 맞음/틀림 |
|------|-----------|-----------|-----------|-----------|
| 1 (빠름) | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 (느림) | | | | |

**예측 정확도:** _____/5 맞음

---

### 가장 느린 쿼리 3개 개선

#### 느린 쿼리 1: _____
**문제점:**

**개선 방법:**
```sql
-- 개선된 쿼리


```

**예상 개선율:** _____배

---

#### 느린 쿼리 2: _____
**문제점:**

**개선 방법:**
```sql
-- 개선된 쿼리


```

**예상 개선율:** _____배

---

#### 느린 쿼리 3: _____
**문제점:**

**개선 방법:**
```sql
-- 개선된 쿼리


```

**예상 개선율:** _____배

---

## 미션 2: JOIN 비용 비교

### 예측 단계

**테이블 정보:**
- users: _____ 건
- orders: _____ 건

#### 방법 1 예측 (인덱스 없음)
```sql
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
```

**예상 비용 계산:**
- JOIN 방식: Nested Loop
- 비용: O(_____)
- 계산: users(_____)건 × orders(_____)건 = _____번 비교
- 예상 시간: _____ms

---

#### 방법 2 예측 (인덱스 있음)
```sql
CREATE INDEX idx_user_id ON orders(user_id);
```

**예상 비용 계산:**
- JOIN 방식: Nested Loop + Index
- 비용: O(_____)
- 계산: users(_____)건 × log₂(orders) = users × _____ = _____번
- 예상 시간: _____ms
- 방법 1 대비 개선율: _____배

---

#### 방법 3 예측 (WHERE 필터)
```sql
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
  AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id;
```

**예상 비용 계산:**
- 필터 후 orders 건수: 약 _____건 (추정)
- 비용: O(_____)
- 예상 시간: _____ms
- 방법 2 대비 개선율: _____배

---

### 예측 순위
| 순위 | 방법 | 예상 시간 | 비용 |
|------|------|-----------|------|
| 1 (빠름) | | | |
| 2 | | | |
| 3 (느림) | | | |

---

### 실제 측정

#### 방법 1 실행
```sql
-- 먼저 인덱스 제거
ALTER TABLE orders DROP INDEX IF EXISTS idx_user_id;

-- EXPLAIN 분석
EXPLAIN SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- 결과:
```

| id | table | type | rows | Extra |
|----|-------|------|------|-------|
| | | | | |
| | | | | |

```sql
-- 실제 실행
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- 실행 시간: _____ms
```

---

#### 방법 2 실행
```sql
-- 인덱스 생성
CREATE INDEX idx_user_id ON orders(user_id);

-- EXPLAIN 분석
EXPLAIN SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- 결과:
```

| id | table | type | rows | Extra |
|----|-------|------|------|-------|
| | | | | |
| | | | | |

```sql
-- 실제 실행
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- 실행 시간: _____ms
```

---

#### 방법 3 실행
```sql
-- EXPLAIN 분석
EXPLAIN SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
  AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id;

-- 결과:
```

| id | table | type | rows | Extra |
|----|-------|------|------|-------|
| | | | | |
| | | | | |

```sql
-- 실제 실행
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
  AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id;

-- 실행 시간: _____ms
```

---

### 성능 비교표

| 방법 | 예측 시간 | 실제 시간 | type | rows | 개선율 |
|------|-----------|-----------|------|------|--------|
| 1. 인덱스 없음 | | | | | - |
| 2. 인덱스 있음 | | | | | ___배 |
| 3. WHERE 필터 | | | | | ___배 |

**예측 정확도:**
- [ ] 순위를 정확히 예측함
- [ ] 개선율을 ±50% 이내로 예측함

---

## 미션 3: 서브쿼리 vs JOIN 성능 대결

### 예측 단계

#### 방법 A 예측 (상관 서브쿼리)
```sql
SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;
```

**예상 비용 계산:**
- 실행 방식: users의 **각 행마다** 서브쿼리 실행
- users 건수: _____건
- 각 서브쿼리 비용: O(_____)
- 총 비용: O(_____)
- 예상 시간: _____ms

---

#### 방법 B 예측 (JOIN)
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

**예상 비용 계산:**
- 1단계: orders GROUP BY - O(_____)
- 2단계: users와 JOIN - O(_____)
- 총 비용: O(_____)
- 예상 시간: _____ms
- 방법 A 대비 개선율: _____배

---

### 실제 측정

#### 방법 A 실행
```sql
-- EXPLAIN 분석
EXPLAIN SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;

-- 결과:
```

| id | select_type | table | type | rows |
|----|-------------|-------|------|------|
| | | | | |

```sql
-- 실제 실행
SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;

-- 실행 시간: _____ms
-- 결과 행 수: _____건
```

---

#### 방법 B 실행
```sql
-- EXPLAIN 분석
EXPLAIN SELECT u.*
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
    HAVING cnt > 10
) o ON u.id = o.user_id;

-- 결과:
```

| id | select_type | table | type | rows |
|----|-------------|-------|------|------|
| | | | | |

```sql
-- 실제 실행
SELECT u.*
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
    HAVING cnt > 10
) o ON u.id = o.user_id;

-- 실행 시간: _____ms
-- 결과 행 수: _____건
```

---

### 성능 비교

| 방법 | 예측 시간 | 실제 시간 | 비용 | 개선율 |
|------|-----------|-----------|------|--------|
| A. 상관 서브쿼리 | | | O(_____) | - |
| B. JOIN | | | O(_____) | ___배 |

**분석:**
왜 이런 차이가 발생했는가?

---

## 미션 4: ORDER BY 비용 감각

### 케이스별 예측

#### 케이스 1: 인덱스 없음
```sql
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;
```

**예측:**
- Using filesort: [ ] 예상됨 [ ] 예상 안 됨
- 비용: O(_____)
- 예상 시간: _____ms

---

#### 케이스 2: created_at 인덱스 있음
```sql
CREATE INDEX idx_created_at ON orders(created_at);

SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;
```

**예측:**
- Using filesort: [ ] 예상됨 [ ] 예상 안 됨
- 비용: O(_____)
- 예상 시간: _____ms

---

#### 케이스 3: 복합 조건
```sql
SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
-- 인덱스: idx_created_at만 있음
```

**예측:**
- Using filesort: [ ] 예상됨 [ ] 예상 안 됨
- 비용: O(_____)
- 예상 시간: _____ms

---

#### 케이스 4: 최적 인덱스
```sql
CREATE INDEX idx_status_created ON orders(status, created_at);

SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

**예측:**
- Using filesort: [ ] 예상됨 [ ] 예상 안 됨
- 비용: O(_____)
- 예상 시간: _____ms

---

### 실제 측정

#### 각 케이스 EXPLAIN 및 실행

**케이스 1:**
```sql
-- EXPLAIN 결과
```

| type | rows | Extra |
|------|------|-------|
| | | |

실행 시간: _____ms

---

**케이스 2:**
```sql
-- EXPLAIN 결과
```

| type | rows | Extra |
|------|------|-------|
| | | |

실행 시간: _____ms

---

**케이스 3:**
```sql
-- EXPLAIN 결과
```

| type | rows | Extra |
|------|------|-------|
| | | |

실행 시간: _____ms

---

**케이스 4:**
```sql
-- EXPLAIN 결과
```

| type | rows | Extra |
|------|------|-------|
| | | |

실행 시간: _____ms

---

### 성능 비교표

| 케이스 | filesort | 실행 시간 | 개선율 |
|--------|----------|-----------|--------|
| 1. 인덱스 없음 | | | - |
| 2. 단일 인덱스 | | | ___배 |
| 3. 복합 조건 | | | ___배 |
| 4. 최적 인덱스 | | | ___배 |

---

## 학습 정리

### 비용 계산 공식 (내가 정리한 것)

**WHERE 절:**
- PRIMARY KEY: O(_____)
- 인덱스 사용: O(_____)
- 인덱스 못 탐: O(_____)
- 함수 사용: O(_____)

**JOIN:**
- 인덱스 없음: O(_____)
- 인덱스 있음: O(_____)

**ORDER BY:**
- 인덱스 없음: O(_____)
- 인덱스 있음: O(_____)

---

### 느린 쿼리 패턴 (암기!)

1.
2.
3.
4.
5.

---

### 예측 능력 자가 진단

**예측 정확도:**
- 미션 1: _____/5 맞음
- 미션 2: _____/3 맞음
- 미션 3: 예측 [ ] 맞음 [ ] 틀림
- 미션 4: _____/4 맞음

**총점:** _____/15

**평가:**
- 12~15점: 예측 고수! 코드 리뷰 때 즉시 발견 가능
- 8~11점: 좋음. 조금 더 연습 필요
- 4~7점: 기본은 잡힘. 더 많은 실습 필요
- 0~3점: 이론 복습 후 재도전 추천

---

## 실무 적용

### 회사 쿼리 비용 분석

#### 쿼리 1
```sql
-- 회사 쿼리 붙여넣기


```

**테이블 크기:**
- 테이블A: _____건
- 테이블B: _____건

**비용 분석:**
- WHERE 비용: O(_____)
- JOIN 비용: O(_____)
- ORDER BY 비용: O(_____)
- 총 예상 비용: O(_____)

**실제 실행 시간:** _____ms

**개선 포인트:**
1.
2.
3.

---

#### 쿼리 2
```sql
-- 회사 쿼리 붙여넣기


```

(동일한 형식으로 분석)

---

#### 쿼리 3
```sql
-- 회사 쿼리 붙여넣기


```

(동일한 형식으로 분석)

---

### 즉시 적용 계획

**코드 리뷰 시 체크리스트:**
- [ ] WHERE 절에 함수 사용하는가?
- [ ] LIKE '%keyword' 패턴 있는가?
- [ ] JOIN 조건에 인덱스 있는가?
- [ ] 상관 서브쿼리 사용하는가?
- [ ] ORDER BY에 filesort 발생하는가?

**팀 공유 내용:**
-

---

## 트러블슈팅

### 예측이 크게 틀린 경우

**케이스 1:**
- 예측: _____
- 실제: _____
- 왜 틀렸나?
- 배운 점:

---

**케이스 2:**
- 예측: _____
- 실제: _____
- 왜 틀렸나?
- 배운 점:

---

## 다음 액션

### 추가 학습 필요
- [ ]
- [ ]
- [ ]

### 실무 적용 기한
- [ ] 1주일 내 회사 쿼리 3개 분석
- [ ] 느린 쿼리 1개 이상 개선
- [ ] 팀에 비용 계산법 공유

---

**완료일:** ___________
**소요 시간:** ___________
**예측 정확도:** _____/15

**다음 주차:** Week 4 - 락과 데드락 처리 🔒
