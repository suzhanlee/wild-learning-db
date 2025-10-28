# Week 7 미션: N+1 쿼리 지옥 탈출하기 🎯

> "루프 안에서 쿼리를 날리는 순간, 당신은 N+1 지옥에 빠진다"

---

## 📋 미션 개요

당신은 전자상거래 플랫폼의 백엔드 개발자입니다.
최근 사용자 목록 API의 응답 시간이 10초 이상 걸려서 프론트엔드 팀의 항의가 빗발치고 있습니다.

**문제 상황:**
- 사용자 100명의 정보와 각 사용자의 주문 내역을 조회하는 API
- 현재 응답 시간: 10초 이상
- 쿼리 로그를 보니 **101번의 쿼리**가 실행되고 있음!

**범인은 N+1 문제!**

```java
// 현재 코드
List<User> users = userRepository.findAll();  // 1번 쿼리
for (User user : users) {
    List<Order> orders = user.getOrders();    // 100번 쿼리!
    // orders를 사용...
}
```

**당신의 임무:**
N+1 문제를 발견하고 해결해서 **50배 이상** 성능을 개선하세요!

---

## 🎯 미션 목표

### 미션 1: N+1 문제 재현 및 탐지 (필수)

**상황:**
스프링 부트 애플리케이션에서 사용자 목록과 각 사용자의 주문을 조회합니다.

**성공 기준:**
- [ ] 기본 코드 작성 (N+1 발생하는 코드)
- [ ] 쿼리 로그 활성화
- [ ] 실행되는 쿼리 개수 측정
- [ ] N+1 문제임을 확인
- [ ] 응답 시간 측정

**재현 코드 예시:**
```java
// Entity
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String email;
    private String name;

    @OneToMany(mappedBy = "user")
    private List<Order> orders;
}

@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    private User user;

    private String status;
    private BigDecimal amount;
}

// Service - N+1 발생!
List<User> users = userRepository.findAll();
for (User user : users) {
    System.out.println(user.getName() + ": " + user.getOrders().size());
}
```

---

### 미션 2: JOIN FETCH로 해결 (필수)

**상황:**
미션 1의 N+1 문제를 JOIN FETCH를 사용해서 해결하세요.

**성공 기준:**
- [ ] JOIN FETCH 쿼리 작성
- [ ] 실행되는 쿼리 개수 확인 (1번으로 감소!)
- [ ] 응답 시간 측정
- [ ] Before/After 비교
- [ ] **최소 50배 이상 성능 개선**

**힌트:**
```java
// Repository에 메서드 추가
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();
```

---

### 미션 3: 페이징과 N+1 (필수)

**상황:**
사용자 목록을 페이징 처리하면서 N+1을 피해야 합니다.
하지만 JOIN FETCH + 페이징은 문제가 있습니다!

**문제 코드:**
```java
// 이렇게 하면 경고 발생!
@Query("SELECT u FROM User u JOIN FETCH u.orders")
Page<User> findAllWithOrders(Pageable pageable);
```

**성공 기준:**
- [ ] 문제점 파악 (MultipleBagFetchException 또는 메모리 로딩)
- [ ] 해결 방법 1: @BatchSize 적용
- [ ] 해결 방법 2: @EntityGraph 사용
- [ ] 쿼리 개수 비교 (N+1 vs 배치 로딩)
- [ ] 성능 측정

**힌트:**
```java
// 방법 1: @BatchSize
@OneToMany(mappedBy = "user")
@BatchSize(size = 10)
private List<Order> orders;

// 방법 2: @EntityGraph
@EntityGraph(attributePaths = {"orders"})
Page<User> findAll(Pageable pageable);
```

---

### 미션 4: 중첩 N+1 해결 (필수)

**상황:**
사용자 → 주문 → 주문 상품 (3단계 관계)에서 N+1이 중첩 발생합니다.

```java
// Entity
@Entity
public class Order {
    @OneToMany(mappedBy = "order")
    private List<OrderItem> items;
}

@Entity
public class OrderItem {
    @ManyToOne
    private Product product;
}

// Service - 폭발적인 N+1!
List<User> users = userRepository.findAll();      // 1번
for (User user : users) {
    for (Order order : user.getOrders()) {        // 100번
        for (OrderItem item : order.getItems()) { // 1000번
            System.out.println(item.getProduct().getName()); // 10000번???
        }
    }
}
```

**성공 기준:**
- [ ] 쿼리 개수 측정 (몇 번?)
- [ ] 중첩 JOIN FETCH로 해결
- [ ] 쿼리 개수 확인 (1번으로 감소!)
- [ ] 성능 비교

**힌트:**
```java
@Query("SELECT DISTINCT u FROM User u " +
       "JOIN FETCH u.orders o " +
       "JOIN FETCH o.items i " +
       "JOIN FETCH i.product")
List<User> findAllWithOrdersAndItems();
```

---

## 💡 제공되는 환경

### 테이블 구조

**users 테이블:**
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100),
    created_at DATETIME
);
-- 데이터: 100건 (테스트용)
```

**orders 테이블:**
```sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    status VARCHAR(20),
    amount DECIMAL(10,2),
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
-- 데이터: 1,000건 (사용자당 평균 10건)
```

**order_items 테이블:**
```sql
CREATE TABLE order_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT,
    product_id BIGINT,
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
-- 데이터: 10,000건 (주문당 평균 10건)
```

### 쿼리 로그 활성화

**application.yml:**
```yaml
spring:
  jpa:
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        use_sql_comments: true

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
```

---

## 🔍 참고: N+1 탐지 방법

### 방법 1: 쿼리 로그 확인
```
Hibernate: select user0_.id as id1_0_ ... from users user0_
Hibernate: select orders0_.user_id as user_id4_1_0_ ... where orders0_.user_id=?
Hibernate: select orders0_.user_id as user_id4_1_0_ ... where orders0_.user_id=?
Hibernate: select orders0_.user_id as user_id4_1_0_ ... where orders0_.user_id=?
...
```
**패턴:** 같은 쿼리가 반복되면 N+1!

### 방법 2: 쿼리 카운터
```java
// 테스트 코드에서
@Test
void testNPlusOne() {
    // 쿼리 카운터 초기화
    queryCounter.clear();

    // 비즈니스 로직 실행
    userService.getUsersWithOrders();

    // 쿼리 개수 확인
    assertThat(queryCounter.getCount()).isLessThan(5);
}
```

### 방법 3: 성능 테스트
```java
@Test
void performanceTest() {
    long start = System.currentTimeMillis();
    userService.getUsersWithOrders();
    long duration = System.currentTimeMillis() - start;

    assertThat(duration).isLessThan(1000); // 1초 이내
}
```

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: N+1은 언제 발생하나?</summary>

**위험 패턴:**
- 루프 안에서 지연 로딩 접근
- `for (User user : users) { user.getOrders(); }`
- 템플릿에서 관계 접근
- `{% for user in users %} {{ user.orders.size }} {% endfor %}`

**안전 패턴:**
- Eager Loading 사용 (JOIN FETCH, @EntityGraph)
- Batch Fetching 사용 (@BatchSize)
- 필요한 데이터만 DTO로 조회

</details>

<details>
<summary>힌트 2: JOIN FETCH 주의사항</summary>

**문제:**
- 페이징과 함께 사용하면 메모리에서 페이징 (위험!)
- OneToMany 여러 개 FETCH 하면 MultipleBagFetchException
- DISTINCT 필수 (중복 제거)

**해결:**
- ToOne 관계만 JOIN FETCH
- ToMany는 @BatchSize 사용
- 또는 별도 쿼리로 분리

</details>

<details>
<summary>힌트 3: @BatchSize vs JOIN FETCH</summary>

**JOIN FETCH:**
- 장점: 1번의 쿼리
- 단점: 페이징 문제, 중복 데이터

**@BatchSize:**
- 장점: 페이징 가능, IN 쿼리로 효율적
- 단점: 2번의 쿼리 (본체 + IN 쿼리)

**선택 기준:**
- 페이징 필요 → @BatchSize
- 페이징 불필요 → JOIN FETCH

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 모든 코드와 쿼리 로그를 기록하세요
3. Before/After 쿼리 개수 비교표를 작성하세요
4. 응답 시간 측정 결과를 기록하세요
5. 배운 점과 실무 적용 계획을 정리하세요

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 15분 (N+1 재현)
- 미션 2: 15분 (JOIN FETCH)
- 미션 3: 15분 (페이징 처리)
- 미션 4: 15분 (중첩 N+1)
- **총 60분**

---

## 🎓 선택 사항: 이론 학습

만약 ORM과 지연 로딩이 생소하다면:
- `docs/week7-n-plus-1.md` 참고

하지만 **야생학습**이니까 일단 부딪혀보세요!

---

## ✅ 시작 전 체크

- [ ] Spring Boot 프로젝트 실행 중
- [ ] MySQL 연결 확인
- [ ] 쿼리 로그 활성화 확인
- [ ] users, orders 테이블 데이터 확인
- [ ] JPA Entity 클래스 준비

---

**난이도:** ⭐⭐ 중
**즉시 적용:** ✓
**ROI:** 높음

**준비되셨나요? 그럼 시작!** 🚀
