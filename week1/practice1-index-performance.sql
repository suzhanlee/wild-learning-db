-- 실습 1: 인덱스 있을 때 vs 없을 때 성능 비교

USE wild_learning_db;

-- 테스트 테이블 생성
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100),
    created_at DATETIME,
    status VARCHAR(20)
);

-- 더미 데이터 100만 건 삽입 프로시저
DELIMITER $$
CREATE PROCEDURE insert_dummy_users()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 1000000 DO
        INSERT INTO users (email, name, created_at, status)
        VALUES (
            CONCAT('user', i, '@example.com'),
            CONCAT('User', i),
            DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1825) DAY),
            ELT(FLOOR(1 + RAND() * 3), 'active', 'inactive', 'pending')
        );
        SET i = i + 1;

        -- 진행상황 출력 (매 10만건마다)
        IF i % 100000 = 0 THEN
            SELECT CONCAT('Inserted ', i, ' rows') AS progress;
        END IF;
    END WHILE;
END$$
DELIMITER ;

-- 더미 데이터 삽입 실행
-- 주의: 시간이 오래 걸릴 수 있습니다 (약 5-10분)
CALL insert_dummy_users();

-- 데이터 삽입 확인
SELECT COUNT(*) AS total_users FROM users;

-- ============================================
-- 성능 테스트 1: 인덱스 없이 조회
-- ============================================

-- 쿼리 실행 시간 측정 시작
SET @start_time = NOW(6);

SELECT * FROM users WHERE email = 'user500000@example.com';

-- 실행 시간 계산
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'execution_time_ms_without_index';

-- EXPLAIN으로 실행 계획 확인
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';

-- ============================================
-- 인덱스 생성
-- ============================================

CREATE INDEX idx_email ON users(email);

-- ============================================
-- 성능 테스트 2: 인덱스 있이 조회
-- ============================================

-- 쿼리 실행 시간 측정 시작
SET @start_time = NOW(6);

SELECT * FROM users WHERE email = 'user500000@example.com';

-- 실행 시간 계산
SET @end_time = NOW(6);
SELECT TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000 AS 'execution_time_ms_with_index';

-- EXPLAIN으로 실행 계획 확인
EXPLAIN SELECT * FROM users WHERE email = 'user500000@example.com';

-- ============================================
-- 결과 기록 테이블
-- ============================================

/*
결과 기록:

| 상황 | 실행시간 | rows 검사 | type | 비고 |
|------|---------|-----------|------|------|
| 인덱스 없음 | ___ms | 1,000,000 | ALL | Full Scan |
| 인덱스 있음 | ___ms | 1 | ref | Index Scan |

성능 개선: 약 ___배
*/
