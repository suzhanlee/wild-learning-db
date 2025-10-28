# Week 4 답안: 데드락 해결사

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: 데드락 재현 및 로그 분석

### 1-1. 환경 준비

#### 테이블 생성
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

-- 데이터 확인
SELECT * FROM accounts;
```

**결과:**
```
-- (여기에 결과 붙여넣기)
```

---

### 1-2. 데드락 재현

#### 터미널 1 - 트랜잭션 A
```sql
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- (여기서 대기 - 아직 COMMIT 안 함)

-- 이제 두 번째 UPDATE 실행
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

**실행 시간:**
- 첫 번째 UPDATE: _____ms
- 두 번째 UPDATE: _____ms (또는 대기 중)

---

#### 터미널 2 - 트랜잭션 B
```sql
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 2;
-- (여기서 대기 - 아직 COMMIT 안 함)

-- 이제 두 번째 UPDATE 실행
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
-- 데드락 발생!
```

**에러 메시지:**
```
-- (여기에 에러 메시지 붙여넣기)
ERROR _____ (_____): _____
```

**데드락 발생 여부:** [ ] 발생 / [ ] 미발생

---

### 1-3. 데드락 로그 분석

```sql
SHOW ENGINE INNODB STATUS\G
```

**LATEST DETECTED DEADLOCK 섹션:**
```
-- (여기에 데드락 로그 전체 붙여넣기)






```

---

### 1-4. 원인 분석

**트랜잭션 A:**
- 획득한 락: id = _____
- 대기 중인 락: id = _____

**트랜잭션 B:**
- 획득한 락: id = _____
- 대기 중인 락: id = _____

**데드락 발생 이유:**
```
1. 트랜잭션 A가 _____
2. 트랜잭션 B가 _____
3. 서로 _____
→ 순환 대기 발생!
```

**롤백된 트랜잭션:** _____

**왜 이 트랜잭션이 롤백되었나?**
```


```

---

## 미션 2: 데드락 해결 - 락 순서 통일

### 2-1. 현재 상황 (데드락 발생)

```sql
-- 터미널 1
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;
UPDATE products SET stock = stock - 1 WHERE id = 2;
COMMIT;

-- 터미널 2 (동시 실행)
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE products SET stock = stock - 1 WHERE id = 1;
COMMIT;
```

**데드락 발생:** [ ] Yes / [ ] No

**에러 메시지:**
```


```

---

### 2-2. 해결 방법 1: 락 순서 통일

#### 개선된 쿼리
```sql
-- 터미널 1
START TRANSACTION;
UPDATE products SET stock = stock - 1
WHERE id IN (1, 2)
ORDER BY id;  -- 항상 ID 순서로!
COMMIT;

-- 터미널 2
START TRANSACTION;
UPDATE products SET stock = stock - 1
WHERE id IN (2, 1)  -- 순서가 달라도
ORDER BY id;  -- ORDER BY로 강제!
COMMIT;
```

**동시 실행 결과:**
- 트랜잭션 1: _____
- 트랜잭션 2: _____
- 데드락 발생: [ ] Yes / [ ] No

---

### 2-3. 해결 방법 2: 하나의 쿼리로 통합

```sql
-- 여러 UPDATE 대신 한 번에
UPDATE products SET stock = stock - 1
WHERE id IN (1, 2)
ORDER BY id;
```

**장점:**
1.
2.
3.

---

### 2-4. EXPLAIN 분석

```sql
EXPLAIN UPDATE products SET stock = stock - 1
WHERE id IN (1, 2)
ORDER BY id;
```

**결과:**
| id | select_type | table | type | key | rows | Extra |
|----|-------------|-------|------|-----|------|-------|
|    |             |       |      |     |      |       |

**분석:**
- 사용된 인덱스: _____
- 락이 걸리는 순서: _____

---

## 미션 3: 낙관적 락으로 충돌 회피

### 3-1. 테이블 준비

```sql
-- posts 테이블 생성
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

-- version 컬럼 추가
ALTER TABLE posts ADD COLUMN version INT DEFAULT 0;

-- 확인
SELECT * FROM posts;
```

---

### 3-2. 비관적 락 방식 (기존)

```sql
START TRANSACTION;
SELECT view_count FROM posts WHERE id = 1 FOR UPDATE;
-- 조회수: _____

UPDATE posts SET view_count = view_count + 1 WHERE id = 1;
COMMIT;

-- 실행 시간: _____ms
```

**동시 실행 테스트:**
- 터미널 1: START TRANSACTION → SELECT ... FOR UPDATE
- 터미널 2: SELECT ... FOR UPDATE 시도
- 결과: _____

---

### 3-3. 낙관적 락 방식 (개선)

#### 구현 로직
```sql
-- 1단계: 읽기
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count = _____, version = _____

-- 2단계: 업데이트 (버전 확인)
UPDATE posts
SET view_count = _____, version = version + 1
WHERE id = 1 AND version = _____;

-- 3단계: 영향받은 행 확인
-- affected_rows = _____ (1이면 성공, 0이면 실패)
```

---

### 3-4. 충돌 상황 재현

**시나리오:** 두 트랜잭션이 동시에 조회수 증가

```sql
-- 터미널 1
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count=0, version=0

UPDATE posts
SET view_count = 1, version = 1
WHERE id = 1 AND version = 0;
-- 결과: _____

-- 터미널 2 (동시 실행)
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count=0, version=0 (같은 값!)

UPDATE posts
SET view_count = 1, version = 1
WHERE id = 1 AND version = 0;
-- 결과: _____ (affected_rows = _____)
```

**터미널 2 결과:**
- affected_rows = _____
- 성공 여부: [ ] 성공 / [ ] 실패

**실패 시 재시도:**
```sql
-- 다시 읽기
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count=_____, version=_____

-- 다시 업데이트
UPDATE posts
SET view_count = _____, version = _____
WHERE id = 1 AND version = _____;
```

---

### 3-5. 성능 비교

| 항목 | 비관적 락 | 낙관적 락 | 차이 |
|------|-----------|-----------|------|
| 락 대기 시간 | _____ms | _____ms | - |
| 충돌 시 처리 | 대기 | 재시도 | - |
| 동시 실행 (10회) | _____ms | _____ms | - |

**결론:**
```
- 낙관적 락이 _____% 빠름
- 충돌이 _____할 때 유리
- 재시도 로직 구현 필요
```

---

## 미션 4: 트랜잭션 타임아웃 설정

### 4-1. 현재 설정 확인

```sql
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout';
```

**결과:**
```
Variable_name              | Value
innodb_lock_wait_timeout   | _____
```

**기본값 의미:**
- _____ 초 동안 락 대기
- 타임아웃 시 에러 발생

---

### 4-2. 타임아웃 설정

```sql
-- 세션 레벨에서 5초로 변경
SET innodb_lock_wait_timeout = 5;

-- 확인
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout';
```

---

### 4-3. 타임아웃 테스트

#### 터미널 1 - 락 보유
```sql
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;
-- COMMIT 안 함 (10초 대기)

-- (10초 후)
COMMIT;
```

---

#### 터미널 2 - 타임아웃 설정 후 대기
```sql
SET innodb_lock_wait_timeout = 5;

-- 락 획득 시도
UPDATE products SET stock = stock - 1 WHERE id = 1;
-- 5초 후 에러 발생 예상
```

**에러 메시지:**
```
ERROR _____ (_____): _____
```

**실제 대기 시간:** _____초

---

### 4-4. 적절한 타임아웃 값 결정

**실무 시나리오별 권장값:**

| 시나리오 | 타임아웃 | 이유 |
|---------|---------|------|
| API 응답 | ___초 | 사용자 대기 시간 고려 |
| 배치 작업 | ___초 | 긴 작업 허용 |
| 결제 처리 | ___초 | 빠른 실패 필요 |

**내가 선택한 값:** _____초

**이유:**
```


```

---

## 학습 정리

### 배운 핵심 개념 5가지
1. **데드락 발생 조건:**
2. **데드락 해결 방법:**
3. **락 순서 통일:**
4. **낙관적 vs 비관적 락:**
5. **타임아웃 설정:**

---

### 데드락 대응 체크리스트 (내가 정리한 기준)

**발생 시:**
- [ ] 에러 로그 확인
- [ ] `SHOW ENGINE INNODB STATUS` 실행
- [ ] 충돌한 트랜잭션 파악
- [ ] 락 순서 확인
- [ ] 원인 분석

**해결:**
- [ ] 락 순서 통일 (ORDER BY)
- [ ] 트랜잭션 최소화
- [ ] 인덱스 확인
- [ ] 타임아웃 설정
- [ ] 재시도 로직 (낙관적 락)

**예방:**
- [ ] 복잡한 트랜잭션 리뷰
- [ ] 락 순서 문서화
- [ ] 모니터링 설정
- [ ] 로드 테스트

---

### 락 전략 선택 가이드 (암기할 것!)

```
낙관적 락 사용 시기:
✓ 충돌이 드묾 (조회수, 좋아요)
✓ 빠른 응답 필요
✓ 읽기가 많음
✗ 재시도 가능

비관적 락 사용 시기:
✓ 충돌이 빈번 (재고, 결제)
✓ 데이터 정합성 중요
✓ 쓰기가 많음
✗ 대기 시간 허용
```

---

## 실무 적용 계획

### 즉시 적용할 부분

**현재 회사/프로젝트:**

**확인할 쿼리 1: 재고 차감**
```sql
-- Before (데드락 위험)




-- After (락 순서 통일)




-- 예상 효과:
```

---

**확인할 쿼리 2: 포인트 차감**
```sql
-- Before




-- After




-- 예상 효과:
```

---

### 팀 공유 내용

**데드락 대응 가이드:**
1.
2.
3.

**코드 리뷰 체크 포인트:**
- [ ] 여러 행 업데이트 시 ORDER BY 확인
- [ ] 트랜잭션 범위 최소화 확인
- [ ] 락 전략 (낙관적/비관적) 적절성
- [ ] 타임아웃 설정 확인

---

## 트러블슈팅

### 겪은 문제 1: 데드락이 재현 안 됨

**문제:**
```


```

**시도한 방법:**
```


```

**해결:**
```


```

**배운 점:**
```


```

---

### 겪은 문제 2: 낙관적 락 재시도 로직

**문제:**
```


```

**해결:**
```


```

---

## 보너스 미션 (선택)

### 보너스 1: 인덱스 없을 때 락 범위

```sql
-- 인덱스 확인
SHOW INDEX FROM products;

-- name 컬럼에 인덱스 없이 업데이트
UPDATE products SET stock = stock - 1 WHERE name = 'iPhone';

-- 다른 터미널에서 다른 상품 업데이트
UPDATE products SET stock = stock - 1 WHERE name = 'Galaxy';
-- 블록됨? _____
```

**결과:**
```


```

**인덱스 추가 후:**
```sql
CREATE INDEX idx_name ON products(name);

-- 재시도
-- 결과: _____
```

---

### 보너스 2: Gap Lock 실험

```sql
-- 범위 업데이트
UPDATE products SET stock = stock - 1
WHERE id BETWEEN 10 AND 20;

-- 다른 터미널에서 INSERT
INSERT INTO products (id, name, stock) VALUES (15, 'New Product', 100);
-- 블록됨? _____
```

**결과:**
```


```

**Gap Lock 이해:**
```


```

---

## 추가 실험 (선택)

### 실험 1: 데드락 모니터링

```sql
-- InnoDB 락 정보
SELECT * FROM information_schema.INNODB_LOCKS;

-- 대기 중인 트랜잭션
SELECT * FROM information_schema.INNODB_LOCK_WAITS;

-- 트랜잭션 목록
SELECT * FROM information_schema.INNODB_TRX;
```

**결과:**
```


```

---

### 실험 2: 다양한 격리 수준에서 데드락

```sql
-- READ COMMITTED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 데드락 발생: _____

-- REPEATABLE READ (기본)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- 데드락 발생: _____

-- SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 데드락 발생: _____
```

**차이점:**
```


```

---

## 다음 액션

### 실무 적용 기한
- [ ] 이번 주 내: 현재 프로젝트 데드락 위험 쿼리 찾기
- [ ] 다음 주 내: 락 순서 통일 적용
- [ ] 2주 내: 모니터링 설정

### 추가 학습 필요
- [ ] Spring @Transactional 락 옵션
- [ ] JPA 낙관적/비관적 락
- [ ] Redis 분산 락

### 팀 회고 공유
```
데드락 경험:


해결 과정:


배운 점:


```

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**어려웠던 점:**
1.
2.
3.

**가장 유용했던 개념:**
1.
2.
3.

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
