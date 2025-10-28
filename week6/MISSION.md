# Week 6 미션: 페이지네이션 최적화하기 🎯

> "Offset 지옥에서 탈출하기"

---

## 📋 미션 개요

당신은 SNS 서비스의 백엔드 개발자입니다.
최근 사용자들이 피드를 많이 내릴수록 앱이 느려진다는 불만이 쇄도하고 있습니다.

**문제 상황:**
- `posts` 테이블에 100만 건의 게시글
- 무한 스크롤 방식의 피드
- 스크롤을 많이 내릴수록 로딩 시간이 기하급수적으로 증가
- 현재 방식: OFFSET 기반 페이지네이션

**당신의 임무:**
Cursor 기반 페이지네이션으로 전환해서 **어느 페이지든 일정한 성능**을 유지하세요!

---

## 🎯 미션 목표

### 미션 1: Offset 지옥 체험하기 (필수)

**상황:**
현재 무한 스크롤은 OFFSET 방식으로 구현되어 있습니다.

```sql
-- 1페이지 (최신 10개)
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;

-- 100페이지 (990~1000번째)
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 990;

-- 1000페이지 (9990~10000번째)
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 9990;
```

**성공 기준:**
- [ ] 1페이지, 100페이지, 1000페이지, 10000페이지 실행 시간 측정
- [ ] EXPLAIN으로 각 페이지의 rows 확인
- [ ] OFFSET이 증가할수록 성능이 어떻게 변하는지 그래프/표로 정리
- [ ] "왜 느려지는가?" 원인 분석

**힌트:**
- MySQL은 OFFSET 1000이면 처음부터 1010개를 읽고 1000개를 버립니다
- 실행 시간 측정: `SET profiling = 1;` 후 `SHOW PROFILES;`

---

### 미션 2: Cursor 페이지네이션 구현 (필수)

**상황:**
OFFSET 대신 "마지막으로 본 게시글" 기준으로 다음 페이지를 조회합니다.

```sql
-- 첫 페이지
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- 다음 페이지 (마지막 게시글: created_at='2024-01-15 10:30:00', id=98765)
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-15 10:30:00', 98765)
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**성공 기준:**
- [ ] 적절한 복합 인덱스 생성
- [ ] Cursor 방식으로 1페이지, 100페이지 상당, 1000페이지 상당 조회
- [ ] 각 페이지 실행 시간이 일정한지 확인
- [ ] EXPLAIN으로 type, rows 확인
- [ ] **모든 페이지가 10ms 이내 응답**

**힌트:**
- Row Value Comparison 문법: `WHERE (a, b) < (?, ?)`
- 복합 인덱스 필수: `CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC)`
- id를 함께 사용하는 이유: created_at이 중복될 수 있음

---

### 미션 3: 실전 시나리오 - 사용자별 주문 내역 (필수)

**상황:**
사용자의 주문 내역을 보여주는 API가 느립니다.

```sql
-- 현재 코드 (Offset 방식)
SELECT * FROM orders
WHERE user_id = 12345
ORDER BY created_at DESC
LIMIT 20 OFFSET 100;
```

주문이 많은 사용자(1000건+)는 페이지를 넘길 때마다 느려집니다.

**성공 기준:**
- [ ] 현재 OFFSET 방식의 성능 측정 (OFFSET 0, 100, 500)
- [ ] Cursor 방식으로 개선
- [ ] 적절한 복합 인덱스 설계 (user_id 포함)
- [ ] Before/After 성능 비교
- [ ] **최소 10배 이상 성능 개선**

**주의사항:**
- user_id로 먼저 필터링 후 정렬해야 함
- 복합 인덱스 순서가 매우 중요!

---

### 미션 4: 데이터 중복/누락 문제 (선택)

**상황:**
사용자가 피드를 보는 중에 새 게시글이 계속 올라옵니다.

```sql
-- 사용자가 2페이지를 보는 중
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 10;

-- 동시에 새 게시글 5개 등록됨

-- 사용자가 3페이지로 이동
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 20;

-- 결과: 2페이지에서 본 게시글 일부가 또 나타남 (중복!)
```

**성공 기준:**
- [ ] Offset 방식의 중복/누락 현상 재현
- [ ] Cursor 방식으로 해결 확인
- [ ] 왜 Cursor는 중복/누락이 없는지 설명

**힌트:**
- 실제로 게시글을 INSERT하면서 테스트해보세요
- Cursor는 절대값(id, created_at) 기준이므로 안전합니다

---

## 💡 제공되는 환경

### 테이블 구조

**posts 테이블:**
```sql
-- posts 테이블이 없다면 생성
CREATE TABLE IF NOT EXISTS posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    title VARCHAR(200),
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_created (created_at)
);

-- 100만 건 더미 데이터 생성 (시간이 좀 걸립니다)
-- 이미 users 테이블이 있다면 활용
```

**orders 테이블:**
```sql
-- 이미 존재하는 orders 테이블 활용
-- 데이터: 1,000,000 건
```

### 더미 데이터 생성 스크립트

**posts 테이블 데이터 생성:**
```sql
-- 100만 건 생성 (한번에 생성하면 오래 걸림)
-- 1만 건씩 100번 반복

DELIMITER $$
CREATE PROCEDURE generate_posts()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE batch INT DEFAULT 0;

    WHILE batch < 100 DO
        SET i = 0;
        WHILE i < 10000 DO
            INSERT INTO posts (user_id, title, content, created_at)
            VALUES (
                FLOOR(1 + RAND() * 10000),
                CONCAT('Post Title ', batch * 10000 + i),
                CONCAT('Post Content ', batch * 10000 + i),
                DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY) + INTERVAL FLOOR(RAND() * 86400) SECOND
            );
            SET i = i + 1;
        END WHILE;
        SET batch = batch + 1;
    END WHILE;
END$$
DELIMITER ;

-- 실행
CALL generate_posts();

-- 확인
SELECT COUNT(*) FROM posts;
```

---

## 🔍 참고: Row Value Comparison

**Row Value Comparison이란?**
MySQL에서 여러 컬럼을 동시에 비교하는 문법입니다.

```sql
-- ✅ 올바른 방법
WHERE (created_at, id) < ('2024-01-15', 100)

-- 다음과 같은 의미:
WHERE created_at < '2024-01-15'
   OR (created_at = '2024-01-15' AND id < 100)

-- ❌ 틀린 방법 (AND를 쓰면 안 됨!)
WHERE created_at < '2024-01-15' AND id < 100
-- 이렇게 하면 created_at과 id가 모두 작아야 해서 데이터를 못 찾을 수 있음
```

**왜 id도 포함해야 하나?**
- created_at이 완전히 unique하지 않음 (같은 시간에 여러 게시글 가능)
- id는 항상 unique하고 순서가 보장됨
- 두 개를 조합하면 정확한 순서 보장

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: Cursor 인덱스 설계</summary>

**필요한 인덱스:**
```sql
-- posts 테이블
CREATE INDEX idx_created_id ON posts(created_at DESC, id DESC);

-- user_id도 필터링하는 경우
CREATE INDEX idx_user_created_id ON orders(user_id, created_at DESC, id DESC);
```

**순서 규칙:**
1. WHERE 동등 조건 (user_id)
2. ORDER BY 컬럼들 (created_at, id)
3. DESC/ASC 방향도 쿼리와 일치해야 함!

</details>

<details>
<summary>힌트 2: Cursor 구현 패턴</summary>

**첫 페이지:**
```sql
SELECT * FROM posts
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**다음 페이지:**
```sql
-- 마지막 행의 created_at, id를 받아서
SELECT * FROM posts
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 10;
```

**이전 페이지 (역방향):**
```sql
SELECT * FROM posts
WHERE (created_at, id) > (?, ?)
ORDER BY created_at ASC, id ASC
LIMIT 10;
-- 결과를 애플리케이션에서 뒤집기
```

</details>

<details>
<summary>힌트 3: 성능 측정 방법</summary>

**실행 시간 측정:**
```sql
SET profiling = 1;

-- 테스트할 쿼리들 실행
SELECT ...;
SELECT ...;

-- 결과 확인
SHOW PROFILES;
```

**더 정확한 측정:**
```sql
-- 캐시 제거
RESET QUERY CACHE;

-- 여러 번 실행해서 평균값 사용
```

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 각 미션별로 실행한 쿼리와 결과를 기록하세요
3. Offset vs Cursor 성능 비교표를 작성하세요
4. 그래프나 차트로 시각화하면 더 좋습니다
5. 실무 적용 계획을 구체적으로 작성하세요

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 15분
- 미션 2: 25분
- 미션 3: 15분
- 미션 4: 5분 (선택)
- **총 60분**

---

## 🎓 배경 지식

### Offset의 내부 동작
```sql
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 10 OFFSET 1000;

-- MySQL의 실제 동작:
-- 1. created_at 순으로 정렬
-- 2. 처음부터 1010개 행 읽기
-- 3. 처음 1000개 버리기
-- 4. 나머지 10개 반환

-- 시간 복잡도: O(N) - N은 OFFSET 크기
-- OFFSET이 클수록 선형적으로 느려짐!
```

### Cursor의 내부 동작
```sql
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-15', 100)
ORDER BY created_at DESC, id DESC
LIMIT 10;

-- MySQL의 실제 동작:
-- 1. 인덱스에서 (2024-01-15, 100) 위치 찾기 - O(log N)
-- 2. 다음 10개 읽기 - O(1)
-- 3. 반환

-- 시간 복잡도: O(log N + 10) ≈ O(1)
-- OFFSET과 무관하게 항상 빠름!
```

---

## ⚠️ 주의사항

### Cursor 방식의 제약사항
1. **특정 페이지로 바로 가기 불가**
   - "10페이지로 바로 가기" 같은 기능은 어려움
   - 무한 스크롤에 적합, 페이지 번호 UI에는 부적합

2. **전체 페이지 수 표시 어려움**
   - COUNT(*)를 매번 하면 느림
   - "더 보기" 버튼만 제공

3. **구현 복잡도**
   - Offset보다 코드가 복잡
   - 프론트엔드도 변경 필요

### 언제 Cursor를 써야 하나?
**✅ Cursor 적합:**
- 무한 스크롤 (SNS 피드, 상품 목록)
- 실시간 피드 (새 글이 계속 올라오는 경우)
- 모바일 앱
- 데이터가 100만 건 이상

**✅ Offset 적합:**
- 페이지 번호가 필요 (1, 2, 3, ...)
- 전체 페이지 수 표시 필요
- 검색 결과 (예: Google)
- 데이터가 적음 (수천 건 이하)
- 데이터가 거의 안 바뀜

---

## 🚀 실전 팁

### 1. Cursor 인코딩
프론트엔드에 cursor 값을 넘겨줄 때는 Base64로 인코딩합니다.

```javascript
// 서버 (Node.js)
const cursor = {
    created_at: '2024-01-15 10:30:00',
    id: 98765
};
const encodedCursor = Buffer.from(JSON.stringify(cursor)).toString('base64');

// API 응답
{
    data: [...],
    next_cursor: 'eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0xNSAxMDozMDowMCIsImlkIjo5ODc2NX0='
}

// 다음 요청
GET /api/posts?cursor=eyJjcmVhdGVkX2F0IjoiMjAyNC0wMS0xNSAxMDozMDowMCIsImlkIjo5ODc2NX0=
```

### 2. NULL 처리
created_at이 NULL일 수 있다면:

```sql
-- NULL을 가장 오래된 값으로 처리
ORDER BY created_at DESC, id DESC

-- Cursor 조건
WHERE (created_at IS NULL AND id < ?)
   OR (created_at IS NOT NULL AND (created_at, id) < (?, ?))
```

### 3. 역방향 페이지네이션
"이전 페이지"로 가는 기능:

```sql
-- 다음 페이지 (아래로)
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC

-- 이전 페이지 (위로)
WHERE (created_at, id) > (?, ?)
ORDER BY created_at ASC, id ASC
LIMIT 10
-- 결과를 reverse() 처리
```

---

**난이도:** ⭐⭐⭐ 중상
**즉시 적용:** ✓
**ROI:** 높음

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] posts 테이블 데이터 100만 건 이상
- [ ] orders 테이블 확인

**준비되셨나요? Offset 지옥에서 탈출하세요!** 🚀
