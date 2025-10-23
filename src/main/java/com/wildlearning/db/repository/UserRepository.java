package com.wildlearning.db.repository;

import com.wildlearning.db.domain.User;
import com.wildlearning.db.domain.User.UserStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 이메일로 사용자 조회 (idx_email 인덱스 사용)
     */
    Optional<User> findByEmail(String email);

    /**
     * 상태별 사용자 목록 조회 (idx_status 인덱스 사용)
     */
    List<User> findByStatus(UserStatus status);

    /**
     * 기간별 사용자 조회 (idx_created_at 인덱스 사용)
     */
    @Query("SELECT u FROM User u WHERE u.createdAt BETWEEN :startDate AND :endDate ORDER BY u.createdAt DESC")
    List<User> findUsersByDateRange(@Param("startDate") LocalDateTime startDate,
                                     @Param("endDate") LocalDateTime endDate);

    /**
     * 페이지네이션 - Offset 방식 (Week 6 실습용)
     */
    Page<User> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /**
     * 커서 기반 페이지네이션 (Week 6 실습용)
     */
    @Query("SELECT u FROM User u WHERE u.id < :cursor ORDER BY u.id DESC")
    List<User> findByCursorPagination(@Param("cursor") Long cursor, Pageable pageable);

    /**
     * 이메일 존재 여부 확인 (Covering Index 예제)
     */
    boolean existsByEmail(String email);

    /**
     * 상태별 카운트
     */
    long countByStatus(UserStatus status);

    /**
     * N+1 문제 해결 예제 (Week 7)
     */
    @Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders WHERE u.id IN :userIds")
    List<User> findUsersWithOrders(@Param("userIds") List<Long> userIds);
}
