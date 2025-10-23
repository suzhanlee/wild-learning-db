# Week 2 답안: EXPLAIN 실전 분석

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: type별 성능 차이 체감하기

### 쿼리 A: PRIMARY KEY 조회

#### EXPLAIN 분석
```sql
EXPLAIN SELECT * FROM orders WHERE id = 500000;

-- 결과:
```

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

#### 실행 시간 측정
```sql
-- 실행 시간: _____ms
```

**분석:**
- type: _____
- rows: _____
- 왜 이 성능이 나왔는가? _____

---

### 쿼리 B: 인덱스 있는 컬럼 조회

#### EXPLAIN 분석
```sql
EXPLAIN SELECT * FROM orders WHERE user_id = 12345;

-- 결과:
```

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

#### 실행 시간 측정
```sql
-- 실행 시간: _____ms
```

**분석:**
- type: _____
- rows: _____
- 사용된 인덱스: _____

---

### 쿼리 C: 범위 조회

#### EXPLAIN 분석
```sql
EXPLAIN SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';

-- 결과:
```

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

#### 실행 시간 측정
```sql
-- 실행 시간: _____ms
```

**분석:**
- type: _____
- rows: _____
- 인덱스 사용 여부: _____

---

### 쿼리 D: 인덱스 없는 컬럼 조회

#### EXPLAIN 분석
```sql
EXPLAIN SELECT * FROM orders WHERE amount > 1000;

-- 결과:
```

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

#### 실행 시간 측정
```sql
-- 실행 시간: _____ms
```

**분석:**
- type: _____
- rows: _____
- 문제점: _____

---

### 쿼리 E: 전체 스캔

#### EXPLAIN 분석
```sql
EXPLAIN SELECT * FROM orders WHERE status LIKE '%ing%';

-- 결과:
```

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

#### 실행 시간 측정
```sql
-- 실행 시간: _____ms
```

**분석:**
- type: _____
- rows: _____
- 왜 느린가? _____

---

### 성능 순위표

| 쿼리 | type | rows | 실행시간 | 순위 |
|------|------|------|---------|------|
| A (id) |  |  | ms | |
| B (user_id) |  |  | ms | |
| C (created_at) |  |  | ms | |
| D (amount) |  |  | ms | |
| E (LIKE) |  |  | ms | |

**배운 점:**
- type=const가 가장 빠른 이유: _____
- type=ALL이 느린 이유: _____
- rows 수가 성능에 미치는 영향: _____

---

## 미션 2: Extra 컬럼 해석하기

### 쿼리 A: 상태별 주문 조회

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

#### EXPLAIN 결과

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**분석:**
- type: _____
- rows: _____
- Extra: _____
- 문제점: _____
- Using filesort 발생 여부: [ ] 예 / [ ] 아니오

**문제가 있다면 원인:**
_____

---

### 쿼리 B: 사용자별 주문 집계

```sql
EXPLAIN SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 10;
```

#### EXPLAIN 결과

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**분석:**
- type: _____
- rows: _____
- Extra: _____
- Using temporary 발생 여부: [ ] 예 / [ ] 아니오
- Using filesort 발생 여부: [ ] 예 / [ ] 아니오

**문제가 있다면 원인:**
_____

---

### 쿼리 C: 커버링 인덱스 확인

```sql
EXPLAIN SELECT id, user_id, status FROM orders
WHERE user_id = 12345 AND status = 'completed';
```

#### EXPLAIN 결과

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**분석:**
- type: _____
- rows: _____
- Extra: _____
- Using index 발생 여부: [ ] 예 / [ ] 아니오

**커버링 인덱스란?**
_____

---

### 쿼리 D: JOIN 쿼리

```sql
EXPLAIN SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'user12345@example.com';
```

#### EXPLAIN 결과

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |
|    |             |       |      |     |      |       |

**분석:**
- orders 테이블 type: _____
- users 테이블 type: _____
- 드라이빙 테이블: _____
- 문제점: _____

---

### Extra 패턴 정리

**발견한 Extra 값들:**

| Extra | 의미 | 성능 영향 | 발견한 쿼리 |
|-------|------|----------|-------------|
| Using where |  |  | |
| Using filesort |  |  | |
| Using temporary |  |  | |
| Using index |  |  | |
| Using index condition |  |  | |

---

## 미션 3: 느린 쿼리 최적화

### 문제 쿼리 1: 상태별 최근 주문 조회

#### Before: 현재 상태 분석

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN 결과 (Before):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (Before):** _____ms

**문제점:**
1. type: _____
2. rows: _____
3. Extra: _____

---

#### 해결 방법

**설계한 인덱스:**
```sql
CREATE INDEX ______________ ON orders(______________);
```

**인덱스를 이렇게 설계한 이유:**
1. _____
2. _____
3. _____

---

#### After: 개선 결과

```sql
EXPLAIN SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN 결과 (After):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (After):** _____ms

---

#### 성능 개선 결과

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ___ms | ___ms | ___배 |
| type | _____ | _____ | - |
| rows | _____ | _____ | ___배 |
| Extra | _____ | _____ | - |

**개선 성공 여부:** [ ] 10배 이상 개선

---

### 문제 쿼리 2: 사용자별 주문 통계

#### Before: 현재 상태 분석

```sql
EXPLAIN SELECT user_id, COUNT(*) as cnt, SUM(amount) as total
FROM orders
WHERE status IN ('completed', 'shipped')
GROUP BY user_id
HAVING total > 10000
ORDER BY total DESC;
```

**EXPLAIN 결과 (Before):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (Before):** _____ms

**문제점:**
1. _____
2. _____
3. _____

---

#### 해결 방법

**설계한 인덱스:**
```sql
CREATE INDEX ______________ ON orders(______________);
```

**또는 쿼리 개선:**
```sql


```

**이유:**
_____

---

#### After: 개선 결과

**EXPLAIN 결과 (After):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (After):** _____ms

#### 성능 개선 결과

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ___ms | ___ms | ___배 |
| type | _____ | _____ | - |
| rows | _____ | _____ | ___배 |
| Extra | _____ | _____ | - |

---

### 문제 쿼리 3: 기간별 주문 집계

#### Before: 현재 상태 분석

```sql
EXPLAIN SELECT DATE(created_at) as order_date, COUNT(*) as cnt
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
GROUP BY DATE(created_at)
ORDER BY order_date;
```

**EXPLAIN 결과 (Before):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (Before):** _____ms

**문제점:**
1. _____
2. _____

---

#### 해결 방법

**설계한 인덱스:**
```sql
CREATE INDEX ______________ ON orders(______________);
```

**또는 쿼리 개선:**
```sql


```

**GROUP BY에 함수 사용의 문제:**
_____

---

#### After: 개선 결과

**EXPLAIN 결과 (After):**

| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**실행 시간 (After):** _____ms

#### 성능 개선 결과

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ___ms | ___ms | ___배 |
| type | _____ | _____ | - |
| rows | _____ | _____ | ___배 |
| Extra | _____ | _____ | - |

---

## 학습 정리

### EXPLAIN 해석 체크리스트 (내가 정리한 기준)

**type 값 판단:**
- [ ] const: 최고 성능, 그대로 사용
- [ ] ref: 좋은 성능, 그대로 사용
- [ ] range: 괜찮은 성능, rows 확인 필요
- [ ] index: 주의 필요, 개선 검토
- [ ] ALL: 문제! 반드시 개선 필요

**rows 판단:**
- [ ] 100 이하: 좋음
- [ ] 1,000 이하: 괜찮음
- [ ] 10,000 이하: 주의
- [ ] 10,000 초과: 문제

**Extra 판단:**
- [ ] Using index: 최고!
- [ ] Using index condition: 좋음
- [ ] Using where: type과 함께 판단
- [ ] Using filesort: 개선 필요
- [ ] Using temporary: 반드시 개선

---

### 배운 핵심 개념 3가지

1. **type의 중요성:**
   _____

2. **Extra 해석 능력:**
   _____

3. **인덱스 최적화 전략:**
   _____

---

### 인덱스 설계 규칙 (내 버전)

**복합 인덱스 순서:**
1. _____
2. _____
3. _____

**Using filesort 방지:**
- _____

**Using temporary 방지:**
- _____

---

## 실무 적용 계획

### 즉시 적용할 부분

**회사/프로젝트:**
_____

**분석할 쿼리 1:**
```sql
-- 현재 쿼리


-- EXPLAIN 예상 결과


-- 개선 계획

```

**분석할 쿼리 2:**
```sql
-- 현재 쿼리


-- EXPLAIN 예상 결과


-- 개선 계획

```

---

### EXPLAIN 활용 계획

**일상 업무에 적용:**
- [ ] 새 쿼리 작성 시 EXPLAIN 습관화
- [ ] 코드 리뷰 시 EXPLAIN 확인
- [ ] 느린 API 발견 시 EXPLAIN으로 분석

**팀 공유:**
- [ ] EXPLAIN 해석 가이드 작성
- [ ] type/rows/Extra 체크리스트 공유
- [ ] 팀 위키에 Best Practice 정리

---

## 트러블슈팅

### 문제 1

**상황:**
_____

**시도한 해결 방법:**
_____

**결과:**
_____

**배운 점:**
_____

---

### 문제 2

**상황:**
_____

**시도한 해결 방법:**
_____

**결과:**
_____

**배운 점:**
_____

---

## 보너스 미션 (선택)

### 보너스 1: JOIN 쿼리 최적화

```sql
EXPLAIN SELECT o.*, u.name, u.email
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'pending'
  AND u.status = 'active'
ORDER BY o.created_at DESC
LIMIT 10;
```

**분석:**
_____

**개선 방법:**
_____

---

### 보너스 2: 서브쿼리 vs JOIN

**서브쿼리 EXPLAIN:**
```sql
EXPLAIN SELECT * FROM orders
WHERE user_id IN (
    SELECT id FROM users WHERE status = 'active'
);
```

**JOIN EXPLAIN:**
```sql
EXPLAIN SELECT o.* FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.status = 'active';
```

**성능 비교:**
_____

**결론:**
_____

---

## 다음 액션

### 이번 주 실무 적용
- [ ] 주요 API 쿼리 EXPLAIN 분석
- [ ] type=ALL 쿼리 찾아서 개선
- [ ] Using filesort 제거
- [ ] 성능 개선 결과 측정

### 팀 공유 계획
- [ ] EXPLAIN 해석 가이드 작성
- [ ] 개선 사례 공유
- [ ] 코드 리뷰 체크리스트 업데이트

### 추가 학습
- [ ] Week 3 준비: 쿼리 성능 비용 감각
- [ ] MySQL 공식 문서 EXPLAIN 섹션 읽기
- [ ] 실전 케이스 스터디 찾아보기

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**자기 평가:**
- [ ] type 순서 완벽히 암기
- [ ] Extra 패턴 이해 완료
- [ ] 실무 쿼리 분석 가능
- [ ] 인덱스 설계 자신감 향상

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
