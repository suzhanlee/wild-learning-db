-- MySQL 9.x 더미 데이터 생성 스크립트
-- 최신 문법 사용: CTE, 윈도우 함수 등

USE wild_learning_db;

-- ============================================
-- 사용자 데이터 생성 (100만 건)
-- ============================================

-- 재귀 CTE를 사용한 더미 데이터 생성
-- MySQL 9.x는 cte_max_recursion_depth를 동적으로 조정 가능
SET SESSION cte_max_recursion_depth = 1000000;

-- 배치 방식으로 데이터 삽입 (성능 최적화)
DROP PROCEDURE IF EXISTS insert_users_batch;

DELIMITER $$

CREATE PROCEDURE insert_users_batch(IN batch_size INT, IN total_batches INT)
BEGIN
    DECLARE batch_num INT DEFAULT 0;
    DECLARE start_id INT;

    -- 자동 커밋 비활성화 (성능 향상)
    SET autocommit = 0;

    WHILE batch_num < total_batches DO
        SET start_id = batch_num * batch_size + 1;

        -- CTE를 사용한 배치 삽입
        INSERT INTO users (email, name, created_at, status, phone)
        WITH RECURSIVE numbers AS (
            SELECT 1 AS n
            UNION ALL
            SELECT n + 1 FROM numbers WHERE n < batch_size
        )
        SELECT
            CONCAT('user', start_id + n - 1, '@example.com') AS email,
            CONCAT('User', start_id + n - 1) AS name,
            TIMESTAMP(DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY),
                     SEC_TO_TIME(FLOOR(RAND() * 86400))) AS created_at,
            ELT(FLOOR(1 + RAND() * 3), 'active', 'inactive', 'pending') AS status,
            CONCAT('010-',
                   LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                   LPAD(FLOOR(RAND() * 10000), 4, '0')) AS phone
        FROM numbers;

        COMMIT;

        SET batch_num = batch_num + 1;

        -- 진행 상황 출력 (10% 단위)
        IF batch_num % GREATEST(1, FLOOR(total_batches / 10)) = 0 THEN
            SELECT CONCAT('Users: ', batch_num * batch_size, ' / ', total_batches * batch_size,
                         ' (', ROUND(batch_num / total_batches * 100, 1), '%)') AS progress;
        END IF;
    END WHILE;

    -- 자동 커밋 복원
    SET autocommit = 1;

    SELECT CONCAT('Total ', batch_num * batch_size, ' users inserted!') AS result;
END$$

DELIMITER ;

-- 100만 건 삽입 (10,000건씩 100번 배치)
-- 시간: 약 3-5분 소요
CALL insert_users_batch(10000, 100);

-- ============================================
-- 주문 데이터 생성 (100만 건)
-- ============================================

DROP PROCEDURE IF EXISTS insert_orders_batch;

DELIMITER $$

CREATE PROCEDURE insert_orders_batch(IN batch_size INT, IN total_batches INT)
BEGIN
    DECLARE batch_num INT DEFAULT 0;
    DECLARE max_user_id BIGINT;

    -- 최대 user_id 조회
    SELECT MAX(id) INTO max_user_id FROM users;

    SET autocommit = 0;

    WHILE batch_num < total_batches DO
        INSERT INTO orders (user_id, status, created_at, amount)
        WITH RECURSIVE numbers AS (
            SELECT 1 AS n
            UNION ALL
            SELECT n + 1 FROM numbers WHERE n < batch_size
        )
        SELECT
            FLOOR(1 + RAND() * max_user_id) AS user_id,
            ELT(FLOOR(1 + RAND() * 5), 'pending', 'completed', 'cancelled', 'shipped', 'refunded') AS status,
            TIMESTAMP(DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY),
                     SEC_TO_TIME(FLOOR(RAND() * 86400))) AS created_at,
            ROUND(10 + RAND() * 990, 2) AS amount
        FROM numbers;

        COMMIT;

        SET batch_num = batch_num + 1;

        IF batch_num % GREATEST(1, FLOOR(total_batches / 10)) = 0 THEN
            SELECT CONCAT('Orders: ', batch_num * batch_size, ' / ', total_batches * batch_size,
                         ' (', ROUND(batch_num / total_batches * 100, 1), '%)') AS progress;
        END IF;
    END WHILE;

    SET autocommit = 1;

    SELECT CONCAT('Total ', batch_num * batch_size, ' orders inserted!') AS result;
END$$

DELIMITER ;

-- 100만 건 삽입 (10,000건씩 100번 배치)
CALL insert_orders_batch(10000, 100);

-- ============================================
-- 데이터 생성 완료 및 통계
-- ============================================

-- 테이블 통계 업데이트
ANALYZE TABLE users;
ANALYZE TABLE orders;

-- 생성된 데이터 확인
SELECT
    'users' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT email) AS unique_emails,
    MIN(created_at) AS earliest_date,
    MAX(created_at) AS latest_date
FROM users

UNION ALL

SELECT
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS unique_users,
    MIN(created_at) AS earliest_date,
    MAX(created_at) AS latest_date
FROM orders;

-- 상태별 분포
SELECT
    'users' AS table_name,
    status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) AS percentage
FROM users
GROUP BY status

UNION ALL

SELECT
    'orders' AS table_name,
    status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY status
ORDER BY table_name, status;

SELECT '=== Data generation completed! ===' AS status;
