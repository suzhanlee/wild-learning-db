# Week 7 정답: N+1 문제 해결

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: N+1 문제 재현 및 탐지 - 정답

### 1-1. N+1이 발생하는 코드

```java
// UserService.java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    public void getUsersWithOrders() {
        // 1번 쿼리: 사용자 조회
        List<User> users = userRepository.findAll();

        // N번 쿼리: 각 사용자의 주문 조회 (N+1!)
        for (User user : users) {
            List<Order> orders = user.getOrders(); // 지연 로딩 트리거
            System.out.println(user.getName() + ": " + orders.size());
        }
    }
}
```

**왜 N+1이 발생하는가?**
1. `findAll()`로 사용자 조회 → **1번 쿼리**
2. `user.getOrders()`는 기본적으로 **지연 로딩(LAZY)**
3. 루프 안에서 `getOrders()` 접근 → 각 사용자마다 **추가 쿼리**
4. 100명의 사용자 → **100번의 추가 쿼리**
5. **총 101번의 쿼리!**

---

### 1-2. 쿼리 로그 분석

```sql
-- 1번째 쿼리: 사용자 100명 조회
Hibernate:
    select
        user0_.id as id1_1_,
        user0_.email as email2_1_,
        user0_.name as name3_1_,
        user0_.created_at as created_4_1_
    from
        users user0_

-- 2~101번째 쿼리: 각 사용자의 주문 조회 (반복!)
Hibernate:
    select
        orders0_.user_id as user_id4_0_0_,
        orders0_.id as id1_0_0_,
        orders0_.id as id1_0_1_,
        orders0_.user_id as user_id4_0_1_,
        orders0_.status as status2_0_1_,
        orders0_.amount as amount3_0_1_
    from
        orders orders0_
    where
        orders0_.user_id=?  -- user_id만 다르고 반복!
```

**N+1 확인 포인트:**
- 같은 형태의 쿼리가 반복됨 ✓
- WHERE 절의 파라미터만 다름 ✓
- 쿼리 개수 = 1 + N (데이터 개수) ✓

---

### 1-3. 성능 측정 결과

| 항목 | 값 |
|------|-----|
| 사용자 수 | 100명 |
| 총 쿼리 개수 | 101번 (1 + 100) |
| 실행 시간 | 약 5,000~10,000ms |
| 평균 쿼리 시간 | 50~100ms/query |

**문제의 심각성:**
- 사용자 1,000명이면? → 1,001번 쿼리!
- 사용자 10,000명이면? → 10,001번 쿼리!
- **선형적으로 증가하는 성능 문제**

---

## 미션 2: JOIN FETCH로 해결 - 정답

### 2-1. 정답 코드

```java
// UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {

    // 정답: JOIN FETCH
    @Query("SELECT DISTINCT u FROM User u JOIN FETCH u.orders")
    List<User> findAllWithOrders();
}
```

```java
// UserService.java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    public void getUsersWithOrders() {
        // JOIN FETCH 사용 → 1번 쿼리!
        List<User> users = userRepository.findAllWithOrders();

        for (User user : users) {
            // 이미 로딩되어 있음 → 추가 쿼리 없음!
            System.out.println(user.getName() + ": " + user.getOrders().size());
        }
    }
}
```

---

### 2-2. 실행되는 SQL

```sql
Hibernate:
    select
        distinct user0_.id as id1_1_0_,
        orders1_.id as id1_0_1_,
        user0_.email as email2_1_0_,
        user0_.name as name3_1_0_,
        user0_.created_at as created_4_1_0_,
        orders1_.user_id as user_id4_0_1_,
        orders1_.status as status2_0_1_,
        orders1_.amount as amount3_0_1_,
        orders1_.created_at as created_5_0_1_,
        orders1_.user_id as user_id4_0_0__,
        orders1_.id as id1_0_0__
    from
        users user0_
    inner join
        orders orders1_
            on user0_.id=orders1_.user_id
```

**총 쿼리:** **1번!**

---

### 2-3. 성능 비교

| 항목 | Before (N+1) | After (JOIN FETCH) | 개선율 |
|------|--------------|---------------------|--------|
| 쿼리 개수 | 101 | 1 | **101배** |
| 실행 시간 | 5,000ms | 50ms | **100배** |
| DB 왕복 | 101번 | 1번 | **101배** |

**결과:** ✅ 50배 이상 개선 달성!

---

### 2-4. DISTINCT가 필요한 이유

#### DISTINCT 없이 실행
```java
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();

// 결과:
// User 100명이지만 List 크기는 1000 (주문 수만큼 중복!)
```

**왜 중복이 발생하는가?**
```
users (100명)
  ├─ user1 (10개 주문)  → JOIN 결과 10 rows
  ├─ user2 (8개 주문)   → JOIN 결과 8 rows
  └─ user3 (12개 주문)  → JOIN 결과 12 rows

총 1000 rows → User 객체가 1000개 생성됨!
```

#### DISTINCT 추가 (정답)
```java
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();

// 결과: User 100명 (중복 제거)
```

**DISTINCT의 역할:**
- SQL에서 중복 제거 (완벽하지 않음)
- **JPA가 메모리에서 중복된 Entity 제거** (핵심!)
- User 100개만 반환

---

## 미션 3: 페이징과 N+1 - 정답

### 3-1. 문제 상황

```java
// ❌ 이렇게 하면 경고 발생!
@Query("SELECT DISTINCT u FROM User u JOIN FETCH u.orders")
Page<User> findAllWithOrders(Pageable pageable);
```

**실행 시 경고:**
```
HHH000104: firstResult/maxResults specified with collection fetch;
applying in memory!
```

**문제점:**
1. OneToMany JOIN FETCH + 페이징 조합은 위험
2. DB에서 페이징하지 못하고 **메모리에서 페이징**
3. 모든 데이터를 DB에서 가져온 후 애플리케이션에서 자름
4. **OutOfMemoryError 위험!**

---

### 3-2. 해결 방법 1: @BatchSize (추천!)

```java
// User.java
@Entity
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String email;
    private String name;

    @OneToMany(mappedBy = "user")
    @BatchSize(size = 100)  // 핵심!
    private List<Order> orders;
}
```

```java
// UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {
    // 기본 findAll 사용
}
```

```java
// UserService.java
@Service
public class UserService {
    public Page<User> getUsersWithOrders(Pageable pageable) {
        // 페이징된 사용자 조회
        Page<User> users = userRepository.findAll(pageable);

        // orders 접근 시 배치로 조회
        users.forEach(user -> user.getOrders().size());

        return users;
    }
}
```

---

#### 실행되는 SQL

```sql
-- 1번째 쿼리: 페이징된 사용자 조회
Hibernate:
    select
        user0_.id as id1_1_,
        user0_.email as email2_1_,
        user0_.name as name3_1_
    from
        users user0_
    limit 10

-- 2번째 쿼리: IN 절로 배치 조회 (BatchSize만큼)
Hibernate:
    select
        orders0_.user_id as user_id4_0_1_,
        orders0_.id as id1_0_1_,
        orders0_.id as id1_0_0_,
        orders0_.user_id as user_id4_0_0_,
        orders0_.status as status2_0_0_,
        orders0_.amount as amount3_0_0_
    from
        orders orders0_
    where
        orders0_.user_id in (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?  -- 10개 user_id
        )
```

**총 쿼리:** **2번!**
- 1번: 페이징된 사용자
- 1번: IN 절로 주문 배치 조회

---

### 3-3. 해결 방법 2: @EntityGraph

```java
// UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {

    @EntityGraph(attributePaths = {"orders"})
    Page<User> findAll(Pageable pageable);
}
```

**실행 결과:**
- @BatchSize와 동일하게 2번 쿼리
- LEFT JOIN으로 한 번에 가져오려 하지만 페이징 문제로 분리됨

---

### 3-4. 해결 방법 비교

| 방법 | 쿼리 | 장점 | 단점 | 추천 |
|------|------|------|------|------|
| JOIN FETCH | 1 | 가장 빠름 | 페이징 불가 | 페이징 없을 때 |
| @BatchSize | 2 | 페이징 가능, 유연함 | 2번 쿼리 | **페이징 필요 시 추천** |
| @EntityGraph | 2 | 선언적, 간단함 | 2번 쿼리 | @BatchSize와 유사 |
| N+1 (기본) | N+1 | 없음 | 매우 느림 | ❌ 절대 사용 금지 |

**베스트 프랙티스:**
- 페이징 없음 → **JOIN FETCH**
- 페이징 필요 → **@BatchSize**
- 배치 사이즈는 **10~100 사이**

---

## 미션 4: 중첩 N+1 해결 - 정답

### 4-1. 문제 재현

```java
// 엔티티 구조
User (100명)
  └─ Order (1000건)
       └─ OrderItem (10000건)
            └─ Product (100개)

// N+1이 폭발하는 코드
List<User> users = userRepository.findAll();

for (User user : users) {                    // 100번
    for (Order order : user.getOrders()) {   // 1000번
        for (OrderItem item : order.getItems()) {  // 10000번
            System.out.println(item.getProduct().getName());
        }
    }
}
```

**쿼리 개수 계산:**
```
1번:    users 조회 (100명)
100번:  orders 조회 (user마다 1번)
1000번: order_items 조회 (order마다 1번)
10000번: products 조회 (item마다 1번)

총: 1 + 100 + 1000 + 10000 = 11,101번!
```

**예상 실행 시간:** 수 분 이상 (서비스 불가능)

---

### 4-2. 정답: 중첩 JOIN FETCH

```java
// UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("SELECT DISTINCT u FROM User u " +
           "JOIN FETCH u.orders o " +
           "JOIN FETCH o.items i " +
           "JOIN FETCH i.product")
    List<User> findAllWithOrdersAndItems();
}
```

**주의사항:**
- **DISTINCT 필수** (중복 제거)
- 관계가 깊어질수록 조인 비용 증가
- 3단계 이상은 성능 테스트 필수

---

### 4-3. 실행되는 SQL

```sql
Hibernate:
    select
        distinct user0_.id as id1_3_0_,
        orders1_.id as id1_2_1_,
        items2_.id as id1_1_2_,
        product3_.id as id1_0_3_,
        user0_.email as email2_3_0_,
        user0_.name as name3_3_0_,
        orders1_.user_id as user_id4_2_1_,
        orders1_.status as status2_2_1_,
        orders1_.amount as amount3_2_1_,
        items2_.order_id as order_id4_1_2_,
        items2_.product_id as product_5_1_2_,
        items2_.quantity as quantity2_1_2_,
        items2_.price as price3_1_2_,
        product3_.name as name2_0_3_,
        product3_.price as price3_0_3_,
        items2_.order_id as order_id4_1_0__,
        items2_.id as id1_1_0__,
        orders1_.user_id as user_id4_2_1__,
        orders1_.id as id1_2_1__
    from
        users user0_
    inner join
        orders orders1_
            on user0_.id=orders1_.user_id
    inner join
        order_items items2_
            on orders1_.id=items2_.order_id
    inner join
        products product3_
            on items2_.product_id=product3_.id
```

**총 쿼리:** **1번!**

---

### 4-4. 성능 비교

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 쿼리 개수 | 11,101 | 1 | **11,101배** |
| 실행 시간 | 180,000ms | 100ms | **1,800배** |
| 사용 가능 | ❌ | ✅ | - |

---

### 4-5. 중첩 N+1 해결 전략

#### 전략 1: 모두 JOIN FETCH (데이터 적을 때)
```java
@Query("SELECT DISTINCT u FROM User u " +
       "JOIN FETCH u.orders o " +
       "JOIN FETCH o.items")
```
- 장점: 1번 쿼리
- 단점: 카테시안 곱, 메모리 부담

---

#### 전략 2: 단계별 BatchSize (데이터 많을 때)
```java
@Entity
public class User {
    @OneToMany(mappedBy = "user")
    @BatchSize(size = 100)
    private List<Order> orders;
}

@Entity
public class Order {
    @OneToMany(mappedBy = "order")
    @BatchSize(size = 100)
    private List<OrderItem> items;
}

@Entity
public class OrderItem {
    @ManyToOne
    @JoinColumn(name = "product_id")
    private Product product;
}
```

**쿼리 개수:**
```
1번: users (100명)
1번: orders IN (user_id batch)
1번: items IN (order_id batch)
1번: products IN (product_id batch)

총: 4번 (11,101번 → 4번!)
```

---

#### 전략 3: DTO Projection (읽기 전용)
```java
@Query("SELECT new com.example.dto.UserOrderDto(" +
       "u.id, u.name, o.id, o.status, " +
       "i.id, p.name) " +
       "FROM User u " +
       "JOIN u.orders o " +
       "JOIN o.items i " +
       "JOIN i.product p")
List<UserOrderDto> findAllAsDto();
```
- 장점: 1번 쿼리, 메모리 효율
- 단점: Entity가 아님, 읽기 전용

---

## 추가 학습: N+1 해결 방법 완전 정리

### 1. JOIN FETCH

**사용 시기:**
- OneToOne, ManyToOne 관계
- OneToMany이지만 페이징 불필요
- 데이터가 많지 않을 때

**코드:**
```java
@Query("SELECT DISTINCT e FROM Entity e JOIN FETCH e.collection")
List<Entity> findAllWithCollection();
```

**장점:**
- 1번의 쿼리
- 가장 빠른 성능

**단점:**
- 페이징 불가 (메모리 페이징 위험)
- MultipleBagFetchException (OneToMany 2개 이상)
- 카테시안 곱으로 중복 데이터

---

### 2. @BatchSize

**사용 시기:**
- 페이징 필요
- OneToMany 관계
- 데이터가 많을 때

**코드:**
```java
@OneToMany(mappedBy = "parent")
@BatchSize(size = 100)
private List<Child> children;
```

**장점:**
- 페이징 가능
- IN 절로 효율적 조회
- 유연한 배치 크기 조정

**단점:**
- 2번의 쿼리 (본체 + IN 쿼리)

**배치 사이즈 선택:**
- 10~100 권장
- DB의 IN 절 제한 고려 (Oracle 1000개)
- 메모리와 네트워크 대역폭 고려

---

### 3. @EntityGraph

**사용 시기:**
- 동적으로 fetch 전략 변경 필요
- 메서드별로 다른 연관 관계 로딩

**코드:**
```java
@EntityGraph(attributePaths = {"orders", "profile"})
List<User> findAll();
```

**장점:**
- 선언적
- 메서드별 fetch 전략

**단점:**
- LEFT JOIN 강제
- 복잡한 관계는 JPQL이 나을 수 있음

---

### 4. FetchType.EAGER (⚠️ 비추천)

**코드:**
```java
@OneToMany(mappedBy = "parent", fetch = FetchType.EAGER)
private List<Child> children;
```

**문제점:**
- 항상 조회 (필요 없어도)
- N+1 발생 가능 (MultipleBagFetchException)
- 제어 불가능

**결론:** **사용하지 마세요!**

---

### 5. DTO Projection

**사용 시기:**
- 읽기 전용 조회
- 필요한 컬럼만 선택
- 집계/통계 쿼리

**코드:**
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
```

**장점:**
- 1번 쿼리
- 메모리 효율
- 필요한 데이터만

**단점:**
- Entity 아님
- 수정 불가

---

## 실전 패턴과 안티패턴

### ❌ 안티패턴 1: 루프 안 지연 로딩
```java
List<User> users = userRepository.findAll();
for (User user : users) {
    user.getOrders().size();  // N+1!
}
```

### ✅ 개선: JOIN FETCH
```java
List<User> users = userRepository.findAllWithOrders();
for (User user : users) {
    user.getOrders().size();  // 추가 쿼리 없음
}
```

---

### ❌ 안티패턴 2: 템플릿에서 지연 로딩
```html
{% for user in users %}
    {{ user.name }}: {{ user.orders.size }}  <!-- N+1! -->
{% endfor %}
```

### ✅ 개선: 미리 로딩
```java
model.addAttribute("users",
    userRepository.findAllWithOrders());
```

---

### ❌ 안티패턴 3: FetchType.EAGER 남발
```java
@OneToMany(fetch = FetchType.EAGER)
private List<Order> orders;

@OneToMany(fetch = FetchType.EAGER)
private List<Address> addresses;
// MultipleBagFetchException!
```

### ✅ 개선: 필요할 때만 FETCH
```java
@OneToMany(fetch = FetchType.LAZY)  // 기본값
private List<Order> orders;

// 필요할 때
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();
```

---

### ❌ 안티패턴 4: 페이징 + JOIN FETCH
```java
@Query("SELECT u FROM User u JOIN FETCH u.orders")
Page<User> findAll(Pageable pageable);
// 메모리 페이징 위험!
```

### ✅ 개선: @BatchSize
```java
@OneToMany(mappedBy = "user")
@BatchSize(size = 100)
private List<Order> orders;

Page<User> users = userRepository.findAll(pageable);
```

---

## 실무 적용 체크리스트

### N+1 탐지
- [ ] 쿼리 로그 항상 활성화 (dev 환경)
- [ ] 같은 쿼리 반복 패턴 확인
- [ ] 쿼리 개수 모니터링
- [ ] 응답 시간 급증 확인

### 코드 리뷰 시
- [ ] 루프 안 지연 로딩 체크
- [ ] FetchType.EAGER 사용 확인
- [ ] 페이징 + 컬렉션 조회 확인
- [ ] 템플릿/뷰에서 관계 접근 확인

### 해결 방법 선택
- [ ] 페이징 필요? → @BatchSize
- [ ] 페이징 불필요? → JOIN FETCH
- [ ] 읽기 전용? → DTO Projection
- [ ] 관계 깊이 3단계 이상? → 배치 또는 DTO

### 성능 측정
- [ ] Before/After 쿼리 개수 비교
- [ ] Before/After 응답 시간 비교
- [ ] 메모리 사용량 확인
- [ ] 프로덕션 부하 테스트

---

## 다음 주차 예고: Week 8 - 커넥션 풀 관리

N+1을 해결했다면, 이제 DB 커넥션을 효율적으로 관리해야 합니다!

- 커넥션 풀 크기 설정
- 커넥션 누수 탐지
- HikariCP 최적화
- 모니터링과 알림

---

**완료 축하합니다!** 🎉

이제 N+1 문제를 보는 즉시 발견하고 해결할 수 있습니다!

**다음 액션:**
1. [ ] ANSWER.md와 SOLUTION.md 비교
2. [ ] 회사 코드에서 N+1 찾기
3. [ ] 최소 3곳 이상 개선
4. [ ] 성능 개선 결과 팀 공유
5. [ ] Week 8 미션 시작

---

## FAQ

### Q1: JOIN FETCH vs @BatchSize 중 뭐가 더 좋나요?
**A:** 상황에 따라 다릅니다.
- 페이징 없고 데이터 적음 → JOIN FETCH
- 페이징 필요하거나 데이터 많음 → @BatchSize

### Q2: BatchSize는 몇으로 설정하나요?
**A:** 10~100 사이 권장
- 너무 작으면: 쿼리 여러 번
- 너무 크면: IN 절 너무 길어짐, 메모리 부담
- DB별 IN 절 제한 확인 (Oracle 1000개)

### Q3: MultipleBagFetchException은 뭔가요?
**A:** OneToMany 2개 이상을 동시에 JOIN FETCH 시 발생
```java
// ❌ 에러 발생
@Query("SELECT u FROM User u " +
       "JOIN FETCH u.orders " +
       "JOIN FETCH u.addresses")

// ✅ 해결 1: 하나만 FETCH, 나머지는 @BatchSize
@Query("SELECT u FROM User u JOIN FETCH u.orders")
@EntityGraph(attributePaths = {"addresses"})

// ✅ 해결 2: Set 사용
@OneToMany
private Set<Order> orders;  // List → Set
```

### Q4: N+1이 항상 나쁜가요?
**A:** 대부분 나쁘지만, 예외는 있습니다.
- 데이터 10건 미만이고 한 번만 조회: 영향 적음
- 하지만 습관적으로 방지하는 게 좋음

### Q5: MyBatis에서도 N+1이 발생하나요?
**A:** 네, 발생 가능합니다.
```xml
<!-- ❌ N+1 발생 -->
<select id="selectUser">
  SELECT * FROM users
</select>
<select id="selectOrders">
  SELECT * FROM orders WHERE user_id = #{userId}
</select>

<!-- ✅ 해결: JOIN -->
<select id="selectUserWithOrders">
  SELECT u.*, o.*
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
</select>
```

### Q6: 프론트엔드에서 N+1을 방지할 수 있나요?
**A:** GraphQL의 DataLoader 패턴
```javascript
// DataLoader가 자동으로 배치 처리
users.forEach(user => {
  userLoader.load(user.id)  // 배치로 조회
})
```
