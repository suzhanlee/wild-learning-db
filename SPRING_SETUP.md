# Spring Boot 프로젝트 설정 가이드 🍃

> Docker MySQL과 연동되는 Spring Boot 프로젝트 설정

## 📋 목차

- [프로젝트 구조](#프로젝트-구조)
- [application.yml 설정](#applicationyml-설정)
- [엔티티 매핑](#엔티티-매핑)
- [Repository 사용법](#repository-사용법)
- [실습 예제](#실습-예제)

---

## 📁 프로젝트 구조

```
src/main/
├── java/com/wildlearning/db/
│   ├── domain/
│   │   ├── User.java              # 사용자 엔티티
│   │   └── Order.java             # 주문 엔티티
│   └── repository/
│       ├── UserRepository.java    # 사용자 리포지토리
│       └── OrderRepository.java   # 주문 리포지토리
│
└── resources/
    ├── application.yml            # 기본 설정
    ├── application-dev.yml        # 개발 환경
    └── application-prod.yml       # 운영 환경
```

---

## ⚙️ application.yml 설정

### 기본 설정 (application.yml)

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3307/wild_learning_db
    username: root
    password: wild123!@#
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000

  jpa:
    database: mysql
    database-platform: org.hibernate.dialect.MySQLDialect
    hibernate:
      ddl-auto: validate
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        use_sql_comments: true
```

### 개발 환경 (application-dev.yml)

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/wild_learning_db
    hikari:
      maximum-pool-size: 5

  jpa:
    show-sql: true

logging:
  level:
    org.hibernate.SQL: debug
    org.hibernate.type.descriptor.sql.BasicBinder: trace
```

### 운영 환경 (application-prod.yml)

```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 20

  jpa:
    show-sql: false

logging:
  level:
    root: warn
```

---

## 🚀 프로파일 활성화

### IntelliJ에서 설정

**방법 1: Run Configuration**
```
Run → Edit Configurations
→ Active profiles: dev
```

**방법 2: application.yml에 추가**
```yaml
spring:
  profiles:
    active: dev
```

**방법 3: VM Options**
```
-Dspring.profiles.active=dev
```

---

## 📦 필요한 의존성 (build.gradle)

```gradle
dependencies {
    // Spring Boot
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-web'

    // MySQL Driver
    runtimeOnly 'com.mysql:mysql-connector-j'

    // Lombok
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    // Test
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

### Maven (pom.xml)

```xml
<dependencies>
    <!-- Spring Boot Data JPA -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- MySQL Driver -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
</dependencies>
```

---

## 🗃️ 엔티티 매핑

### User 엔티티

```java
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_email", columnList = "email"),
    @Index(name = "idx_created_at", columnList = "created_at"),
    @Index(name = "idx_status", columnList = "status")
})
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String email;

    @Column(nullable = false, length = 100)
    private String name;

    @CreationTimestamp
    @Column(name = "created_at", columnDefinition = "TIMESTAMP(6)")
    private LocalDateTime createdAt;

    @Enumerated(EnumType.STRING)
    private UserStatus status;
}
```

### Order 엔티티

```java
@Entity
@Table(name = "orders", indexes = {
    @Index(name = "idx_user_status_created",
           columnList = "user_id, status, created_at")
})
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    @Column(precision = 10, scale = 2)
    private BigDecimal amount;
}
```

---

## 🔍 Repository 사용 예제

### 기본 조회

```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    // 이메일로 사용자 조회 (idx_email 인덱스 사용)
    public User findByEmail(String email) {
        return userRepository.findByEmail(email)
            .orElseThrow(() -> new EntityNotFoundException("User not found"));
    }

    // 상태별 사용자 목록 (idx_status 인덱스 사용)
    public List<User> findActiveUsers() {
        return userRepository.findByStatus(UserStatus.ACTIVE);
    }
}
```

### 복합 인덱스 활용 (Week 1 실습)

```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;

    // idx_user_status_created 복합 인덱스 사용
    public List<Order> findUserCompletedOrders(Long userId) {
        return orderRepository.findByUserIdAndStatusOrderByCreatedAtDesc(
            userId,
            OrderStatus.COMPLETED,
            PageRequest.of(0, 10)
        );
    }
}
```

### 페이지네이션 (Week 6 실습)

```java
// Offset 방식 (비효율적)
Page<User> users = userRepository.findAllByOrderByCreatedAtDesc(
    PageRequest.of(0, 20)
);

// 커서 방식 (효율적)
List<User> users = userRepository.findByCursorPagination(
    lastUserId,
    PageRequest.of(0, 20)
);
```

### N+1 문제 해결 (Week 7 실습)

```java
// ❌ N+1 문제 발생
List<Order> orders = orderRepository.findAll();
for (Order order : orders) {
    String userName = order.getUser().getName(); // 추가 쿼리!
}

// ✅ Fetch Join으로 해결
List<Order> orders = orderRepository.findOrdersWithUser(orderIds);
for (Order order : orders) {
    String userName = order.getUser().getName(); // 추가 쿼리 없음!
}
```

---

## 🧪 실습 예제 코드

### Week 1: 인덱스 성능 비교

```java
@SpringBootTest
class IndexPerformanceTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void 인덱스_성능_비교() {
        // 인덱스 사용 (빠름)
        long start = System.currentTimeMillis();
        User user = userRepository.findByEmail("user500000@example.com")
            .orElseThrow();
        long duration = System.currentTimeMillis() - start;

        System.out.println("Execution time: " + duration + "ms");
        // 예상: 1-10ms (인덱스 사용)
    }
}
```

### Week 2: EXPLAIN 분석

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    @Query(value = "EXPLAIN SELECT * FROM users WHERE email = :email",
           nativeQuery = true)
    List<Object[]> explainFindByEmail(@Param("email") String email);
}

// 사용
List<Object[]> explain = userRepository.explainFindByEmail("test@example.com");
explain.forEach(row -> System.out.println(Arrays.toString(row)));
```

### Week 6: 커서 기반 페이지네이션

```java
@RestController
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/api/users")
    public List<User> getUsers(
        @RequestParam(required = false) Long cursor,
        @RequestParam(defaultValue = "20") int size
    ) {
        if (cursor == null) {
            // 첫 페이지
            return userRepository.findAll(
                PageRequest.of(0, size, Sort.by("id").descending())
            ).getContent();
        } else {
            // 커서 기반
            return userRepository.findByCursorPagination(
                cursor,
                PageRequest.of(0, size)
            );
        }
    }
}
```

---

## 🔧 트러블슈팅

### "Table 'users' doesn't exist" 에러

**원인**: Docker MySQL이 실행 중이 아님

**해결**:
```bash
scripts\start.bat
```

### "Access denied for user 'root'" 에러

**원인**: 비밀번호 오류

**해결**: application.yml에서 비밀번호 확인
```yaml
spring:
  datasource:
    password: wild123!@#
```

### HikariPool 연결 실패

**원인**: 포트 번호 오류

**해결**: 포트 3307 확인
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/wild_learning_db
```

### ddl-auto: create로 인한 데이터 손실

**해결**: validate 또는 none 사용
```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # 테이블 검증만
```

---

## 📊 로깅 설정

### SQL 쿼리 로그

```yaml
logging:
  level:
    org.hibernate.SQL: debug                    # SQL 쿼리
    org.hibernate.type.descriptor.sql: trace    # 바인딩 파라미터
```

**출력 예제**:
```sql
Hibernate:
    select
        u1_0.id,
        u1_0.email,
        u1_0.name,
        u1_0.status
    from
        users u1_0
    where
        u1_0.email=?
binding parameter [1] as [VARCHAR] - [user500000@example.com]
```

### 커넥션 풀 로그

```yaml
logging:
  level:
    com.zaxxer.hikari: debug
```

---

## 💡 Best Practices

### 1. Fetch Type 설정

```java
// ✅ 대부분의 경우 LAZY 사용
@ManyToOne(fetch = FetchType.LAZY)
private User user;

// ❌ EAGER는 N+1 문제 발생
@ManyToOne(fetch = FetchType.EAGER)
private User user;
```

### 2. 인덱스 설계

```java
// ✅ 복합 인덱스 순서 중요
@Index(name = "idx_user_status_created",
       columnList = "user_id, status, created_at")

// ❌ 순서가 잘못됨
@Index(name = "idx_wrong",
       columnList = "status, user_id, created_at")
```

### 3. Timestamp 정확도

```java
// ✅ TIMESTAMP(6) 마이크로초 정확도
@Column(columnDefinition = "TIMESTAMP(6)")
private LocalDateTime createdAt;
```

---

## ✅ 체크리스트

- [ ] Docker MySQL 실행 (scripts\start.bat)
- [ ] application.yml 설정 완료
- [ ] 의존성 추가 (MySQL Driver, JPA)
- [ ] 엔티티 매핑 확인
- [ ] Repository 작성
- [ ] 프로파일 설정 (dev/prod)
- [ ] 로깅 설정
- [ ] 테스트 코드 작성

---

**설정 완료!** 🎉

이제 Spring Boot 애플리케이션을 실행하고 Week 1부터 실습을 시작하세요!
