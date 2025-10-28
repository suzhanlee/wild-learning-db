# Week 3 미션: 쿼리 보고 비용 예측하기 🎯

> "코드 리뷰 중 느린 쿼리를 1초 만에 발견하는 능력"

---

## 📋 미션 개요

당신은 코드 리뷰어입니다.
동료가 작성한 PR을 리뷰하는 중, 여러 쿼리들을 발견했습니다.
실행해보지 않고도 어떤 쿼리가 느릴지 예측할 수 있나요?

**문제 상황:**
- 다양한 쿼리 패턴이 섞여 있음
- 일부는 빠르고, 일부는 치명적으로 느림
- 성능 테스트 없이 배포하면 장애 발생 위험

**당신의 임무:**
쿼리만 보고 시간복잡도를 계산하여 **느린 쿼리를 사전에 찾아내세요!**

---

## 🎯 미션 목표

### 미션 1: WHERE 비용 계산 (필수)

**상황:**
다음 5개의 쿼리 중 가장 느린 것은?

```sql
-- 쿼리 A: PRIMARY KEY 조회
SELECT * FROM products WHERE id = 50000;

-- 쿼리 B: 인덱스 사용
SELECT * FROM products WHERE category = 'electronics';

-- 쿼리 C: 부분 문자열 검색
SELECT * FROM products WHERE name LIKE '%phone%';

-- 쿼리 D: 함수 사용
SELECT * FROM products WHERE YEAR(created_at) = 2024;

-- 쿼리 E: 범위 조건
SELECT * FROM products
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**성공 기준:**
- [ ] 각 쿼리의 시간복잡도 예측 (O(1), O(log N), O(N))
- [ ] EXPLAIN으로 예측 검증
- [ ] 실제 실행 시간 측정
- [ ] 가장 느린 쿼리 3개 식별
- [ ] 개선 방안 제시

**힌트:**
- 인덱스를 탈 수 있는가?
- 전체 테이블을 스캔해야 하는가?
- 함수나 연산이 들어가 있는가?

---

### 미션 2: JOIN 비용 비교 (필수)

**상황:**
회원 통계를 구하는 쿼리가 3가지 방식으로 작성되어 있습니다.

```sql
-- 방법 1: 인덱스 없음
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
-- orders.user_id에 인덱스 없음

-- 방법 2: 인덱스 있음
-- orders.user_id에 인덱스 추가
CREATE INDEX idx_user_id ON orders(user_id);

SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- 방법 3: WHERE로 선필터
SELECT u.name, COUNT(*) as order_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status = 'completed'
  AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id;
```

**성공 기준:**
- [ ] 각 방법의 비용 계산 (O 표기법)
- [ ] 예상 실행 시간 순위 매기기
- [ ] 실제 실행 시간 측정 및 비교
- [ ] EXPLAIN으로 type, rows 확인
- [ ] 최소 10배 이상 차이 나는 케이스 찾기

**힌트:**
- users: 100,000 건
- orders: 1,000,000 건
- Nested Loop Join 방식 가정
- 인덱스 있을 때: O(N × log M)
- 인덱스 없을 때: O(N × M)

---

### 미션 3: 서브쿼리 vs JOIN 성능 대결 (필수)

**상황:**
10개 이상 주문한 사용자를 찾는 쿼리를 두 가지 방식으로 작성했습니다.

```sql
-- 방법 A: 상관 서브쿼리 (Correlated Subquery)
SELECT *
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM orders o
    WHERE o.user_id = u.id
) > 10;

-- 방법 B: JOIN + GROUP BY
SELECT u.*
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as cnt
    FROM orders
    GROUP BY user_id
    HAVING cnt > 10
) o ON u.id = o.user_id;
```

**성공 기준:**
- [ ] 각 방법의 시간복잡도 계산
- [ ] 예상 실행 시간 차이 예측 (몇 배?)
- [ ] 실제 실행 시간 측정
- [ ] EXPLAIN으로 실행 계획 비교
- [ ] 왜 차이가 나는지 설명

**힌트:**
- 상관 서브쿼리는 각 users 행마다 서브쿼리 실행
- users가 100,000건이면?

---

### 미션 4: ORDER BY 비용 감각 (필수)

**상황:**
최신 주문 10건을 조회하는 쿼리입니다.

```sql
-- 케이스 1: 인덱스 없음
SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;

-- 케이스 2: created_at 인덱스 있음
CREATE INDEX idx_created_at ON orders(created_at);

SELECT * FROM orders
ORDER BY created_at DESC
LIMIT 10;

-- 케이스 3: 복합 조건
SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
-- 인덱스: idx_created_at만 있음

-- 케이스 4: 최적 인덱스
-- 인덱스: (status, created_at)
SELECT * FROM orders
WHERE status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

**성공 기준:**
- [ ] 각 케이스의 EXPLAIN 분석
- [ ] Extra에서 'Using filesort' 확인
- [ ] filesort가 발생하는 케이스 식별
- [ ] 실행 시간 측정 및 비교
- [ ] 최적 인덱스 설계

**힌트:**
- 'Using filesort'가 보이면 정렬 비용 발생
- 100만 건 정렬: O(N log N) = 매우 느림
- 인덱스가 정렬되어 있으면: O(log N) + 10건 = 매우 빠름

---

## 💡 제공되는 환경

### 테이블 구조

**products 테이블:**
```sql
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200),
    price DECIMAL(10,2),
    category VARCHAR(50),
    created_at DATETIME,
    INDEX idx_category (category),
    INDEX idx_created_at (created_at)
);
-- 데이터: 1,000,000 건
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
-- 데이터: 100,000 건
```

**orders 테이블:**
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    created_at DATETIME,
    amount DECIMAL(10,2)
);
-- 데이터: 1,000,000 건
```

### 비용 계산 공식

**시간복잡도 기준:**
- O(1): 상수 시간 - 거의 즉시 (< 1ms)
- O(log N): 로그 시간 - 매우 빠름 (1~10ms)
- O(N): 선형 시간 - 데이터 크기에 비례 (100~1000ms)
- O(N log N): 선형 로그 - 정렬 시 (1~10초)
- O(N × M): 제곱 시간 - 매우 느림 (수 분 이상)

**예시 계산:**
```
100만 건 테이블 기준:
- O(1): 1번 비교
- O(log N): log₂(1,000,000) ≈ 20번 비교
- O(N): 1,000,000번 비교
- O(N log N): 20,000,000번 비교
```

---

## 🔍 참고: 비용 예측 체크리스트

### WHERE 절 체크
- [ ] 인덱스가 있는 컬럼인가?
- [ ] 함수나 연산이 들어가 있는가?
- [ ] LIKE의 와일드카드 위치는? (앞/뒤)
- [ ] 부정 조건(!=, NOT)을 사용하는가?
- [ ] 타입 변환이 필요한가?

### JOIN 체크
- [ ] JOIN 조건 컬럼에 인덱스가 있는가?
- [ ] 몇 개의 테이블을 JOIN하는가?
- [ ] 각 테이블의 크기는?
- [ ] WHERE로 먼저 필터링하는가?

### ORDER BY/GROUP BY 체크
- [ ] 정렬/그룹핑 컬럼에 인덱스가 있는가?
- [ ] EXPLAIN에 'Using filesort'가 있는가?
- [ ] 'Using temporary'가 있는가?

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 가장 느린 패턴 TOP 3</summary>

1. **상관 서브쿼리**: 각 행마다 서브쿼리 실행 (O(N × M))
2. **인덱스 없는 JOIN**: 모든 조합 비교 (O(N × M))
3. **전체 테이블 정렬**: filesort 발생 (O(N log N))

이 3가지가 보이면 즉시 빨간불!

</details>

<details>
<summary>힌트 2: 빠른 쿼리의 특징</summary>

- PRIMARY KEY나 UNIQUE 인덱스로 조회: O(1)
- 인덱스 사용: O(log N)
- LIMIT과 인덱스 조합: 매우 빠름
- WHERE로 먼저 대폭 필터링

</details>

<details>
<summary>힌트 3: EXPLAIN 빠른 해석법</summary>

**위험 신호:**
- type = ALL: 전체 스캔
- rows가 크다 (수만 이상)
- Extra = Using filesort: 정렬 비용
- Extra = Using temporary: 임시 테이블

**좋은 신호:**
- type = const, eq_ref, ref: 인덱스 사용
- rows가 작다 (수십~수백)
- Extra = Using index: 커버링 인덱스

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 각 쿼리를 실행하기 **전에** 먼저 예측하세요
3. 시간복잡도를 O 표기법으로 계산하세요
4. 예측 후 실제 실행하여 검증하세요
5. 예측과 실제의 차이를 분석하세요

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## 🎮 추가 도전 과제 (선택)

### 도전 1: 회사 쿼리 비용 분석
실제 회사 코드에서 쿼리 3개를 찾아 비용을 분석하세요.

### 도전 2: 최악의 쿼리 만들기
의도적으로 가장 느린 쿼리를 작성해보세요. (학습용!)
- 목표: 10초 이상 걸리는 쿼리
- 제약: 100만 건 이하의 테이블 사용

### 도전 3: 비용 계산기 만들기
쿼리를 입력하면 예상 비용을 계산해주는 스크립트 작성

---

## ⏱️ 예상 소요 시간

- 미션 1: 20분
- 미션 2: 15분
- 미션 3: 15분
- 미션 4: 10분
- **총 60분**

---

## 🎓 선택 사항: 이론 학습

비용 계산이 생소하다면:
- `docs/week3-query-cost.md` 참고
- 알고리즘 시간복잡도 기초 학습

하지만 **야생학습**이니까 일단 예측해보고, 틀리면서 배우는 것을 추천합니다!

---

**난이도:** ⭐⭐⭐ 중상
**즉시 적용:** ✓
**ROI:** 매우 높음

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] products, users, orders 테이블 확인
- [ ] 인덱스 상태 확인 (SHOW INDEX)

**준비되셨나요? 예측 시작!** 🔮
