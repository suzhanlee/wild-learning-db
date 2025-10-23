-- MySQL 9.x 초기화 스크립트
-- 데이터베이스 생성은 docker-compose.yml에서 자동으로 됨

USE wild_learning_db;

-- 기존 테이블 삭제 (재실행 대비)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

-- 사용자 테이블 생성
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    status ENUM('active', 'inactive', 'pending') DEFAULT 'active',
    phone VARCHAR(20),
    INDEX idx_created_at (created_at),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 주문 테이블 생성
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    status ENUM('pending', 'completed', 'cancelled', 'shipped', 'refunded') DEFAULT 'pending',
    created_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_orders_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 초기 데이터 확인용 메시지
SELECT 'Database initialized successfully!' AS status;
SELECT VERSION() AS mysql_version;
