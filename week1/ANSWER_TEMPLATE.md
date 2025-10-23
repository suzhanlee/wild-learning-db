# Week 1 답안: 인덱스 성능 개선

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: 단일 인덱스 성능 개선

### 1-1. 현재 상황 분석

#### 인덱스 확인
```sql
SHOW INDEX FROM users;

-- 결과:
-- (여기에 결과 붙여넣기)
```

#### 인덱스 없이 실행
```sql
-- 실행한 쿼리
SELECT * FROM users WHERE email = 'user500000@example.com';

-- 실행 시간: _____ms
```

#### EXPLAIN 분석 (Before)
```sql
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';

-- 결과:
```

| id | select_type | table | type | possible_keys | key | rows | Extra |
|----|-------------|-------|------|---------------|-----|------|-------|
|    |             |       |      |               |     |      |       |

**문제점 파악:**
- type: _____
- rows: _____
- 왜 느린가? _____

---

### 1-2. 인덱스 생성

```sql
-- 생성한 인덱스
CREATE INDEX ______________ ON users(______________);

-- 인덱스 생성 시간: _____초
```

**이 인덱스를 선택한 이유:**
1.
2.
3.

---

### 1-3. 결과 비교

#### 인덱스 있이 실행
```sql
SELECT * FROM users WHERE email = 'user500000@example.com';

-- 실행 시간: _____ms
```

#### EXPLAIN 분석 (After)
```sql
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';

-- 결과:
```

| id | select_type | table | type | possible_keys | key | rows | Extra |
|----|-------------|-------|------|---------------|-----|------|-------|
|    |             |       |      |               |     |      |       |

**개선 내용:**
- type: _____ → _____
- rows: _____ → _____
- 사용된 인덱스: _____

---

### 1-4. 성능 개선 결과

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ___ms | ___ms | ___배 |
| 검사한 rows | _____ | _____ | ___배 |
| type | _____ | _____ | - |

**성공 여부:** [ ] 50배 이상 개선 달성

---

## 미션 2: 복합 인덱스 설계

### 2-1. 현재 상황 분석

#### 인덱스 없이 실행
```sql
SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- 실행 시간: _____ms
```

#### EXPLAIN 분석 (Before)
```sql
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- 결과:
```

| id | select_type | table | type | rows | Extra |
|----|-------------|-------|------|------|-------|
|    |             |       |      |      |       |

---

### 2-2. 복합 인덱스 설계

**내가 설계한 인덱스:**
```sql
CREATE INDEX idx___________ ON orders(______, ______, ______);
```

**컬럼 순서 결정 이유:**
1. 첫 번째 컬럼 (_____): _____
2. 두 번째 컬럼 (_____): _____
3. 세 번째 컬럼 (_____): _____

---

### 2-3. 결과 비교

#### 인덱스 있이 실행
```sql
SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- 실행 시간: _____ms
```

#### EXPLAIN 분석 (After)
```sql
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- 결과:
```

| id | select_type | table | type | rows | Extra |
|----|-------------|-------|------|------|-------|
|    |             |       |      |      |       |

---

### 2-4. 성능 개선 결과

| 항목 | Before | After | 개선 |
|------|--------|-------|------|
| 실행 시간 | ___ms | ___ms | ___배 |
| type | _____ | _____ | - |
| rows | _____ | _____ | ___배 |
| Extra | _____ | _____ | - |

---

## 미션 3: 인덱스를 못 타는 쿼리 찾기

### 쿼리 A 분석
```sql
SELECT * FROM users WHERE YEAR(created_at) = 2024;
```

**EXPLAIN 결과:**
| type | rows | Extra |
|------|------|-------|
|      |      |       |

**인덱스 사용 여부:** [ ] 사용 / [ ] 미사용

**문제점:**

**개선된 쿼리:**
```sql


```

**성능 비교:**
- Before: _____ms
- After: _____ms

---

### 쿼리 B 분석
```sql
SELECT * FROM users WHERE created_at >= '2024-01-01'
                      AND created_at < '2025-01-01';
```

**EXPLAIN 결과:**
| type | rows | Extra |
|------|------|-------|
|      |      |       |

**인덱스 사용 여부:** [ ] 사용 / [ ] 미사용

**이유:**

---

### 쿼리 C 분석
```sql
SELECT * FROM users WHERE email LIKE '%@gmail.com';
```

**EXPLAIN 결과:**
| type | rows | Extra |
|------|------|-------|
|      |      |       |

**인덱스 사용 여부:** [ ] 사용 / [ ] 미사용

**문제점:**

**대안:**

---

### 쿼리 D 분석
```sql
SELECT * FROM users WHERE email LIKE 'user123%';
```

**EXPLAIN 결과:**
| type | rows | Extra |
|------|------|-------|
|      |      |       |

**인덱스 사용 여부:** [ ] 사용 / [ ] 미사용

**이유:**

---

### 쿼리 E 분석
```sql
SELECT * FROM orders WHERE status != 'cancelled';
```

**EXPLAIN 결과:**
| type | rows | Extra |
|------|------|-------|
|      |      |       |

**인덱스 사용 여부:** [ ] 사용 / [ ] 미사용

**문제점:**

**개선된 쿼리:**
```sql


```

---

## 학습 정리

### 배운 핵심 개념 3가지
1.
2.
3.

### 인덱스 설계 체크리스트 (내가 정리한 기준)
- [ ]
- [ ]
- [ ]
- [ ]
- [ ]

### 인덱스를 못 타는 패턴 (암기할 것!)
1.
2.
3.
4.
5.

---

## 실무 적용 계획

### 즉시 적용할 부분
**현재 회사/프로젝트:**

**적용할 쿼리 1:**
```sql
-- Before


-- After (예상)


-- 예상 개선율:
```

**적용할 쿼리 2:**
```sql
-- Before


-- After (예상)


-- 예상 개선율:
```

---

### 추가로 확인할 부분
1.
2.
3.

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

### 실험 1: Cardinality 비교
```sql
-- 높은 Cardinality (email)
SELECT COUNT(DISTINCT email) FROM users;
-- 결과: _____

-- 낮은 Cardinality (status)
SELECT COUNT(DISTINCT status) FROM users;
-- 결과: _____

-- status에 인덱스를 걸면?


-- 결과:
```

---

### 실험 2: 복합 인덱스 순서 바꿔보기
```sql
-- 원래 설계: (user_id, status, created_at)
-- 바꿔본 설계: (status, user_id, created_at)

-- 성능 비교:
```

---

## 다음 액션

### 팀 공유 내용
-

### 추가 학습 필요
-

### 실무 적용 기한
- [ ] 1주일 내 적용
- [ ] 결과 측정
- [ ] 팀 회고 공유

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
