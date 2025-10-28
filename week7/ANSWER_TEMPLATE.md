# Week 7 답안: N+1 문제 해결

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: N+1 문제 재현 및 탐지

### 1-1. 환경 설정

#### 쿼리 로그 활성화 확인
```yaml
# application.yml
spring:
  jpa:
    show-sql: true
    properties:
      hibernate:
        format_sql: true

# 적용 여부: [ ] 완료
```

#### 테스트 데이터 확인
```sql
-- 사용자 수
SELECT COUNT(*) FROM users;
-- 결과: _____

-- 주문 수
SELECT COUNT(*) FROM orders;
-- 결과: _____

-- 사용자당 평균 주문 수
SELECT AVG(order_count) FROM (
    SELECT user_id, COUNT(*) as order_count
    FROM orders
    GROUP BY user_id
) as counts;
-- 결과: _____
```

---

### 1-2. N+1 재현 코드

#### Entity 클래스
```java
// User.java
@Entity
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String email;
    private String name;

    @OneToMany(mappedBy = "user")
    private List<Order> orders;

    // getters, setters
}

// Order.java
@Entity
public class Order {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    private String status;
    private BigDecimal amount;

    // getters, setters
}
```

#### Service 코드 (N+1 발생)
```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    public void getUsersWithOrders() {
        List<User> users = userRepository.findAll();

        for (User user : users) {
            System.out.println(user.getName() + ": " +
                             user.getOrders().size() + " orders");
        }
    }
}
```

---

### 1-3. 쿼리 로그 분석

#### 실행된 쿼리 로그
```sql
-- 1번째 쿼리: 사용자 조회
Hibernate:
    select
        user0_.id as id1_1_,
        user0_.email as email2_1_,
        user0_.name as name3_1_
    from
        users user0_

-- 2번째 쿼리: user_id = 1의 주문
Hibernate:
    select
        orders0_.user_id as user_id4_0_0_,
        orders0_.id as id1_0_0_
    from
        orders orders0_
    where
        orders0_.user_id=?

-- 3번째 쿼리: user_id = 2의 주문
Hibernate:
    select
        ...
    where
        orders0_.user_id=?

-- ... (반복!)
```

**패턴 발견:**
- [ ] 같은 형태의 쿼리가 반복됨
- [ ] WHERE 절의 user_id만 다름
- [ ] N+1 문제 확인!

---

### 1-4. 성능 측정

#### 쿼리 개수
```java
// 실행된 총 쿼리 개수: _____
// 계산: 1 (users) + _____ (orders) = _____
```

#### 실행 시간
```java
long start = System.currentTimeMillis();
userService.getUsersWithOrders();
long duration = System.currentTimeMillis() - start;

// 결과: _____ms
```

---

## 미션 2: JOIN FETCH로 해결

### 2-1. JOIN FETCH 적용

#### Repository 메서드 추가
```java
public interface UserRepository extends JpaRepository<User, Long> {

    // 기존 메서드
    // List<User> findAll();

    // JOIN FETCH 추가
    @Query("____________________________________________")
    List<User> findAllWithOrders();
}
```

**내가 작성한 쿼리:**
```java
@Query("____________________________________________")
```

**이 쿼리를 선택한 이유:**
1.
2.
3.

---

### 2-2. Service 코드 수정

```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    public void getUsersWithOrders() {
        // Before
        // List<User> users = userRepository.findAll();

        // After
        List<User> users = userRepository.________________();

        for (User user : users) {
            System.out.println(user.getName() + ": " +
                             user.getOrders().size() + " orders");
        }
    }
}
```

---

### 2-3. 결과 비교

#### 실행된 쿼리 (After)
```sql
Hibernate:
    select
        ...
    from
        users user0_
    inner join
        orders orders1_
            on user0_.id=orders1_.user_id

-- 총 쿼리: _____번
```

#### 성능 비교

| 항목 | Before (N+1) | After (JOIN FETCH) | 개선율 |
|------|--------------|---------------------|--------|
| 쿼리 개수 | _____ | _____ | _____배 |
| 실행 시간 | _____ms | _____ms | _____배 |

**성공 여부:** [ ] 50배 이상 개선 달성

---

### 2-4. DISTINCT 필요성

#### DISTINCT 없이 실행했을 때
```java
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();

// 결과 개수: _____
// 문제점: _____
```

#### DISTINCT 추가
```java
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();

// 결과 개수: _____
// 해결: _____
```

---

## 미션 3: 페이징과 N+1

### 3-1. 문제 재현

#### 페이징 + JOIN FETCH 시도
```java
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.orders")
Page<User> findAllWithOrders(Pageable pageable);

// 실행 결과:
// 경고 메시지: _____
```

**문제점:**
- [ ] firstResult/maxResults specified with collection fetch 경고
- [ ] 메모리에서 페이징 처리
- [ ] 성능 문제 발생 가능

---

### 3-2. 해결 방법 1: @BatchSize

#### Entity 수정
```java
@Entity
public class User {
    // ...

    @OneToMany(mappedBy = "user")
    @BatchSize(size = _____) // 적절한 배치 사이즈 설정
    private List<Order> orders;
}
```

**배치 사이즈를 _____로 설정한 이유:**

---

#### 실행 결과
```sql
-- 1번째 쿼리: 페이징된 사용자 조회
Hibernate: select ... from users ... limit ?

-- 2번째 쿼리: IN 절로 주문 조회
Hibernate:
    select
        ...
    from
        orders orders0_
    where
        orders0_.user_id in (
            ?, ?, ?, ...
        )

-- 총 쿼리: _____번
```

---

### 3-3. 해결 방법 2: @EntityGraph

#### Repository 메서드
```java
@EntityGraph(attributePaths = {"_____"})
Page<User> findAll(Pageable pageable);
```

#### 실행 결과
```sql
-- 실행된 쿼리:

-- 총 쿼리: _____번
```

---

### 3-4. 방법 비교

| 방법 | 쿼리 개수 | 장점 | 단점 |
|------|-----------|------|------|
| JOIN FETCH | 1 | 가장 빠름 | 페이징 문제 |
| @BatchSize | 2 | 페이징 가능 | 2번 쿼리 |
| @EntityGraph | 2 | 선언적 | 2번 쿼리 |

**내가 선택한 방법:** _____

**이유:**

---

## 미션 4: 중첩 N+1 해결

### 4-1. 문제 재현

#### Entity 추가
```java
@Entity
public class Order {
    // ...

    @OneToMany(mappedBy = "order")
    private List<OrderItem> items;
}

@Entity
public class OrderItem {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "order_id")
    private Order order;

    @ManyToOne
    @JoinColumn(name = "product_id")
    private Product product;

    private Integer quantity;
    private BigDecimal price;
}

@Entity
public class Product {
    @Id @GeneratedValue
    private Long id;
    private String name;
    private BigDecimal price;
}
```

---

#### N+1이 중첩되는 코드
```java
List<User> users = userRepository.findAll();

for (User user : users) {
    for (Order order : user.getOrders()) {
        for (OrderItem item : order.getItems()) {
            System.out.println(item.getProduct().getName());
        }
    }
}
```

---

### 4-2. 쿼리 개수 측정

```
1번: users 조회 (___명)
N번: orders 조회 (user마다 1번, 총 ___번)
M번: order_items 조회 (order마다 1번, 총 ___번)
K번: products 조회 (item마다 1번, 총 ___번)

총 쿼리: 1 + ___ + ___ + ___ = _____번
```

**실행 시간:** _____ms

---

### 4-3. 중첩 JOIN FETCH로 해결

#### Repository 메서드
```java
@Query("_______________________________________________" +
       "_______________________________________________" +
       "_______________________________________________" +
       "_______________________________________________")
List<User> findAllWithOrdersAndItems();
```

**내가 작성한 쿼리:**
```sql
SELECT DISTINCT u
FROM User u
JOIN FETCH _____
JOIN FETCH _____
JOIN FETCH _____
```

---

### 4-4. 결과 비교

#### 실행된 쿼리 (After)
```sql
Hibernate:
    select
        distinct user0_.id as id1_3_0_,
        ...
    from
        users user0_
    inner join
        orders orders1_ on ...
    inner join
        order_items items2_ on ...
    inner join
        products product3_ on ...

-- 총 쿼리: _____번
```

#### 성능 비교

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 쿼리 개수 | _____ | _____ | _____배 |
| 실행 시간 | _____ms | _____ms | _____배 |

---

## 학습 정리

### 배운 핵심 개념 3가지
1.
2.
3.

### N+1 해결 방법 정리

#### 1. JOIN FETCH
**언제 사용:**

**장점:**

**단점:**

---

#### 2. @BatchSize
**언제 사용:**

**장점:**

**단점:**

---

#### 3. @EntityGraph
**언제 사용:**

**장점:**

**단점:**

---

### N+1 탐지 체크리스트
- [ ] 루프 안에서 지연 로딩 접근 확인
- [ ] 쿼리 로그에서 반복 패턴 확인
- [ ] 쿼리 개수가 데이터 개수와 비례하는지 확인
- [ ] 템플릿/뷰에서 관계 접근 확인
- [ ] API 응답 시간 모니터링

---

## 실무 적용 계획

### 현재 회사/프로젝트에서 N+1이 의심되는 곳

**1번 케이스:**
```java
// 파일: _____
// 메서드: _____

// 현재 코드:


// 예상 쿼리 개수: _____

// 개선 계획:


// 예상 개선율: _____
```

---

**2번 케이스:**
```java
// 파일: _____
// 메서드: _____

// 현재 코드:


// 예상 쿼리 개수: _____

// 개선 계획:


// 예상 개선율: _____
```

---

### 즉시 적용할 부분
1.
2.
3.

### 팀 공유 계획
- [ ] N+1 문제 설명 자료 작성
- [ ] 코드 리뷰 시 체크리스트 추가
- [ ] 쿼리 로그 모니터링 방법 공유
- [ ] Best Practice 문서화

---

## 트러블슈팅

### 겪은 문제 1: MultipleBagFetchException
**문제:**

**원인:**

**해결:**

**배운 점:**

---

### 겪은 문제 2: 페이징 경고
**문제:**

**원인:**

**해결:**

**배운 점:**

---

## 추가 실험

### 실험 1: FetchType.EAGER vs JOIN FETCH 비교
```java
// FetchType.EAGER
@OneToMany(mappedBy = "user", fetch = FetchType.EAGER)
private List<Order> orders;

// 쿼리 개수: _____
// 문제점: _____

// JOIN FETCH
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();

// 쿼리 개수: _____
// 장점: _____

// 결론:
```

---

### 실험 2: BatchSize 크기별 성능 비교
```java
// BatchSize = 10
// 쿼리 개수: _____
// 실행 시간: _____ms

// BatchSize = 50
// 쿼리 개수: _____
// 실행 시간: _____ms

// BatchSize = 100
// 쿼리 개수: _____
// 실행 시간: _____ms

// 최적 배치 사이즈: _____
// 이유:
```

---

### 실험 3: DTO Projection으로 N+1 피하기
```java
public interface UserOrderDto {
    Long getId();
    String getName();
    Integer getOrderCount();
}

@Query("SELECT u.id as id, u.name as name, " +
       "COUNT(o) as orderCount " +
       "FROM User u LEFT JOIN u.orders o " +
       "GROUP BY u.id, u.name")
List<UserOrderDto> findAllWithOrderCount();

// 쿼리 개수: _____
// 장점:
// 단점:
```

---

## 다음 액션

### 1주일 내 실행할 것
- [ ] 회사 코드에서 N+1 패턴 찾기
- [ ] 최소 3곳 이상 개선
- [ ] 성능 측정 및 문서화
- [ ] 팀 공유

### 추가 학습 필요
- [ ] Hibernate 배치 처리
- [ ] QueryDSL과 N+1
- [ ] MyBatis N+1 방지

### 모니터링 설정
- [ ] 쿼리 로그 영구 활성화 (dev 환경)
- [ ] 슬로우 쿼리 알림 설정
- [ ] APM 도구 연동 (Scouter, Pinpoint 등)

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
- [ ] 실무 적용 완료
