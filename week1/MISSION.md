# Week 1 미션: 인덱스로 쿼리 성능 개선하기 🎯

> "인덱스 하나로 100만 건 조회를 1초 안에"

---

## 📋 미션 개요

당신은 사용자 서비스의 백엔드 개발자입니다.
최근 사용자 검색 API의 응답 시간이 너무 느려서 고객 불만이 쇄도하고 있습니다.

**문제 상황:**
- `users` 테이블에 100만 건의 데이터
- 이메일로 사용자 검색하는 API가 매우 느림
- 현재 응답 시간: 수 초 이상

**당신의 임무:**
인덱스를 활용해서 **최소 50배 이상** 성능을 개선하세요!

---

## 🎯 미션 목표

### 미션 1: 단일 인덱스 성능 개선 (필수)

**상황:**
```sql
SELECT * FROM users
WHERE email = 'user500000@example.com';
```

**성공 기준:**
- [ ] 인덱스 생성 전 실행 시간 측정
- [ ] 적절한 인덱스 생성
- [ ] 인덱스 생성 후 실행 시간 측정
- [ ] EXPLAIN으로 실행 계획 비교
- [ ] **최소 50배 이상 성능 개선**

---

### 미션 2: 복합 인덱스 설계 (필수)

**상황:**
주문 조회 API가 느립니다.
```sql
SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;
```

**성공 기준:**
- [ ] 인덱스 없이 실행 시간 측정
- [ ] 최적의 복합 인덱스 설계 (컬럼 순서가 중요!)
- [ ] 인덱스 생성 후 성능 비교
- [ ] EXPLAIN으로 `type`, `rows`, `Extra` 확인

**힌트:**
- 복합 인덱스의 컬럼 순서가 성능을 좌우합니다
- WHERE 조건과 ORDER BY를 모두 고려하세요
- 동등 조건(=)과 범위 조건(>, <)의 순서를 생각해보세요

---

### 미션 3: 인덱스를 못 타는 쿼리 찾기 (필수)

**상황:**
다음 쿼리들 중 인덱스를 제대로 활용하지 못하는 것을 찾아내세요.

```sql
-- 쿼리 A
SELECT * FROM users WHERE YEAR(created_at) = 2024;

-- 쿼리 B
SELECT * FROM users WHERE created_at >= '2024-01-01'
                      AND created_at < '2025-01-01';

-- 쿼리 C
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- 쿼리 D
SELECT * FROM users WHERE email LIKE 'user123%';

-- 쿼리 E
SELECT * FROM orders WHERE status != 'cancelled';
```

**성공 기준:**
- [ ] 각 쿼리를 EXPLAIN으로 분석
- [ ] 인덱스를 못 타는 쿼리 식별
- [ ] 개선된 쿼리 작성
- [ ] Before/After 성능 비교

---

## 💡 제공되는 환경

### 테이블 구조

**users 테이블:**
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100),
    created_at DATETIME,
    status VARCHAR(20)
);
-- 데이터: 1,000,000 건
```

**orders 테이블:**
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    created_at DATETIME,
    amount DECIMAL(10,2)
);
-- 데이터: 1,000,000 건
```

### 데이터 확인 방법
```sql
-- 테이블 상태 확인
SHOW TABLE STATUS LIKE 'users';
SHOW TABLE STATUS LIKE 'orders';

-- 데이터 건수 확인
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders;

-- 인덱스 확인
SHOW INDEX FROM users;
SHOW INDEX FROM orders;
```

---

## 🔍 참고: EXPLAIN 해석 방법

```sql
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```

**주요 컬럼:**
- `type`: 접근 방식 (ALL, index, range, ref, eq_ref, const)
  - `ALL`: 전체 스캔 (느림!)
  - `ref`: 인덱스 사용 (빠름!)
  - `const`: 최적화된 상수 조회 (매우 빠름!)

- `rows`: 검사할 예상 행 수 (적을수록 좋음)

- `Extra`: 추가 정보
  - `Using filesort`: 정렬 필요 (느릴 수 있음)
  - `Using temporary`: 임시 테이블 사용 (느림)
  - `Using index`: 인덱스만으로 처리 (빠름!)

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 어떤 컬럼에 인덱스를 걸어야 할까?</summary>

- WHERE 절에 자주 사용되는 컬럼
- JOIN 조건에 사용되는 컬럼
- ORDER BY에 사용되는 컬럼
- Cardinality가 높은 컬럼 (값이 다양한 컬럼)

</details>

<details>
<summary>힌트 2: 복합 인덱스 순서 규칙</summary>

1. 동등 조건(=)이 범위 조건(>, <)보다 앞
2. Cardinality가 높은 컬럼이 앞
3. ORDER BY 컬럼은 마지막

예: `INDEX (user_id, status, created_at)`
- user_id: WHERE 동등 조건
- status: WHERE 동등 조건
- created_at: ORDER BY

</details>

<details>
<summary>힌트 3: 인덱스를 못 타는 패턴</summary>

**안 좋은 예:**
- `WHERE YEAR(created_at) = 2024` (함수 사용)
- `WHERE email LIKE '%gmail.com'` (앞부분 와일드카드)
- `WHERE status != 'cancelled'` (부정 조건)

**좋은 예:**
- `WHERE created_at >= '2024-01-01'` (범위 조건)
- `WHERE email LIKE 'user%'` (뒷부분 와일드카드)
- `WHERE status IN ('active', 'pending')` (긍정 조건)

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 실행한 모든 쿼리와 결과를 기록하세요
3. Before/After 성능 비교표를 작성하세요
4. 배운 점과 실무 적용 계획을 정리하세요
5. 완료 후 Claude에게 피드백을 요청하세요!

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 20분
- 미션 2: 20분
- 미션 3: 20분
- **총 60분**

---

## 🎓 선택 사항: 이론 학습

만약 인덱스 개념이 생소하다면, 먼저 이론을 학습하세요:
- `docs/reference/week1-theory.md` (기존 가이드를 참고자료로 이동 예정)

하지만! **야생학습**이니까 일단 부딪혀보고, 막히면 찾아보는 것을 추천합니다!

---

**난이도:** ⭐⭐ 중
**즉시 적용:** ✓
**ROI:** 매우 높음

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] users, orders 테이블 데이터 확인

**준비되셨나요? 그럼 시작!** 🚀
