# Week 3: 쿼리 성능 비용 감각 ⭐⭐⭐

> "쿼리 보고 느릴지 예측"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"코드 리뷰 중 느린 쿼리 즉시 발견하기"**

이번 주차를 완료하면:
- WHERE, JOIN, ORDER BY 비용 계산 가능
- 쿼리만 보고 성능 예측 가능
- 비효율적인 쿼리 패턴 즉시 식별
- 최적화 우선순위 판단 가능

---

## 📚 학습 내용

### 1. WHERE 비용 (15분)

#### 시간 복잡도

**O(1) - 상수 시간** ✅
```sql
-- PRIMARY KEY나 UNIQUE 인덱스
SELECT * FROM users WHERE id = 123;

비용: 거의 0
이유: 해시 또는 트리 1번 탐색
```

**O(log N) - 로그 시간** ✅
```sql
-- 인덱스 사용
SELECT * FROM users WHERE email = 'test@example.com';

비용: 매우 낮음
예시: 100만 건 → 약 20번 비교
```

**O(N) - 선형 시간** ❌
```sql
-- 인덱스 없거나 못 탐
SELECT * FROM users WHERE name LIKE '%김%';

비용: 매우 높음
예시: 100만 건 → 100만 번 비교
```

#### 실전 예시
```sql
-- ❌ 나쁨: O(N)
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-01';
-- 100만 건 테이블 → 100만 번 함수 실행

-- ✅ 좋음: O(log N)
SELECT * FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2024-01-02';
-- 인덱스 사용 → 약 20번 비교
```

---

### 2. JOIN 비용 (20분)

#### Nested Loop Join (기본 방식)
```sql
SELECT *
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'completed';

비용 계산:
1. orders 테이블에서 status='completed' 찾기: N건
2. 각 order마다 users 테이블 조회: N × M

총 비용: O(N × log M)  -- users에 인덱스 있을 때
       O(N × M)       -- users에 인덱스 없을 때
```

#### 실전 예시

**❌ 최악의 경우**
```sql
-- orders: 100만 건
-- users: 10만 건
-- user_id에 인덱스 없음

SELECT *
FROM orders o
JOIN users u ON o.user_id = u.id;

비용: 100만 × 10만 = 1000억 번 비교
시간: 수 분 ~ 수 시간
```

**✅ 최적화된 경우**
```sql
-- user_id에 인덱스 있음

비용: 100만 × log(10만) ≈ 100만 × 17 = 1700만 번
시간: 수 초
```

#### JOIN 최적화 체크리스트
- [ ] JOIN 조건 컬럼에 인덱스 있는가?
- [ ] JOIN 전에 WHERE로 필터링하는가?
- [ ] 작은 테이블을 먼저 JOIN하는가?

---

### 3. ORDER BY 비용 (15분)

#### 인덱스를 타는 경우 ✅
```sql
-- created_at에 인덱스 있음
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;

비용: O(log N) + 10건 읽기
EXPLAIN Extra: Using index
```

#### 인덱스를 못 타는 경우 ❌
```sql
-- created_at에 인덱스 없음
SELECT * FROM orders
ORDER BY created_at DESC;

비용: O(N log N) -- 전체 정렬
EXPLAIN Extra: Using filesort
```

#### Filesort 비용
```
메모리 정렬 (sort_buffer_size 이하):
  - 빠름
  - 비용: O(N log N)

디스크 정렬 (sort_buffer_size 초과):
  - 매우 느림
  - 비용: O(N log N) + 디스크 I/O
```

---

### 4. 서브쿼리 vs JOIN 비용 (10분)

#### 상관 서브쿼리 (Correlated Subquery) ❌
```sql
-- 매우 느림
SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;

비용: O(N × M)
이유: 각 user마다 서브쿼리 실행
```

#### JOIN으로 변환 ✅
```sql
-- 빠름
SELECT u.*
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
    HAVING cnt > 10
) o ON u.id = o.user_id;

비용: O(N log N)
```

---

## 🔬 실습

### 실습 1: WHERE 비용 체감 (20분)

```sql
-- 테스트 데이터: 100만 건
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200),
    price DECIMAL(10,2),
    category VARCHAR(50),
    created_at DATETIME,
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
);

-- 1. O(1) - PRIMARY KEY
SELECT * FROM products WHERE id = 50000;
-- 실행시간: _____ms
-- rows: _____

-- 2. O(log N) - 인덱스
SELECT * FROM products WHERE category = 'electronics';
-- 실행시간: _____ms
-- rows: _____

-- 3. O(N) - 인덱스 못 탐
SELECT * FROM products WHERE name LIKE '%phone%';
-- 실행시간: _____ms
-- rows: _____

-- 4. O(N) - 함수 사용
SELECT * FROM products WHERE YEAR(created_at) = 2024;
-- 실행시간: _____ms
-- rows: _____

-- 5. O(log N) - 범위 조건
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
-- 실행시간: _____ms
-- rows: _____
```

#### 성능 비교
| 쿼리 | 시간복잡도 | 실행시간 | rows | 배속 |
|------|-----------|---------|------|------|
| PRIMARY KEY | O(1) | | | 1x |
| 인덱스 | O(log N) | | | x |
| LIKE | O(N) | | | x |
| 함수 | O(N) | | | x |
| 범위 | O(log N) | | | x |

---

### 실습 2: JOIN 비용 비교 (20분)

```sql
-- 준비: users 10만, orders 100만
CREATE TABLE users (
    id INT PRIMARY KEY,
    email VARCHAR(255),
    name VARCHAR(100)
);

CREATE TABLE orders (
    id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2),
    status VARCHAR(20)
);

-- 케이스 1: 인덱스 없음 (최악)
-- user_id 인덱스 제거
ALTER TABLE orders DROP INDEX idx_user_id;

SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
-- 실행시간: _____ms

-- 케이스 2: 인덱스 있음 (개선)
CREATE INDEX idx_user_id ON orders(user_id);

SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
-- 실행시간: _____ms

-- 케이스 3: WHERE로 선필터 (최적)
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
GROUP BY u.id;
-- 실행시간: _____ms
```

#### 결과 분석
| 케이스 | 실행시간 | 개선율 | EXPLAIN type |
|--------|---------|--------|--------------|
| 인덱스 없음 | | - | |
| 인덱스 있음 | | % | |
| WHERE 필터 | | % | |

---

### 실습 3: 회사 코드 비용 예측 (20분)

회사 코드에서 쿼리를 찾아 비용 분석:

```sql
-- 쿼리 1
[회사 쿼리 붙여넣기]

-- 비용 분석
테이블 크기:
  - 테이블A: _____ 건
  - 테이블B: _____ 건

WHERE 비용:
  - 조건1: O(_____)
  - 조건2: O(_____)

JOIN 비용:
  - 방식: _____
  - 예상: O(_____)

ORDER BY 비용:
  - 인덱스 사용: YES / NO
  - 예상: O(_____)

총 예상 비용: O(_____)
실제 실행시간: _____ms

개선 포인트:
1.
2.
3.
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] WHERE 시간복잡도 이해 (O(1), O(log N), O(N))
- [ ] JOIN 비용 계산 방법 숙지
- [ ] ORDER BY 인덱스 사용 여부 판단
- [ ] 서브쿼리 vs JOIN 비용 차이 이해

### 실습 완료
- [ ] WHERE 비용 실험 (5가지 케이스)
- [ ] JOIN 비용 비교 (3가지 케이스)
- [ ] 회사 쿼리 3개 비용 분석
- [ ] 개선 전후 성능 측정

### 실무 적용
- [ ] 코드 리뷰 시 쿼리 비용 체크
- [ ] 신규 쿼리 작성 시 비용 예측
- [ ] 느린 API 쿼리 비용 분석
- [ ] 최적화 우선순위 문서화

---

## 📝 학습 노트

### 비용 계산 공식 정리
```
WHERE: O(_____)
JOIN: O(_____)
ORDER BY: O(_____)
```

### 실무 적용 사례

**발견한 쿼리:**
```sql

```

**비용 분석:**
-

**개선 후:**
```sql

```

**개선율:** _____%

---

## 📚 참고 자료

- [알고리즘 시간복잡도](https://www.bigocheatsheet.com/)
- MySQL 공식 문서: [Optimization](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐⭐ 중상
**즉시 적용**: ✓
**ROI**: 매우 높음

**완료일**: ___________
