# Week 4 미션: 데드락 해결사 되기 🔒

> "서비스 멈추는 데드락, 이제는 내가 고친다"

---

## 📋 미션 개요

당신은 쇼핑몰 백엔드 개발자입니다.
최근 결제 프로세스에서 간헐적으로 데드락이 발생하여 트랜잭션이 실패하고 있습니다.

**문제 상황:**
- 동시에 여러 주문이 발생할 때 데드락 에러 발생
- 에러 로그: `ERROR 1213: Deadlock found when trying to get lock`
- 고객들의 결제 실패 불만 쇄도
- 원인을 모르겠고, 해결 방법도 막막함

**당신의 임무:**
데드락을 재현하고, 원인을 분석하고, 완전히 해결하세요!

---

## 🎯 미션 목표

### 미션 1: 데드락 재현 및 로그 분석 (필수)

**상황:**
두 명의 사용자가 동시에 계좌이체를 하는 상황입니다.

```sql
-- 사용자 A: 계좌1 → 계좌2로 이체
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- 사용자 B: 계좌2 → 계좌1로 이체 (동시 실행)
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 2;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;
```

**성공 기준:**
- [ ] 데드락을 실제로 발생시킴
- [ ] 에러 메시지 캡처
- [ ] `SHOW ENGINE INNODB STATUS`로 데드락 로그 확인
- [ ] 어떤 트랜잭션이 롤백되었는지 파악
- [ ] 왜 데드락이 발생했는지 원인 분석

---

### 미션 2: 데드락 해결 - 락 순서 통일 (필수)

**상황:**
재고 차감과 주문 생성이 동시에 일어나는 상황입니다.

```sql
-- 트랜잭션 A: 상품 1, 2 재고 차감
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;
UPDATE products SET stock = stock - 1 WHERE id = 2;
COMMIT;

-- 트랜잭션 B: 상품 2, 1 재고 차감 (다른 순서!)
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;
```

**성공 기준:**
- [ ] 위 쿼리로 데드락 발생 확인
- [ ] 락 순서를 통일하여 해결
- [ ] 동시 실행 테스트 (데드락 미발생 확인)
- [ ] EXPLAIN으로 실행 계획 확인

**힌트:**
- 여러 행을 업데이트할 때 항상 같은 순서로!
- ORDER BY 절을 활용하세요

---

### 미션 3: 낙관적 락으로 충돌 회피 (필수)

**상황:**
게시글 조회수를 증가시킬 때 락 없이 안전하게 처리하고 싶습니다.

**비관적 락 방식 (현재):**
```sql
START TRANSACTION;
SELECT view_count FROM posts WHERE id = 1 FOR UPDATE;
UPDATE posts SET view_count = view_count + 1 WHERE id = 1;
COMMIT;
```

**낙관적 락 방식 (목표):**
```sql
-- version 컬럼 추가
ALTER TABLE posts ADD COLUMN version INT DEFAULT 0;

-- 낙관적 락 구현
-- 1. 읽기
SELECT id, view_count, version FROM posts WHERE id = 1;

-- 2. 업데이트 (버전 확인)
UPDATE posts
SET view_count = ?, version = version + 1
WHERE id = 1 AND version = ?;

-- 3. 영향받은 행 확인 → 0이면 재시도
```

**성공 기준:**
- [ ] posts 테이블에 version 컬럼 추가
- [ ] 낙관적 락 로직 구현
- [ ] 충돌 상황 재현 (2개 트랜잭션 동시 실행)
- [ ] 재시도 로직 테스트
- [ ] 비관적 락과 성능 비교

---

### 미션 4: 트랜잭션 타임아웃 설정 (필수)

**상황:**
락 대기로 인한 무한 대기를 방지하고 싶습니다.

**성공 기준:**
- [ ] 현재 타임아웃 설정 확인
  ```sql
  SHOW VARIABLES LIKE 'innodb_lock_wait_timeout';
  ```
- [ ] 타임아웃 5초로 설정
  ```sql
  SET innodb_lock_wait_timeout = 5;
  ```
- [ ] 락 대기 상황 재현
  ```sql
  -- 터미널 1
  START TRANSACTION;
  UPDATE products SET stock = stock - 1 WHERE id = 1;
  -- COMMIT 안 함 (10초 대기)

  -- 터미널 2
  UPDATE products SET stock = stock - 1 WHERE id = 1;
  -- 5초 후 타임아웃 에러 발생 확인
  ```
- [ ] 타임아웃 에러 메시지 캡처
- [ ] 적절한 타임아웃 값 결정 (실무 상황 고려)

---

## 💡 제공되는 환경

### 테이블 구조

**accounts 테이블:**
```sql
CREATE TABLE accounts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    balance DECIMAL(10,2) DEFAULT 0
);

INSERT INTO accounts (user_id, balance) VALUES
(1, 1000.00),
(2, 1000.00),
(3, 1000.00);
```

**products 테이블:**
```sql
-- 이미 존재 (week1에서 생성)
-- id, name, stock, created_at
```

**posts 테이블:**
```sql
CREATE TABLE posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200),
    view_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO posts (title) VALUES
('첫 번째 게시글'),
('두 번째 게시글'),
('세 번째 게시글');
```

### 터미널 2개 준비 방법

**방법 1: MySQL Workbench**
- Query Tab 2개 열기
- 각각 별도 세션으로 동작

**방법 2: CLI**
```bash
# 터미널 1
scripts\connect.bat

# 터미널 2 (새 창)
scripts\connect.bat
```

**방법 3: Docker Exec**
```bash
# 터미널 1
docker exec -it wild-learning-db-mysql-1 mysql -uroot -proot123 testdb

# 터미널 2
docker exec -it wild-learning-db-mysql-1 mysql -uroot -proot123 testdb
```

---

## 🔍 참고: 데드락 로그 읽는 법

```sql
SHOW ENGINE INNODB STATUS\G

-- 관련 섹션
------------------------
LATEST DETECTED DEADLOCK
------------------------
```

**로그 분석 포인트:**

```
*** (1) TRANSACTION:
TRANSACTION 1234, ACTIVE 5 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 10, query id 100 localhost root updating
UPDATE accounts SET balance = balance - 100 WHERE id = 1

*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2 page no 3 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 1234 lock_mode X locks rec but not gap waiting

*** (2) TRANSACTION:
TRANSACTION 5678, ACTIVE 3 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 11, query id 101 localhost root updating
UPDATE accounts SET balance = balance - 100 WHERE id = 2

*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 2 page no 3 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 5678 lock_mode X locks rec but not gap

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2 page no 3 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 5678 lock_mode X locks rec but not gap waiting

*** WE ROLL BACK TRANSACTION (2)
```

**해석:**
1. Transaction (1)이 id=1 락 보유, id=2 대기
2. Transaction (2)가 id=2 락 보유, id=1 대기
3. 순환 대기 발생 → Transaction (2) 롤백

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 데드락이 왜 발생하나?</summary>

**데드락 4가지 조건 (모두 만족 시 발생):**
1. **상호 배제**: 자원을 독점적으로 사용
2. **점유와 대기**: 자원을 가진 상태에서 다른 자원 대기
3. **비선점**: 다른 트랜잭션의 자원을 강제로 뺏을 수 없음
4. **순환 대기**: A → B, B → A로 대기 (Circular Wait)

**해결 방법:**
- 순환 대기를 깨면 됨! → 락 순서 통일

</details>

<details>
<summary>힌트 2: 락 순서를 통일하는 방법</summary>

**나쁜 예:**
```sql
-- 트랜잭션마다 다른 순서
UPDATE ... WHERE id IN (3, 1, 2);  -- 3 → 1 → 2
UPDATE ... WHERE id IN (1, 3, 2);  -- 1 → 3 → 2
```

**좋은 예:**
```sql
-- 항상 ID 오름차순
UPDATE ... WHERE id IN (3, 1, 2) ORDER BY id;  -- 1 → 2 → 3
UPDATE ... WHERE id IN (1, 3, 2) ORDER BY id;  -- 1 → 2 → 3
```

**핵심:** ORDER BY로 순서 강제!

</details>

<details>
<summary>힌트 3: 낙관적 락 vs 비관적 락 선택</summary>

**비관적 락 (FOR UPDATE):**
- 장점: 확실한 동시성 제어
- 단점: 대기 시간 발생
- 사용: 충돌이 자주 발생 (재고 차감, 결제)

**낙관적 락 (version):**
- 장점: 락 없음, 빠름
- 단점: 충돌 시 재시도 필요
- 사용: 충돌이 드문 경우 (게시글 수정, 조회수)

**선택 기준:**
```
충돌 빈도 높음 + 데이터 중요 → 비관적 락
충돌 빈도 낮음 + 빠른 응답 → 낙관적 락
```

</details>

<details>
<summary>힌트 4: 실전 데드락 대응 순서</summary>

1. **에러 로그 확인**
   - 데드락 에러 메시지 캡처
   - 어떤 쿼리에서 발생했는지 파악

2. **데드락 로그 분석**
   ```sql
   SHOW ENGINE INNODB STATUS\G
   ```
   - 어떤 트랜잭션들이 충돌했는지
   - 어떤 순서로 락을 획득했는지

3. **원인 파악**
   - 락 순서가 다른가?
   - 트랜잭션이 너무 긴가?
   - 인덱스가 없어서 많은 행 락?

4. **해결 방법 적용**
   - 락 순서 통일
   - 트랜잭션 최소화
   - 인덱스 추가

5. **테스트 및 검증**
   - 동시 실행 테스트
   - 데드락 재발 확인

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 모든 SQL 쿼리와 결과를 기록하세요
3. 데드락 로그를 붙여넣고 분석하세요
4. Before/After 비교표를 작성하세요
5. 실무 적용 계획을 정리하세요

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 20분 (데드락 재현 및 분석)
- 미션 2: 15분 (락 순서 통일)
- 미션 3: 15분 (낙관적 락 구현)
- 미션 4: 10분 (타임아웃 설정)
- **총 60분**

---

## 🎓 선택 사항: 고급 미션

### 보너스 미션 1: 인덱스 없을 때 락 범위

```sql
-- products 테이블에서 name 컬럼에 인덱스 없음
UPDATE products SET stock = stock - 1 WHERE name = 'iPhone';

-- Q. 몇 개 행에 락이 걸릴까?
-- A. 확인해보세요!
```

**실험:**
- [ ] 인덱스 없이 UPDATE 실행
- [ ] 다른 터미널에서 다른 상품 UPDATE 시도
- [ ] 블록되는지 확인
- [ ] 인덱스 추가 후 재시도

---

### 보너스 미션 2: Gap Lock 이해하기

```sql
-- 범위 조건으로 업데이트
UPDATE products SET stock = stock - 1
WHERE id BETWEEN 10 AND 20;

-- Q. id=15인 행이 없다면, 그 사이 간격(gap)에도 락이 걸릴까?
```

**실험:**
- [ ] 범위 UPDATE 실행
- [ ] 다른 터미널에서 해당 범위에 INSERT 시도
- [ ] 블록되는지 확인

---

## 📚 참고 자료

**MySQL 공식 문서:**
- [InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)
- [Deadlock Detection](https://dev.mysql.com/doc/refman/8.0/en/innodb-deadlock-detection.html)

**추천 읽을거리:**
- Real MySQL 8.0 - 5장 트랜잭션과 잠금

---

**난이도:** ⭐⭐⭐ 중상
**즉시 적용:** 상황 발생 시
**ROI:** 높음 (서비스 안정성 직결)

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] 터미널 2개 준비
- [ ] 테이블 생성 완료

**준비되셨나요? 데드락과의 전쟁 시작!** 🚀
