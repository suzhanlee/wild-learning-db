# Week 8 정답: 커넥션 풀 관리

> ⚠️ **경고:** 이 파일은 미션을 모두 완료한 후에 확인하세요!
>
> 먼저 스스로 해결하고, ANSWER.md를 작성한 다음, 이 파일로 정답을 확인하세요.

---

## 미션 1: 커넥션 고갈 재현 및 분석 - 정답

### 1-1. 환경 설정

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/wild_learning
    username: user
    password: password
    hikari:
      maximum-pool-size: 3
      connection-timeout: 5000
      pool-name: TestPool
```

**설정 이유:**
- `maximum-pool-size: 3`: 적은 수로 고갈 상황 쉽게 재현
- `connection-timeout: 5000`: 5초만 대기 (빠른 실패)

---

### 1-2. 느린 쿼리 API 구현

```java
@RestController
public class TestController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/slow-query")
    public String slowQuery() {
        // MySQL SLEEP 함수로 10초 대기
        jdbcTemplate.queryForObject("SELECT SLEEP(10)", String.class);
        return "done";
    }
}
```

---

### 1-3. 부하 테스트 실행

```bash
# Apache Bench 사용
ab -n 10 -c 10 http://localhost:8080/slow-query

# 조건:
# - 총 요청: 10개
# - 동시 요청: 10개
# - 각 요청 소요 시간: 10초
# - 풀 사이즈: 3개

# 예상 결과:
# - 1~3번 요청: 성공 (커넥션 획득)
# - 4~10번 요청: 타임아웃 에러 (5초 후)
```

---

### 1-4. 결과 분석

**에러 로그:**
```
2025-10-23 10:15:32.123 ERROR [http-nio-8080-exec-5]
HikariPool-1 - Connection is not available, request timed out after 5000ms.

java.sql.SQLTransientConnectionException:
HikariPool-1 - Connection is not available, request timed out after 5000ms.
    at com.zaxxer.hikari.pool.HikariPool.createTimeoutException(HikariPool.java:695)
    at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:197)
    ...

Caused by: org.springframework.dao.DataAccessResourceFailureException:
Unable to acquire JDBC Connection
```

**통계:**
- 총 요청: 10개
- 성공: 3개
- 실패: 7개 (타임아웃)
- 실패율: 70%

**원인:**
1. 풀 사이즈: **3개**
2. 동시 요청: **10개**
3. 각 요청 소요 시간: **10초**
4. **결론:** 3개 커넥션은 10초 동안 점유 중, 나머지 7개는 5초 대기 후 타임아웃

---

### 1-5. 풀 상태 메트릭

**정상 상태 (부하 전):**
```json
{
  "active": 0,
  "idle": 3,
  "total": 3,
  "waiting": 0
}
```

**부하 상태 (부하 중):**
```json
{
  "active": 3,    // 모두 사용 중!
  "idle": 0,      // 유휴 커넥션 없음
  "total": 3,
  "waiting": 7    // 7개 스레드 대기 중!
}
```

**분석:**
- active 커넥션이 3개로 **최대치 도달**
- idle 커넥션이 **0개** (위험!)
- waiting 스레드가 **7개 발생** (심각!)
- 전형적인 **커넥션 고갈** 상황

---

## 미션 2: 적정 풀 사이즈 찾기 - 정답

### 2-1. 테스트 API

```java
@RestController
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/api/users")
    public List<User> getUsers() {
        // 평균 100ms 쿼리
        return userRepository.findAll(PageRequest.of(0, 100)).getContent();
    }
}
```

---

### 2-2. 테스트 결과 종합

| Pool Size | 응답시간 (ms) | 실패율 (%) | 처리량 (req/s) | DB CPU (%) | 평가 |
|-----------|--------------|-----------|---------------|-----------|------|
| 5 | 850 | 15% | 80 | 45% | ❌ 너무 작음 |
| 10 | 320 | 2% | 250 | 60% | ✅ 적정 |
| 20 | 280 | 0% | 280 | 75% | ✅ 좋음 |
| 50 | 290 | 0% | 270 | 95% | ❌ 너무 큼 |

**상세 분석:**

#### Pool Size = 5 (너무 작음)
- **문제점:**
  - 타임아웃 에러 15% 발생
  - 응답 시간 매우 느림 (850ms)
  - waiting 스레드 평균 3~5개
- **증상:** "커넥션 부족"
- **결론:** 동시 사용자 100명에게 부족

---

#### Pool Size = 10 (적정)
- **장점:**
  - 타임아웃 에러 거의 없음 (2%)
  - 응답 시간 양호 (320ms)
  - DB 리소스 적정 (60%)
- **단점:** 피크 시간에 약간 부족할 수 있음
- **결론:** **기본값으로 적절**

---

#### Pool Size = 20 (우수)
- **장점:**
  - 타임아웃 에러 없음
  - 응답 시간 빠름 (280ms)
  - 여유 있는 설정
- **단점:** DB CPU 75% (여전히 안전)
- **결론:** **프로덕션 권장**

---

#### Pool Size = 50 (과도함)
- **문제점:**
  - 응답 시간 개선 미미 (290ms, 오히려 증가)
  - DB CPU 95% (과부하 임박)
  - 과도한 Context Switching
  - 메모리 낭비
- **증상:** "DB 과부하"
- **결론:** 불필요한 설정

---

### 2-3. 최적 풀 사이즈 결정

**최종 선택:** **20개**

**선택 근거:**
1. **응답 시간:** 280ms (우수)
2. **실패율:** 0% (완벽)
3. **DB 리소스:** 75% (안전)
4. **여유 버퍼:** 피크 시간 대비 가능

**공식 검증:**
```
시스템 환경:
- CPU 코어: 8개
- 스토리지: SSD (효과적인 스핀들 수 = 1)

공식 계산:
풀 사이즈 = (8 × 2) + 1 = 17

실제 최적값: 20

차이 이유:
- 공식은 "시작점" 제시
- 실제 워크로드는 OLTP (빠른 쿼리)
- 피크 트래픽 대비 20% 여유
- 부하 테스트로 실측한 값이 더 정확
```

---

### 2-4. 풀 사이즈 선택 가이드

**너무 작은 풀 증상:**
- ❌ 타임아웃 에러 빈번
- ❌ 응답 시간 증가
- ❌ waiting 스레드 > 0
- ❌ 5xx 에러율 증가
- ❌ 낮은 처리량

**적정한 풀 증상:**
- ✅ 타임아웃 에러 없음 (또는 < 1%)
- ✅ 안정적인 응답 시간
- ✅ waiting 스레드 = 0
- ✅ DB 리소스 50~70%
- ✅ 높은 처리량

**너무 큰 풀 증상:**
- ❌ 응답 시간 개선 미미
- ❌ DB CPU > 80%
- ❌ Context Switching 증가
- ❌ 메모리 낭비
- ❌ DB max_connections 근접

---

## 미션 3: 커넥션 누수 찾기 - 정답

### 3-1. 코드 A: ❌ 위험 (커넥션 누수 가능)

```java
public void codeA() {
    Connection conn = dataSource.getConnection();
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");

    // 데이터 처리

    conn.close();  // 예외 발생 시 실행 안 됨!
}
```

**문제점:**
1. **커넥션 누수:** 예외 발생 시 `close()` 미실행
2. **리소스 누수:** `Statement`, `ResultSet`도 닫히지 않음
3. **예외 처리 누락**

**시나리오:**
```java
Connection conn = dataSource.getConnection();  // 커넥션 획득
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT * FROM users");

// 여기서 NullPointerException 발생!
String name = rs.getString("name").toUpperCase();  // NPE!

conn.close();  // 이 라인은 실행되지 않음!
// → 커넥션 누수 발생!
```

**개선된 코드:**
```java
// ✅ try-with-resources 사용
public void codeA_fixed() {
    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT * FROM users")) {

        // 데이터 처리
        // 예외 발생해도 자동으로 close() 호출

    } catch (SQLException e) {
        // 예외 처리
        log.error("Database error", e);
    }
}
```

**개선 효과:**
- 예외 발생 시에도 **반드시** close() 호출
- 코드 간결
- 리소스 누수 방지

---

### 3-2. 코드 B: ✅ 안전

```java
public void codeB() {
    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT * FROM users")) {

        // 데이터 처리
    }
}
```

**평가:**
- ✅ **try-with-resources** 사용
- ✅ 자동 리소스 관리
- ✅ 예외 안전

**동작 원리:**
```java
// try-with-resources는 다음과 같이 변환됨:

Connection conn = null;
try {
    conn = dataSource.getConnection();
    // 사용
} finally {
    if (conn != null) {
        conn.close();  // 반드시 실행!
    }
}
```

---

### 3-3. 코드 C: ❌ 심각 (커넥션 오래 점유)

```java
@Transactional
public void codeC(Long orderId) {
    // [트랜잭션 시작 → 커넥션 획득]

    Order order = orderRepository.findById(orderId);  // 50ms

    // 외부 API 호출 (5초 소요)
    paymentService.charge(order);  // 5000ms

    // 알림 발송 (3초 소요)
    notificationService.send(order);  // 3000ms

    orderRepository.save(order);  // 50ms

    // [트랜잭션 종료 → 커넥션 반납]
}
// 총 커넥션 점유 시간: 8100ms!
```

**문제점:**
1. **커넥션 오래 점유:** 8.1초 동안 커넥션 독점
2. **외부 호출 포함:** 트랜잭션 안에 네트워크 I/O
3. **동시성 저하:** 풀 10개면 초당 1.2개 요청만 처리 가능

**영향 분석:**
```
풀 사이즈: 10
각 요청 소요 시간: 8초
동시 요청: 100개

처리 가능: 10개
대기: 90개 → 대부분 타임아웃!
```

**개선된 코드:**
```java
// ✅ 트랜잭션 최소화
public void codeC_fixed(Long orderId) {
    // 커넥션 없이 조회 (읽기만)
    Order order = findOrder(orderId);

    // 외부 API 호출 (트랜잭션 밖)
    paymentService.charge(order);  // 5000ms

    // 알림 발송 (트랜잭션 밖)
    notificationService.send(order);  // 3000ms

    // 최소한의 트랜잭션 (쓰기만)
    updateOrder(order);  // 100ms
}

@Transactional(readOnly = true)
private Order findOrder(Long orderId) {
    return orderRepository.findById(orderId).orElseThrow();
}

@Transactional
private void updateOrder(Order order) {
    orderRepository.save(order);
}
// 총 커넥션 점유 시간: 150ms!
```

**개선 효과:**
- Before: 8100ms
- After: 150ms
- **개선율: 98%** (54배 빠름!)
- 동시 처리량: 1.2 req/s → 66 req/s

---

### 3-4. 코드 D: ✅ 우수

```java
public void codeD(Long orderId) {
    Order order = findOrder(orderId);

    paymentService.charge(order);
    notificationService.send(order);

    updateOrder(order);
}

@Transactional
private void updateOrder(Order order) {
    orderRepository.save(order);
}
```

**평가:**
- ✅ 트랜잭션 최소화
- ✅ 외부 호출 분리
- ✅ 커넥션 효율적 사용

**Best Practice:**
1. **트랜잭션은 최소한으로:** DB 작업만
2. **외부 호출은 트랜잭션 밖:** 네트워크 I/O 제외
3. **읽기/쓰기 분리:** `@Transactional(readOnly = true)`

**주의사항:**
- 외부 API 실패 시 롤백 처리 필요
- 보상 트랜잭션 (Saga 패턴) 고려

---

### 3-5. 커넥션 점유 시간 비교

| 코드 | 커넥션 누수 | 점유 시간 | 평가 | 비고 |
|------|----------|---------|------|------|
| A | ❌ 높음 | 100ms | ❌ | 예외 시 누수 |
| B | ✅ 없음 | 100ms | ✅ | 안전 |
| C | ✅ 없음 | 8100ms | ❌ | 너무 오래 점유 |
| D | ✅ 없음 | 150ms | ✅ | 최적화됨 |

**실무 영향:**
```
동시 사용자: 100명
풀 사이즈: 10

코드 C 사용 시:
- 처리 가능: 1.2 req/s
- 실패율: 99%
- 결과: 장애!

코드 D 사용 시:
- 처리 가능: 66 req/s
- 실패율: 0%
- 결과: 안정적
```

---

## 미션 4: 모니터링 및 알람 구축 - 정답

### 4-1. 모니터링 API 구현

```java
@RestController
public class PoolMonitorController {

    @Autowired
    private HikariDataSource dataSource;

    @GetMapping("/pool-status")
    public Map<String, Object> getPoolStatus() {
        HikariPoolMXBean poolBean = dataSource.getHikariPoolMXBean();

        int active = poolBean.getActiveConnections();
        int idle = poolBean.getIdleConnections();
        int total = poolBean.getTotalConnections();
        int waiting = poolBean.getThreadsAwaitingConnection();

        Map<String, Object> status = new HashMap<>();
        status.put("active", active);
        status.put("idle", idle);
        status.put("total", total);
        status.put("waiting", waiting);

        // 상태 평가
        String health = evaluateHealth(active, total, waiting);
        status.put("status", health);

        return status;
    }

    private String evaluateHealth(int active, int total, int waiting) {
        double usage = (double) active / total;

        if (waiting > 0) {
            return "critical";  // 대기 스레드 있음
        } else if (usage > 0.9) {
            return "warning";   // 사용률 90% 초과
        } else {
            return "healthy";
        }
    }
}
```

---

### 4-2. 상태별 응답 예시

**정상 상태:**
```json
{
  "active": 2,
  "idle": 8,
  "total": 10,
  "waiting": 0,
  "status": "healthy"
}
```

**경고 상태:**
```json
{
  "active": 9,
  "idle": 1,
  "total": 10,
  "waiting": 0,
  "status": "warning"
}
```

**위험 상태:**
```json
{
  "active": 10,
  "idle": 0,
  "total": 10,
  "waiting": 5,
  "status": "critical"
}
```

---

### 4-3. Spring Actuator 설정

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  endpoint:
    health:
      show-details: always
  metrics:
    enable:
      hikaricp: true
```

**메트릭 확인:**
```bash
# Active connections
curl http://localhost:8080/actuator/metrics/hikaricp.connections.active

{
  "name": "hikaricp.connections.active",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 3.0
    }
  ],
  "availableTags": [
    {
      "tag": "pool",
      "values": ["HikariPool-1"]
    }
  ]
}

# Idle connections
curl http://localhost:8080/actuator/metrics/hikaricp.connections.idle

{
  "name": "hikaricp.connections.idle",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 7.0
    }
  ]
}

# Pending threads (waiting)
curl http://localhost:8080/actuator/metrics/hikaricp.connections.pending

{
  "name": "hikaricp.connections.pending",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 0.0
    }
  ]
}
```

---

### 4-4. 경고 임계값 설정

#### Warning (경고)
| 메트릭 | 임계값 | 이유 | 대응 |
|--------|-------|------|------|
| active / total | > 80% | 여유 부족 | 모니터링 강화 |
| waiting threads | > 0 | 대기 발생 | 풀 사이즈 검토 |
| idle connections | < 2 | 버퍼 부족 | 쿼리 최적화 |
| connection wait time | > 1s | 대기 시간 증가 | 부하 분산 |

#### Critical (심각)
| 메트릭 | 임계값 | 이유 | 대응 |
|--------|-------|------|------|
| active / total | > 95% | 고갈 임박 | 즉시 풀 증가 |
| waiting threads | > 5 | 심각한 부족 | 긴급 조치 |
| idle connections | = 0 | 여유 없음 | 장애 위험 |
| timeout errors | > 0 | 장애 발생 | 즉시 대응 |

---

### 4-5. 알람 설정 예시 (Prometheus + Alertmanager)

```yaml
# prometheus-alert-rules.yml
groups:
  - name: hikaricp
    interval: 10s
    rules:
      # Warning: 사용률 80% 초과
      - alert: HikariCPHighUsage
        expr: hikaricp_connections_active / hikaricp_connections_max > 0.8
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "HikariCP usage high"
          description: "Pool usage {{ $value | humanizePercentage }}"

      # Critical: 대기 스레드 발생
      - alert: HikariCPThreadsWaiting
        expr: hikaricp_connections_pending > 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Threads waiting for connections"
          description: "{{ $value }} threads waiting"

      # Critical: 타임아웃 에러
      - alert: HikariCPTimeouts
        expr: rate(hikaricp_connections_timeout_total[1m]) > 0
        labels:
          severity: critical
        annotations:
          summary: "Connection timeouts detected"
          description: "{{ $value }} timeouts/sec"
```

---

### 4-6. Grafana 대시보드 예시

**주요 패널:**
1. **Active Connections (시계열)**
   - 실시간 활성 커넥션 수
   - 최대값 표시

2. **Connection Pool Usage (%)**
   - active / total 비율
   - 80%, 95% 임계값 표시

3. **Waiting Threads (게이지)**
   - 대기 중인 스레드 수
   - 0이 정상

4. **Connection Acquisition Time (히스토그램)**
   - 커넥션 획득 소요 시간
   - P50, P95, P99 표시

---

## 추가 학습: 고급 설정 및 최적화

### 1. leak-detection-threshold (누수 탐지)

```yaml
spring:
  datasource:
    hikari:
      leak-detection-threshold: 10000  # 10초
```

**동작:**
- 커넥션을 10초 이상 반납하지 않으면 경고 로그 출력
- 누수 위치를 스택 트레이스로 표시

**로그 예시:**
```
[HikariPool-1] Connection leak detection triggered for
    com.zaxxer.hikari.pool.ProxyConnection@12345678 on thread
    http-nio-8080-exec-3, stack trace follows

java.lang.Exception: Apparent connection leak detected
    at com.example.UserService.slowMethod(UserService.java:45)
    ...
```

**주의:**
- 성능 오버헤드 있음 (프로덕션에서 신중히 사용)
- 개발/스테이징 환경에서 활용

---

### 2. keepaliveTime (연결 유지)

```yaml
spring:
  datasource:
    hikari:
      keepalive-time: 30000  # 30초
```

**동작:**
- 유휴 커넥션을 주기적으로 검증
- DB 방화벽/로드밸런서가 연결을 끊는 것 방지

**언제 필요한가:**
- DB와 애플리케이션 사이에 방화벽/로드밸런서가 있을 때
- 긴 idle-timeout을 사용할 때

---

### 3. 읽기/쓰기 분리 (Read Replica)

```yaml
spring:
  datasource:
    # 쓰기 전용 (Master)
    master:
      jdbc-url: jdbc:mysql://master-db:3306/wild_learning
      hikari:
        maximum-pool-size: 10

    # 읽기 전용 (Replica)
    slave:
      jdbc-url: jdbc:mysql://slave-db:3306/wild_learning
      hikari:
        maximum-pool-size: 20  # 읽기가 더 많음
        read-only: true
```

**장점:**
- 읽기 부하를 Replica로 분산
- Master 풀을 쓰기 전용으로 작게 유지
- 전체 처리량 증가

---

### 4. 트랜잭션 타임아웃 설정

```java
@Transactional(timeout = 5)  // 5초 제한
public void method() {
    // 5초 안에 완료되지 않으면 롤백
}
```

**장점:**
- 긴 트랜잭션 방지
- 커넥션 오래 점유 방지
- 데드락 위험 감소

---

## 실무 체크리스트

### 설정 검토
- [ ] `maximum-pool-size`: 부하 테스트로 결정
- [ ] `connection-timeout`: 30초 (기본값 유지)
- [ ] `max-lifetime`: 30분 (DB wait_timeout보다 작게)
- [ ] `leak-detection-threshold`: 개발 환경에서 활성화

### 코드 검토
- [ ] try-with-resources 사용
- [ ] `@Transactional` 범위 최소화
- [ ] 외부 API 호출을 트랜잭션 밖으로
- [ ] 느린 쿼리 최적화 (Week 1~3)

### 모니터링 구축
- [ ] `/pool-status` API 구현
- [ ] Spring Actuator 활성화
- [ ] Grafana 대시보드 구축
- [ ] 알람 설정 (80%, 95% 임계값)

### 장애 대응
- [ ] 장애 대응 매뉴얼 작성
- [ ] 긴급 조치 방법 숙지
- [ ] 롤백 계획 수립
- [ ] 팀 공유 및 훈련

---

## 실전 팁

### 풀 사이즈 튜닝 프로세스

**1단계: 현재 상태 파악**
```bash
# 현재 설정 확인
grep "maximum-pool-size" application.yml

# 현재 메트릭 확인
curl /pool-status
```

**2단계: 부하 테스트**
```bash
# 실제 트래픽 패턴으로 테스트
k6 run --vus 100 --duration 5m load-test.js
```

**3단계: 메트릭 분석**
- active 최대값
- waiting 발생 빈도
- DB CPU/메모리

**4단계: 점진적 조정**
```
현재: 10
→ 테스트: 15 (50% 증가)
→ 테스트: 20 (100% 증가)
→ 최적: 18 (미세 조정)
```

**5단계: 프로덕션 적용**
- 배포 시간대 선택 (트래픽 적은 시간)
- 카나리 배포 (일부 서버만)
- 모니터링 강화
- 롤백 준비

---

### 장애 대응 플레이북

#### 증상: Connection timeout 에러 급증

**1분 이내 (긴급 조치):**
```bash
# 1. 풀 상태 확인
curl /pool-status

# 2. DB 프로세스 확인
mysql> SHOW PROCESSLIST;

# 3. 느린 쿼리 Kill (주의!)
mysql> KILL [느린 쿼리 ID];

# 4. 풀 사이즈 긴급 증가 (임시)
# application.yml 수정 후 재시작
maximum-pool-size: 20 → 30
```

**10분 이내 (근본 원인 분석):**
```bash
# 1. 최근 배포 확인
git log --since="1 hour ago"

# 2. 트래픽 급증 확인
# CloudWatch/Prometheus 확인

# 3. 슬로우 쿼리 로그 확인
mysql> SELECT * FROM mysql.slow_log
       WHERE start_time > NOW() - INTERVAL 1 HOUR;

# 4. 애플리케이션 로그 확인
grep "Connection leak" app.log
```

**1시간 이내 (영구 해결):**
```bash
# 1. 쿼리 최적화
# 2. 인덱스 추가
# 3. 트랜잭션 최소화 코드 수정
# 4. 풀 사이즈 적정화
# 5. 배포 및 검증
```

---

## 다음 주차 예고: Week 9 - 슬로우 쿼리 로그

이번 주차에서 커넥션 풀을 최적화했다면,
다음 주차에서는 **느린 쿼리를 찾아내고 개선하는 법**을 배웁니다!

- 슬로우 쿼리 로그 설정 및 수집
- pt-query-digest로 로그 분석
- 병목 쿼리 찾기
- 자동 모니터링 구축

---

**완료 축하합니다!** 🎉

커넥션 풀 관리를 마스터했습니다.
이제 서버가 다운되는 장애를 사전에 예방할 수 있습니다!

**다음 액션:**
1. [ ] ANSWER.md와 이 SOLUTION.md 비교
2. [ ] 현재 서비스 커넥션 풀 설정 검토
3. [ ] 모니터링 시스템 구축
4. [ ] 코드 리뷰 체크리스트 작성
5. [ ] Week 9 미션 시작

---

**핵심 정리:**

1. **적정 풀 사이즈** = 부하 테스트로 결정 (공식은 시작점)
2. **커넥션 누수 방지** = try-with-resources
3. **트랜잭션 최소화** = 외부 호출 제외
4. **모니터링 필수** = active, idle, waiting 추적
5. **알람 설정** = 80% warning, 95% critical

**실무 적용 우선순위:**
1. 모니터링 구축 (즉시)
2. 코드 리뷰 (1주일)
3. 부하 테스트 (2주일)
4. 풀 사이즈 최적화 (1개월)
