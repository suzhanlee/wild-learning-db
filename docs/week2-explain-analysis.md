# Week 2: EXPLAIN 실전 분석 ⭐⭐⭐

> "EXPLAIN 보고 3초 안에 문제 발견"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"쿼리 실행 계획을 읽고 즉시 문제 파악하기"**

이번 주차를 완료하면:
- EXPLAIN 각 컬럼의 의미 이해
- type 값으로 성능 예측 가능
- rows로 비효율 판단 가능
- Extra로 추가 최적화 포인트 발견

---

## 📚 학습 내용

### 1. EXPLAIN 기본 구조 (15분)

#### EXPLAIN 사용법
```sql
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```

#### 주요 컬럼
```
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
```

---

### 2. type 해석 (20분)

#### 성능 순위 (빠름 → 느림)
```
const > eq_ref > ref > range > index > ALL
```

#### 각 type 설명

**✅ const** (가장 빠름)
```sql
-- PRIMARY KEY나 UNIQUE 인덱스로 단 1건 조회
SELECT * FROM users WHERE id = 1;

type: const
의미: 상수처럼 한 번만 읽음
성능: ★★★★★
```

**✅ eq_ref**
```sql
-- JOIN에서 PRIMARY KEY나 UNIQUE 인덱스 사용
SELECT * FROM orders o
JOIN users u ON o.user_id = u.id;

type: eq_ref (users 테이블)
의미: 조인마다 1건씩 읽음
성능: ★★★★☆
```

**✅ ref**
```sql
-- 인덱스 사용하지만 여러 건 반환
SELECT * FROM orders WHERE user_id = 123;

type: ref
의미: 인덱스로 여러 건 찾음
성능: ★★★★☆
```

**⚠️ range**
```sql
-- 범위 검색
SELECT * FROM orders WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';

type: range
의미: 인덱스 범위 스캔
성능: ★★★☆☆
주의: 범위가 넓으면 느림
```

**⚠️ index**
```sql
-- 인덱스 풀 스캔
SELECT id FROM users;

type: index
의미: 인덱스 전체를 읽음
성능: ★★☆☆☆
주의: 테이블 스캔보단 빠르지만 비효율적
```

**❌ ALL** (가장 느림)
```sql
-- 테이블 풀 스캔
SELECT * FROM users WHERE name LIKE '%김%';

type: ALL
의미: 테이블 전체를 읽음
성능: ★☆☆☆☆
주의: 큰 테이블에서 치명적
```

---

### 3. rows 해석 (10분)

#### rows의 의미
```
rows = 쿼리 실행을 위해 검사해야 하는 예상 행 수
```

#### 판단 기준
```sql
-- 테이블 총 행 수: 1,000,000

-- ✅ 좋음
rows: 1 ~ 100

-- ⚠️ 주의
rows: 100 ~ 10,000

-- ❌ 문제
rows: 10,000+
```

#### 실제 예시
```sql
-- 문제 있는 쿼리
EXPLAIN SELECT * FROM orders WHERE status = 'pending';

+-------+------+-------+------+-------+
| table | type | key   | rows | Extra |
+-------+------+-------+------+-------+
| orders| ALL  | NULL  | 950000 | Using where |
+-------+------+-------+------+-------+

문제: 95만 건 검사 → 매우 느림
해결: status에 인덱스 생성
```

---

### 4. Extra 해석 (15분)

#### 좋은 Extra

**✅ Using index** (최고!)
```sql
SELECT id, user_id FROM orders WHERE user_id = 123;

Extra: Using index
의미: 커버링 인덱스 (인덱스만으로 쿼리 완료)
성능: 최고
```

**✅ Using index condition**
```sql
Extra: Using index condition
의미: 인덱스 조건 푸시다운
성능: 좋음
```

#### 나쁜 Extra

**❌ Using filesort** (정렬 비용)
```sql
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC;

Extra: Using filesort
의미: 메모리/디스크에서 별도 정렬
문제: 느림, 메모리 사용
해결: 인덱스에 ORDER BY 컬럼 포함
```

**❌ Using temporary** (임시 테이블)
```sql
SELECT user_id, COUNT(*)
FROM orders
GROUP BY user_id
ORDER BY COUNT(*) DESC;

Extra: Using temporary; Using filesort
의미: 임시 테이블 생성 후 정렬
문제: 매우 느림
해결: 인덱스 최적화
```

**⚠️ Using where**
```sql
Extra: Using where
의미: WHERE 조건을 스토리지 엔진이 아닌 MySQL 엔진에서 처리
판단: type과 함께 봐야 함
  - type=ALL + Using where → 나쁨
  - type=ref + Using where → 괜찮음
```

---

## 🔬 실습

### 실습 1: type별 성능 비교 (20분)

```sql
-- 테스트 데이터 준비
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    amount DECIMAL(10,2),
    created_at DATETIME,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- 100만 건 더미 데이터 삽입

-- 1. const
EXPLAIN SELECT * FROM orders WHERE id = 100;
-- type: _______  rows: _______  실행시간: _______ms

-- 2. ref
EXPLAIN SELECT * FROM orders WHERE user_id = 1000;
-- type: _______  rows: _______  실행시간: _______ms

-- 3. range
EXPLAIN SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
-- type: _______  rows: _______  실행시간: _______ms

-- 4. index
EXPLAIN SELECT id FROM orders;
-- type: _______  rows: _______  실행시간: _______ms

-- 5. ALL
EXPLAIN SELECT * FROM orders WHERE amount > 1000;
-- type: _______  rows: _______  실행시간: _______ms
```

#### 결과 비교표
| type | rows | 실행시간 | 성능 |
|------|------|---------|------|
| const | | | |
| ref | | | |
| range | | | |
| index | | | |
| ALL | | | |

---

### 실습 2: 회사 코드 쿼리 분석 (30분)

회사 코드에서 자주 실행되는 쿼리 10개를 찾아 분석:

```sql
-- 쿼리 1
EXPLAIN [회사 쿼리];

-- 분석
type: _______
rows: _______
Extra: _______
문제점: _______
개선방안: _______

-- (쿼리 2-10 반복)
```

#### 발견한 문제들
| 쿼리 | type | rows | 문제 | 우선순위 |
|------|------|------|------|----------|
| 1 | | | | |
| 2 | | | | |
| ... | | | | |

---

### 실습 3: Before/After 개선 (30분)

문제가 있는 쿼리 3개를 선정하여 개선:

```sql
-- 개선 사례 1
-- Before
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

EXPLAIN:
- type: ALL
- rows: 800,000
- Extra: Using filesort
실행시간: _____ms

-- After (인덱스 추가)
CREATE INDEX idx_status_created ON orders(status, created_at);

EXPLAIN:
- type: ref
- rows: 1,234
- Extra: Using index
실행시간: _____ms

개선율: _____%

-- 개선 사례 2-3 작성
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] EXPLAIN 각 컬럼 의미 이해
- [ ] type 순서 암기 (const > eq_ref > ref > range > index > ALL)
- [ ] rows 판단 기준 숙지
- [ ] Extra 패턴 이해 (Using filesort, Using temporary 위험)

### 실습 완료
- [ ] type별 성능 실험
- [ ] 회사 쿼리 10개 EXPLAIN 분석
- [ ] 문제 쿼리 3개 개선
- [ ] Before/After 성능 측정

### 실무 적용
- [ ] 주요 API의 쿼리 EXPLAIN 검토
- [ ] type=ALL 쿼리 찾아서 개선
- [ ] rows 큰 쿼리 최적화
- [ ] 팀 코드 리뷰 시 EXPLAIN 확인 습관화

---

## 📝 학습 노트

### 오늘 배운 핵심 3가지
1.
2.
3.

### 실무 적용 계획
-

### 놀라운 발견
**Before 성능:**
**After 성능:**
**개선율:**

### 주의할 패턴
-

---

## 📚 참고 자료

- MySQL 공식 문서: [EXPLAIN Output Format](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html)
- [EXPLAIN 완벽 가이드](https://use-the-index-luke.com/sql/explain-plan/mysql/operations)

---

**학습 시간**: 60분 야생학습 + 실무 적용
**난이도**: ⭐⭐⭐ 중
**즉시 적용**: ✓
**ROI**: 매우 높음

**완료일**: ___________
