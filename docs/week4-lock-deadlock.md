# Week 4: 락과 데드락 처리 ⭐⭐⭐

> "서비스 멈추는 데드락 대응법"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"데드락 발생 시 당황하지 않고 해결하기"**

이번 주차를 완료하면:
- 락의 종류와 동작 원리 이해
- 데드락 발생 원인 파악 가능
- 데드락 로그 분석 가능
- 낙관적/비관적 락 선택 가능

---

## 📚 학습 내용

### 1. 락의 종류 (15분)

#### Shared Lock (S-Lock, 공유 락)
```sql
-- 읽기 락
SELECT * FROM products WHERE id = 1 LOCK IN SHARE MODE;

특징:
- 여러 트랜잭션이 동시에 읽기 가능
- 쓰기는 블록됨
- 용도: 읽는 동안 데이터 변경 방지
```

#### Exclusive Lock (X-Lock, 배타 락)
```sql
-- 쓰기 락
SELECT * FROM products WHERE id = 1 FOR UPDATE;
UPDATE products SET stock = stock - 1 WHERE id = 1;

특징:
- 다른 트랜잭션의 읽기/쓰기 모두 블록
- 용도: 데이터 수정 시
```

#### Row Lock vs Table Lock
```sql
-- Row Lock (행 단위)
UPDATE products SET stock = stock - 1 WHERE id = 1;
-- id=1 행만 락

-- Table Lock (테이블 단위)
LOCK TABLES products WRITE;
-- 전체 테이블 락 (거의 안 씀)
```

---

### 2. 데드락이란? (15분)

#### 데드락 발생 조건
```
트랜잭션 A: 자원1 획득 → 자원2 대기
트랜잭션 B: 자원2 획득 → 자원1 대기
→ 서로 무한 대기 (Deadlock!)
```

#### 실제 예시
```sql
-- 트랜잭션 1
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;  -- 락 획득
-- ... 다른 작업 ...
UPDATE products SET stock = stock - 1 WHERE id = 2;  -- 락 대기
COMMIT;

-- 트랜잭션 2 (동시 실행)
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 2;  -- 락 획득
-- ... 다른 작업 ...
UPDATE products SET stock = stock - 1 WHERE id = 1;  -- 락 대기 → DEADLOCK!
COMMIT;
```

#### 데드락 발생 시
```
ERROR 1213 (40001): Deadlock found when trying to get lock;
try restarting transaction
```

---

### 3. 데드락 로그 분석 (15분)

#### 로그 확인 방법
```sql
SHOW ENGINE INNODB STATUS\G

-- 데드락 로그 섹션
------------------------
LATEST DETECTED DEADLOCK
------------------------
```

#### 로그 읽는 법
```
*** (1) TRANSACTION:
TRANSACTION 1234, ACTIVE 5 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 10, OS thread handle 123456, query id 100 localhost root updating
UPDATE products SET stock = stock - 1 WHERE id = 1

*** (2) TRANSACTION:
TRANSACTION 5678, ACTIVE 3 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 11, OS thread handle 789012, query id 101 localhost root updating
UPDATE products SET stock = stock - 1 WHERE id = 2

*** WE ROLL BACK TRANSACTION (2)
```

#### 분석 포인트
1. 어떤 트랜잭션들이 충돌했는가?
2. 어떤 테이블/행에서 발생했는가?
3. 어떤 순서로 락을 획득했는가?

---

### 4. 데드락 예방 (15분)

#### 원칙 1: 락 순서 통일
```sql
-- ❌ 나쁨: 순서가 다름
-- 트랜잭션 A: 1 → 2
-- 트랜잭션 B: 2 → 1

-- ✅ 좋음: 순서가 같음
-- 트랜잭션 A: 1 → 2
-- 트랜잭션 B: 1 → 2

-- 구현
UPDATE products SET stock = stock - 1
WHERE id IN (1, 2)
ORDER BY id;  -- 항상 ID 순서로
```

#### 원칙 2: 트랜잭션 최소화
```sql
-- ❌ 나쁨: 불필요하게 긴 트랜잭션
START TRANSACTION;
SELECT * FROM products WHERE id = 1 FOR UPDATE;
-- 외부 API 호출 (5초 소요)
-- 복잡한 계산 (3초 소요)
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;

-- ✅ 좋음: 최소한의 트랜잭션
-- 외부 API 호출 (트랜잭션 밖)
-- 복잡한 계산 (트랜잭션 밖)
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;
```

#### 원칙 3: 인덱스 활용
```sql
-- ❌ 나쁨: 인덱스 없으면 많은 행 락
UPDATE products SET stock = stock - 1
WHERE name = 'iPhone';  -- name에 인덱스 없음
-- → 많은 행 스캔 = 많은 락

-- ✅ 좋음: 인덱스로 최소 락
CREATE INDEX idx_name ON products(name);
```

---

### 5. 낙관적 락 vs 비관적 락 (15분)

#### 비관적 락 (Pessimistic Lock)
```sql
-- "다른 사람이 수정할 것이다" 가정
START TRANSACTION;
SELECT * FROM products WHERE id = 1 FOR UPDATE;  -- 락 걸기
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;

장점: 확실한 동시성 제어
단점: 대기 시간 발생
사용: 충돌이 자주 일어나는 경우
```

#### 낙관적 락 (Optimistic Lock)
```sql
-- "다른 사람이 수정 안 할 것이다" 가정
-- 1. 버전 읽기
SELECT id, stock, version FROM products WHERE id = 1;
-- stock=10, version=5

-- 2. 버전 확인하며 업데이트
UPDATE products
SET stock = 9, version = 6
WHERE id = 1 AND version = 5;

-- 3. 영향받은 행 확인
affected_rows = 1 → 성공
affected_rows = 0 → 실패 (다른 트랜잭션이 먼저 수정)

장점: 락 없음, 빠름
단점: 충돌 시 재시도 필요
사용: 충돌이 드문 경우
```

#### 선택 기준
```
충돌 빈도:
  높음 → 비관적 락
  낮음 → 낙관적 락

응답 시간:
  빠름 필요 → 낙관적 락
  확실함 필요 → 비관적 락

예시:
  - 재고 관리 (충돌 많음) → 비관적 락
  - 게시글 수정 (충돌 적음) → 낙관적 락
```

---

## 🔬 실습

### 실습 1: 데드락 재현 (20분)

```sql
-- 준비: 테스트 테이블
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    balance DECIMAL(10,2)
);

INSERT INTO accounts VALUES (1, 1000), (2, 1000);

-- 터미널 1 (트랜잭션 A)
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- 5초 대기
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- 터미널 2 (트랜잭션 B) - 동시 실행
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 2;
-- 즉시 실행
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;
```

#### 결과 확인
```sql
SHOW ENGINE INNODB STATUS\G

-- 데드락 로그 붙여넣기:


-- 분석:
- 트랜잭션 A가 잠근 자원: _____
- 트랜잭션 B가 잠근 자원: _____
- 롤백된 트랜잭션: _____
```

---

### 실습 2: 데드락 해결 (20분)

```sql
-- 해결 방법 1: 락 순서 통일
-- 터미널 1
START TRANSACTION;
UPDATE accounts SET balance = balance - 100
WHERE id IN (1, 2) ORDER BY id;
COMMIT;

-- 터미널 2
START TRANSACTION;
UPDATE accounts SET balance = balance + 100
WHERE id IN (1, 2) ORDER BY id;
COMMIT;

-- 데드락 발생 여부: _____

-- 해결 방법 2: 트랜잭션 분리
-- (하나씩 업데이트)

-- 해결 방법 3: 타임아웃 설정
SET innodb_lock_wait_timeout = 5;
```

---

### 실습 3: 낙관적 락 vs 비관적 락 (20분)

```sql
-- 시나리오: 재고 차감

-- 비관적 락 구현
START TRANSACTION;
SELECT stock FROM products WHERE id = 1 FOR UPDATE;
-- stock 확인
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;
-- 실행시간: _____ms

-- 낙관적 락 구현
-- 1. 읽기
SELECT id, stock, version FROM products WHERE id = 1;

-- 2. 업데이트
UPDATE products
SET stock = stock - 1, version = version + 1
WHERE id = 1 AND version = ?;

-- 3. 재시도 로직
IF affected_rows = 0 THEN
    RETRY
END IF
-- 실행시간: _____ms

-- 성능 비교 (10명 동시 실행)
-- 비관적 락: _____ms
-- 낙관적 락: _____ms
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] Shared Lock vs Exclusive Lock 이해
- [ ] 데드락 발생 조건 숙지
- [ ] 데드락 로그 읽는 법 학습
- [ ] 낙관적 락 vs 비관적 락 비교

### 실습 완료
- [ ] 데드락 재현 실험
- [ ] 데드락 로그 분석
- [ ] 데드락 해결 방법 3가지 테스트
- [ ] 낙관적/비관적 락 성능 비교

### 실무 적용
- [ ] 데드락 발생 시 대응 프로세스 정리
- [ ] 동시성 제어 전략 수립
- [ ] 재고 관리 등 핵심 로직 락 전략 검토

---

## 📝 학습 노트

### 데드락 대응 체크리스트
1. [ ] 로그 확인 (`SHOW ENGINE INNODB STATUS`)
2. [ ] 충돌 테이블/쿼리 파악
3. [ ] 락 순서 확인
4. [ ] 해결 방법 적용
5. [ ] 재발 방지 문서화

### 실무 적용 사례

**발생한 데드락:**
```
날짜: _____
에러 로그:


원인:


해결:


```

---

## 📚 참고 자료

- MySQL 공식 문서: [InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)
- [데드락 완벽 가이드](https://dev.mysql.com/doc/refman/8.0/en/innodb-deadlocks.html)

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐⭐ 중상
**즉시 적용**: 상황 발생 시
**ROI**: 높음

**완료일**: ___________
