package com.wildlearning.db.repository;

import com.wildlearning.db.domain.Order;
import com.wildlearning.db.domain.Order.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {

    /**
     * Week 1 실습: 복합 인덱스 사용 예제
     * idx_user_status_created 인덱스 사용
     */
    @Query("SELECT o FROM Order o WHERE o.user.id = :userId AND o.status = :status ORDER BY o.createdAt DESC")
    List<Order> findByUserIdAndStatusOrderByCreatedAtDesc(
        @Param("userId") Long userId,
        @Param("status") OrderStatus status,
        Pageable pageable
    );

    /**
     * 사용자별 주문 목록 (idx_user_id 인덱스 사용)
     */
    List<Order> findByUserId(Long userId);

    /**
     * 상태별 주문 조회 (idx_status 인덱스 사용)
     */
    List<Order> findByStatus(OrderStatus status);

    /**
     * 기간 및 상태별 주문 조회
     */
    @Query("SELECT o FROM Order o WHERE o.createdAt BETWEEN :startDate AND :endDate AND o.status = :status")
    List<Order> findByDateRangeAndStatus(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate,
        @Param("status") OrderStatus status
    );

    /**
     * 사용자별 주문 통계
     */
    @Query("SELECT o.status, COUNT(o), SUM(o.amount) FROM Order o WHERE o.user.id = :userId GROUP BY o.status")
    List<Object[]> getOrderStatsByUserId(@Param("userId") Long userId);

    /**
     * 금액별 주문 조회
     */
    @Query("SELECT o FROM Order o WHERE o.amount >= :minAmount AND o.amount <= :maxAmount")
    List<Order> findByAmountRange(@Param("minAmount") BigDecimal minAmount,
                                   @Param("maxAmount") BigDecimal maxAmount);

    /**
     * N+1 문제 해결: Fetch Join 사용
     */
    @Query("SELECT o FROM Order o JOIN FETCH o.user WHERE o.id IN :orderIds")
    List<Order> findOrdersWithUser(@Param("orderIds") List<Long> orderIds);

    /**
     * 페이지네이션 예제
     */
    Page<Order> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /**
     * 커서 기반 페이지네이션
     */
    @Query("SELECT o FROM Order o WHERE o.id < :cursor ORDER BY o.id DESC")
    List<Order> findByCursorPagination(@Param("cursor") Long cursor, Pageable pageable);
}
