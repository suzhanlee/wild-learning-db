-- 실습 3: 인덱스 안티패턴 발견 및 개선

USE wild_learning_db;

-- ============================================
-- 안티패턴 1: 함수 사용
-- ============================================

-- ❌ 나쁜 예: 컬럼에 함수 적용
EXPLAIN SELECT * FROM users
WHERE YEAR(created_at) = 2024;

-- ✅ 좋은 예: 범위 조건으로 변경
EXPLAIN SELECT * FROM users
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';

-- 인덱스 생성 (있다면)
CREATE INDEX idx_created_at ON users(created_at);

-- 성능 비교
SET @start_time = NOW(6);
SELECT COUNT(*) FROM users WHERE YEAR(created_at) = 2024;
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'with_function_ms';

SET @start_time = NOW(6);
SELECT COUNT(*) FROM users WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'without_function_ms';

-- ============================================
-- 안티패턴 2: 앞부분 와일드카드
-- ============================================

-- ❌ 나쁜 예: 앞부분 와일드카드 (인덱스 사용 불가)
EXPLAIN SELECT * FROM users
WHERE email LIKE '%@gmail.com';

-- ✅ 좋은 예: 뒷부분 와일드카드만 (인덱스 사용 가능)
EXPLAIN SELECT * FROM users
WHERE email LIKE 'user123%';

-- ============================================
-- 안티패턴 3: OR 조건 (다른 인덱스)
-- ============================================

-- 전화번호 컬럼 추가 (테스트용)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
UPDATE users SET phone = CONCAT('010-', LPAD(FLOOR(RAND() * 10000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0'));
CREATE INDEX idx_phone ON users(phone);

-- ❌ 나쁜 예: 서로 다른 인덱스의 OR 조건
EXPLAIN SELECT * FROM users
WHERE email = 'user50000@example.com'
   OR phone = '010-1234-5678';

-- ✅ 좋은 예: UNION으로 분리
EXPLAIN
SELECT * FROM users WHERE email = 'user50000@example.com'
UNION
SELECT * FROM users WHERE phone = '010-1234-5678';

-- ============================================
-- 안티패턴 4: NOT, !=, <>
-- ============================================

-- ❌ 나쁜 예: 부정 조건 (인덱스 효율 낮음)
EXPLAIN SELECT * FROM orders
WHERE status != 'cancelled';

-- ✅ 좋은 예: IN으로 변경 (긍정 조건)
EXPLAIN SELECT * FROM orders
WHERE status IN ('pending', 'completed', 'shipped', 'refunded');

-- 성능 비교
SET @start_time = NOW(6);
SELECT COUNT(*) FROM orders WHERE status != 'cancelled';
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'not_equal_ms';

SET @start_time = NOW(6);
SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'completed', 'shipped', 'refunded');
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'in_clause_ms';

-- ============================================
-- 안티패턴 5: 타입 불일치
-- ============================================

-- ❌ 나쁜 예: 타입 불일치 (암묵적 형변환)
EXPLAIN SELECT * FROM users WHERE id = '12345';

-- ✅ 좋은 예: 타입 일치
EXPLAIN SELECT * FROM users WHERE id = 12345;

-- ============================================
-- 안티패턴 6: 복합 인덱스 중간 컬럼 생략
-- ============================================

-- 복합 인덱스가 (user_id, status, created_at)인 경우

-- ✅ 좋은 예: 순서대로 사용
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed'
  AND created_at > '2024-01-01';

-- ✅ 좋은 예: 앞부분만 사용
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND status = 'completed';

-- ❌ 나쁜 예: 중간 생략 (status를 건너뜀)
EXPLAIN SELECT * FROM orders
WHERE user_id = 12345
  AND created_at > '2024-01-01';
-- created_at은 인덱스를 사용하지 못함!

-- ❌ 나쁜 예: 순서 무시 (앞부분 생략)
EXPLAIN SELECT * FROM orders
WHERE status = 'completed'
  AND created_at > '2024-01-01';
-- 인덱스를 제대로 사용하지 못함!

-- ============================================
-- 안티패턴 정리 및 체크리스트
-- ============================================

/*
인덱스 안티패턴 체크리스트:

1. [ ] WHERE 절에 함수 사용 (YEAR, DATE, UPPER 등)
   → 범위 조건으로 변경하거나 계산된 컬럼에 인덱스 생성

2. [ ] LIKE '%keyword' 또는 LIKE '%keyword%'
   → 가능하면 'keyword%' 형태로 변경 또는 Full-Text Search 고려

3. [ ] 서로 다른 컬럼의 OR 조건
   → UNION으로 분리

4. [ ] NOT, !=, <> 사용
   → IN 절로 긍정 조건으로 변경

5. [ ] 타입 불일치 (WHERE id = '123')
   → 타입 일치시키기

6. [ ] 복합 인덱스 순서 무시
   → 인덱스 컬럼 순서대로 WHERE 절 작성

7. [ ] Cardinality 낮은 컬럼에 단독 인덱스
   → 복합 인덱스로 변경 고려

8. [ ] 인덱스가 있지만 통계 정보가 오래됨
   → ANALYZE TABLE 실행
*/

-- 통계 정보 업데이트
ANALYZE TABLE users;
ANALYZE TABLE orders;

-- 현재 인덱스 확인
SHOW INDEX FROM users;
SHOW INDEX FROM orders;
