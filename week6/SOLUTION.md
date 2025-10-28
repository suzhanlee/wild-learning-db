# Week 6 정답: 페이지네이션 최적화

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: Offset 지옥 체험하기 - 정답

### 1-1. Offset 방식 성능 분석

**성능 측정 결과 (예상값):**

| 페이지 | OFFSET | 실행 시간 | 배율 (1페이지 대비) |
|--------|--------|-----------|---------------------|
| 1      | 0      | ~10ms     | 1x                  |
| 100    | 990    | ~100ms    | 10x                 |
| 1000   | 9990   | ~800ms    | 80x                 |
| 10000  | 99990  | ~8000ms   | 800x                |

**EXPLAIN 결과:**
```sql
EXPLAIN SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 99990;
```

- `type`: **index** (인덱스 전체 스캔) 또는 **ALL** (전체 테이블 스캔)
- `rows`: **1,000,000** (전체 행 검사)
- `Extra`: **Using filesort** (정렬 수행)

---

### 1-2. 왜 느려지는가?

**MySQL의 내부 동작:**

```
LIMIT 10 OFFSET 99990을 실행하면:

1. ORDER BY created_at DESC로 정렬
2. 처음부터 100,000개 행 읽기 (99990 + 10)
3. 처음 99,990개 버리기 (메모리에서 삭제)
4. 나머지 10개만 반환

시간 복잡도: O(N) - N은 OFFSET 크기
```

**문제점:**
1. **선형 증가**: OFFSET이 2배 → 시간도 ~2배
2. **낭비**: 99,990개를 읽고 버림
3. **메모리 사용**: 정렬을 위해 많은 메모리 필요
4. **디스크 I/O**: 데이터가 크면 디스크 읽기 증가

---

## 미션 2: Cursor 페이지네이션 구현 - 정답

### 2-1. 정답 인덱스

```sql
-- 정답 복합 인덱스
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);
```

**컬럼 순서 이유:**

**1. created_at (DESC)**
- ORDER BY의 주 정렬 컬럼
- 최신 게시글부터 보여주므로 DESC
- 범위 검색에 사용 (`<` 조건)

**2. id (DESC)**
- created_at이 같을 수 있으므로 2차 정렬 키
- id는 unique하고 AUTO_INCREMENT이므로 순서 보장
- 정확한 커서 위치 파악 가능

**3. DESC 방향**
- 쿼리의 `ORDER BY created_at DESC, id DESC`와 일치
- 방향이 일치하지 않으면 인덱스를 못 쓸 수 있음

---

### 2-2. Cursor 방식 구현

#### 첫 페이지
```sql
-- 정답 쿼리
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**결과:**
- 실행 시간: **~1ms**
- type: **index** (인덱스 스캔)
- rows: **10** (필요한 만큼만)
- Extra: **Using index** (인덱스만 사용) 또는 없음

---

#### 다음 페이지 (100번째, 1000번째, 10000번째 모두 동일)

```sql
-- 마지막 커서: created_at='2024-01-15 10:30:00', id=98765

-- 정답 쿼리
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-15 10:30:00', 98765)
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**결과:**
- 실행 시간: **~1ms** (항상 일정!)
- type: **range** (범위 스캔)
- rows: **10~100** (인덱스로 효율적으로 찾음)
- Extra: **Using where; Using index** 또는 없음

---

### 2-3. 성능 비교 (예상값)

| 페이지 | Offset 시간 | Cursor 시간 | 개선율 |
|--------|-------------|-------------|--------|
| 1      | 10ms        | 1ms         | 10x    |
| 100    | 100ms       | 1ms         | 100x   |
| 1000   | 800ms       | 1ms         | 800x   |
| 10000  | 8000ms      | 1ms         | 8000x  |

**핵심:**
- Cursor는 **페이지와 무관하게 항상 O(1)** 시간 복잡도
- OFFSET은 **O(N)** 시간 복잡도

---

### 2-4. Cursor의 내부 동작

```
WHERE (created_at, id) < ('2024-01-15', 98765) 실행 시:

1. B-Tree 인덱스에서 (2024-01-15, 98765) 위치 찾기
   → 이진 탐색: O(log N)

2. 그 위치에서 다음 10개 행 읽기
   → 순차 읽기: O(1)

3. 반환

총 시간 복잡도: O(log N + 10) ≈ O(1)
OFFSET과 무관!
```

---

## 미션 3: 실전 시나리오 - 사용자별 주문 내역 - 정답

### 3-1. 정답 인덱스

```sql
-- 정답 복합 인덱스
CREATE INDEX idx_user_created_id ON orders(user_id, created_at DESC, id DESC);
```

**컬럼 순서 결정 이유:**

**1번: user_id**
- WHERE 절의 **동등 조건** (`user_id = 12345`)
- 먼저 해당 사용자의 주문만 필터링
- Cardinality는 중간 정도 (사용자 수만큼)

**2번: created_at (DESC)**
- ORDER BY 주 정렬 컬럼
- user_id로 필터링된 결과를 정렬
- Cursor 범위 조건 (`<`)에 사용

**3번: id (DESC)**
- ORDER BY 2차 정렬 컬럼
- created_at 중복 처리
- unique 보장

**왜 이 순서인가?**
- 복합 인덱스는 **동등 조건 → 범위/정렬 조건** 순서
- WHERE user_id = ? AND (created_at, id) < (?, ?)
- 인덱스를 **user_id → created_at → id** 순으로 탐색

---

### 3-2. 구현 방법

#### 현재 코드 (Offset - 잘못된 방법)
```sql
-- ❌ 나쁜 예
SELECT * FROM orders
WHERE user_id = 12345
ORDER BY created_at DESC
LIMIT 20 OFFSET 500;

-- 문제점:
-- 1. user_id로 필터링: 예를 들어 1000건
-- 2. 그 중 520건을 읽고 500개 버림
-- 3. 시간: ~100ms (사용자마다 다름)
```

---

#### 개선 코드 (Cursor - 올바른 방법)
```sql
-- ✅ 좋은 예 (첫 페이지)
SELECT * FROM orders
WHERE user_id = 12345
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- ✅ 다음 페이지 (커서: created_at='2024-01-10', id=5678)
SELECT * FROM orders
WHERE user_id = 12345
  AND (created_at, id) < ('2024-01-10', 5678)
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- 시간: ~1ms (항상 일정)
```

---

### 3-3. 성능 비교 (예상값)

| 위치 | Offset 시간 | Cursor 시간 | 개선율 |
|------|-------------|-------------|--------|
| 0    | 10ms        | 1ms         | 10x    |
| 100  | 50ms        | 1ms         | 50x    |
| 500  | 200ms       | 1ms         | 200x   |

**EXPLAIN 비교:**

**Before (Offset):**
- type: **ref** (user_id 인덱스 사용)
- rows: **520** (user_id로 필터링된 결과 중 520개)
- Extra: **Using filesort** (정렬 필요)

**After (Cursor):**
- type: **range** (복합 인덱스 사용)
- rows: **20** (필요한 만큼만)
- Extra: **Using where** (filesort 사라짐!)

---

### 3-4. 잘못된 인덱스와 비교

#### 안 좋은 예시 1: (created_at, user_id, id)
```sql
-- ❌ 잘못된 인덱스
CREATE INDEX idx_wrong1 ON orders(created_at DESC, user_id, id DESC);
```

**문제점:**
- WHERE user_id = ?를 인덱스 첫 번째 컬럼으로 못 씀
- created_at 범위 스캔 → 그 안에서 user_id 필터링 (비효율)
- 인덱스 활용도 매우 낮음

---

#### 안 좋은 예시 2: (user_id, id, created_at)
```sql
-- ❌ 잘못된 인덱스
CREATE INDEX idx_wrong2 ON orders(user_id, id DESC, created_at DESC);
```

**문제점:**
- id와 created_at 순서가 바뀜
- Cursor 조건 `(created_at, id) < (?, ?)`를 제대로 못 씀
- ORDER BY created_at, id와 인덱스 순서 불일치

---

## 미션 4: 데이터 중복/누락 문제 - 정답

### 4-1. Offset 방식의 중복 현상

**시나리오:**
```sql
-- 1. 사용자가 2페이지 조회
SELECT id FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 10;
-- 결과: [id: 90, 89, 88, ..., 81]

-- 2. 새 게시글 5개 등록
INSERT INTO posts ...
-- 새 게시글 id: [101, 102, 103, 104, 105]

-- 3. 사용자가 3페이지 조회
SELECT id FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 20;
-- 결과: [id: 85, 84, 83, ..., 76]
```

**문제 발생:**
- 2페이지에서 본 id 85, 84, 83, 82, 81이
- 3페이지에서 다시 나타남! (중복)

**원인:**
- 새 게시글 5개가 앞에 추가되면서
- 기존 게시글들이 5칸씩 밀림
- OFFSET 20은 "절대 위치"가 아니라 "상대 위치"
- 데이터가 바뀌면 위치도 바뀜

---

### 4-2. Cursor 방식은 안전

**시나리오:**
```sql
-- 1. 사용자가 2페이지 조회 (커서: id=81, created_at='2024-01-10')
SELECT id FROM posts
WHERE (created_at, id) < ('2024-01-10', 81)
ORDER BY created_at DESC, id DESC
LIMIT 10;
-- 결과: [id: 80, 79, 78, ..., 71]

-- 2. 새 게시글 5개 등록
INSERT INTO posts ...
-- 새 게시글 id: [101, 102, 103, 104, 105]

-- 3. 사용자가 3페이지 조회 (커서: id=71, created_at='2024-01-09')
SELECT id FROM posts
WHERE (created_at, id) < ('2024-01-09', 71)
ORDER BY created_at DESC, id DESC
LIMIT 10;
-- 결과: [id: 70, 69, 68, ..., 61]
```

**중복 없음!**
- Cursor는 **절대값** (id=81, created_at='2024-01-10')을 기준
- "81보다 작은 것"을 찾으므로 항상 정확
- 새 게시글이 추가되어도 영향 없음

---

## 핵심 개념 정리

### 1. Row Value Comparison 문법

**올바른 사용:**
```sql
-- ✅ 정답
WHERE (created_at, id) < ('2024-01-15', 100)

-- 이것은 다음과 같은 의미:
WHERE created_at < '2024-01-15'
   OR (created_at = '2024-01-15' AND id < 100)
```

**잘못된 사용:**
```sql
-- ❌ 틀림
WHERE created_at < '2024-01-15' AND id < 100

-- 문제점:
-- created_at='2024-01-15', id=50 같은 행을 못 찾음
-- (created_at이 작지 않으므로 AND 조건 실패)
```

---

### 2. 복합 인덱스 설계 규칙 (Cursor용)

**규칙 1: WHERE 동등 조건 먼저**
```sql
-- ✅ 좋음
WHERE user_id = ? AND (created_at, id) < (?, ?)
INDEX (user_id, created_at DESC, id DESC)

-- ❌ 나쁨
INDEX (created_at DESC, user_id, id DESC)
-- user_id를 효율적으로 못 씀
```

---

**규칙 2: ORDER BY 컬럼 순서와 일치**
```sql
-- ✅ 좋음
ORDER BY created_at DESC, id DESC
INDEX (created_at DESC, id DESC)

-- ❌ 나쁨
ORDER BY created_at DESC, id DESC
INDEX (created_at ASC, id ASC)
-- 방향 불일치 → filesort 발생
```

---

**규칙 3: id 포함 필수**
```sql
-- ✅ 좋음
INDEX (created_at DESC, id DESC)

-- ⚠️ 주의
INDEX (created_at DESC)
-- created_at이 중복되면 순서 보장 안 됨
-- 중복/누락 발생 가능
```

---

### 3. Offset vs Cursor 선택 기준

#### ✅ Cursor 써야 하는 경우
1. **무한 스크롤** (SNS 피드, 상품 목록)
   - 페이지 번호 불필요
   - "더 보기" 버튼만 필요

2. **실시간 데이터** (새 글이 계속 올라오는 경우)
   - 중복/누락 방지 필요
   - 안정적인 페이지네이션 필요

3. **대용량 데이터** (100만 건 이상)
   - 깊은 페이지까지 조회
   - OFFSET 성능 문제

4. **모바일 앱**
   - 무한 스크롤 UI
   - 네트워크 효율

---

#### ✅ Offset 써도 되는 경우
1. **페이지 번호 필수** (1, 2, 3, ... 표시)
   - 예: 게시판, 관리자 페이지

2. **전체 페이지 수 필요** ("10페이지 중 3페이지")
   - COUNT(*) 쿼리 필요

3. **특정 페이지 직접 이동** ("5페이지로 가기")
   - Cursor는 순차 접근만 가능

4. **검색 결과** (Google 같은)
   - 페이지 번호 + "다음" 버튼
   - 대부분 첫 몇 페이지만 봄

5. **소량 데이터** (수천 건 이하)
   - OFFSET 성능 문제 없음

6. **정적 데이터** (거의 안 바뀜)
   - 중복/누락 문제 없음

---

## 실전 구현 팁

### 1. Cursor 인코딩

**서버 (Node.js):**
```javascript
// 커서 생성
const cursor = {
    created_at: '2024-01-15 10:30:00',
    id: 98765
};

// Base64 인코딩
const encodedCursor = Buffer.from(JSON.stringify(cursor)).toString('base64');
// 'eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0xNSAxMDozMDowMCIsImlkIjo5ODc2NX0='

// API 응답
res.json({
    data: posts,
    next_cursor: encodedCursor,
    has_more: posts.length === limit
});

// 디코딩
const decodedCursor = JSON.parse(
    Buffer.from(req.query.cursor, 'base64').toString()
);
// { created_at: '2024-01-15 10:30:00', id: 98765 }
```

---

**서버 (Python):**
```python
import base64
import json

# 인코딩
cursor = {"created_at": "2024-01-15 10:30:00", "id": 98765}
encoded = base64.b64encode(json.dumps(cursor).encode()).decode()

# 디코딩
decoded = json.loads(base64.b64decode(encoded).decode())
```

---

**서버 (Java/Spring):**
```java
// 인코딩
String cursor = String.format("{\"created_at\":\"%s\",\"id\":%d}",
    createdAt, id);
String encoded = Base64.getEncoder().encodeToString(cursor.getBytes());

// 디코딩
String decoded = new String(Base64.getDecoder().decode(encoded));
JSONObject cursorObj = new JSONObject(decoded);
```

---

### 2. NULL 처리

**created_at이 NULL일 수 있는 경우:**

```sql
-- ❌ 문제 발생
SELECT * FROM posts
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- NULL 행은 조회 안 됨!
```

**해결 방법 1: COALESCE 사용**
```sql
-- ✅ NULL을 특정 값으로 치환
SELECT * FROM posts
ORDER BY COALESCE(created_at, '1970-01-01') DESC, id DESC
LIMIT 10;

-- 인덱스: (created_at DESC, id DESC)는 그대로 사용 가능
-- 단, 함수 사용으로 인덱스 효율 약간 저하
```

**해결 방법 2: NULL을 맨 앞 또는 맨 뒤로**
```sql
-- MySQL에서 NULL은 ORDER BY DESC 시 맨 앞에 옴
-- NULL을 최신으로 취급하려면 그대로 사용
ORDER BY created_at DESC NULLS FIRST, id DESC

-- NULL을 가장 오래된 것으로 취급하려면
ORDER BY created_at DESC NULLS LAST, id DESC
```

**해결 방법 3: 애플리케이션에서 분리**
```sql
-- NULL인 것과 NOT NULL인 것을 별도 쿼리
SELECT * FROM posts
WHERE created_at IS NULL
ORDER BY id DESC
LIMIT 10;

UNION ALL

SELECT * FROM posts
WHERE created_at IS NOT NULL
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

---

### 3. 역방향 페이지네이션 (이전 페이지)

**"이전 페이지"로 올라가기:**

```sql
-- 다음 페이지 (아래로)
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-15', 100)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 이전 페이지 (위로)
SELECT * FROM posts
WHERE (created_at, id) > ('2024-01-15', 100)
ORDER BY created_at ASC, id ASC
LIMIT 10;

-- ⚠️ 주의: 결과를 애플리케이션에서 reverse() 처리!
```

**애플리케이션 코드 (JavaScript):**
```javascript
// 이전 페이지 조회
const posts = await db.query(`
    SELECT * FROM posts
    WHERE (created_at, id) > (?, ?)
    ORDER BY created_at ASC, id ASC
    LIMIT ?
`, [cursor.created_at, cursor.id, limit]);

// 결과를 뒤집기
posts.reverse();

// 커서 생성 (마지막 행 기준)
const nextCursor = {
    created_at: posts[posts.length - 1].created_at,
    id: posts[posts.length - 1].id
};
```

---

### 4. has_more 플래그

**"더 보기" 버튼을 보여줄지 판단:**

```javascript
// LIMIT보다 1개 더 조회
const limit = 10;
const posts = await db.query(`
    SELECT * FROM posts
    WHERE (created_at, id) < (?, ?)
    ORDER BY created_at DESC, id DESC
    LIMIT ?
`, [cursor.created_at, cursor.id, limit + 1]);

// has_more 판단
const hasMore = posts.length > limit;

// limit 만큼만 반환
if (hasMore) {
    posts.pop(); // 마지막 1개 제거
}

res.json({
    data: posts,
    next_cursor: encodeCursor(posts[posts.length - 1]),
    has_more: hasMore
});
```

---

### 5. 복잡한 필터링과 Cursor 조합

**여러 WHERE 조건이 있는 경우:**

```sql
-- 예: 카테고리별 게시글 조회
SELECT * FROM posts
WHERE category = 'tech'
  AND status = 'published'
  AND (created_at, id) < ('2024-01-15', 100)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 필요한 인덱스:
CREATE INDEX idx_category_status_created_id
ON posts(category, status, created_at DESC, id DESC);

-- 인덱스 순서:
-- 1. category (동등 조건)
-- 2. status (동등 조건)
-- 3. created_at (범위 조건 + ORDER BY)
-- 4. id (ORDER BY)
```

---

## 실무 체크리스트

### Cursor 페이지네이션 구현 전

#### 기술적 검토
- [ ] 복합 인덱스 설계 및 크기 예상
- [ ] DESC/ASC 방향 확인
- [ ] NULL 처리 방안 검토
- [ ] 기존 쿼리 성능 측정

#### 협업 사항
- [ ] 프론트엔드와 API 스펙 논의
- [ ] 기존 Offset API와 병행 운영 계획
- [ ] 마이그레이션 일정 수립
- [ ] QA 테스트 시나리오 작성

#### 모니터링
- [ ] 성능 지표 추가 (응답 시간, 쿼리 실행 시간)
- [ ] 에러 알림 설정 (커서 디코딩 실패 등)
- [ ] 슬로우 쿼리 로그 확인

---

### Cursor 페이지네이션 구현 후

#### 성능 검증
- [ ] Before/After 성능 비교
- [ ] 다양한 페이지 위치에서 테스트
- [ ] 부하 테스트 (동시 사용자 증가)
- [ ] 인덱스 사용 확인 (EXPLAIN)

#### 기능 검증
- [ ] 중복/누락 없는지 확인
- [ ] NULL 데이터 처리 확인
- [ ] has_more 플래그 정확성
- [ ] 이전 페이지 동작 (있다면)

#### 문서화
- [ ] API 문서 업데이트
- [ ] 팀 위키에 구현 가이드 작성
- [ ] 코드 리뷰 체크리스트 추가

---

## 주의사항

### 1. 인덱스 생성 시 주의
```sql
-- 대용량 테이블에 인덱스 생성 시:

-- ❌ 운영 DB에서 바로 실행 금지
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);
-- 테이블 잠금 발생 가능!

-- ✅ MySQL 5.6+ 온라인 DDL 사용
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC)
ALGORITHM=INPLACE, LOCK=NONE;

-- ✅ pt-online-schema-change 사용 (Percona Toolkit)
pt-online-schema-change \
  --alter "ADD INDEX idx_created_id (created_at DESC, id DESC)" \
  --execute \
  D=mydb,t=posts
```

---

### 2. 커서 보안
```sql
-- ❌ 커서를 그대로 노출하면 사용자가 조작 가능
?cursor=2024-01-15,12345

-- ✅ Base64 인코딩 (난독화)
?cursor=eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0xNSIsImlkIjoxMjM0NX0=

-- ✅ 서명 추가 (위변조 방지)
const signature = hmac('sha256', cursor, SECRET_KEY);
const signedCursor = `${encodedCursor}.${signature}`;

// 검증
const [encoded, sig] = req.query.cursor.split('.');
const expectedSig = hmac('sha256', encoded, SECRET_KEY);
if (sig !== expectedSig) {
    throw new Error('Invalid cursor');
}
```

---

### 3. 캐싱 고려
```sql
-- Cursor 페이지네이션은 캐싱이 어려움

-- Offset 방식:
-- GET /api/posts?page=2 → 항상 같은 결과 (캐시 가능)

-- Cursor 방식:
-- GET /api/posts?cursor=abc123 → 데이터 변경 시 결과 달라짐

-- 해결: 짧은 TTL 캐싱 또는 캐싱 포기
```

---

## 다음 주차 예고: Week 7 - N+1 문제 해결

Cursor 페이지네이션을 완벽히 구현했다면,
다음은 ORM의 대표적인 성능 문제인 **N+1 쿼리**를 해결할 차례입니다!

- N+1 문제 발견 및 분석
- Eager Loading vs Lazy Loading
- JPA/Hibernate 최적화
- 실전 쿼리 개선 사례

---

## 추가 학습 자료

### 1. MySQL 공식 문서
- [Row Constructor Expression](https://dev.mysql.com/doc/refman/8.0/en/comparison-operators.html#row-constructor-expression-comparison)
- [Index Optimization](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)

### 2. 블로그 글
- [Use The Index, Luke: No Offset](https://use-the-index-luke.com/no-offset)
- [Cursor-based Pagination](https://www.sitepoint.com/paginating-real-time-data-cursor-based-pagination/)

### 3. GraphQL Relay Cursor Spec
- [Relay Cursor Connections Specification](https://relay.dev/graphql/connections.htm)

---

**완료 축하합니다!** 🎉

이제 당신은 페이지네이션 최적화 전문가입니다!
무한 스크롤 API를 만나도 자신 있게 Cursor 방식으로 구현할 수 있습니다.

**다음 액션:**
1. [ ] ANSWER.md와 이 SOLUTION.md 비교
2. [ ] 틀린 부분 복습
3. [ ] 실무 API 1개 이상 Cursor로 전환
4. [ ] 성능 개선 효과 측정 및 공유
5. [ ] Week 7 미션 시작

**실무 적용 목표:**
- 1주일 내: 인덱스 설계 및 추가
- 2주일 내: Cursor API 구현 및 배포
- 1달 내: Before/After 성능 비교 및 팀 공유
