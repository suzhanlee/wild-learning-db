-- 실습 2: 복합 인덱스 순서 비교

USE wild_learning_db;

-- 주문 테이블 생성
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    status VARCHAR(20),
    created_at DATETIME,
    amount DECIMAL(10,2)
);

-- 더미 데이터 100만 건 삽입 프로시저
DELIMITER $$
CREATE PROCEDURE insert_dummy_orders()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 1000000 DO
        INSERT INTO orders (user_id, status, created_at, amount)
        VALUES (
            FLOOR(1 + RAND() * 100000),  -- 10만명의 유저
            ELT(FLOOR(1 + RAND() * 5), 'pending', 'completed', 'cancelled', 'shipped', 'refunded'),
            DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY),
            ROUND(10 + RAND() * 990, 2)  -- 10 ~ 1000 사이의 금액
        );
        SET i = i + 1;

        -- 진행상황 출력 (매 10만건마다)
        IF i % 100000 = 0 THEN
            SELECT CONCAT('Inserted ', i, ' orders') AS progress;
        END IF;
    END WHILE;
END$$
DELIMITER ;

-- 더미 데이터 삽입 실행
CALL insert_dummy_orders();

-- 데이터 삽입 확인
SELECT COUNT(*) AS total_orders FROM orders;
SELECT COUNT(DISTINCT user_id) AS total_users FROM orders;

-- ============================================
-- 시나리오: 특정 유저의 완료된 주문을 최신순으로 조회
-- ============================================

SET @test_user_id = 12345;

-- ============================================
-- 테스트 1: 인덱스 없음
-- ============================================

SET @start_time = NOW(6);

SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'no_index_ms';

-- EXPLAIN 분석
EXPLAIN SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 테스트 2: 잘못된 순서의 복합 인덱스
-- ============================================

CREATE INDEX idx_wrong ON orders(status, user_id, created_at);

SET @start_time = NOW(6);

SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'wrong_index_ms';

-- EXPLAIN 분석
EXPLAIN SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 테스트 3: 올바른 순서의 복합 인덱스
-- ============================================

-- 잘못된 인덱스 삭제
DROP INDEX idx_wrong ON orders;

-- 올바른 인덱스 생성
CREATE INDEX idx_correct ON orders(user_id, status, created_at);

SET @start_time = NOW(6);

SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'correct_index_ms';

-- EXPLAIN 분석
EXPLAIN SELECT * FROM orders
WHERE user_id = @test_user_id
  AND status = 'completed'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 결과 비교 정리
-- ============================================

/*
결과 비교:

| 인덱스 | 실행시간 | type | rows | key | Extra |
|--------|---------|------|------|-----|-------|
| 없음 | ___ms | ALL | ~1000000 | NULL | Using where; Using filesort |
| 잘못된 순서 | ___ms | ref/range | ??? | idx_wrong | Using where; Using filesort |
| 올바른 순서 | ___ms | ref | ~10 | idx_correct | Using where |

분석:
1. 인덱스 없음: Full Table Scan + filesort (매우 느림)
2. 잘못된 순서: status로 먼저 필터링 → user_id 범위가 넓어짐 → filesort 발생
3. 올바른 순서: user_id로 먼저 필터링 → status 추가 필터링 → created_at으로 정렬 (인덱스 사용)

핵심:
- 복합 인덱스는 (동등조건1, 동등조건2, 정렬조건) 순서로!
- Cardinality가 높은 컬럼(user_id)을 앞에 배치
*/
