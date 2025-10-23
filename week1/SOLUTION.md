# Week 1 정답: 인덱스 성능 개선

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: 단일 인덱스 성능 개선 - 정답

### 1-1. 현재 상황 분석

```sql
-- 인덱스 확인
SHOW INDEX FROM users;
-- PRIMARY KEY (id)만 존재하고, email에는 인덱스 없음
```

```sql
-- EXPLAIN 분석 (Before)
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';
```

**결과:**
- `type`: **ALL** (전체 테이블 스캔)
- `rows`: **1,000,000** (모든 행 검사)
- `Extra`: -

**문제점:** 인덱스가 없어서 100만 건을 전부 읽음

---

### 1-2. 해결 방법

```sql
-- 정답 인덱스
CREATE INDEX idx_email ON users(email);
```

**이유:**
1. **WHERE 절에서 사용**: `WHERE email = '...'`로 자주 검색됨
2. **Cardinality가 높음**: 이메일은 사용자마다 고유함 (100만 가지 값)
3. **동등 조건**: `=` 조건은 인덱스 효율이 매우 좋음

---

### 1-3. 성능 개선 결과

```sql
-- EXPLAIN 분석 (After)
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';
```

**결과:**
- `type`: **ref** (인덱스 참조)
- `rows`: **1** (1개 행만 검사)
- `key`: **idx_email** (인덱스 사용)

**성능 비교:**

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ~2000ms | ~1ms | **약 2000배** |
| 검사한 rows | 1,000,000 | 1 | **1,000,000배** |
| type | ALL | ref | ✓ |

**결과:** ✅ 50배 이상 개선 달성!

---

## 미션 2: 복합 인덱스 설계 - 정답

### 2-1. 현재 상황

```sql
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

**Before:**
- `type`: ALL
- `rows`: 1,000,000
- `Extra`: Using where; Using filesort (정렬 별도 수행)

---

### 2-2. 정답 인덱스

```sql
-- 정답 복합 인덱스
CREATE INDEX idx_user_status_created ON orders(user_id, status, created_at);
```

### 컬럼 순서 이유

**1번 컬럼: user_id**
- WHERE 절의 **동등 조건** (`=`)
- Cardinality가 높음 (사용자 수만큼 다양)
- 가장 먼저 필터링해서 데이터를 대폭 줄임

**2번 컬럼: status**
- WHERE 절의 **동등 조건** (`=`)
- user_id로 필터링된 결과를 추가로 필터링
- Cardinality는 낮지만 (5가지 정도), 동등 조건이므로 효율적

**3번 컬럼: created_at**
- **ORDER BY** 절에서 사용
- 인덱스가 이미 정렬되어 있으므로 별도 정렬 불필요
- 마지막에 위치해야 정렬 최적화

---

### 2-3. 성능 개선 결과

**After:**
- `type`: **ref** (인덱스 참조)
- `rows`: **~50** (user_id + status로 필터링된 결과)
- `Extra`: **Using index condition** (filesort 사라짐!)

**성능 비교:**

| 항목 | Before | After | 개선 |
|------|--------|-------|------|
| 실행 시간 | ~1500ms | ~1ms | **약 1500배** |
| type | ALL | ref | ✓ |
| rows | 1,000,000 | ~50 | **20,000배** |
| Extra | Using filesort | - | ✓ |

---

### 2-4. 잘못된 순서와 비교

#### 안 좋은 예시 1: (status, user_id, created_at)
```sql
CREATE INDEX idx_wrong1 ON orders(status, user_id, created_at);
```
**문제점:**
- status가 먼저 오면 Cardinality가 낮아서 필터링 효율 떨어짐
- 5가지 값으로만 나뉘므로, 각 status마다 20만 건씩 남음
- 성능 개선 효과 **30% 정도만**

#### 안 좋은 예시 2: (created_at, user_id, status)
```sql
CREATE INDEX idx_wrong2 ON orders(created_at, user_id, status);
```
**문제점:**
- 범위/정렬 컬럼이 먼저 오면, 뒤 컬럼들을 제대로 못 씀
- user_id 필터링이 비효율적
- 인덱스를 거의 못 탐

---

## 미션 3: 인덱스를 못 타는 쿼리 찾기 - 정답

### 쿼리 A: ❌ 인덱스 못 탐
```sql
SELECT * FROM users WHERE YEAR(created_at) = 2024;
```

**문제점:** 컬럼에 **함수(YEAR)** 사용
- MySQL은 함수 적용 후 값을 비교하므로 인덱스 못 씀
- 모든 행의 created_at에 YEAR()을 적용해야 함

**개선된 쿼리:**
```sql
-- ✅ 범위 조건으로 변경
SELECT * FROM users
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**성능 비교:**
- Before: type = ALL, rows = 1,000,000
- After: type = range, rows = ~200,000 (2024년 데이터만)

---

### 쿼리 B: ✅ 인덱스 사용 가능
```sql
SELECT * FROM users
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**이유:**
- **범위 조건**이지만 함수 없이 직접 비교
- created_at에 인덱스가 있으면 사용 가능
- type = range로 효율적으로 검색

---

### 쿼리 C: ❌ 인덱스 못 탐
```sql
SELECT * FROM users WHERE email LIKE '%@gmail.com';
```

**문제점:** **앞부분 와일드카드** (`%`로 시작)
- 이메일 끝부분(@gmail.com)을 찾는 것이므로 인덱스 못 씀
- B-Tree는 앞에서부터 정렬되어 있는데, 뒷부분 매칭은 불가능

**대안:**
1. **Full-Text Search** 사용 (MySQL 5.6+)
```sql
ALTER TABLE users ADD FULLTEXT INDEX ft_email (email);
SELECT * FROM users WHERE MATCH(email) AGAINST('gmail.com');
```

2. **역색인 테이블** 생성 (도메인별로 저장)
```sql
-- email_domains 테이블
-- user_id | domain
-- 1       | gmail.com
-- 2       | naver.com

SELECT u.* FROM users u
JOIN email_domains ed ON u.id = ed.user_id
WHERE ed.domain = 'gmail.com';
```

3. **Elasticsearch** 같은 검색 엔진 사용 (대규모라면)

---

### 쿼리 D: ✅ 인덱스 사용 가능
```sql
SELECT * FROM users WHERE email LIKE 'user123%';
```

**이유:**
- **뒷부분 와일드카드** (끝에만 `%`)
- B-Tree는 앞에서부터 정렬되므로 'user123'로 시작하는 값을 찾을 수 있음
- type = range로 검색

---

### 쿼리 E: ❌ 인덱스 못 탐 (또는 비효율)
```sql
SELECT * FROM orders WHERE status != 'cancelled';
```

**문제점:** **부정 조건** (`!=`, `NOT`)
- "cancelled가 아닌 모든 것"을 찾으려면 대부분의 행을 검사해야 함
- MySQL이 인덱스보다 Full Scan이 빠르다고 판단할 수 있음

**개선된 쿼리:**
```sql
-- ✅ 긍정 조건으로 변경
SELECT * FROM orders
WHERE status IN ('pending', 'completed', 'shipped', 'delivered');
```

**이유:**
- 긍정 조건은 인덱스를 효율적으로 사용
- 각 status 값을 인덱스에서 직접 찾을 수 있음

**성능 비교:**
- Before: type = ALL (또는 index)
- After: type = range, rows 대폭 감소

---

## 추가 학습: 복합 인덱스 규칙 정리

### 규칙 1: 동등 조건 먼저, 범위 조건 나중
```sql
-- ✅ 좋음
WHERE a = 1 AND b > 10
INDEX (a, b)

-- ❌ 나쁨
WHERE a = 1 AND b > 10
INDEX (b, a)  -- b가 범위 조건인데 먼저 오면 a를 못 씀
```

---

### 규칙 2: Cardinality 높은 것 먼저
```sql
-- user_id: 100만 가지 (높음)
-- status: 5가지 (낮음)

-- ✅ 좋음
INDEX (user_id, status)  -- user_id로 먼저 대폭 필터링

-- ❌ 나쁨
INDEX (status, user_id)  -- status로는 1/5만 필터링
```

---

### 규칙 3: ORDER BY/GROUP BY는 마지막
```sql
-- ✅ 좋음
WHERE category = 'book' ORDER BY created_at
INDEX (category, created_at)

-- ❌ 나쁨
WHERE category = 'book' ORDER BY created_at
INDEX (created_at, category)  -- 정렬 최적화 안 됨
```

---

### 규칙 4: 중간 컬럼 건너뛰면 뒤는 못 씀
```sql
INDEX (a, b, c)

-- ✅ a만 사용
WHERE a = 1

-- ✅ a, b 사용
WHERE a = 1 AND b = 2

-- ✅ a, b, c 모두 사용
WHERE a = 1 AND b = 2 AND c = 3

-- ⚠️ a만 사용 (b를 건너뛰면 c는 못 씀)
WHERE a = 1 AND c = 3
```

---

## 실전 팁

### 인덱스 생성 체크리스트
- [ ] WHERE 절에 자주 사용되는 컬럼인가?
- [ ] Cardinality가 높은가? (값이 다양한가?)
- [ ] JOIN 조건에 사용되는가?
- [ ] ORDER BY / GROUP BY에 사용되는가?
- [ ] 자주 UPDATE되는 컬럼은 아닌가? (인덱스 유지 비용)
- [ ] 테이블이 충분히 큰가? (수천 건 이하면 불필요)

---

### 인덱스를 못 타는 패턴 (외우기!)
1. ❌ 함수 사용: `WHERE YEAR(date) = 2024`
2. ❌ 앞부분 와일드카드: `LIKE '%keyword'`
3. ❌ 부정 조건: `!=`, `NOT`, `NOT IN`
4. ❌ OR 조건 (인덱스가 다를 때)
5. ❌ 타입 불일치: `WHERE id = '123'` (id가 INT)
6. ❌ 연산: `WHERE age + 1 > 20`
7. ❌ NULL 비교: `WHERE col IS NULL` (경우에 따라)

---

### 성능 측정 방법

```sql
-- 1. 실행 시간 측정
SET profiling = 1;
SELECT ...;
SHOW PROFILES;

-- 2. EXPLAIN 확인
EXPLAIN SELECT ...;

-- 3. EXPLAIN ANALYZE (MySQL 8.0.18+)
EXPLAIN ANALYZE SELECT ...;

-- 4. 인덱스 사용 통계
SHOW INDEX FROM table_name;
```

---

## 실무 적용 체크리스트

### 즉시 할 것
- [ ] 회사 주요 테이블 인덱스 현황 파악
  ```sql
  SHOW INDEX FROM [주요 테이블];
  ```

- [ ] 느린 쿼리 로그 확인 (Week 9에서 자세히)
  ```sql
  SHOW VARIABLES LIKE 'slow_query%';
  ```

- [ ] WHERE 절 자주 사용되는데 인덱스 없는 컬럼 찾기

- [ ] 안티패턴 검색
  - `WHERE YEAR(` 검색
  - `LIKE '%` 검색
  - `!= ` 검색

---

### 팀 공유할 내용
- 인덱스 설계 규칙 (복합 인덱스 순서)
- 안티패턴 목록 (코드 리뷰 시 체크)
- EXPLAIN 읽는 법 (type, rows 위주)
- 성능 개선 사례 (Before/After)

---

### 주의사항
1. **무분별한 인덱스 생성 금지**
   - 인덱스는 저장 공간 차지
   - INSERT/UPDATE 느려질 수 있음
   - 실제 사용하는 쿼리 기준으로 생성

2. **복합 인덱스 vs 단일 인덱스**
   - 여러 컬럼 조합이 자주 사용되면 복합 인덱스
   - 각각 따로 사용되면 단일 인덱스

3. **운영 DB에 직접 적용 금지**
   - 개발/스테이징 환경에서 먼저 테스트
   - 인덱스 생성은 테이블 잠금 발생 가능 (MySQL 5.6+는 온라인 DDL 지원)
   - 배포 시간대 고려 (트래픽 적은 시간)

---

## 다음 주차 예고: Week 2 - EXPLAIN 실전 분석

이번 주차에서 EXPLAIN을 맛봤다면,
다음 주차에서는 EXPLAIN의 모든 컬럼을 완벽하게 해석하는 법을 배웁니다!

- type의 모든 종류와 성능 순서
- Extra의 숨겨진 의미
- 실전 쿼리 최적화 프로세스
- 복잡한 JOIN 쿼리 분석

---

**완료 축하합니다!** 🎉

인덱스 기본기를 마스터했습니다.
이제 실무에서 느린 쿼리를 만나면 자신 있게 개선할 수 있습니다!

**다음 액션:**
1. [ ] ANSWER.md와 이 SOLUTION.md 비교
2. [ ] 틀린 부분 복습
3. [ ] 실무 쿼리 1개 이상 개선 시도
4. [ ] Week 2 미션 시작
