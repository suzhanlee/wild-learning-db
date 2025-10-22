# Week 1: 인덱스 핵심 원리 ⭐⭐

> "인덱스만 잘 써도 90% 문제 해결"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"인덱스 보고 3초 안에 판단하기"**

이번 주차를 완료하면:
- B-Tree 구조가 어떻게 동작하는지 이해
- 어떤 컬럼에 인덱스를 걸어야 하는지 판단 가능
- 복합 인덱스 순서를 올바르게 설계 가능
- 인덱스를 타지 않는 쿼리 패턴 식별 가능

---

## 📚 학습 내용

### 1. B-Tree 구조 (15분)

#### 인덱스가 없을 때
```
테이블: 100만 건
검색: WHERE user_id = 12345
→ 100만 건 전부 읽음 (Full Scan)
→ 매우 느림!
```

#### 인덱스가 있을 때
```
B-Tree 인덱스 구조:
         [50만]
        /      \
   [25만]      [75만]
   /    \      /    \
[12만] [37만] [62만] [87만]
...

검색: WHERE user_id = 12345
→ 트리 탐색: 3-4번만 읽음
→ 매우 빠름!
```

#### 핵심 개념
- **B-Tree**: 균형 잡힌 트리 구조
- **정렬된 상태 유지**: 삽입/삭제 시 자동 정렬
- **O(log N)**: 데이터가 많아도 빠름
- **리프 노드**: 실제 데이터 위치 정보 포함

---

### 2. 어디에 인덱스를 걸까? (15분)

#### 인덱스 생성 기준

✅ **인덱스를 걸어야 하는 경우**
```sql
-- WHERE 절에 자주 사용
SELECT * FROM users WHERE email = 'user@example.com';
CREATE INDEX idx_email ON users(email);

-- JOIN 조건에 사용
SELECT * FROM orders o JOIN users u ON o.user_id = u.id;
CREATE INDEX idx_user_id ON orders(user_id);

-- ORDER BY에 사용
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10;
CREATE INDEX idx_created_at ON posts(created_at);

-- Cardinality가 높은 컬럼 (값이 다양함)
-- 예: 이메일, 주문번호, UUID
```

❌ **인덱스를 걸면 안 되는 경우**
```sql
-- Cardinality가 낮은 컬럼 (값이 제한적)
-- 예: 성별(M/F), 상태(active/inactive)
CREATE INDEX idx_gender ON users(gender); -- ❌ 비효율적

-- 자주 변경되는 컬럼
-- 인덱스 재정렬 비용이 큼

-- 작은 테이블 (수천 건 이하)
-- Full Scan이 더 빠를 수 있음
```

#### 판단 기준
```
인덱스 생성 여부 =
  (조회 빈도 × 성능 개선) > (삽입/수정 느려짐 + 저장공간)
```

---

### 3. 복합 인덱스 순서 (15분)

#### 잘못된 복합 인덱스
```sql
-- ❌ 순서가 잘못됨
CREATE INDEX idx_wrong ON orders(status, user_id, created_at);

-- 이 쿼리는 인덱스를 제대로 못 탐
SELECT * FROM orders
WHERE user_id = 123
  AND status = 'completed'
ORDER BY created_at DESC;
```

#### 올바른 복합 인덱스
```sql
-- ✅ 순서가 맞음
CREATE INDEX idx_correct ON orders(user_id, status, created_at);

-- 이유:
-- 1. user_id: WHERE 조건 (가장 먼저 필터링)
-- 2. status: WHERE 조건 (추가 필터링)
-- 3. created_at: ORDER BY (정렬)
```

#### 복합 인덱스 순서 규칙
1. **동등 조건(=) 먼저**
   ```sql
   WHERE user_id = 123  -- = 조건
   AND created_at > '2024-01-01'  -- 범위 조건

   INDEX (user_id, created_at)  -- ✅
   INDEX (created_at, user_id)  -- ❌
   ```

2. **Cardinality 높은 것 먼저**
   ```sql
   -- user_id: 100만 가지 값
   -- status: 5가지 값

   INDEX (user_id, status)  -- ✅
   INDEX (status, user_id)  -- ❌
   ```

3. **ORDER BY 컬럼은 마지막**
   ```sql
   WHERE category = 'book'
   ORDER BY created_at DESC

   INDEX (category, created_at)  -- ✅
   ```

---

### 4. 인덱스를 못 타는 패턴 (15분)

#### 안티패턴 모음

```sql
-- ❌ 함수 사용
SELECT * FROM users WHERE YEAR(created_at) = 2024;
-- ✅ 범위 조건으로 변경
SELECT * FROM users WHERE created_at >= '2024-01-01'
                      AND created_at < '2025-01-01';

-- ❌ 앞부분 와일드카드
SELECT * FROM users WHERE email LIKE '%@gmail.com';
-- ✅ 뒷부분 와일드카드만 인덱스 사용
SELECT * FROM users WHERE email LIKE 'user@%';

-- ❌ OR 조건 (인덱스가 다를 때)
SELECT * FROM users WHERE email = 'a@b.com' OR phone = '010-1234-5678';
-- ✅ UNION으로 분리
SELECT * FROM users WHERE email = 'a@b.com'
UNION
SELECT * FROM users WHERE phone = '010-1234-5678';

-- ❌ NOT, !=, <>
SELECT * FROM orders WHERE status != 'cancelled';
-- ✅ IN으로 변경
SELECT * FROM orders WHERE status IN ('pending', 'completed', 'shipped');

-- ❌ 타입 불일치
SELECT * FROM users WHERE id = '123';  -- id가 INT인데 문자열 비교
-- ✅ 타입 맞춤
SELECT * FROM users WHERE id = 123;

-- ❌ 복합 인덱스 중간 컬럼 생략
INDEX (a, b, c)
SELECT * FROM t WHERE a = 1 AND c = 3;  -- b를 건너뛰면 c는 인덱스 못 탐
```

---

## 🔬 실습

### 실습 1: 인덱스 있을 때 vs 없을 때 (20분)

```sql
-- 테스트 테이블 생성
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100),
    created_at DATETIME,
    status VARCHAR(20)
);

-- 더미 데이터 100만 건 삽입 (프로시저 사용)
DELIMITER $$
CREATE PROCEDURE insert_dummy_users()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 1000000 DO
        INSERT INTO users (email, name, created_at, status)
        VALUES (
            CONCAT('user', i, '@example.com'),
            CONCAT('User', i),
            DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY),
            ELT(FLOOR(1 + RAND() * 3), 'active', 'inactive', 'pending')
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL insert_dummy_users();

-- 인덱스 없이 조회
SELECT * FROM users WHERE email = 'user50000@example.com';
-- 실행 시간 측정: _____ms

-- 인덱스 생성
CREATE INDEX idx_email ON users(email);

-- 인덱스 있이 조회
SELECT * FROM users WHERE email = 'user50000@example.com';
-- 실행 시간 측정: _____ms

-- 성능 비교: 약 ___배 개선
```

#### 결과 기록
| 상황 | 실행시간 | rows 검사 | 비고 |
|------|---------|-----------|------|
| 인덱스 없음 | ___ms | 1,000,000 | Full Scan |
| 인덱스 있음 | ___ms | 1 | Index Scan |

---

### 실습 2: 복합 인덱스 순서 비교 (20분)

```sql
-- 주문 테이블
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    created_at DATETIME,
    amount DECIMAL(10,2)
);

-- 더미 데이터 100만 건
-- (생략 - 실습 시 삽입)

-- 시나리오: 특정 유저의 완료된 주문을 최신순으로
SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- 테스트 1: 인덱스 없음
-- 실행 시간: _____ms

-- 테스트 2: 잘못된 순서
CREATE INDEX idx_wrong ON orders(status, user_id, created_at);
-- 실행 시간: _____ms

-- 테스트 3: 올바른 순서
DROP INDEX idx_wrong ON orders;
CREATE INDEX idx_correct ON orders(user_id, status, created_at);
-- 실행 시간: _____ms

-- 각각 EXPLAIN으로 확인
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

#### 결과 비교
| 인덱스 | 실행시간 | type | rows | Extra |
|--------|---------|------|------|-------|
| 없음 | ___ms | | | |
| 잘못된 순서 | ___ms | | | |
| 올바른 순서 | ___ms | | | |

---

### 실습 3: 안티패턴 발견하기 (20분)

회사 코드에서 다음 패턴 찾기:

```sql
-- 1. 함수 사용
WHERE DATE(created_at) = '2024-01-01'
WHERE YEAR(created_at) = 2024

-- 2. 와일드카드
WHERE name LIKE '%김%'

-- 3. OR 조건
WHERE email = 'a@b.com' OR phone = '010-1234'

-- 4. NOT, !=
WHERE status != 'deleted'

-- 5. 타입 불일치
WHERE id = '123'  -- id는 INT
```

#### 발견한 쿼리 기록
```
파일: _________________
라인: _________________
패턴: _________________
개선: _________________
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] B-Tree 구조 이해
- [ ] 인덱스 생성 기준 숙지
- [ ] 복합 인덱스 순서 규칙 이해
- [ ] 안티패턴 패턴 암기

### 실습 완료
- [ ] 인덱스 성능 비교 실험
- [ ] 복합 인덱스 순서 테스트
- [ ] 회사 코드 안티패턴 발견
- [ ] 개선 쿼리 작성

### 실무 적용
- [ ] 회사 주요 테이블 인덱스 검토
- [ ] 느린 쿼리 1개 이상 개선
- [ ] 팀원과 인덱스 전략 공유

---

## 📝 학습 노트

### 오늘 배운 핵심 3가지
1.
2.
3.

### 실무 적용 계획
-

### 추가로 공부할 것
-

### 트러블슈팅 경험
**문제:**

**해결:**

**배운 점:**

---

## 📚 참고 자료

- MySQL 공식 문서: [Optimization and Indexes](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)
- Use The Index, Luke: https://use-the-index-luke.com/
- Real MySQL 8.0: 8장 인덱스

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐ 중
**즉시 적용**: ✓
**ROI**: 매우 높음

**완료일**: ___________
