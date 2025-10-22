# Week 8: 커넥션 풀 관리 ⭐⭐

> "서버 죽는 이유 1순위 방지"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"커넥션 부족으로 서비스 다운 방지하기"**

이번 주차를 완료하면:
- 커넥션 풀 동작 원리 이해
- 적정 풀 사이즈 계산 가능
- 커넥션 고갈 문제 진단 가능
- 모니터링으로 장애 예방 가능

---

## 📚 학습 내용

### 1. 커넥션 풀이란? (15분)

#### 커넥션 생성 비용
```
DB 커넥션 생성 과정:
1. TCP 연결 (3-way handshake)
2. DB 인증
3. 세션 초기화
4. 리소스 할당

소요 시간: 10~100ms
→ 매번 생성하면 느림!
```

#### 커넥션 풀 개념
```
┌─────────────────────┐
│   Connection Pool   │
│  ┌──┐ ┌──┐ ┌──┐    │
│  │C1│ │C2│ │C3│ ...│  미리 생성해둔 커넥션
│  └──┘ └──┘ └──┘    │
└─────────────────────┘
         ↕
     빌려쓰기/반납

장점:
- 빠른 응답 (커넥션 재사용)
- 안정성 (최대 개수 제한)
- 효율성 (리소스 관리)
```

#### HikariCP (Java/Spring)
```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10        # 최대 커넥션 수
      minimum-idle: 5              # 최소 유지 커넥션 수
      connection-timeout: 30000    # 커넥션 대기 시간 (30초)
      idle-timeout: 600000         # 유휴 커넥션 제거 시간 (10분)
      max-lifetime: 1800000        # 커넥션 최대 수명 (30분)
```

---

### 2. 커넥션 고갈 문제 (15분)

#### 문제 상황
```
풀 사이즈: 10
동시 요청: 100

1-10번 요청: 커넥션 획득 ✅
11-100번 요청: 대기... ⏳
→ timeout 발생 → 서비스 다운! 💥
```

#### 실제 에러
```
java.sql.SQLTransientConnectionException:
HikariPool-1 - Connection is not available,
request timed out after 30000ms.

org.springframework.dao.DataAccessResourceFailureException:
Unable to acquire JDBC Connection
```

#### 원인
```
1. 풀 사이즈 너무 작음
2. 커넥션 누수 (반납 안 함)
3. 느린 쿼리 (커넥션 오래 점유)
4. 트랜잭션 너무 김
```

---

### 3. 적정 풀 사이즈 계산 (15분)

#### 공식
```
풀 사이즈 = (Core 수 × 2) + 효과적인 스핀들 수

예시:
- CPU 코어: 4개
- HDD: 1개
→ 4 × 2 + 1 = 9

일반적 권장:
- 시작: 10
- 모니터링 후 조정
```

#### 고려 사항

**너무 작으면:**
```
문제:
- 커넥션 대기 시간 증가
- 타임아웃 에러 발생
- 처리량(throughput) 감소

증상:
- 응답 시간 증가
- 5xx 에러 증가
- 커넥션 대기 로그
```

**너무 크면:**
```
문제:
- DB 리소스 낭비
- Context Switching 증가
- DB 과부하

증상:
- DB CPU/메모리 높음
- 쿼리 응답 시간 증가
- DB max_connections 초과
```

#### 튜닝 전략
```
1. 모니터링 데이터 수집
   - 활성 커넥션 수
   - 대기 커넥션 수
   - 대기 시간

2. 병목 확인
   - 항상 풀 Max? → 증가
   - 대부분 Idle? → 감소

3. 점진적 조정
   - 한 번에 2-3개씩
   - 부하 테스트로 검증
```

---

### 4. 커넥션 누수 방지 (15분)

#### 누수 패턴

**❌ 나쁜 예 1: 수동 커넥션 관리**
```java
Connection conn = dataSource.getConnection();
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT ...");

// 예외 발생 시 반납 안 됨!
// → 커넥션 누수

conn.close();  // 실행 안 될 수 있음
```

**✅ 좋은 예 1: try-with-resources**
```java
try (Connection conn = dataSource.getConnection();
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT ...")) {

    // 사용

} // 자동으로 close() 호출
```

**❌ 나쁜 예 2: 긴 트랜잭션**
```java
@Transactional
public void processOrder(Long orderId) {
    // 커넥션 획득
    Order order = orderRepository.findById(orderId);

    // 외부 API 호출 (5초 소요)
    paymentService.charge(order);

    // 커넥션을 5초 동안 점유!
}
```

**✅ 좋은 예 2: 트랜잭션 최소화**
```java
public void processOrder(Long orderId) {
    Order order = orderRepository.findById(orderId);

    // 외부 API 호출 (트랜잭션 밖)
    paymentService.charge(order);

    // 최소한의 트랜잭션
    updateOrderStatus(orderId, "PAID");
}

@Transactional
public void updateOrderStatus(Long orderId, String status) {
    // 빠른 업데이트만
}
```

---

### 5. 모니터링 (15분)

#### HikariCP 메트릭
```java
@RestController
public class PoolMonitorController {

    @Autowired
    private HikariDataSource dataSource;

    @GetMapping("/pool-status")
    public Map<String, Object> getPoolStatus() {
        HikariPoolMXBean poolBean = dataSource.getHikariPoolMXBean();

        Map<String, Object> status = new HashMap<>();
        status.put("active", poolBean.getActiveConnections());
        status.put("idle", poolBean.getIdleConnections());
        status.put("total", poolBean.getTotalConnections());
        status.put("waiting", poolBean.getThreadsAwaitingConnection());

        return status;
    }
}
```

#### 경고 임계값
```yaml
alerts:
  connection_pool:
    # 활성 커넥션 > 80%
    - metric: active_connections
      threshold: 8  # (10 * 0.8)
      severity: warning

    # 대기 스레드 > 0
    - metric: waiting_threads
      threshold: 0
      severity: critical

    # 커넥션 획득 시간 > 1초
    - metric: connection_wait_time
      threshold: 1000
      severity: warning
```

---

## 🔬 실습

### 실습 1: 커넥션 고갈 재현 (20분)

```java
// 설정: 풀 사이즈 3
spring.datasource.hikari.maximum-pool-size=3
spring.datasource.hikari.connection-timeout=5000

// 느린 쿼리 API
@RestController
public class TestController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/slow-query")
    public String slowQuery() {
        jdbcTemplate.queryForObject(
            "SELECT SLEEP(10)", // 10초 대기
            String.class
        );
        return "done";
    }
}

// 부하 테스트
// 동시 요청 10개
ab -n 10 -c 10 http://localhost:8080/slow-query

// 결과:
// - 처음 3개: 성공 (커넥션 획득)
// - 나머지 7개: 타임아웃 에러

// 에러 로그 확인
[HikariPool-1] Connection is not available, request timed out after 5000ms

// 모니터링
GET /pool-status
{
    "active": 3,    // 모두 사용 중
    "idle": 0,
    "total": 3,
    "waiting": 7    // 7개 대기 중!
}
```

---

### 실습 2: 적정 풀 사이즈 찾기 (25분)

```bash
# 시나리오: API 성능 테스트
# 동시 사용자: 100명
# 각 요청: 평균 100ms 쿼리

# 테스트 1: pool-size = 5
spring.datasource.hikari.maximum-pool-size=5

ab -n 1000 -c 100 http://localhost:8080/api/users

# 결과:
# - 평균 응답 시간: _____ms
# - 실패율: _____%
# - 대기 스레드: _____

# 테스트 2: pool-size = 10
spring.datasource.hikari.maximum-pool-size=10

ab -n 1000 -c 100 http://localhost:8080/api/users

# 결과:
# - 평균 응답 시간: _____ms
# - 실패율: _____%
# - 대기 스레드: _____

# 테스트 3: pool-size = 20
spring.datasource.hikari.maximum-pool-size=20

ab -n 1000 -c 100 http://localhost:8080/api/users

# 결과:
# - 평균 응답 시간: _____ms
# - 실패율: _____%
# - 대기 스레드: _____

# 테스트 4: pool-size = 50
spring.datasource.hikari.maximum-pool-size=50

ab -n 1000 -c 100 http://localhost:8080/api/users

# 결과:
# - 평균 응답 시간: _____ms
# - 실패율: _____%
# - 대기 스레드: _____
```

#### 성능 비교
| Pool Size | 응답시간 | 실패율 | 대기 스레드 | 최적? |
|-----------|---------|--------|------------|-------|
| 5 | | | | |
| 10 | | | | |
| 20 | | | | ✅ |
| 50 | | | | |

---

### 실습 3: 모니터링 대시보드 구축 (15분)

```java
// Actuator 설정
// pom.xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

// application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics
  metrics:
    enable:
      hikaricp: true

// 메트릭 확인
GET /actuator/metrics/hikaricp.connections.active
GET /actuator/metrics/hikaricp.connections.idle
GET /actuator/metrics/hikaricp.connections.pending

// Prometheus + Grafana 연동 (선택)
// 실시간 모니터링 대시보드 구축

// 테스트
// 1. 정상 상태 메트릭 기록
// 2. 부하 발생 시 메트릭 변화 관찰
// 3. 알람 임계값 설정
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] 커넥션 풀 동작 원리 이해
- [ ] HikariCP 주요 설정 숙지
- [ ] 적정 풀 사이즈 계산 방법 학습
- [ ] 커넥션 누수 패턴 인식

### 실습 완료
- [ ] 커넥션 고갈 재현
- [ ] 풀 사이즈 튜닝 실험
- [ ] 모니터링 대시보드 구축
- [ ] 알람 임계값 설정

### 실무 적용
- [ ] 현재 서비스 커넥션 풀 설정 검토
- [ ] 모니터링 시스템 구축
- [ ] 커넥션 누수 코드 패턴 점검
- [ ] 장애 대응 매뉴얼 작성

---

## 📝 학습 노트

### 커넥션 풀 체크리스트

**설정 검토**
- [ ] maximum-pool-size 적정한가?
- [ ] connection-timeout 충분한가?
- [ ] max-lifetime 설정되었는가?

**모니터링**
- [ ] active connections 추적
- [ ] waiting threads 추적
- [ ] 알람 설정

**코드 검토**
- [ ] try-with-resources 사용
- [ ] 트랜잭션 최소화
- [ ] 느린 쿼리 개선

### 장애 대응 플레이북

**증상: Connection timeout**
1. [ ] 풀 상태 확인 (`/pool-status`)
2. [ ] 활성 커넥션 수 확인
3. [ ] 대기 스레드 확인
4. [ ] 최근 배포 확인
5. [ ] 느린 쿼리 확인 (`SHOW PROCESSLIST`)
6. [ ] 풀 사이즈 임시 증가 (긴급)
7. [ ] 근본 원인 분석

---

## 📚 참고 자료

- [HikariCP 공식 문서](https://github.com/brettwooldridge/HikariCP)
- [About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing)
- Spring Boot Actuator: Monitoring

---

**학습 시간**: 45분 야생학습
**난이도**: ⭐⭐ 쉬움
**즉시 적용**: ✓
**ROI**: 높음 (장애 예방)

**완료일**: ___________
