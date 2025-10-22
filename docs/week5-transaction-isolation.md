# Week 5: 트랜잭션 격리 수준 ⭐⭐⭐

> "격리 수준별 문제 이해"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"격리 수준을 상황에 맞게 선택하기"**

이번 주차를 완료하면:
- 4가지 격리 수준의 차이 이해
- 각 격리 수준의 문제점 파악
- 실무에서 적절한 격리 수준 선택 가능
- 격리 수준 관련 버그 디버깅 가능

---

## 📚 학습 내용

### 1. 트랜잭션 격리 수준 개요 (10분)

#### 4가지 격리 수준 (낮음 → 높음)
```
READ UNCOMMITTED (레벨 0)
  ↓
READ COMMITTED (레벨 1) ← PostgreSQL 기본
  ↓
REPEATABLE READ (레벨 2) ← MySQL 기본
  ↓
SERIALIZABLE (레벨 3)
```

#### Trade-off
```
격리 수준 ↑ = 안전성 ↑, 성능 ↓, 동시성 ↓
격리 수준 ↓ = 안전성 ↓, 성능 ↑, 동시성 ↑
```

#### 확인 방법
```sql
-- 현재 격리 수준 확인
SELECT @@transaction_isolation;

-- 격리 수준 변경 (세션)
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 격리 수준 변경 (전역)
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

---

### 2. READ UNCOMMITTED (10분)

#### 특징
```
가장 낮은 격리 수준
커밋되지 않은 데이터도 읽을 수 있음
```

#### Dirty Read 문제
```sql
-- 트랜잭션 A
START TRANSACTION;
UPDATE products SET stock = 0 WHERE id = 1;
-- 아직 커밋 안 함

-- 트랜잭션 B (READ UNCOMMITTED)
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;
-- stock = 0 읽음 (커밋 안 된 데이터!)

-- 트랜잭션 A
ROLLBACK;  -- 롤백!

-- 문제: B는 존재하지 않는 데이터를 읽음
```

#### 사용 사례
```
거의 사용 안 함
예외: 대략적인 통계 (정확도 불필요)
```

---

### 3. READ COMMITTED (15분)

#### 특징
```
커밋된 데이터만 읽음
PostgreSQL, Oracle 기본 값
```

#### Dirty Read 해결 ✅
```sql
-- 트랜잭션 A
START TRANSACTION;
UPDATE products SET stock = 0 WHERE id = 1;

-- 트랜잭션 B (READ COMMITTED)
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;
-- 이전 값(10) 읽음 (커밋 안 된 데이터는 안 보임)

-- 트랜잭션 A
COMMIT;

-- 트랜잭션 B
SELECT stock FROM products WHERE id = 1;
-- 새 값(0) 읽음
```

#### Non-Repeatable Read 문제 ❌
```sql
-- 트랜잭션 A
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;  -- stock = 10

-- 트랜잭션 B
START TRANSACTION;
UPDATE products SET stock = 5 WHERE id = 1;
COMMIT;

-- 트랜잭션 A (같은 트랜잭션 내)
SELECT stock FROM products WHERE id = 1;  -- stock = 5

-- 문제: 같은 트랜잭션에서 같은 쿼리가 다른 결과!
```

#### 사용 사례
```
일반적인 웹 애플리케이션
OLTP (온라인 트랜잭션 처리)
```

---

### 4. REPEATABLE READ (15분)

#### 특징
```
트랜잭션 시작 시점의 스냅샷 유지
MySQL 기본 값
```

#### Non-Repeatable Read 해결 ✅
```sql
-- 트랜잭션 A (REPEATABLE READ)
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;  -- stock = 10

-- 트랜잭션 B
START TRANSACTION;
UPDATE products SET stock = 5 WHERE id = 1;
COMMIT;

-- 트랜잭션 A
SELECT stock FROM products WHERE id = 1;  -- stock = 10 (변경 안 보임!)
COMMIT;
```

#### Phantom Read 문제 ❌
```sql
-- 트랜잭션 A
START TRANSACTION;
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- count = 10

-- 트랜잭션 B
START TRANSACTION;
INSERT INTO products (category, name) VALUES ('phone', 'iPhone');
COMMIT;

-- 트랜잭션 A
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- MySQL: count = 10 (Phantom Read 없음!)
-- 표준 SQL: count = 11 (Phantom Read 발생)

-- MySQL은 Next-Key Lock으로 Phantom Read도 방지
```

#### 사용 사례
```
MySQL 기본값으로 대부분 이것 사용
금융 거래, 재고 관리 등
```

---

### 5. SERIALIZABLE (10분)

#### 특징
```
가장 높은 격리 수준
모든 문제 해결
사실상 순차 실행
```

#### 모든 문제 해결 ✅
```
Dirty Read: ✅ 해결
Non-Repeatable Read: ✅ 해결
Phantom Read: ✅ 해결
```

#### 성능 문제 ❌
```sql
-- 트랜잭션 A
START TRANSACTION;
SELECT * FROM products WHERE category = 'phone';
-- 테이블 전체 락!

-- 트랜잭션 B
START TRANSACTION;
INSERT INTO products (category, name) VALUES ('laptop', 'MacBook');
-- 대기... (다른 카테고리인데도 블록됨)
```

#### 사용 사례
```
거의 사용 안 함
예외: 절대적인 일관성 필요 (회계 마감 등)
```

---

## 🔬 실습

### 실습 1: Dirty Read 재현 (15분)

```sql
-- 준비
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    balance DECIMAL(10,2)
);
INSERT INTO accounts VALUES (1, 1000);

-- 터미널 1: READ UNCOMMITTED 설정
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- 트랜잭션 A (터미널 2)
START TRANSACTION;
UPDATE accounts SET balance = 0 WHERE id = 1;
-- 아직 커밋 안 함

-- 트랜잭션 B (터미널 1 - READ UNCOMMITTED)
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
-- 결과: _____ (Dirty Read!)

-- 트랜잭션 A (터미널 2)
ROLLBACK;

-- 트랜잭션 B (터미널 1)
SELECT balance FROM accounts WHERE id = 1;
-- 결과: _____
COMMIT;
```

#### 결과 기록
| 시점 | 읽은 값 | 실제 값 | 문제 |
|------|---------|---------|------|
| A 업데이트 후 | | | |
| A 롤백 후 | | | |

---

### 실습 2: Non-Repeatable Read 재현 (15분)

```sql
-- 터미널 1: READ COMMITTED 설정
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 트랜잭션 A (터미널 1)
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;
-- 결과: _____

-- 트랜잭션 B (터미널 2)
START TRANSACTION;
UPDATE accounts SET balance = 500 WHERE id = 1;
COMMIT;

-- 트랜잭션 A (터미널 1) - 같은 트랜잭션
SELECT balance FROM accounts WHERE id = 1;
-- 결과: _____ (Non-Repeatable Read!)
COMMIT;

-- 이제 REPEATABLE READ로 테스트
-- 터미널 1: REPEATABLE READ 설정
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 위 과정 반복
-- 결과: _____ (변경 안 보임!)
```

---

### 실습 3: Phantom Read 테스트 (15분)

```sql
-- 준비
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    category VARCHAR(50)
);

INSERT INTO products (name, category) VALUES
('iPhone', 'phone'),
('Galaxy', 'phone');

-- 터미널 1: REPEATABLE READ (MySQL 기본)
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 트랜잭션 A (터미널 1)
START TRANSACTION;
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: _____

-- 트랜잭션 B (터미널 2)
START TRANSACTION;
INSERT INTO products (name, category) VALUES ('Pixel', 'phone');
COMMIT;

-- 트랜잭션 A (터미널 1)
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- MySQL 결과: _____ (Phantom Read 없음!)
COMMIT;

-- 다시 조회
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: _____ (이제 보임)
```

---

### 실습 4: 격리 수준별 성능 비교 (15분)

```sql
-- 동시 트랜잭션 100개 실행
-- 각 격리 수준별 처리 시간 측정

-- READ COMMITTED
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 100개 트랜잭션 실행
-- 처리 시간: _____ms

-- REPEATABLE READ
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- 100개 트랜잭션 실행
-- 처리 시간: _____ms

-- SERIALIZABLE
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 100개 트랜잭션 실행
-- 처리 시간: _____ms
```

#### 성능 비교
| 격리 수준 | 처리 시간 | 동시성 | 안정성 |
|-----------|----------|--------|--------|
| READ COMMITTED | | 높음 | 낮음 |
| REPEATABLE READ | | 중간 | 중간 |
| SERIALIZABLE | | 낮음 | 높음 |

---

## ✅ 체크리스트

### 이론 학습
- [ ] 4가지 격리 수준 이해
- [ ] Dirty Read, Non-Repeatable Read, Phantom Read 차이 숙지
- [ ] MySQL vs PostgreSQL 기본 격리 수준 차이 인지
- [ ] 각 격리 수준의 사용 사례 이해

### 실습 완료
- [ ] Dirty Read 재현
- [ ] Non-Repeatable Read 재현
- [ ] Phantom Read 테스트
- [ ] 격리 수준별 성능 비교

### 실무 적용
- [ ] 현재 서비스의 격리 수준 확인
- [ ] 격리 수준 관련 버그 검토
- [ ] 필요 시 격리 수준 변경 고려

---

## 📝 학습 노트

### 격리 수준 선택 가이드

| 상황 | 권장 격리 수준 | 이유 |
|------|---------------|------|
| 일반 웹 서비스 | READ COMMITTED | 성능/동시성 균형 |
| 금융 거래 | REPEATABLE READ | 일관성 중요 |
| 통계 조회 | READ UNCOMMITTED | 속도 우선 |
| 회계 마감 | SERIALIZABLE | 정확성 최우선 |

### 실무 적용 사례

**현재 서비스:**
- 격리 수준: _____
- 선택 이유: _____
- 문제점: _____
- 개선 계획: _____

---

## 📚 참고 자료

- MySQL 공식 문서: [Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html)
- [ACID와 격리 수준 완벽 가이드](https://en.wikipedia.org/wiki/Isolation_(database_systems))

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐⭐ 중상
**즉시 적용**: △ (기본값 사용 중)
**ROI**: 중간 (개념 이해용)

**완료일**: ___________
