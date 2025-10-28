# Week 5 정답: 트랜잭션 격리 수준

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: Dirty Read 재현하기 - 정답

### 1-1. READ UNCOMMITTED에서 Dirty Read 발생

#### 실습 순서 및 결과

**Step 1 - 터미널 1:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
UPDATE accounts SET balance = 0 WHERE id = 1;
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 0 (커밋 안 함!)
```

**Step 2 - 터미널 2:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 0 (Dirty Read 발생! ❌)
-- 커밋되지 않은 데이터가 보임
```

**Step 3 - 터미널 1:**
```sql
ROLLBACK;
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 1000 (원래대로 복구)
```

**Step 4 - 터미널 2:**
```sql
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 1000 (롤백된 값!)
-- 터미널 2는 "존재하지 않았던 데이터"를 읽었음
COMMIT;
```

---

### 1-2. READ COMMITTED에서 Dirty Read 방지

**Step 1 - 터미널 1:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
UPDATE accounts SET balance = 0 WHERE id = 1;
-- 아직 COMMIT 안 함
```

**Step 2 - 터미널 2:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 1000 (커밋 전 값!)
-- Dirty Read 방지 ✅
```

**Step 3 - 터미널 1:**
```sql
COMMIT;
```

**Step 4 - 터미널 2:**
```sql
SELECT * FROM accounts WHERE id = 1;
-- 결과: balance = 0 (커밋 후 값!)
-- 이제 변경된 값이 보임
COMMIT;
```

---

### 1-3. 정답 정리

#### Dirty Read 비교표

| 단계 | 터미널 1 작업 | READ UNCOMMITTED<br>(터미널 2 읽은 값) | READ COMMITTED<br>(터미널 2 읽은 값) |
|------|--------------|--------------------------------------|-------------------------------------|
| 1 | UPDATE (커밋 안 함) | 0 (커밋 안 된 데이터) | 1000 (커밋된 데이터) |
| 2 | ROLLBACK | 1000 (롤백됨) | 1000 (변화 없음) |
| 결과 | - | Dirty Read 발생 ❌ | 방지 ✅ |

#### 핵심 개념

**Dirty Read란:**
- 커밋되지 않은 데이터를 읽는 현상
- 해당 트랜잭션이 롤백되면 "존재하지 않는 데이터"를 읽은 것이 됨
- 심각한 데이터 불일치 발생

**READ UNCOMMITTED:**
- 가장 낮은 격리 수준
- 성능은 좋지만 데이터 일관성 보장 안 됨
- 실무에서 거의 사용 안 함 (예외: 대략적인 통계)

**READ COMMITTED:**
- Dirty Read를 방지
- PostgreSQL, Oracle 기본값
- 커밋된 데이터만 읽음

---

## 미션 2: Non-Repeatable Read 재현하기 - 정답

### 2-1. READ COMMITTED에서 Non-Repeatable Read 발생

**Step 1 - 터미널 1:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = 100
```

**Step 2 - 터미널 2:**
```sql
START TRANSACTION;
UPDATE products SET stock = 50 WHERE id = 1;
COMMIT;
```

**Step 3 - 터미널 1:**
```sql
-- 같은 트랜잭션 내에서
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = 50 (변경된 값!)
-- Non-Repeatable Read 발생 ❌
COMMIT;
```

**문제점:**
- 같은 트랜잭션에서 같은 쿼리를 두 번 실행했는데 결과가 다름
- 트랜잭션 내 일관성이 깨짐

---

### 2-2. REPEATABLE READ에서 Non-Repeatable Read 방지

**데이터 초기화:**
```sql
UPDATE products SET stock = 100 WHERE id = 1;
```

**Step 1 - 터미널 1:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = 100
```

**Step 2 - 터미널 2:**
```sql
START TRANSACTION;
UPDATE products SET stock = 50 WHERE id = 1;
COMMIT;
```

**Step 3 - 터미널 1:**
```sql
-- 같은 트랜잭션 내에서
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = 100 (원래 값 유지!)
-- Non-Repeatable Read 방지 ✅

COMMIT;

-- 트랜잭션 종료 후
SELECT stock FROM products WHERE id = 1;
-- 결과: stock = 50 (이제 변경된 값 보임)
```

---

### 2-3. 정답 정리

#### Non-Repeatable Read 비교표

| 단계 | 터미널 1 작업 | READ COMMITTED | REPEATABLE READ |
|------|--------------|----------------|-----------------|
| 1차 조회 | SELECT stock | 100 | 100 |
| 중간 | 터미널 2가 UPDATE & COMMIT | - | - |
| 2차 조회 | SELECT stock (같은 트랜잭션) | 50 (변경됨) ❌ | 100 (유지됨) ✅ |
| 커밋 후 | SELECT stock (새 트랜잭션) | 50 | 50 |

#### 핵심 개념

**Non-Repeatable Read란:**
- 같은 트랜잭션 내에서 같은 쿼리의 결과가 달라지는 현상
- 다른 트랜잭션의 UPDATE/DELETE 때문에 발생

**REPEATABLE READ 동작 원리:**
- 트랜잭션 시작 시점의 스냅샷 유지 (MVCC)
- Undo Log를 통해 과거 버전 데이터 읽기
- 트랜잭션 내 일관성 보장

**MySQL이 REPEATABLE READ를 기본으로 사용하는 이유:**
1. 바이너리 로그 기반 복제(Replication) 때문
2. 트랜잭션 내 일관성이 중요
3. MVCC로 성능 저하 최소화

---

## 미션 3: Phantom Read 테스트하기 - 정답

### 3-1. REPEATABLE READ에서 Phantom Read 테스트

**Step 1 - 터미널 1:**
```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: count = 2

SELECT id, name, category FROM products WHERE category = 'phone';
-- iPhone 15, Galaxy S24
```

**Step 2 - 터미널 2:**
```sql
START TRANSACTION;
INSERT INTO products (name, category, stock, price)
VALUES ('iPhone 16', 'phone', 30, 1300000);
COMMIT;

SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: count = 3
```

**Step 3 - 터미널 1:**
```sql
-- 같은 트랜잭션 내에서
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- MySQL 결과: count = 2 (Phantom Read 없음!) ✅

SELECT id, name, category FROM products WHERE category = 'phone';
-- iPhone 15, Galaxy S24 (iPhone 16 안 보임)

COMMIT;

-- 커밋 후
SELECT COUNT(*) FROM products WHERE category = 'phone';
-- 결과: count = 3 (이제 보임)
```

---

### 3-2. MySQL의 특별한 점: Next-Key Lock

**실험: FOR UPDATE로 락 획득**

**터미널 1:**
```sql
START TRANSACTION;
SELECT * FROM products WHERE category = 'phone' FOR UPDATE;
-- 현재 phone 카테고리 행들에 락 + Gap Lock
```

**터미널 2:**
```sql
START TRANSACTION;
INSERT INTO products (name, category, stock, price)
VALUES ('Galaxy S25', 'phone', 40, 1100000);
-- 결과: 대기... (락 때문에 블록됨!)
```

**터미널 1:**
```sql
COMMIT;
-- 락 해제
```

**터미널 2:**
```sql
-- INSERT가 이제 실행됨
COMMIT;
```

---

### 3-3. 정답 정리

#### Phantom Read 비교표

| 동작 | 표준 SQL REPEATABLE READ | MySQL REPEATABLE READ |
|------|-------------------------|----------------------|
| 일반 SELECT | Phantom Read 발생 가능 | 발생 안 함 (스냅샷) |
| SELECT ... FOR UPDATE | - | Gap Lock으로 INSERT 차단 |
| 이유 | 락 기반 | MVCC + Next-Key Lock |

#### 핵심 개념

**Phantom Read란:**
- 같은 쿼리를 실행했는데 이전에 없던 "유령 행"이 나타나는 현상
- 다른 트랜잭션의 INSERT 때문에 발생

**MySQL REPEATABLE READ의 특별한 점:**
1. **일반 SELECT:** MVCC 스냅샷으로 Phantom Read 방지
2. **SELECT FOR UPDATE:** Next-Key Lock으로 INSERT까지 차단
3. **표준 SQL과 다름:** 표준은 Phantom Read 허용, MySQL은 방지

**Next-Key Lock:**
- Record Lock + Gap Lock
- 인덱스 레코드 + 그 사이 간격(Gap)까지 락
- Phantom Read 완벽 방지

**PostgreSQL과의 차이:**
- PostgreSQL 기본: READ COMMITTED (Phantom Read 발생)
- MySQL 기본: REPEATABLE READ (Phantom Read 방지)

---

## 미션 4: 실전 격리 수준 선택하기 - 정답

### 시나리오 A: 실시간 재고 관리 시스템

**정답: REPEATABLE READ (MySQL 기본값)**

#### 선택 이유:
1. **데이터 일관성:** 재고는 음수가 되면 안 되므로 트랜잭션 내 일관성 필요
2. **성능 균형:** MVCC로 읽기는 블록 안 되고, FOR UPDATE로 쓰기만 제어
3. **실전 검증:** 대부분의 이커머스가 사용하는 방식

#### 정답 코드:
```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

START TRANSACTION;

-- 재고 확인 및 락 획득
SELECT stock FROM products WHERE id = 1 FOR UPDATE;
-- 다른 트랜잭션은 이 행을 수정할 수 없음 (대기)

-- 재고가 충분한지 확인 후 감소
UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0;

-- ROW_COUNT()로 성공 여부 확인
SELECT ROW_COUNT(); -- 1이면 성공, 0이면 재고 부족

COMMIT;
```

#### 주의사항:
- **FOR UPDATE 필수:** 일반 SELECT는 다른 트랜잭션의 UPDATE를 막지 못함
- **WHERE stock > 0:** 조건부 UPDATE로 음수 방지
- **타임아웃 설정:** `innodb_lock_wait_timeout` 적절히 설정

---

### 시나리오 B: 일일 매출 통계 생성

**정답: READ UNCOMMITTED**

#### 선택 이유:
1. **성능 최우선:** 대량 데이터 집계에서 속도가 중요
2. **정확도 허용:** ±1% 오차 괜찮음 (통계 목적)
3. **읽기 전용:** 데이터 수정 없이 조회만 하므로 낮은 격리 수준 가능

#### 정답 코드:
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

-- 일일 매출 집계 (빠른 조회)
SELECT
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM orders
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at)
ORDER BY date DESC;

COMMIT;
```

#### 대안: READ COMMITTED
- 약간 더 정확한 통계가 필요하면 READ COMMITTED 사용
- 성능 차이가 크지 않다면 안전하게 READ COMMITTED 추천

---

### 시나리오 C: 회계 마감 처리

**정답: SERIALIZABLE**

#### 선택 이유:
1. **절대적 정확성:** 회계 데이터는 1원도 틀리면 안 됨
2. **순차 처리:** 마감은 보통 야간에 단독으로 실행
3. **검증 가능:** 마감 중 다른 트랜잭션 완전 차단

#### 정답 코드:
```sql
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

-- 1. 마감 대상 기간 데이터 조회
SELECT
    DATE_FORMAT(created_at, '%Y-%m') as month,
    SUM(amount) as total_amount,
    COUNT(*) as order_count
FROM orders
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2024-10'
GROUP BY month
INTO @month, @total_amount, @order_count;

-- 2. 검증: 개별 합계와 전체 합계 비교
SELECT SUM(amount) as verify_sum FROM orders
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2024-10'
HAVING verify_sum = @total_amount;
-- 일치하지 않으면 ROLLBACK

-- 3. 마감 데이터 저장
INSERT INTO accounting_summary (month, total_amount, order_count, closed_at)
VALUES (@month, @total_amount, @order_count, NOW());

-- 4. 마감 상태 업데이트
UPDATE orders
SET is_closed = 1
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2024-10';

COMMIT;
```

#### 주의사항:
- **야간 배치로 실행:** 다른 트랜잭션이 없는 시간대
- **타임아웃 주의:** SERIALIZABLE은 락 대기가 길어질 수 있음
- **검증 단계 필수:** 데이터 일관성 확인 후 커밋

---

### 시나리오별 비교 정리

| 시나리오 | 격리 수준 | 성능 | 안정성 | 핵심 이유 |
|---------|----------|------|--------|----------|
| A. 재고 관리 | REPEATABLE READ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 일관성 + 성능 균형 |
| B. 매출 통계 | READ UNCOMMITTED | ⭐⭐⭐⭐⭐ | ⭐⭐ | 속도 우선, 정확도 타협 |
| C. 회계 마감 | SERIALIZABLE | ⭐⭐ | ⭐⭐⭐⭐⭐ | 정확성 최우선 |

---

## 격리 수준 선택 가이드 (실무용)

### 1단계: 데이터 중요도 판단

```
질문: "이 데이터가 조금이라도 틀리면 큰 문제인가?"

예 → SERIALIZABLE 고려
대부분 괜찮음 → REPEATABLE READ
통계/근사치 → READ UNCOMMITTED/READ COMMITTED
```

### 2단계: 동시성 요구사항

```
질문: "동시에 여러 사용자가 접근하는가?"

많음 → REPEATABLE READ (MVCC 활용)
중간 → READ COMMITTED
거의 없음 → SERIALIZABLE 가능
```

### 3단계: 성능 요구사항

```
질문: "속도가 절대적으로 중요한가?"

매우 중요 → READ UNCOMMITTED (읽기 전용)
중요 → READ COMMITTED
보통 → REPEATABLE READ
상관없음 → SERIALIZABLE
```

---

## 실무 격리 수준 체크리스트

### ✅ REPEATABLE READ 사용 (MySQL 기본값)
- [ ] 금융 거래
- [ ] 재고 관리
- [ ] 포인트/마일리지 관리
- [ ] 일반적인 웹 애플리케이션
- [ ] 트랜잭션 내 일관성이 중요한 경우

### ✅ READ COMMITTED 사용
- [ ] PostgreSQL/Oracle 사용 시 (기본값)
- [ ] 높은 동시성 필요
- [ ] 쓰기 충돌이 적은 경우
- [ ] 일반 CRUD 작업

### ✅ READ UNCOMMITTED 사용 (신중히)
- [ ] 대량 데이터 집계 (통계)
- [ ] 정확도 1~5% 오차 허용
- [ ] 읽기 전용 쿼리
- [ ] 속도가 절대적으로 중요

### ✅ SERIALIZABLE 사용 (매우 신중히)
- [ ] 회계 마감
- [ ] 정산 작업
- [ ] 법적 기록
- [ ] 절대적 정확성 필요
- [ ] 야간 배치 작업

---

## 격리 수준별 문제 해결 패턴

### Dirty Read 문제

**증상:**
- 커밋 안 된 데이터가 보임
- 롤백 후 데이터 불일치

**해결:**
```sql
-- READ UNCOMMITTED → READ COMMITTED로 변경
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

---

### Non-Repeatable Read 문제

**증상:**
- 같은 트랜잭션에서 같은 쿼리 결과가 다름
- 다른 세션의 UPDATE가 즉시 반영됨

**해결:**
```sql
-- READ COMMITTED → REPEATABLE READ로 변경
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

---

### Phantom Read 문제

**증상:**
- 이전에 없던 행이 나타남
- 집계 쿼리 결과가 달라짐

**해결:**
```sql
-- MySQL REPEATABLE READ는 이미 방지
-- 또는 SERIALIZABLE 사용
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- 또는 FOR UPDATE로 Gap Lock
SELECT * FROM table WHERE condition FOR UPDATE;
```

---

### Lost Update 문제 (보너스)

**증상:**
- 두 트랜잭션의 업데이트 중 하나가 사라짐

**해결:**
```sql
-- FOR UPDATE로 배타적 락 획득
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

---

## 격리 수준과 성능 트레이드오프

### 성능 순서 (빠름 → 느림)
```
READ UNCOMMITTED
    ↓ (약간 느림)
READ COMMITTED
    ↓ (조금 느림)
REPEATABLE READ
    ↓ (많이 느림)
SERIALIZABLE
```

### 안정성 순서 (낮음 → 높음)
```
READ UNCOMMITTED (위험)
    ↓
READ COMMITTED
    ↓
REPEATABLE READ
    ↓
SERIALIZABLE (가장 안전)
```

### 동시성 순서 (높음 → 낮음)
```
READ UNCOMMITTED (동시 실행 많이 가능)
    ↓
READ COMMITTED
    ↓
REPEATABLE READ
    ↓
SERIALIZABLE (거의 순차 실행)
```

---

## MySQL vs PostgreSQL 기본값 차이

### MySQL: REPEATABLE READ

**이유:**
1. 바이너리 로그 기반 복제 (Replication)
2. MVCC로 성능 저하 최소화
3. Next-Key Lock으로 Phantom Read도 방지

**특징:**
- Phantom Read까지 방지 (표준과 다름)
- FOR UPDATE 시 Gap Lock 사용

---

### PostgreSQL: READ COMMITTED

**이유:**
1. 높은 동시성 지원
2. MVCC가 매우 효율적
3. Snapshot Isolation 지원

**특징:**
- Non-Repeatable Read 발생 가능
- SERIALIZABLE은 SSI(Serializable Snapshot Isolation) 사용

---

## 실전 팁

### 1. 기본값 그대로 사용하기
```sql
-- MySQL → REPEATABLE READ (기본값)
-- PostgreSQL → READ COMMITTED (기본값)

-- 대부분의 경우 기본값이 최적
-- 특별한 이유 없으면 변경 금지
```

### 2. 트랜잭션 단위로 설정
```sql
-- 전역 변경은 위험!
-- 특정 트랜잭션만 변경
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
-- ...
COMMIT;
```

### 3. 애플리케이션 레벨 제어
```java
// Spring Boot 예시
@Transactional(isolation = Isolation.REPEATABLE_READ)
public void processOrder(Long orderId) {
    // ...
}

@Transactional(isolation = Isolation.READ_UNCOMMITTED)
public Statistics getDailyStats() {
    // ...
}
```

### 4. 모니터링
```sql
-- 현재 실행 중인 트랜잭션 확인
SELECT * FROM information_schema.INNODB_TRX;

-- 락 대기 확인
SELECT * FROM information_schema.INNODB_LOCKS;

-- 락 대기 중인 트랜잭션
SELECT * FROM information_schema.INNODB_LOCK_WAITS;
```

---

## 추가 학습: MVCC (Multi-Version Concurrency Control)

### MVCC란?
- 읽기와 쓰기가 서로 블록하지 않는 동시성 제어 기법
- 각 행의 여러 버전을 유지
- Undo Log를 통해 과거 버전 읽기

### MVCC 확인하기
```sql
-- InnoDB 상태 확인
SHOW ENGINE INNODB STATUS\G

-- History list length 확인
-- 이 값이 크면 Undo Log가 많이 쌓인 것
-- → 오래된 트랜잭션이 있다는 의미

-- Undo Log 공간 확인
SELECT
    TABLE_NAME,
    DATA_LENGTH,
    DATA_FREE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'wild_learning';
```

### MVCC의 장점
- 읽기는 거의 블록 안 됨
- 높은 동시성
- REPEATABLE READ에서도 성능 좋음

### MVCC의 단점
- Undo Log 관리 필요
- 오래된 트랜잭션은 메모리/디스크 사용
- 스냅샷 유지 비용

---

## 다음 주차 예고: Week 6 - 페이지네이션 최적화

트랜잭션 격리 수준을 마스터했다면,
다음은 실전 성능 문제인 페이지네이션 최적화입니다!

**배울 내용:**
- OFFSET의 치명적인 문제
- Cursor 기반 페이지네이션
- No Offset 페이지네이션
- 대용량 데이터 조회 최적화

---

**완료 축하합니다!** 🎉

트랜잭션 격리 수준의 개념을 완벽하게 이해했습니다!
이제 동시성 버그를 예측하고 방지할 수 있습니다!

**다음 액션:**
1. [ ] ANSWER.md와 SOLUTION.md 비교
2. [ ] 틀린 부분 복습 (특히 MVCC)
3. [ ] 현재 프로젝트의 격리 수준 확인
4. [ ] 팀원들과 격리 수준 선택 기준 공유
5. [ ] Week 6 미션 시작

**핵심 요약:**
- READ UNCOMMITTED: 거의 안 씀
- READ COMMITTED: PostgreSQL/Oracle 기본
- REPEATABLE READ: MySQL 기본 (Phantom Read까지 방지)
- SERIALIZABLE: 절대적 정확성 필요할 때만

**실무 원칙:**
> "기본값을 믿어라. 특별한 이유 없으면 변경하지 마라."
