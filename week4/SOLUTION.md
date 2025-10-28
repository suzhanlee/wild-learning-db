# Week 4 정답: 데드락 해결사

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: 데드락 재현 및 로그 분석 - 정답

### 1-1. 데드락 재현 성공

**터미널 1 (트랜잭션 A):**
```sql
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- ✓ 성공: id=1 행에 X-Lock 획득
-- (여기서 5초 대기)

UPDATE accounts SET balance = balance + 100 WHERE id = 2;
-- ⏳ 대기: id=2는 트랜잭션 B가 락 보유 중
-- → 데드락 감지!
COMMIT;
```

**터미널 2 (트랜잭션 B):**
```sql
START TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 2;
-- ✓ 성공: id=2 행에 X-Lock 획득
-- (즉시 실행)

UPDATE accounts SET balance = balance + 100 WHERE id = 1;
-- ❌ ERROR 1213: Deadlock found when trying to get lock
-- → MySQL이 이 트랜잭션을 롤백!
```

**에러 메시지:**
```
ERROR 1213 (40001): Deadlock found when trying to get lock;
try restarting transaction
```

---

### 1-2. 데드락 로그 분석

```sql
SHOW ENGINE INNODB STATUS\G
```

**중요 섹션:**

```
------------------------
LATEST DETECTED DEADLOCK
------------------------
2025-10-23 10:30:45 0x7f8b2c001700
*** (1) TRANSACTION:
TRANSACTION 421394771828736, ACTIVE 8 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 10, OS thread handle 140240123456, query id 150 localhost root updating
UPDATE accounts SET balance = balance + 100 WHERE id = 2

*** (1) HOLDS THE LOCK(S):
RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 421394771828736 lock_mode X locks rec but not gap
Record lock, heap no 2 PHYSICAL RECORD: n_fields 4; compact format; info bits 0
 0: len 4; hex 80000001; asc     ;;  -- id = 1
 1: len 6; hex 000000000001; asc       ;;
 2: len 7; hex 36000001234567; asc 6   4Eg;;
 3: len 5; hex 3930302e3030; asc 900.00;;

*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 421394771828736 lock_mode X locks rec but not gap waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 4; compact format; info bits 0
 0: len 4; hex 80000002; asc     ;;  -- id = 2

*** (2) TRANSACTION:
TRANSACTION 421394771828800, ACTIVE 5 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 11, OS thread handle 140240234567, query id 151 localhost root updating
UPDATE accounts SET balance = balance + 100 WHERE id = 1

*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 421394771828800 lock_mode X locks rec but not gap
Record lock, heap no 3 PHYSICAL RECORD: n_fields 4; compact format; info bits 0
 0: len 4; hex 80000002; asc     ;;  -- id = 2

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`accounts`
trx id 421394771828800 lock_mode X locks rec but not gap waiting
Record lock, heap no 2 PHYSICAL RECORD: n_fields 4; compact format; info bits 0
 0: len 4; hex 80000001; asc     ;;  -- id = 1

*** WE ROLL BACK TRANSACTION (2)
```

---

### 1-3. 로그 해석

**트랜잭션 (1) - 터미널 1:**
- **보유한 락:** id = 1 (X-Lock)
- **대기 중인 락:** id = 2 (X-Lock)
- **상태:** ACTIVE 8 sec

**트랜잭션 (2) - 터미널 2:**
- **보유한 락:** id = 2 (X-Lock)
- **대기 중인 락:** id = 1 (X-Lock)
- **상태:** ACTIVE 5 sec
- **결과:** ❌ **롤백됨**

**데드락 발생 원인:**
```
1. 트랜잭션 (1)이 id=1 락 획득
2. 트랜잭션 (2)가 id=2 락 획득
3. 트랜잭션 (1)이 id=2 락 요청 → 대기
4. 트랜잭션 (2)가 id=1 락 요청 → 대기
5. 순환 대기 (Circular Wait) 발생!
→ MySQL이 트랜잭션 (2)를 자동 롤백
```

**왜 (2)가 롤백되었나?**
- MySQL은 **롤백 비용이 적은** 트랜잭션을 선택
- (2)가 더 최근에 시작됨 (ACTIVE 5 sec < 8 sec)
- (2)가 잠근 행이 적거나 수정량이 적음

---

## 미션 2: 데드락 해결 - 락 순서 통일 - 정답

### 2-1. 문제 상황

**데드락 발생 쿼리:**
```sql
-- 트랜잭션 A: 1 → 2 순서
UPDATE products SET stock = stock - 1 WHERE id = 1;
UPDATE products SET stock = stock - 1 WHERE id = 2;

-- 트랜잭션 B: 2 → 1 순서 (다른 순서!)
UPDATE products SET stock = stock - 1 WHERE id = 2;
UPDATE products SET stock = stock - 1 WHERE id = 1;
```

**결과:** ❌ Deadlock 발생

---

### 2-2. 정답 해결 방법

#### 방법 1: ORDER BY로 락 순서 강제

```sql
-- ✅ 트랜잭션 A
UPDATE products SET stock = stock - 1
WHERE id IN (1, 2)
ORDER BY id;  -- 항상 1 → 2 순서

-- ✅ 트랜잭션 B
UPDATE products SET stock = stock - 1
WHERE id IN (2, 1)  -- 입력 순서가 달라도
ORDER BY id;  -- ORDER BY로 1 → 2 순서 강제!
```

**핵심 원리:**
- `ORDER BY id`를 사용하면 MySQL이 **항상 ID 오름차순**으로 행을 잠금
- 모든 트랜잭션이 **같은 순서**로 락을 획득
- 순환 대기 불가능 → **데드락 예방!**

**결과:** ✅ 데드락 발생하지 않음

---

#### 방법 2: 단일 쿼리로 통합

```sql
-- ✅ 한 번에 여러 행 업데이트
UPDATE products SET stock = stock - 1
WHERE id IN (1, 2, 3)
ORDER BY id;
```

**장점:**
1. **원자성 보장**: 한 트랜잭션에서 모두 처리
2. **락 순서 통일**: ORDER BY로 자동 정렬
3. **성능 향상**: 쿼리 횟수 감소
4. **데드락 위험 감소**: 여러 UPDATE 없음

---

#### 방법 3: 애플리케이션 레벨에서 정렬

```java
// ✅ Java/Spring 예시
public void updateStock(List<Integer> productIds) {
    Collections.sort(productIds);  // ID 정렬!

    for (Integer id : productIds) {
        productRepository.updateStock(id, -1);
    }
}
```

**주의사항:**
- 정렬을 **잊지 않도록** 문서화 필요
- 코드 리뷰에서 체크

---

### 2-3. EXPLAIN 분석

```sql
EXPLAIN UPDATE products SET stock = stock - 1
WHERE id IN (1, 2, 3)
ORDER BY id;
```

**결과:**
- `type`: **range** (여러 행 범위 검색)
- `key`: **PRIMARY** (PK 인덱스 사용)
- `rows`: 3
- `Extra`: **Using where**

**락이 걸리는 순서:**
1. id = 1에 X-Lock
2. id = 2에 X-Lock
3. id = 3에 X-Lock

→ 모든 트랜잭션이 **동일한 순서**로 락 획득!

---

## 미션 3: 낙관적 락으로 충돌 회피 - 정답

### 3-1. 비관적 락 방식 (기존)

```sql
-- ❌ 락 발생, 대기 시간 있음
START TRANSACTION;
SELECT view_count FROM posts WHERE id = 1 FOR UPDATE;
-- 다른 트랜잭션은 여기서 대기!
UPDATE posts SET view_count = view_count + 1 WHERE id = 1;
COMMIT;
```

**문제점:**
- `FOR UPDATE`로 즉시 X-Lock 획득
- 다른 트랜잭션이 **대기** (블로킹)
- 동시성 낮음

**사용 시기:**
- 충돌이 **자주** 발생 (재고 차감, 결제)
- 데이터 정합성이 **매우 중요**

---

### 3-2. 낙관적 락 방식 (정답)

#### 1단계: version 컬럼 추가

```sql
ALTER TABLE posts ADD COLUMN version INT DEFAULT 0;
```

#### 2단계: 낙관적 락 로직

```sql
-- 1. 읽기 (락 없음!)
SELECT id, view_count, version FROM posts WHERE id = 1;
-- 결과: view_count=10, version=5

-- 2. 비즈니스 로직 처리 (트랜잭션 밖에서도 가능)
-- new_view_count = 11

-- 3. 업데이트 시 버전 확인
UPDATE posts
SET view_count = 11, version = 6
WHERE id = 1 AND version = 5;  -- 버전 체크!

-- 4. 결과 확인
-- affected_rows = 1 → ✅ 성공
-- affected_rows = 0 → ❌ 실패 (다른 트랜잭션이 먼저 수정)
```

---

### 3-3. 충돌 상황 재현

**시나리오:** 두 트랜잭션이 동시에 조회수 증가

```sql
-- 초기 상태
SELECT * FROM posts WHERE id = 1;
-- view_count=0, version=0

-- 터미널 1
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count=0, version=0

UPDATE posts SET view_count = 1, version = 1
WHERE id = 1 AND version = 0;
-- ✅ affected_rows = 1 (성공!)

-- 터미널 2 (거의 동시)
SELECT id, view_count, version FROM posts WHERE id = 1;
-- view_count=0, version=0 (같은 값 읽음!)

UPDATE posts SET view_count = 1, version = 1
WHERE id = 1 AND version = 0;
-- ❌ affected_rows = 0 (실패! 버전이 이미 1로 변경됨)
```

---

### 3-4. 재시도 로직 (정답)

**애플리케이션 코드 (Java/Spring):**

```java
@Transactional
public void incrementViewCount(Long postId) {
    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
        // 1. 읽기
        Post post = postRepository.findById(postId);
        int currentVersion = post.getVersion();

        // 2. 업데이트 시도
        int updated = postRepository.updateWithVersion(
            postId,
            post.getViewCount() + 1,
            currentVersion + 1,
            currentVersion  // WHERE version = ?
        );

        // 3. 성공 여부 확인
        if (updated > 0) {
            return;  // ✅ 성공!
        }

        // 4. 실패 시 재시도
        retryCount++;
        Thread.sleep(50);  // 짧은 대기
    }

    throw new OptimisticLockException("충돌 재시도 실패");
}
```

**SQL:**
```sql
-- Spring Data JPA
@Modifying
@Query("UPDATE Post p SET p.viewCount = :viewCount, p.version = :newVersion " +
       "WHERE p.id = :id AND p.version = :currentVersion")
int updateWithVersion(@Param("id") Long id,
                      @Param("viewCount") int viewCount,
                      @Param("newVersion") int newVersion,
                      @Param("currentVersion") int currentVersion);
```

---

### 3-5. 성능 비교

**테스트 조건:** 10개 트랜잭션이 동시에 같은 행 업데이트

| 항목 | 비관적 락 | 낙관적 락 | 차이 |
|------|-----------|-----------|------|
| 총 실행 시간 | ~1000ms | ~150ms | **6.7배 빠름** |
| 락 대기 시간 | ~900ms | 0ms | - |
| 재시도 횟수 | 0 | ~2회 | - |
| 동시 처리 | 순차 | 병렬 | - |

**결론:**
- 낙관적 락이 **충돌이 적을 때** 훨씬 빠름
- 충돌률 < 10%면 낙관적 락 권장
- 충돌률 > 30%면 비관적 락 고려

---

## 미션 4: 트랜잭션 타임아웃 설정 - 정답

### 4-1. 기본 설정 확인

```sql
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout';
```

**결과:**
```
Variable_name              | Value
innodb_lock_wait_timeout   | 50
```

**의미:**
- 기본값: **50초**
- 50초 동안 락 대기
- 타임아웃 시 `ERROR 1205: Lock wait timeout exceeded`

---

### 4-2. 타임아웃 설정 (정답)

**세션 레벨 설정:**
```sql
-- 5초로 변경
SET innodb_lock_wait_timeout = 5;
```

**글로벌 레벨 설정 (재시작 시 유지):**
```sql
-- my.cnf 또는 my.ini 파일
[mysqld]
innodb_lock_wait_timeout = 10
```

---

### 4-3. 타임아웃 테스트

**터미널 1 - 락 보유:**
```sql
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 1;
-- ✓ 락 획득, COMMIT 안 함

-- (10초 대기)

COMMIT;
```

**터미널 2 - 타임아웃:**
```sql
SET innodb_lock_wait_timeout = 5;

-- 같은 행 업데이트 시도
UPDATE products SET stock = stock - 1 WHERE id = 1;
-- ⏳ 5초 대기...
-- ❌ ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

**에러 메시지:**
```
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

---

### 4-4. 적절한 타임아웃 값 (정답)

**실무 시나리오별 권장값:**

| 시나리오 | 권장 타임아웃 | 이유 |
|---------|--------------|------|
| **웹 API** | **3~5초** | 사용자 대기 시간 고려 (3초 이상은 느림) |
| **배치 작업** | **30~60초** | 긴 트랜잭션 허용 |
| **결제 처리** | **5~10초** | 빠른 실패 후 재시도 |
| **읽기 전용** | **10초** | 대기 허용 범위 |
| **실시간 알림** | **1~3초** | 즉시 실패 필요 |

**추천 기본값: 10초**

**이유:**
1. 50초는 **너무 김** (사용자가 이미 떠남)
2. 3초는 **너무 짧을 수 있음** (네트워크 지연 고려)
3. 10초면 **대부분의 정상 트랜잭션 완료**
4. 타임아웃 시 **재시도 로직**으로 복구 가능

---

## 추가 학습: 데드락 예방 전략 정리

### 전략 1: 락 순서 통일 ⭐⭐⭐

**원칙:**
```sql
-- ✅ 항상 ID 순서로
UPDATE ... WHERE id IN (...) ORDER BY id;
```

**효과:** 데드락 **80% 예방**

---

### 전략 2: 트랜잭션 최소화 ⭐⭐

**나쁜 예:**
```sql
-- ❌ 트랜잭션이 너무 김
START TRANSACTION;
SELECT ... FOR UPDATE;
-- 외부 API 호출 (5초)
-- 복잡한 계산 (3초)
-- 파일 쓰기 (2초)
UPDATE ...;
COMMIT;  -- 총 10초 동안 락 보유!
```

**좋은 예:**
```sql
-- ✅ 트랜잭션 밖에서 처리
-- 외부 API 호출
-- 복잡한 계산
-- 파일 쓰기

-- 필요한 부분만 트랜잭션
START TRANSACTION;
UPDATE ...;
COMMIT;  -- 0.1초만 락 보유
```

**효과:** 락 보유 시간 **90% 감소**

---

### 전략 3: 인덱스 활용 ⭐⭐⭐

**나쁜 예:**
```sql
-- ❌ 인덱스 없으면 많은 행 락
UPDATE products SET stock = stock - 1
WHERE name = 'iPhone';  -- name에 인덱스 없음
-- → 테이블 스캔 → 많은 행 락 → 데드락 위험 증가!
```

**좋은 예:**
```sql
-- ✅ 인덱스로 최소 락
CREATE INDEX idx_name ON products(name);

UPDATE products SET stock = stock - 1
WHERE name = 'iPhone';
-- → 인덱스 사용 → 필요한 행만 락 → 데드락 위험 감소!
```

**효과:** 락 범위 **1000배 감소**

---

### 전략 4: 낙관적 락 사용 ⭐⭐

**적용 시나리오:**
- 충돌이 드문 경우
- 조회수, 좋아요, 게시글 수정

**장점:**
- 락 없음 → 데드락 0%
- 빠른 응답 시간

**단점:**
- 재시도 로직 필요

---

### 전략 5: 타임아웃 설정 ⭐

**기본값 변경:**
```sql
SET innodb_lock_wait_timeout = 10;
```

**효과:**
- 무한 대기 방지
- 빠른 실패 후 재시도

---

## 실전 팁

### 데드락 발생 시 대응 체크리스트

1. **에러 로그 확인**
   ```
   ERROR 1213: Deadlock found when trying to get lock
   ```

2. **데드락 로그 분석**
   ```sql
   SHOW ENGINE INNODB STATUS\G
   ```

3. **원인 파악**
   - 어떤 테이블/행?
   - 어떤 쿼리?
   - 락 순서는?

4. **해결 방법 선택**
   - 락 순서 통일 (가장 효과적)
   - 트랜잭션 최소화
   - 인덱스 추가
   - 낙관적 락으로 전환

5. **테스트 및 검증**
   - 동시 실행 테스트
   - 로드 테스트
   - 모니터링 설정

---

### 코드 리뷰 체크 포인트

- [ ] **여러 행 UPDATE 시 ORDER BY 있는가?**
  ```sql
  UPDATE ... WHERE id IN (...) ORDER BY id;
  ```

- [ ] **트랜잭션 범위가 최소화되었는가?**
  - 외부 API 호출은 트랜잭션 밖?
  - 복잡한 계산은 트랜잭션 밖?

- [ ] **충돌 빈도가 낮은데 비관적 락 사용?**
  - 낙관적 락으로 전환 고려

- [ ] **인덱스가 적절히 설정되었는가?**
  - WHERE 절 컬럼에 인덱스 확인

- [ ] **타임아웃 설정이 적절한가?**
  - 너무 길면 무한 대기
  - 너무 짧으면 정상 트랜잭션 실패

---

### 모니터링 쿼리

**데드락 발생 횟수 확인:**
```sql
SHOW STATUS LIKE 'Innodb_deadlocks';
```

**현재 락 정보:**
```sql
-- MySQL 8.0
SELECT * FROM performance_schema.data_locks;
SELECT * FROM performance_schema.data_lock_waits;

-- MySQL 5.7
SELECT * FROM information_schema.INNODB_LOCKS;
SELECT * FROM information_schema.INNODB_LOCK_WAITS;
```

**실행 중인 트랜잭션:**
```sql
SELECT * FROM information_schema.INNODB_TRX;
```

---

## 실무 적용 예시

### Case 1: 주문 처리 (재고 차감)

**Before (데드락 발생):**
```java
@Transactional
public void createOrder(List<Long> productIds) {
    for (Long id : productIds) {
        // 순서가 랜덤 → 데드락 위험!
        productRepository.decreaseStock(id, 1);
    }
}
```

**After (데드락 해결):**
```java
@Transactional
public void createOrder(List<Long> productIds) {
    // ✅ 정렬!
    Collections.sort(productIds);

    // 또는 한 번에 업데이트
    productRepository.decreaseStockBatch(productIds);
}

// Repository
@Query("UPDATE Product p SET p.stock = p.stock - 1 " +
       "WHERE p.id IN :ids ORDER BY p.id")
void decreaseStockBatch(@Param("ids") List<Long> ids);
```

---

### Case 2: 포인트 차감/적립

**Before (데드락 발생):**
```java
@Transactional
public void transferPoints(Long fromUserId, Long toUserId, int amount) {
    // 순서가 매번 다름!
    userRepository.decreasePoints(fromUserId, amount);
    userRepository.increasePoints(toUserId, amount);
}
```

**After (데드락 해결):**
```java
@Transactional
public void transferPoints(Long fromUserId, Long toUserId, int amount) {
    // ✅ 항상 작은 ID 먼저!
    Long firstId = Math.min(fromUserId, toUserId);
    Long secondId = Math.max(fromUserId, toUserId);

    if (fromUserId.equals(firstId)) {
        userRepository.decreasePoints(fromUserId, amount);
        userRepository.increasePoints(toUserId, amount);
    } else {
        userRepository.increasePoints(toUserId, amount);
        userRepository.decreasePoints(fromUserId, amount);
    }
}
```

---

### Case 3: 조회수 증가

**Before (비관적 락):**
```java
@Transactional
public void incrementViewCount(Long postId) {
    Post post = postRepository.findByIdWithLock(postId);  // FOR UPDATE
    post.incrementViewCount();
    postRepository.save(post);
}
```

**After (낙관적 락):**
```java
@Entity
public class Post {
    @Id
    private Long id;

    private int viewCount;

    @Version  // ✅ JPA 낙관적 락
    private int version;
}

@Transactional
public void incrementViewCount(Long postId) {
    int maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
        try {
            Post post = postRepository.findById(postId);
            post.incrementViewCount();
            postRepository.save(post);
            return;  // 성공
        } catch (OptimisticLockException e) {
            // 재시도
            if (i == maxRetries - 1) throw e;
        }
    }
}
```

---

## 보너스: 인덱스 없을 때 락 범위

### 실험 결과

**시나리오:** products 테이블에서 name 컬럼에 인덱스 없음

```sql
-- 인덱스 확인
SHOW INDEX FROM products;
-- PRIMARY KEY (id)만 존재

-- 터미널 1
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE name = 'iPhone';
-- ⚠️ name에 인덱스 없음 → 테이블 스캔!

-- 터미널 2 (동시)
UPDATE products SET stock = stock - 1 WHERE name = 'Galaxy';
-- ❌ 블록됨! (왜?)
```

**원인:**
- **인덱스가 없으면** MySQL이 **테이블 스캔**
- 스캔하는 모든 행에 **락** 획득
- name='iPhone'인 행뿐 아니라 **다른 행들도 락**!

**해결:**
```sql
-- ✅ 인덱스 추가
CREATE INDEX idx_name ON products(name);

-- 이제 정확히 필요한 행만 락!
```

**교훈:**
- **인덱스가 성능뿐 아니라 동시성에도 영향**
- WHERE 절 컬럼에는 반드시 인덱스!

---

## 다음 주차 예고: Week 5 - 트랜잭션 격리 수준

이번 주차에서 락과 데드락을 다뤘다면,
다음 주차에서는 **트랜잭션 격리 수준**을 배웁니다!

**다룰 내용:**
- READ UNCOMMITTED vs READ COMMITTED vs REPEATABLE READ vs SERIALIZABLE
- Dirty Read, Non-Repeatable Read, Phantom Read
- 격리 수준별 성능과 정합성 트레이드오프
- 실무에서 격리 수준 선택 기준

---

**완료 축하합니다!** 🎉

이제 데드락이 발생해도 당황하지 않고 해결할 수 있습니다!

**다음 액션:**
1. [ ] ANSWER.md와 이 SOLUTION.md 비교
2. [ ] 틀린 부분 복습
3. [ ] 현재 프로젝트에서 데드락 위험 쿼리 찾기
4. [ ] 락 순서 통일 적용
5. [ ] 낙관적 락 적용 고려
6. [ ] Week 5 미션 시작

**실무 적용 체크리스트:**
- [ ] 여러 행 UPDATE 시 ORDER BY 추가
- [ ] 트랜잭션 범위 최소화
- [ ] 타임아웃 10초로 설정
- [ ] 모니터링 쿼리 추가
- [ ] 팀 공유 및 코드 리뷰 기준 업데이트
