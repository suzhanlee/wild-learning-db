-- Week 1: 인덱스 핵심 원리 - 실습 환경 설정
-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS wild_learning_db;
USE wild_learning_db;

-- 기존 테이블 삭제 (재실행을 위해)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;
DROP PROCEDURE IF EXISTS insert_dummy_users;
DROP PROCEDURE IF EXISTS insert_dummy_orders;
