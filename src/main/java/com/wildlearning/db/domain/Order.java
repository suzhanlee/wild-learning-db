package com.wildlearning.db.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "orders", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_created_at", columnList = "created_at"),
    @Index(name = "idx_user_status_created", columnList = "user_id, status, created_at")
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, foreignKey = @ForeignKey(name = "fk_orders_user_id"))
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrderStatus status = OrderStatus.PENDING;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMP(6)")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false, columnDefinition = "TIMESTAMP(6)")
    private LocalDateTime updatedAt;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount = BigDecimal.ZERO;

    public enum OrderStatus {
        PENDING, COMPLETED, CANCELLED, SHIPPED, REFUNDED
    }

    // 생성 메서드
    public static Order createOrder(User user, BigDecimal amount) {
        Order order = new Order();
        order.user = user;
        order.amount = amount;
        order.status = OrderStatus.PENDING;
        return order;
    }

    // 비즈니스 메서드
    public void complete() {
        if (this.status != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be completed");
        }
        this.status = OrderStatus.COMPLETED;
    }

    public void cancel() {
        if (this.status == OrderStatus.COMPLETED) {
            throw new IllegalStateException("Completed orders cannot be cancelled");
        }
        this.status = OrderStatus.CANCELLED;
    }

    public void ship() {
        if (this.status != OrderStatus.COMPLETED) {
            throw new IllegalStateException("Only completed orders can be shipped");
        }
        this.status = OrderStatus.SHIPPED;
    }

    public void refund() {
        if (this.status != OrderStatus.COMPLETED && this.status != OrderStatus.SHIPPED) {
            throw new IllegalStateException("Only completed or shipped orders can be refunded");
        }
        this.status = OrderStatus.REFUNDED;
    }
}
