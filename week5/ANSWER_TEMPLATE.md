# Week 5 답안: 트랜잭션 격리 수준

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: Dirty Read 재현하기

### 1-1. 환경 준비

#### 테이블 생성 및 데이터 준비
```sql
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    user_name VARCHAR(100),
    balance DECIMAL(10,2)
);

INSERT INTO accounts VALUES
(1, 'Alice', 1000),
(2, 'Bob', 2000),
(3, 'Charlie', 1500);

-- 초기 데이터 확인
SELECT * FROM accounts;
```

#### 현재 격리 수준 확인
```sql
-- 터미널 1, 2 모두 확인
SELECT @@transaction_isolation;

-- 결과: _____
```

---

### 1-2. READ UNCOMMITTED에서 Dirty Read 재현

#### 터미널 1, 2 격리 수준 설정
```sql
-- 터미널 1
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @@transaction_isolation;

-- 터미널 2
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT @@transaction_isolation;
```

#### 실습 진행 (시간 순서대로)

**Step 1 - 터미널 1: 트랜잭션 시작 및 잔액 변경**
```sql
START TRANSACTION;
UPDATE accounts SET balance = 0 WHERE id = 1;
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____
-- 아직 COMMIT 안 함!
```

**Step 2 - 터미널 2: 변경된 데이터 조회**
```sql
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____ (Dirty Read 발생!)
-- 커밋되지 않은 데이터가 보임
```

**Step 3 - 터미널 1: ROLLBACK**
```sql
ROLLBACK;
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____ (원래대로)
```

**Step 4 - 터미널 2: 다시 조회**
```sql
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____ (롤백된 값!)
-- 터미널 2는 존재하지 않는 데이터를 읽었음
COMMIT;
```

---

### 1-3. READ COMMITTED에서 Dirty Read 방지

#### 격리 수준 변경
```sql
-- 터미널 1
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 터미널 2
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

#### 같은 시나리오 재실행

**Step 1 - 터미널 1: 잔액 변경 (커밋 안 함)**
```sql
START TRANSACTION;
UPDATE accounts SET balance = 0 WHERE id = 1;

-- 아직 COMMIT 안 함
```

**Step 2 - 터미널 2: 조회**
```sql
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____ (커밋 전 값!)
-- Dirty Read 방지 ✅
```

**Step 3 - 터미널 1: COMMIT**
```sql
COMMIT;
```

**Step 4 - 터미널 2: 다시 조회**
```sql
SELECT * FROM accounts WHERE id = 1;

-- 결과: balance = _____ (커밋 후 값!)
-- 이제 변경된 값이 보임
COMMIT;
```

---

### 1-4. 결과 정리

#### Dirty Read 비교표

| 단계 | 터미널 1 작업 | READ UNCOMMITTED<br>(터미널 2 읽은 값) | READ COMMITTED<br>(터미널 2 읽은 값) |
|------|--------------|--------------------------------------|-------------------------------------|
| 1 | UPDATE (커밋 안 함) | _____ | _____ |
| 2 | ROLLBACK | _____ | _____ |
| 최종 | - | Dirty Read ❌ | 방지 ✅ |

**배운 점:**
1. READ UNCOMMITTED는 _____
2. READ COMMITTED는 _____
3. 실무에서는 _____

---

## 미션 2: Non-Repeatable Read 재현하기

### 2-1. READ COMMITTED에서 Non-Repeatable Read 재현

#### 격리 수준 확인
```sql
-- 터미널 1, 2
SELECT @@transaction_isolation;
-- READ COMMITTED 확인
```

#### 실습 진행

**Step 1 - 터미널 1: 트랜잭션 시작 및 조회**
```sql
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;

-- 결과: stock = _____
```

**Step 2 - 터미널 2: 재고 변경 및 커밋**
```sql
START TRANSACTION;
UPDATE products SET stock = 50 WHERE id = 1;
COMMIT;

-- 변경 완료
```

**Step 3 - 터미널 1: 같은 쿼리 다시 실행**
```sql
-- 같은 트랜잭션 내에서
SELECT stock FROM products WHERE id = 1;

-- 결과: stock = _____ (변경된 값!)
-- Non-Repeatable Read 발생 ❌
COMMIT;
```

---

### 2-2. REPEATABLE READ에서 Non-Repeatable Read 방지

#### 격리 수준 변경
```sql
-- 터미널 1, 2
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT @@transaction_isolation;
```

#### 데이터 초기화
```sql
UPDATE products SET stock = 100 WHERE id = 1;
```

#### 같은 시나리오 재실행

**Step 1 - 터미널 1: 트랜잭션 시작 및 조회**
```sql
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;

-- 결과: stock = _____
```

**Step 2 - 터미널 2: 재고 변경 및 커밋**
```sql
START TRANSACTION;
UPDATE products SET stock = 50 WHERE id = 1;
COMMIT;
```

**Step 3 - 터미널 1: 같은 쿼리 다시 실행**
```sql
-- 같은 트랜잭션 내에서
SELECT stock FROM products WHERE id = 1;

-- 결과: stock = _____ (원래 값!)
-- Non-Repeatable Read 방지 ✅
COMMIT;

-- 트랜잭션 종료 후 다시 조회
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = _____ (이제 변경된 값!)
```

---

### 2-3. 결과 정리

#### Non-Repeatable Read 비교표

| 단계 | 터미널 1 작업 | READ COMMITTED | REPEATABLE READ |
|------|--------------|----------------|-----------------|
| 1차 조회 | SELECT stock | _____ | _____ |
| 중간 | 터미널 2가 UPDATE & COMMIT | - | - |
| 2차 조회 | SELECT stock (같은 트랜잭션) | _____ (변경됨) | _____ (유지됨) |
| 결과 | - | Non-Repeatable Read ❌ | 방지 ✅ |

**이해한 내용:**
1. READ COMMITTED는 _____
2. REPEATABLE READ는 _____
3. MySQL이 REPEATABLE READ를 기본으로 사용하는 이유: _____

---

## 미션 3: Phantom Read 테스트하기

### 3-1. REPEATABLE READ에서 Phantom Read 테스트

#### 격리 수준 확인
```sql
-- 터미널 1, 2
SELECT @@transaction_isolation;
-- REPEATABLE READ 확인
```

#### 실습 진행

**Step 1 - 터미널 1: 카운트 조회**
```sql
START TRANSACTION;
SELECT COUNT(*) FROM products WHERE category = 'phone';

-- 결과: count = _____

-- 상세 조회
SELECT id, name, category FROM products WHERE category = 'phone';
```

**Step 2 - 터미널 2: 새 상품 추가**
```sql
START TRANSACTION;
INSERT INTO products (name, category, stock, price)
VALUES ('iPhone 16', 'phone', 30, 1300000);
COMMIT;

-- 추가 완료 확인
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: count = _____
```

**Step 3 - 터미널 1: 다시 카운트 조회**
```sql
-- 같은 트랜잭션 내에서
SELECT COUNT(*) FROM products WHERE category = 'phone';

-- 결과: count = _____ (변화 없음?)

-- 상세 조회
SELECT id, name, category FROM products WHERE category = 'phone';

-- MySQL 특별한 점: Phantom Read가 _____
COMMIT;

-- 커밋 후 조회
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: count = _____
```

---

### 3-2. MySQL의 특별한 점: Next-Key Lock

**실험: UPDATE 쿼리로 테스트**
```sql
-- 터미널 1
START TRANSACTION;
SELECT * FROM products WHERE category = 'phone' FOR UPDATE;
-- FOR UPDATE: 락 획득

-- 터미널 2
START TRANSACTION;
INSERT INTO products (name, category, stock, price)
VALUES ('Galaxy S25', 'phone', 40, 1100000);
-- 결과: _____ (대기? 즉시 실행?)

-- 터미널 1
COMMIT;

-- 터미널 2
-- INSERT가 _____
COMMIT;
```

**관찰 결과:**
- FOR UPDATE 없이: _____
- FOR UPDATE 사용: _____
- Next-Key Lock의 역할: _____

---

### 3-3. 결과 정리

#### Phantom Read 비교표

| 동작 | 표준 SQL REPEATABLE READ | MySQL REPEATABLE READ |
|------|-------------------------|----------------------|
| SELECT COUNT(*) | Phantom Read 발생 가능 | _____ |
| SELECT ... FOR UPDATE | - | _____ |
| 이유 | - | _____ |

**배운 점:**
1. Phantom Read란: _____
2. MySQL REPEATABLE READ의 특별한 점: _____
3. Next-Key Lock: _____

---

## 미션 4: 실전 격리 수준 선택하기

### 시나리오 A: 실시간 재고 관리 시스템

**상황 분석:**
- 동시 접근: _____
- 데이터 중요도: _____
- 성능 요구사항: _____

**선택한 격리 수준:** _____

**선택 이유:**
1.
2.
3.

**테스트 쿼리:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL _____;

START TRANSACTION;

-- 재고 확인
SELECT stock FROM products WHERE id = 1 FOR UPDATE;

-- 재고 감소
UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0;

-- 결과 확인
SELECT ROW_COUNT(); -- 1이면 성공, 0이면 재고 부족

COMMIT;
```

**예상 문제와 해결:**
- 문제: _____
- 해결: _____

---

### 시나리오 B: 일일 매출 통계 생성

**상황 분석:**
- 데이터 양: _____
- 정확도 요구: _____
- 성능 우선순위: _____

**선택한 격리 수준:** _____

**선택 이유:**
1.
2.
3.

**테스트 쿼리:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL _____;

START TRANSACTION;

-- 일일 매출 합계
SELECT
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(amount) as total_amount
FROM orders
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at);

COMMIT;
```

**이 격리 수준의 장단점:**
- 장점: _____
- 단점: _____

---

### 시나리오 C: 회계 마감 처리

**상황 분석:**
- 정확성 요구: _____
- 처리 시간: _____
- 동시 작업: _____

**선택한 격리 수준:** _____

**선택 이유:**
1.
2.
3.

**테스트 쿼리:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL _____;

START TRANSACTION;

-- 월별 매출 마감
CREATE TEMPORARY TABLE monthly_summary AS
SELECT
    DATE_FORMAT(created_at, '%Y-%m') as month,
    SUM(amount) as total_amount,
    COUNT(*) as order_count
FROM orders
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2024-10'
GROUP BY month;

-- 검증
SELECT * FROM monthly_summary;

-- 마감 데이터 저장
INSERT INTO accounting_summary (month, total_amount, order_count)
SELECT * FROM monthly_summary;

COMMIT;
```

**SERIALIZABLE 사용 시 주의사항:**
- _____
- _____

---

### 시나리오별 격리 수준 비교

| 시나리오 | 격리 수준 | 성능 | 안정성 | 이유 |
|---------|----------|------|--------|------|
| A. 재고 관리 | _____ | _____ | _____ | _____ |
| B. 매출 통계 | _____ | _____ | _____ | _____ |
| C. 회계 마감 | _____ | _____ | _____ | _____ |

---

## 학습 정리

### 격리 수준별 특징 요약

#### READ UNCOMMITTED
**허용하는 문제:** _____
**사용 사례:** _____
**실무 사용 빈도:** _____

#### READ COMMITTED
**허용하는 문제:** _____
**사용 사례:** _____
**실무 사용 빈도:** _____

#### REPEATABLE READ
**허용하는 문제:** _____
**사용 사례:** _____
**실무 사용 빈도:** _____

#### SERIALIZABLE
**허용하는 문제:** _____
**사용 사례:** _____
**실무 사용 빈도:** _____

---

### 배운 핵심 개념 3가지
1.
2.
3.

---

### 격리 수준 선택 체크리스트 (내가 정리한 기준)

**데이터 중요도:**
- [ ] 조금의 오차도 허용 안 됨 → _____
- [ ] 약간의 불일치 괜찮음 → _____
- [ ] 대략적인 값이면 됨 → _____

**성능 요구사항:**
- [ ] 빠른 조회가 최우선 → _____
- [ ] 균형 잡힌 성능 → _____
- [ ] 느려도 됨 → _____

**동시성 수준:**
- [ ] 동시 접근 매우 많음 → _____
- [ ] 중간 정도 → _____
- [ ] 순차 처리 가능 → _____

---

## 실무 적용 계획

### 현재 프로젝트 격리 수준 확인

```sql
-- 현재 사용 중인 격리 수준
SELECT @@GLOBAL.transaction_isolation;
SELECT @@SESSION.transaction_isolation;

-- 결과: _____
```

**현재 프로젝트:**
- 프로젝트명: _____
- DB: MySQL / PostgreSQL / _____
- 격리 수준: _____
- 문제점: _____

---

### 개선이 필요한 부분

**케이스 1: _____**
```sql
-- 현재 코드

-- 문제점:

-- 개선 방안:
-- 격리 수준: _____
-- 이유:
```

**케이스 2: _____**
```sql
-- 현재 코드

-- 문제점:

-- 개선 방안:
```

---

### 팀 공유 내용
1. 격리 수준별 차이점
2. MySQL vs PostgreSQL 기본값 차이
3. 실무 선택 가이드
4. _____

---

## 트러블슈팅

### 문제 1: 격리 수준이 변경되지 않음

**문제:**


**원인:**


**해결:**


---

### 문제 2: 트랜잭션 타임아웃

**문제:**


**원인:**


**해결:**


---

### 문제 3: 데드락 발생

**문제:**


**원인:**


**해결:**


---

## 추가 실험 (선택)

### 실험 1: 격리 수준별 성능 비교

```sql
-- 동일 쿼리 100번 실행 시간 측정

-- READ COMMITTED
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 평균 실행 시간: _____ms

-- REPEATABLE READ
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- 평균 실행 시간: _____ms

-- SERIALIZABLE
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 평균 실행 시간: _____ms
```

**결과 분석:**


---

### 실험 2: MVCC (Multi-Version Concurrency Control) 확인

```sql
-- InnoDB 상태 확인
SHOW ENGINE INNODB STATUS\G

-- History list length 확인
-- 값: _____
-- 의미: _____
```

**배운 점:**


---

## 다음 액션

### 추가 학습 필요
- [ ] MVCC 동작 원리 깊이 있게 학습
- [ ] PostgreSQL 격리 수준 비교
- [ ] 실무 데드락 케이스 분석
- [ ] _____

### 실무 적용 기한
- [ ] 1주일 내: 현재 프로젝트 격리 수준 분석
- [ ] 2주일 내: 문제 있는 부분 개선 제안
- [ ] 팀 공유 세션 준비

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**느낀 점:**


**가장 어려웠던 부분:**


**가장 인상 깊었던 부분:**


---

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
