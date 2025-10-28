# Week 5 미션: 트랜잭션 격리 수준 마스터하기 🎯

> "동시성 버그를 예측하고 방지하라"

---

## 📋 미션 개요

당신은 전자상거래 플랫폼의 백엔드 개발자입니다.
최근 동시성 문제로 인한 버그가 발생하고 있습니다:
- 재고가 마이너스로 떨어지는 문제
- 같은 트랜잭션에서 읽은 값이 달라지는 문제
- 커밋되지 않은 데이터가 보이는 문제

**문제 상황:**
- 여러 사용자가 동시에 주문/결제 진행
- 트랜잭션 격리 수준을 제대로 이해하지 못함
- 데이터 일관성 문제 발생

**당신의 임무:**
4가지 격리 수준을 실습하고, **각 상황에 맞는 격리 수준을 선택**할 수 있어야 합니다!

---

## 🎯 미션 목표

### 미션 1: Dirty Read 재현하기 (필수)

**상황:**
은행 계좌 이체 시스템에서 커밋되지 않은 데이터가 보이는 문제를 재현하세요.

**시나리오:**
```
트랜잭션 A: 계좌 잔액을 1,000원에서 0원으로 변경 (아직 커밋 안 함)
트랜잭션 B: 계좌 잔액을 조회 → ?원이 보일까?
트랜잭션 A: ROLLBACK
```

**성공 기준:**
- [ ] READ UNCOMMITTED 격리 수준 설정
- [ ] Dirty Read 발생 재현
- [ ] READ COMMITTED로 변경 후 Dirty Read 방지 확인
- [ ] Before/After 비교표 작성

**힌트:**
- 두 개의 터미널(세션) 필요
- `START TRANSACTION` 사용
- `ROLLBACK` 전후 비교

---

### 미션 2: Non-Repeatable Read 재현하기 (필수)

**상황:**
주문 처리 중 같은 트랜잭션 내에서 같은 쿼리를 두 번 실행했는데 결과가 다릅니다.

**시나리오:**
```
트랜잭션 A: 상품 재고 조회 → 100개
트랜잭션 B: 상품 재고를 50개로 변경 후 커밋
트랜잭션 A: 같은 상품 재고 다시 조회 → ?개?
```

**성공 기준:**
- [ ] READ COMMITTED에서 Non-Repeatable Read 발생 재현
- [ ] REPEATABLE READ로 변경 후 문제 해결 확인
- [ ] 각 격리 수준별 결과 비교
- [ ] 왜 MySQL 기본값이 REPEATABLE READ인지 이해

---

### 미션 3: Phantom Read 테스트하기 (필수)

**상황:**
카테고리별 상품 수를 집계하는 중에 새로운 상품이 추가되면 어떻게 될까?

**시나리오:**
```
트랜잭션 A: SELECT COUNT(*) FROM products WHERE category = 'phone' → 10개
트랜잭션 B: INSERT INTO products (category, name) VALUES ('phone', 'iPhone 16')
트랜잭션 A: SELECT COUNT(*) 다시 조회 → ?개?
```

**성공 기준:**
- [ ] REPEATABLE READ에서 Phantom Read 테스트
- [ ] MySQL이 Phantom Read를 방지하는지 확인
- [ ] PostgreSQL과의 차이점 이해
- [ ] Next-Key Lock 개념 파악

---

### 미션 4: 실전 격리 수준 선택하기 (필수)

**상황:**
다음 3가지 시나리오에서 적절한 격리 수준을 선택하세요.

**시나리오 A: 실시간 재고 관리 시스템**
- 여러 사용자가 동시에 상품 구매
- 재고가 음수가 되면 안 됨
- 성능도 중요함
- **권장 격리 수준: ?**

**시나리오 B: 일일 매출 통계 생성**
- 대량 데이터 조회 (읽기 전용)
- 정확도는 ±1% 오차 허용
- 빠른 조회가 최우선
- **권장 격리 수준: ?**

**시나리오 C: 회계 마감 처리**
- 월말 회계 마감
- 절대적인 정확성 필요
- 처리 시간은 많이 걸려도 됨
- **권장 격리 수준: ?**

**성공 기준:**
- [ ] 각 시나리오별 격리 수준 선택 및 이유 작성
- [ ] 선택한 격리 수준으로 테스트 쿼리 작성
- [ ] 성능과 안정성 트레이드오프 분석

---

## 💡 제공되는 환경

### 테스트용 테이블

**accounts 테이블 (은행 계좌):**
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
```

**products 테이블 (상품):**
```sql
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    category VARCHAR(50),
    stock INT,
    price DECIMAL(10,2)
);

INSERT INTO products (name, category, stock, price) VALUES
('iPhone 15', 'phone', 100, 1200000),
('Galaxy S24', 'phone', 80, 1000000),
('iPad Pro', 'tablet', 50, 1500000);
```

**orders 테이블 (주문):**
```sql
-- 이미 존재 (100만 건)
-- user_id, status, created_at, amount
```

---

## 🔍 참고: 격리 수준 설정 방법

### 현재 격리 수준 확인
```sql
-- 전역 격리 수준
SELECT @@GLOBAL.transaction_isolation;

-- 현재 세션 격리 수준
SELECT @@transaction_isolation;
```

### 격리 수준 변경
```sql
-- 현재 세션만 변경
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- 다음 트랜잭션부터 적용
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

### 트랜잭션 제어
```sql
-- 트랜잭션 시작
START TRANSACTION;

-- 커밋
COMMIT;

-- 롤백
ROLLBACK;
```

---

## 🔬 실습 가이드

### 터미널 2개 준비
미션 1~3은 **동시에 실행되는 2개의 트랜잭션**을 시뮬레이션합니다.

**방법 1: MySQL 클라이언트 2개 실행**
```bash
# 터미널 1
docker exec -it wild-learning-mysql mysql -uroot -proot123 wild_learning

# 터미널 2 (새 터미널)
docker exec -it wild-learning-mysql mysql -uroot -proot123 wild_learning
```

**방법 2: IDE에서 2개 쿼리 콘솔 열기**
- IntelliJ/DataGrip: 쿼리 콘솔 2개 열기
- phpMyAdmin: 2개 탭 열기

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 격리 수준과 문제의 관계</summary>

| 격리 수준 | Dirty Read | Non-Repeatable Read | Phantom Read |
|-----------|------------|---------------------|--------------|
| READ UNCOMMITTED | 발생 ❌ | 발생 ❌ | 발생 ❌ |
| READ COMMITTED | 방지 ✅ | 발생 ❌ | 발생 ❌ |
| REPEATABLE READ | 방지 ✅ | 방지 ✅ | MySQL은 방지 ✅ |
| SERIALIZABLE | 방지 ✅ | 방지 ✅ | 방지 ✅ |

</details>

<details>
<summary>힌트 2: 실무 격리 수준 선택 기준</summary>

**READ UNCOMMITTED:**
- 거의 사용 안 함
- 예외: 대략적인 통계 (정확도 불필요)

**READ COMMITTED:**
- 일반적인 웹 애플리케이션
- PostgreSQL, Oracle 기본값
- 성능과 안정성 균형

**REPEATABLE READ:**
- MySQL 기본값
- 금융 거래, 재고 관리
- 트랜잭션 내 일관성 보장

**SERIALIZABLE:**
- 절대적 일관성 필요
- 회계 마감, 정산 작업
- 성능은 희생

</details>

<details>
<summary>힌트 3: MySQL의 특별한 점</summary>

**MySQL의 REPEATABLE READ는 특별합니다:**
- 표준 SQL: Phantom Read 발생 가능
- MySQL: Next-Key Lock으로 Phantom Read도 방지
- InnoDB 엔진의 특별한 기능

**PostgreSQL과의 차이:**
- PostgreSQL 기본: READ COMMITTED
- MySQL 기본: REPEATABLE READ
- 이유: 역사적 배경과 복제 메커니즘

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 각 미션별로 실행한 SQL과 결과를 기록하세요
3. 터미널 1, 터미널 2를 명확히 구분해서 작성하세요
4. 시간 순서대로 단계별로 기록하세요
5. 결과 비교표를 작성하세요

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 15분
- 미션 2: 15분
- 미션 3: 15분
- 미션 4: 15분
- **총 60분**

---

## 🎓 이론 학습

미션 수행 전 또는 막힐 때 참고하세요:
- `docs/week5-transaction-isolation.md` - 격리 수준 상세 가이드

---

## ⚠️ 주의사항

### 실습 시 주의할 점
1. **반드시 2개의 세션 사용**
   - 같은 세션에서는 동시성 테스트 불가능

2. **트랜잭션 시작 잊지 말기**
   - `START TRANSACTION` 없이 실행하면 자동 커밋됨

3. **격리 수준 확인**
   - 각 테스트 전에 `SELECT @@transaction_isolation;` 확인

4. **롤백 잊지 말기**
   - 테스트 후 `ROLLBACK` 또는 `COMMIT` 필수

### 데이터 초기화
테스트 후 데이터를 원래대로 되돌리려면:
```sql
-- accounts 테이블 초기화
TRUNCATE accounts;
INSERT INTO accounts VALUES
(1, 'Alice', 1000),
(2, 'Bob', 2000),
(3, 'Charlie', 1500);

-- products 테이블 초기화
DELETE FROM products WHERE id > 3;
UPDATE products SET stock = CASE id
    WHEN 1 THEN 100
    WHEN 2 THEN 80
    WHEN 3 THEN 50
END;
```

---

## 🧪 추가 실험 (선택사항)

시간이 남으면 다음을 실험해보세요:

### 실험 1: 격리 수준별 성능 비교
```sql
-- 동일한 쿼리를 각 격리 수준에서 100번 실행
-- 평균 실행 시간 비교
```

### 실험 2: 데드락 발생시키기
```sql
-- 두 트랜잭션이 서로 다른 순서로 락을 획득하면?
-- Week 4 내용 복습
```

### 실험 3: MVCC 확인하기
```sql
-- REPEATABLE READ에서 undo log를 어떻게 사용하는지
-- SHOW ENGINE INNODB STATUS로 확인
```

---

## 📚 참고 자료

- MySQL 공식 문서: [Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html)
- [MVCC (Multi-Version Concurrency Control)](https://dev.mysql.com/doc/refman/8.0/en/innodb-multi-versioning.html)

---

**난이도:** ⭐⭐⭐ 중상
**즉시 적용:** △ (개념 이해용)
**ROI:** 중간 (버그 예방)

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] 터미널 2개 준비 완료
- [ ] 격리 수준 개념 이해 (간단히)

**준비되셨나요? 동시성의 세계로!** 🚀

**팁:** 처음엔 혼란스러울 수 있습니다. 각 미션을 천천히, 단계별로 따라가세요!
