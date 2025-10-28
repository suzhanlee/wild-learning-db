# Week 6 답안: 페이지네이션 최적화

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: Offset 지옥 체험하기

### 1-1. 환경 확인

```sql
-- posts 테이블 데이터 건수
SELECT COUNT(*) FROM posts;
-- 결과: _____

-- 인덱스 확인
SHOW INDEX FROM posts;
-- 결과: (붙여넣기)
```

---

### 1-2. Offset 방식 성능 측정

#### 실행 시간 측정 설정
```sql
SET profiling = 1;
RESET QUERY CACHE; -- 캐시 영향 제거
```

#### 1페이지 (OFFSET 0)
```sql
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

-- 실행 시간: _____ms
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

-- 결과:
```

| type | rows | Extra |
|------|------|-------|
|      |      |       |

---

#### 100페이지 (OFFSET 990)
```sql
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 990;

-- 실행 시간: _____ms
```

---

#### 1000페이지 (OFFSET 9990)
```sql
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 9990;

-- 실행 시간: _____ms
```

---

#### 10000페이지 (OFFSET 99990)
```sql
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 99990;

-- 실행 시간: _____ms
```

---

### 1-3. 성능 분석

#### 실행 시간 비교표
| 페이지 | OFFSET | 실행 시간 | 배율 (1페이지 대비) |
|--------|--------|-----------|---------------------|
| 1      | 0      | ___ms     | 1x                  |
| 100    | 990    | ___ms     | ___x                |
| 1000   | 9990   | ___ms     | ___x                |
| 10000  | 99990  | ___ms     | ___x                |

#### 왜 느려지는가?

**원인 분석:**
1. MySQL의 내부 동작:
   -
   -
   -

2. OFFSET이 클수록 느려지는 이유:
   -
   -

3. 실제 검사한 rows:
   - OFFSET 0: _____
   - OFFSET 99990: _____

**결론:**
-

---

## 미션 2: Cursor 페이지네이션 구현

### 2-1. 인덱스 생성

```sql
-- 생성한 인덱스
CREATE INDEX idx_______________ ON posts(_________, _________);

-- 생성 시간: _____초
```

**이 인덱스를 선택한 이유:**
1. created_at: _____
2. id: _____
3. DESC 방향: _____

---

### 2-2. Cursor 방식 성능 측정

#### 첫 페이지
```sql
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 실행 시간: _____ms

-- 마지막 행의 값:
-- created_at: _____
-- id: _____
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 결과:
```

| type | key | rows | Extra |
|------|-----|------|-------|
|      |     |      |       |

---

#### 100페이지 상당 (Cursor 100번 이동)

**실제 구현:**
```sql
-- 100번째 페이지의 마지막 커서를 구하기 위해
-- 임시로 OFFSET 사용 (실전에서는 실제로 100번 호출)
SELECT created_at, id FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 999;

-- 결과:
-- created_at: _____
-- id: _____

-- 이 커서로 다음 페이지 조회
SELECT * FROM posts
WHERE (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 실행 시간: _____ms
```

---

#### 1000페이지 상당 (Cursor 1000번 이동)

```sql
-- 1000번째 페이지 커서 구하기
SELECT created_at, id FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 9999;

-- 결과:
-- created_at: _____
-- id: _____

-- Cursor 방식 조회
SELECT * FROM posts
WHERE (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 실행 시간: _____ms
```

---

#### 10000페이지 상당 (Cursor 10000번 이동)

```sql
-- 10000번째 페이지 커서
SELECT created_at, id FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 99999;

-- 결과:
-- created_at: _____
-- id: _____

-- Cursor 방식 조회
SELECT * FROM posts
WHERE (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 실행 시간: _____ms
```

---

### 2-3. Cursor 성능 분석

#### 실행 시간 비교표
| 페이지 상당 | 실행 시간 | 일정한가? |
|-------------|-----------|-----------|
| 1           | ___ms     | -         |
| 100         | ___ms     | ✓ / ✗     |
| 1000        | ___ms     | ✓ / ✗     |
| 10000       | ___ms     | ✓ / ✗     |

**EXPLAIN 분석 결과:**
- type: _____
- rows: _____
- Extra: _____

**왜 일정한가?**
-

---

### 2-4. Offset vs Cursor 최종 비교

| 페이지 | Offset 시간 | Cursor 시간 | 개선율 |
|--------|-------------|-------------|--------|
| 1      | ___ms       | ___ms       | ___x   |
| 100    | ___ms       | ___ms       | ___x   |
| 1000   | ___ms       | ___ms       | ___x   |
| 10000  | ___ms       | ___ms       | ___x   |

**성공 여부:** [ ] 모든 페이지 10ms 이내 달성

---

## 미션 3: 실전 시나리오 - 사용자별 주문 내역

### 3-1. 현재 상황 (Offset 방식)

#### 테스트 사용자 선택
```sql
-- 주문이 많은 사용자 찾기
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 5;

-- 선택한 user_id: _____
-- 주문 건수: _____
```

---

#### Offset 방식 성능 측정

**OFFSET 0:**
```sql
SELECT * FROM orders
WHERE user_id = _____
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- 실행 시간: _____ms
```

**OFFSET 100:**
```sql
SELECT * FROM orders
WHERE user_id = _____
ORDER BY created_at DESC
LIMIT 20 OFFSET 100;

-- 실행 시간: _____ms
```

**OFFSET 500:**
```sql
SELECT * FROM orders
WHERE user_id = _____
ORDER BY created_at DESC
LIMIT 20 OFFSET 500;

-- 실행 시간: _____ms
```

**EXPLAIN 분석 (OFFSET 500):**
```sql
EXPLAIN SELECT * FROM orders
WHERE user_id = _____
ORDER BY created_at DESC
LIMIT 20 OFFSET 500;

-- 결과:
```

| type | rows | Extra |
|------|------|-------|
|      |      |       |

**문제점 파악:**
-

---

### 3-2. Cursor 방식으로 개선

#### 복합 인덱스 설계
```sql
-- 설계한 인덱스
CREATE INDEX idx_______________ ON orders(_________, _________, _________);
```

**컬럼 순서 결정 이유:**
1. user_id: _____
2. created_at: _____
3. id: _____

**왜 이 순서인가?**
-

---

#### Cursor 방식 구현

**첫 페이지:**
```sql
SELECT * FROM orders
WHERE user_id = _____
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- 실행 시간: _____ms
-- 마지막 커서: created_at=_____, id=_____
```

**100건째 이후:**
```sql
-- 100번째 주문의 커서 구하기
SELECT created_at, id FROM orders
WHERE user_id = _____
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 99;

-- 결과: created_at=_____, id=_____

-- Cursor 방식 조회
SELECT * FROM orders
WHERE user_id = _____
  AND (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- 실행 시간: _____ms
```

**500건째 이후:**
```sql
-- 500번째 주문의 커서
SELECT created_at, id FROM orders
WHERE user_id = _____
ORDER BY created_at DESC, id DESC
LIMIT 1 OFFSET 499;

-- 결과: created_at=_____, id=_____

-- Cursor 방식 조회
SELECT * FROM orders
WHERE user_id = _____
  AND (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- 실행 시간: _____ms
```

---

### 3-3. 성능 비교

| 위치 | Offset 시간 | Cursor 시간 | 개선율 |
|------|-------------|-------------|--------|
| 0    | ___ms       | ___ms       | ___x   |
| 100  | ___ms       | ___ms       | ___x   |
| 500  | ___ms       | ___ms       | ___x   |

**성공 여부:** [ ] 10배 이상 개선 달성

**EXPLAIN 비교:**

Before (Offset):
- type: _____
- rows: _____
- Extra: _____

After (Cursor):
- type: _____
- rows: _____
- Extra: _____

---

## 미션 4: 데이터 중복/누락 문제 (선택)

### 4-1. Offset 방식의 중복 현상 재현

#### 초기 상태
```sql
-- 2페이지 조회
SELECT id, title, created_at FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 10;

-- 결과 (id만 기록):
-- [___, ___, ___, ___, ___, ___, ___, ___, ___, ___]
```

---

#### 새 게시글 5개 추가
```sql
INSERT INTO posts (user_id, title, content, created_at)
VALUES
    (1, 'New Post 1', 'Content 1', NOW()),
    (2, 'New Post 2', 'Content 2', NOW()),
    (3, 'New Post 3', 'Content 3', NOW()),
    (4, 'New Post 4', 'Content 4', NOW()),
    (5, 'New Post 5', 'Content 5', NOW());
```

---

#### 3페이지 조회
```sql
SELECT id, title, created_at FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 20;

-- 결과 (id만 기록):
-- [___, ___, ___, ___, ___, ___, ___, ___, ___, ___]
```

**중복 발견:**
- [ ] 2페이지와 3페이지에서 중복된 게시글 있음
- 중복된 id: _____

**왜 중복이 발생하나?**
-

---

### 4-2. Cursor 방식은 안전한가?

#### 2페이지 조회 (Cursor)
```sql
-- 첫 페이지
SELECT id, title, created_at FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 마지막 커서: created_at=_____, id=_____

-- 2페이지
SELECT id, title, created_at FROM posts
WHERE (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 결과 (id만 기록):
-- [___, ___, ___, ___, ___, ___, ___, ___, ___, ___]
```

---

#### 새 게시글 추가 후 3페이지
```sql
-- 새 게시글 5개 추가 (위와 동일)

-- 3페이지 (2페이지의 마지막 커서 사용)
SELECT id, title, created_at FROM posts
WHERE (created_at, id) < ('_____', _____)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 결과 (id만 기록):
-- [___, ___, ___, ___, ___, ___, ___, ___, ___, ___]
```

**중복 여부:**
- [ ] 중복 없음
- [ ] 중복 있음

**왜 Cursor는 안전한가?**
-

---

## 학습 정리

### 배운 핵심 개념 3가지
1.
2.
3.

---

### Offset vs Cursor 비교 (내가 정리한 기준)

| 항목 | Offset | Cursor |
|------|--------|--------|
| 성능 | | |
| 데이터 중복/누락 | | |
| 특정 페이지 이동 | | |
| 구현 복잡도 | | |
| 적합한 사례 | | |

---

### Cursor 구현 체크리스트
- [ ] 복합 인덱스 생성 (정렬 컬럼 + id)
- [ ] Row Value Comparison 사용
- [ ] ORDER BY에 id 포함 (unique 보장)
- [ ] 인덱스 방향(DESC/ASC)과 쿼리 일치
- [ ] user_id 등 필터 조건은 인덱스 맨 앞

---

### 언제 Cursor를 쓸 것인가?

**✅ Cursor 써야 하는 경우:**
-
-
-

**✅ Offset이 나은 경우:**
-
-
-

---

## 실무 적용 계획

### 즉시 적용할 부분

**현재 회사/프로젝트:**
-

**적용 대상 API 1:**
```
- API: _____
- 현재 방식: Offset / Cursor
- 데이터 건수: _____
- 예상 개선 효과: _____
```

**구현 계획:**
```sql
-- 현재 쿼리
SELECT ...

-- 변경 후 쿼리
SELECT ...

-- 필요한 인덱스
CREATE INDEX ...
```

---

**적용 대상 API 2:**
```
- API: _____
- 현재 방식: Offset / Cursor
- 데이터 건수: _____
- 예상 개선 효과: _____
```

**구현 계획:**
```sql
-- 현재 쿼리


-- 변경 후 쿼리


-- 필요한 인덱스

```

---

### 프론트엔드 협업 사항

**API 변경 내용:**
```
Before:
GET /api/posts?page=2&limit=10

After:
GET /api/posts?cursor=eyJ...&limit=10
```

**응답 형식:**
```json
{
    "data": [...],
    "next_cursor": "eyJ...",
    "has_more": true
}
```

**프론트엔드 변경 필요 사항:**
1.
2.
3.

---

### 주의사항 체크리스트
- [ ] 인덱스 생성 전 운영 DB 부하 확인
- [ ] 프론트엔드와 API 변경 일정 조율
- [ ] 기존 Offset 방식과 병행 운영 기간 설정
- [ ] 모니터링 대시보드에 성능 지표 추가
- [ ] Cursor 인코딩/디코딩 에러 처리

---

## 트러블슈팅

### 겪은 문제 1
**문제:**


**시도한 방법:**


**해결:**


**배운 점:**


---

### 겪은 문제 2
**문제:**


**시도한 방법:**


**해결:**


**배운 점:**


---

## 추가 실험 (선택)

### 실험 1: 역방향 페이지네이션
```sql
-- "이전 페이지"로 가기
SELECT * FROM posts
WHERE (created_at, id) > (?, ?)
ORDER BY created_at ASC, id ASC
LIMIT 10;

-- 결과를 reverse() 처리

-- 실행 시간: _____ms
```

**결과:**
-

---

### 실험 2: NULL 처리
```sql
-- created_at이 NULL인 데이터 삽입
INSERT INTO posts (user_id, title, content, created_at)
VALUES (1, 'Test', 'Test', NULL);

-- Cursor 쿼리가 제대로 동작하나?


-- 결과:
```

---

### 실험 3: Cursor 인코딩
```javascript
// Node.js 예제
const cursor = {
    created_at: '2024-01-15 10:30:00',
    id: 98765
};

const encoded = Buffer.from(JSON.stringify(cursor)).toString('base64');
console.log(encoded);
// 결과: _____

const decoded = JSON.parse(Buffer.from(encoded, 'base64').toString());
console.log(decoded);
// 결과: _____
```

---

## 성능 그래프 (선택)

### Offset vs Cursor 실행 시간 비교

```
실행 시간 (ms)
  |
  |        Offset (선형 증가)
  |                     /
  |                   /
  |                 /
  |               /
  |             /
  |           /
  |         /
  |_______/_________________ Cursor (일정)
  |
  +-----------------------------------> 페이지
    1   100   1000   10000
```

---

## 다음 액션

### 팀 공유 내용
- [ ] Offset vs Cursor 성능 비교 결과
- [ ] Cursor 구현 가이드 문서화
- [ ] 코드 리뷰 시 Pagination 체크리스트

---

### 추가 학습 필요
- [ ] Elasticsearch 페이지네이션 방식
- [ ] GraphQL Relay Cursor Connections
- [ ] Keyset Pagination 변형 패턴

---

### 실무 적용 기한
- [ ] 1주일 내 인덱스 추가
- [ ] 2주일 내 API 변경 및 배포
- [ ] 1달 내 성능 개선 효과 측정
- [ ] 팀 회고 공유

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
- [ ] 실무 적용 결과 공유
