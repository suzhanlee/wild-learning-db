# Week 6: 페이지네이션 최적화 ⭐⭐⭐

> "Offset 지옥 탈출"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"무한 스크롤을 빠르게 구현하기"**

이번 주차를 완료하면:
- Offset 방식의 문제점 이해
- Cursor 방식으로 전환 가능
- 적절한 페이지네이션 방식 선택 가능
- 성능 10배 이상 개선 가능

---

## 📚 학습 내용

### 1. Offset 방식의 문제 (15분)

#### 일반적인 페이지네이션
```sql
-- 1페이지 (0~10)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 0;

-- 2페이지 (10~20)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 10;

-- 100페이지 (990~1000)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 990;
```

#### 문제점

**문제 1: OFFSET이 클수록 느림**
```sql
-- 10000페이지
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 99990;

내부 동작:
1. 100,000개 행 읽기
2. 99,990개 버리기
3. 10개만 반환

시간 복잡도: O(N)
OFFSET이 크면 엄청 느림!
```

**문제 2: 데이터 중복/누락**
```sql
-- 사용자가 2페이지 보는 중
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 10;

-- 동시에 새 게시글 3개 등록됨

-- 사용자가 3페이지로 이동
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 20;

결과: 2페이지에서 본 게시글 3개가 또 나옴 (중복!)
```

#### 성능 비교
```
데이터: 100만 건

OFFSET 0:     10ms
OFFSET 1000:  50ms
OFFSET 10000: 500ms
OFFSET 100000: 5000ms (5초!)
```

---

### 2. Cursor 방식 (커서 페이지네이션) (20분)

#### 핵심 아이디어
```
"마지막으로 본 항목" 기준으로 다음 항목 조회
OFFSET 대신 WHERE 조건 사용
```

#### 구현 방법

**기본 구조**
```sql
-- 첫 페이지
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

결과:
- id: 100, created_at: 2024-01-10
- id: 99, created_at: 2024-01-10
- ...
- id: 91, created_at: 2024-01-09  ← 마지막 커서

-- 다음 페이지 (커서: created_at=2024-01-09, id=91)
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-09', 91)
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**중요: 복합 정렬 처리**
```sql
-- ❌ 틀린 방법
WHERE created_at < '2024-01-09' AND id < 91

-- ✅ 올바른 방법 (Row Value Comparison)
WHERE (created_at, id) < ('2024-01-09', 91)

-- 또는
WHERE created_at < '2024-01-09'
   OR (created_at = '2024-01-09' AND id < 91)
```

#### 인덱스 필수!
```sql
-- Cursor 페이지네이션에는 복합 인덱스 필요
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);

인덱스 없으면:
  Offset보다 더 느림!
```

---

### 3. Cursor 방식 장단점 (10분)

#### 장점 ✅
```
1. 성능: 항상 O(1) - OFFSET과 무관
2. 안정성: 데이터 중복/누락 없음
3. 확장성: 데이터 많아도 빠름
```

#### 단점 ❌
```
1. 특정 페이지 직접 이동 불가 (예: 10페이지로 바로 가기)
2. 전체 페이지 수 표시 어려움
3. 구현 복잡도 높음
```

#### 사용 사례
```
✅ Cursor 방식 적합:
- 무한 스크롤 (SNS 피드)
- 실시간 피드
- 모바일 앱
- 데이터가 계속 추가되는 경우

✅ Offset 방식 적합:
- 페이지 번호 필요 (1, 2, 3, ...)
- 전체 페이지 수 표시
- 검색 결과 (예: Google)
- 데이터가 거의 안 바뀌는 경우
```

---

### 4. 실전 구현 팁 (15분)

#### 팁 1: Cursor 인코딩
```javascript
// 커서를 Base64로 인코딩
const cursor = {
    created_at: '2024-01-09',
    id: 91
};

const encodedCursor = Buffer.from(JSON.stringify(cursor)).toString('base64');
// eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wOSIsImlkIjo5MX0=

// API 응답
{
    data: [...],
    next_cursor: 'eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wOSIsImlkIjo5MX0='
}
```

#### 팁 2: 중복 created_at 처리
```sql
-- 같은 시간에 생성된 게시글 처리
-- id를 추가로 사용 (UNIQUE하므로)

CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);

SELECT * FROM posts
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

#### 팁 3: 역방향 페이지네이션
```sql
-- 이전 페이지 (올라가기)
SELECT * FROM posts
WHERE (created_at, id) > (?, ?)
ORDER BY created_at ASC, id ASC
LIMIT 10;

-- 결과를 역순으로 뒤집기 (애플리케이션 레벨)
```

---

## 🔬 실습

### 실습 1: Offset vs Cursor 성능 비교 (20분)

```sql
-- 준비: 100만 건 데이터
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200),
    content TEXT,
    created_at DATETIME,
    INDEX idx_created (created_at)
);

-- 더미 데이터 삽입 (생략)

-- 테스트 1: Offset 방식
-- 1페이지
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;
-- 실행시간: _____ms

-- 100페이지
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 990;
-- 실행시간: _____ms

-- 1000페이지
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 9990;
-- 실행시간: _____ms

-- 10000페이지
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 99990;
-- 실행시간: _____ms

-- 테스트 2: Cursor 방식
-- 인덱스 추가
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);

-- 1페이지
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;
-- 실행시간: _____ms
-- 마지막: created_at=_____, id=_____

-- 100페이지 (커서 100번 이동)
SELECT * FROM posts
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 10;
-- 실행시간: _____ms (각 호출)

-- 1000페이지
-- 실행시간: _____ms (각 호출)

-- 10000페이지
-- 실행시간: _____ms (각 호출)
```

#### 성능 비교표
| 페이지 | Offset 시간 | Cursor 시간 | 개선율 |
|--------|-------------|-------------|--------|
| 1 | | | |
| 100 | | | |
| 1000 | | | |
| 10000 | | | |

---

### 실습 2: Cursor 페이지네이션 구현 (25분)

```sql
-- API 엔드포인트 시뮬레이션

-- GET /api/posts?limit=10
-- 첫 페이지
SELECT id, title, created_at
FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 응답
{
    "data": [
        {"id": 100, "title": "...", "created_at": "2024-01-10"},
        ...
        {"id": 91, "title": "...", "created_at": "2024-01-09"}
    ],
    "next_cursor": "eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wOSIsImlkIjo5MX0="
}

-- GET /api/posts?limit=10&cursor=eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0wOSIsImlkIjo5MX0=
-- 커서 디코딩: created_at=2024-01-09, id=91

SELECT id, title, created_at
FROM posts
WHERE (created_at, id) < ('2024-01-09', 91)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 코드 구현 (Pseudo)
function getPosts(limit, cursor) {
    if (cursor) {
        // 커서 디코딩
        decoded = base64_decode(cursor)
        created_at = decoded.created_at
        id = decoded.id

        // 쿼리
        query = "SELECT * FROM posts
                 WHERE (created_at, id) < (?, ?)
                 ORDER BY created_at DESC, id DESC
                 LIMIT ?"
        results = execute(query, [created_at, id, limit])
    } else {
        // 첫 페이지
        query = "SELECT * FROM posts
                 ORDER BY created_at DESC, id DESC
                 LIMIT ?"
        results = execute(query, [limit])
    }

    // 다음 커서 생성
    if (results.length > 0) {
        last = results[results.length - 1]
        next_cursor = base64_encode({
            created_at: last.created_at,
            id: last.id
        })
    }

    return {
        data: results,
        next_cursor: next_cursor
    }
}
```

---

### 실습 3: 회사 코드 개선 (15분)

```sql
-- 현재 코드 (Offset 방식)
SELECT * FROM orders
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 10 OFFSET ?;

-- 분석
- 데이터 건수: _____
- 평균 OFFSET: _____
- 평균 응답 시간: _____ms
- 문제점: _____

-- 개선 (Cursor 방식)
-- 1. 인덱스 추가
CREATE INDEX idx_user_created_id
ON orders(user_id, created_at DESC, id DESC);

-- 2. 쿼리 변경
SELECT * FROM orders
WHERE user_id = ?
  AND (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 3. 성능 측정
-- Before: _____ms
-- After: _____ms
-- 개선율: _____%
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] Offset 방식의 문제점 이해 (성능, 중복/누락)
- [ ] Cursor 방식 원리 이해
- [ ] Row Value Comparison 문법 숙지
- [ ] Cursor vs Offset 사용 사례 구분

### 실습 완료
- [ ] Offset vs Cursor 성능 비교 실험
- [ ] Cursor 페이지네이션 구현
- [ ] 복합 인덱스 생성 및 검증
- [ ] 회사 코드 개선 (있다면)

### 실무 적용
- [ ] 무한 스크롤 API를 Cursor 방식으로 전환
- [ ] 적절한 인덱스 추가
- [ ] API 문서 업데이트
- [ ] 프론트엔드와 협업

---

## 📝 학습 노트

### Cursor 구현 체크리스트
- [ ] 복합 인덱스 생성 (정렬 컬럼 + id)
- [ ] Row Value Comparison 사용
- [ ] Cursor 인코딩/디코딩
- [ ] NULL 처리
- [ ] 역방향 페이지네이션 (선택)

### 실무 적용 사례

**개선한 API:**
- 엔드포인트: _____
- Before 성능: _____ms
- After 성능: _____ms
- 개선율: _____%

**배운 점:**
-

---

## 📚 참고 자료

- [Cursor Pagination vs Offset Pagination](https://www.sitepoint.com/paginating-real-time-data-cursor-based-pagination/)
- [Use The Index, Luke: Pagination](https://use-the-index-luke.com/no-offset)

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐⭐ 중상
**즉시 적용**: ✓
**ROI**: 높음

**완료일**: ___________
