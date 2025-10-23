# Week 2 미션: EXPLAIN으로 느린 쿼리 찾아내기 🎯

> "EXPLAIN 3초만 보면 문제가 보인다"

---

## 📋 미션 개요

당신은 급성장 중인 이커머스 플랫폼의 백엔드 개발자입니다.
최근 주문 조회 API의 성능 문제로 고객 불만이 증가하고 있습니다.

**문제 상황:**
- `orders` 테이블에 100만 건의 데이터
- 특정 쿼리들이 너무 느려서 타임아웃 발생
- 어떤 쿼리가 문제인지, 왜 느린지 불분명

**당신의 임무:**
EXPLAIN을 활용해서 **문제 쿼리를 찾아내고 최적화**하세요!

---

## 🎯 미션 목표

### 미션 1: type별 성능 차이 체감하기 (필수)

**상황:**
다양한 쿼리들의 성능 차이를 직접 측정하고 EXPLAIN으로 분석하세요.

```sql
-- 쿼리 A: PRIMARY KEY 조회
SELECT * FROM orders WHERE id = 500000;

-- 쿼리 B: 인덱스 있는 컬럼 조회
SELECT * FROM orders WHERE user_id = 12345;

-- 쿼리 C: 범위 조회
SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';

-- 쿼리 D: 인덱스 없는 컬럼 조회
SELECT * FROM orders WHERE amount > 1000;

-- 쿼리 E: 전체 스캔
SELECT * FROM orders WHERE status LIKE '%ing%';
```

**성공 기준:**
- [ ] 각 쿼리의 EXPLAIN 결과 분석
- [ ] type 값 확인 (const, ref, range, index, ALL)
- [ ] rows 값 비교
- [ ] 실행 시간 측정
- [ ] 성능 순위표 작성

---

### 미션 2: Extra 컬럼 해석하기 (필수)

**상황:**
다음 쿼리들의 Extra 컬럼을 분석하고 문제점을 찾으세요.

```sql
-- 쿼리 A
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

-- 쿼리 B
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 10;

-- 쿼리 C
SELECT id, user_id, status FROM orders
WHERE user_id = 12345 AND status = 'completed';

-- 쿼리 D
SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'user12345@example.com';
```

**성공 기준:**
- [ ] 각 쿼리의 Extra 값 확인
- [ ] Using filesort 발견 여부
- [ ] Using temporary 발견 여부
- [ ] Using index 발견 여부
- [ ] Using where의 의미 이해
- [ ] 문제 있는 쿼리 식별

---

### 미션 3: 느린 쿼리 최적화 (필수)

**상황:**
아래 느린 쿼리를 EXPLAIN으로 분석하고 최적화하세요.

```sql
-- 문제 쿼리 1: 상태별 최근 주문 조회
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

-- 문제 쿼리 2: 사용자별 주문 통계
SELECT user_id, COUNT(*) as cnt, SUM(amount) as total
FROM orders
WHERE status IN ('completed', 'shipped')
GROUP BY user_id
HAVING total > 10000
ORDER BY total DESC;

-- 문제 쿼리 3: 기간별 주문 집계
SELECT DATE(created_at) as order_date, COUNT(*) as cnt
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
GROUP BY DATE(created_at)
ORDER BY order_date;
```

**성공 기준:**
- [ ] EXPLAIN으로 Before 상태 분석
- [ ] type, rows, Extra 문제점 파악
- [ ] 적절한 인덱스 설계 및 생성
- [ ] EXPLAIN으로 After 상태 확인
- [ ] 성능 개선율 측정 (최소 10배 이상)

---

## 💡 제공되는 환경

### 테이블 구조

**orders 테이블:**
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    amount DECIMAL(10,2),
    created_at DATETIME,
    INDEX idx_user_id (user_id)
);
-- 데이터: 1,000,000 건
-- status 값: pending, completed, shipped, delivered, cancelled
```

**users 테이블:**
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100),
    created_at DATETIME,
    status VARCHAR(20)
);
-- 데이터: 1,000,000 건
```

### 현재 인덱스 확인

```sql
-- 인덱스 목록 조회
SHOW INDEX FROM orders;
SHOW INDEX FROM users;

-- 테이블 통계 확인
SHOW TABLE STATUS LIKE 'orders';
```

---

## 🔍 참고: EXPLAIN 주요 컬럼 정리

### type (성능 순위: 빠름 → 느림)

```
const > eq_ref > ref > range > index > ALL
```

- **const**: PRIMARY KEY나 UNIQUE 인덱스로 1건 조회 (최고!)
- **eq_ref**: JOIN에서 PRIMARY KEY 사용
- **ref**: 인덱스로 여러 건 조회
- **range**: 범위 스캔 (BETWEEN, >, <)
- **index**: 인덱스 풀 스캔
- **ALL**: 테이블 풀 스캔 (느림!)

### rows

- 쿼리 실행을 위해 검사해야 하는 예상 행 수
- 적을수록 좋음
- 100 이하: 좋음
- 1,000~10,000: 주의
- 10,000 이상: 문제

### Extra

**좋은 것들:**
- **Using index**: 커버링 인덱스 (최고!)
- **Using index condition**: 인덱스 조건 푸시다운

**나쁜 것들:**
- **Using filesort**: 별도 정렬 필요 (느림)
- **Using temporary**: 임시 테이블 생성 (느림)

**주의 필요:**
- **Using where**: MySQL 엔진에서 필터링 (type과 함께 판단)

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: type=ALL이 나오는 이유</summary>

type=ALL이 나오는 경우:
1. WHERE 절 컬럼에 인덱스가 없음
2. 인덱스는 있지만 함수 사용 (YEAR, DATE 등)
3. LIKE '%keyword'처럼 앞부분 와일드카드
4. MySQL이 인덱스보다 풀스캔이 빠르다고 판단

해결 방법:
- 적절한 인덱스 생성
- 함수 제거하고 범위 조건으로 변경
- 와일드카드 위치 조정

</details>

<details>
<summary>힌트 2: Using filesort 없애는 방법</summary>

Using filesort가 나오는 경우:
- ORDER BY 컬럼이 인덱스에 없음
- WHERE 조건과 ORDER BY 조건이 따로 놀음

해결 방법:
1. WHERE + ORDER BY를 모두 포함하는 복합 인덱스 생성
2. 순서: WHERE 동등 조건 → WHERE 범위 조건 → ORDER BY
3. 예: `INDEX (status, created_at)` for `WHERE status = 'x' ORDER BY created_at`

</details>

<details>
<summary>힌트 3: Using temporary 없애는 방법</summary>

Using temporary가 나오는 경우:
- GROUP BY와 ORDER BY가 다른 컬럼 사용
- GROUP BY 컬럼에 인덱스 없음

해결 방법:
1. GROUP BY 컬럼에 인덱스 생성
2. GROUP BY와 ORDER BY를 같은 컬럼으로 맞추기
3. 서브쿼리나 CTE 활용

</details>

<details>
<summary>힌트 4: 복합 인덱스 순서 결정 방법</summary>

복합 인덱스 컬럼 순서 규칙:
1. WHERE 동등 조건 (=) 컬럼
2. WHERE 범위 조건 (>, <, BETWEEN) 컬럼
3. ORDER BY 컬럼
4. Cardinality 높은 것 우선

예시:
```sql
WHERE user_id = ? AND status = ? ORDER BY created_at
→ INDEX (user_id, status, created_at)
```

</details>

---

## 📝 답안 작성 방법

1. `ANSWER_TEMPLATE.md`를 복사해서 `ANSWER.md` 생성
2. 각 미션별로 실행한 쿼리와 EXPLAIN 결과 기록
3. Before/After 비교표 작성
4. 성능 개선 수치 측정
5. 배운 점 정리

---

## 📊 성능 측정 방법

```sql
-- 방법 1: 실행 시간 측정
SET profiling = 1;
SELECT ...;
SHOW PROFILES;

-- 방법 2: EXPLAIN으로 예측
EXPLAIN SELECT ...;

-- 방법 3: 실제 실행 계획 (MySQL 8.0.18+)
EXPLAIN ANALYZE SELECT ...;
```

---

## ⏱️ 예상 소요 시간

- 미션 1: 20분 (type별 성능 차이)
- 미션 2: 15분 (Extra 해석)
- 미션 3: 25분 (쿼리 최적화)
- **총 60분**

---

## 🎓 선택 사항: 추가 미션

시간이 남거나 더 도전하고 싶다면:

### 보너스 1: JOIN 쿼리 최적화
```sql
SELECT o.*, u.name, u.email
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'pending'
  AND u.status = 'active'
ORDER BY o.created_at DESC
LIMIT 10;
```

### 보너스 2: 서브쿼리 vs JOIN 성능 비교
```sql
-- 서브쿼리 방식
SELECT * FROM orders
WHERE user_id IN (
    SELECT id FROM users WHERE status = 'active'
);

-- JOIN 방식
SELECT o.* FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.status = 'active';
```

---

## 체크리스트

**시작 전:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] orders, users 테이블 데이터 확인 (각 100만 건)

**완료 후:**
- [ ] 모든 미션 완료
- [ ] EXPLAIN 해석 능력 향상
- [ ] type 순서 암기
- [ ] Extra 패턴 이해
- [ ] 실무 적용 계획 수립

---

**난이도:** ⭐⭐⭐ 중상
**즉시 적용:** ✓
**ROI:** 매우 높음

**준비되셨나요? EXPLAIN 마스터로 가는 첫걸음을 시작하세요!** 🚀
