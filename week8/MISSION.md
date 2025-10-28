# Week 8 미션: 커넥션 풀 장애 예방하기 🎯

> "서버가 죽기 전에 커넥션 풀을 최적화하라"

---

## 📋 미션 개요

당신은 전자상거래 플랫폼의 백엔드 개발자입니다.
최근 대규모 프로모션 이벤트 중 서버가 다운되는 장애가 발생했습니다.

**문제 상황:**
- 로그: `HikariPool-1 - Connection is not available, request timed out after 30000ms`
- 동시 사용자 급증 시 5xx 에러 발생
- 현재 커넥션 풀 설정: 기본값 (10개)

**당신의 임무:**
커넥션 풀을 최적화하고 모니터링 시스템을 구축해서 **다시는 장애가 발생하지 않도록** 하세요!

---

## 🎯 미션 목표

### 미션 1: 커넥션 고갈 재현 및 분석 (필수)

**상황:**
풀 사이즈는 3개인데, 10초씩 걸리는 느린 쿼리에 동시 요청 10개가 들어옵니다.

```java
// application.yml
spring.datasource.hikari.maximum-pool-size=3
spring.datasource.hikari.connection-timeout=5000

// API 엔드포인트
@GetMapping("/slow-query")
public String slowQuery() {
    jdbcTemplate.queryForObject("SELECT SLEEP(10)", String.class);
    return "done";
}
```

**성공 기준:**
- [ ] 설정 파일에서 풀 사이즈를 3으로 제한
- [ ] 느린 쿼리 API 구현
- [ ] 부하 테스트 실행 (동시 요청 10개)
- [ ] 타임아웃 에러 발생 확인
- [ ] 에러 로그와 원인 분석
- [ ] 풀 상태 메트릭 확인 (active, idle, waiting)

**힌트:**
- Apache Bench: `ab -n 10 -c 10 http://localhost:8080/slow-query`
- 또는 JMeter, k6 등 부하 테스트 도구 사용

---

### 미션 2: 적정 풀 사이즈 찾기 (필수)

**상황:**
동시 사용자 100명이 평균 100ms 쿼리를 실행하는 API를 테스트합니다.
다양한 풀 사이즈로 실험해서 최적 값을 찾아야 합니다.

**테스트 시나리오:**
```bash
# 테스트 1: pool-size = 5
# 테스트 2: pool-size = 10
# 테스트 3: pool-size = 20
# 테스트 4: pool-size = 50

# 각 테스트마다 측정할 항목:
# - 평균 응답 시간
# - 실패율 (5xx 에러)
# - CPU 사용률
# - 대기 스레드 수
```

**성공 기준:**
- [ ] 4가지 이상의 풀 사이즈로 부하 테스트 실행
- [ ] 각 테스트의 성능 메트릭 수집
- [ ] 성능 비교표 작성
- [ ] 최적의 풀 사이즈 결정 및 근거 제시
- [ ] "너무 작은 풀"과 "너무 큰 풀"의 증상 확인

**힌트:**
- 공식: `풀 사이즈 = (CPU 코어 수 × 2) + 효과적인 스핀들 수`
- 응답 시간만이 아니라 **실패율**도 중요합니다
- DB 리소스도 함께 모니터링하세요

---

### 미션 3: 커넥션 누수 찾기 (필수)

**상황:**
다음 코드들 중 커넥션 누수를 일으킬 수 있는 패턴을 찾아내세요.

```java
// 코드 A: 수동 커넥션 관리
public void codeA() {
    Connection conn = dataSource.getConnection();
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");

    // 데이터 처리

    conn.close();
}

// 코드 B: try-with-resources
public void codeB() {
    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT * FROM users")) {

        // 데이터 처리
    }
}

// 코드 C: 긴 트랜잭션
@Transactional
public void codeC(Long orderId) {
    Order order = orderRepository.findById(orderId);

    // 외부 API 호출 (5초 소요)
    paymentService.charge(order);

    // 알림 발송 (3초 소요)
    notificationService.send(order);

    orderRepository.save(order);
}

// 코드 D: 트랜잭션 최소화
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

**성공 기준:**
- [ ] 각 코드의 문제점 또는 장점 분석
- [ ] 커넥션 누수가 발생할 수 있는 코드 식별
- [ ] 커넥션을 오래 점유하는 코드 식별
- [ ] 개선된 코드 작성
- [ ] Before/After 커넥션 점유 시간 비교

---

### 미션 4: 모니터링 및 알람 구축 (필수)

**상황:**
장애를 사전에 감지하기 위해 커넥션 풀 모니터링 시스템을 구축해야 합니다.

**요구사항:**
1. HikariCP 메트릭 수집 API 구현
2. 주요 메트릭 실시간 모니터링
3. 경고 임계값 설정

**성공 기준:**
- [ ] `/pool-status` API 엔드포인트 구현
- [ ] 다음 메트릭 수집:
  - `active`: 활성 커넥션 수
  - `idle`: 유휴 커넥션 수
  - `total`: 전체 커넥션 수
  - `waiting`: 대기 중인 스레드 수
- [ ] Spring Actuator 설정 (선택)
- [ ] 경고 임계값 문서화
- [ ] 부하 테스트 중 메트릭 변화 관찰

**예제 응답:**
```json
{
  "active": 8,
  "idle": 2,
  "total": 10,
  "waiting": 0,
  "status": "healthy"
}
```

---

## 💡 제공되는 환경

### Spring Boot 프로젝트 구조

**의존성:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>com.zaxxer</groupId>
    <artifactId>HikariCP</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**기본 설정 파일:**
```yaml
# application.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/wild_learning
    username: user
    password: password
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### 테스트 데이터
- users 테이블: 1,000,000 건
- orders 테이블: 1,000,000 건

---

## 🔍 참고: HikariCP 주요 설정

```yaml
hikari:
  # 필수 설정
  maximum-pool-size: 10        # 최대 커넥션 수 (기본: 10)
  minimum-idle: 5              # 최소 유지 커넥션 (기본: maximum-pool-size와 동일)

  # 타임아웃 설정
  connection-timeout: 30000    # 커넥션 대기 시간 (기본: 30초)
  idle-timeout: 600000         # 유휴 커넥션 제거 시간 (기본: 10분)
  max-lifetime: 1800000        # 커넥션 최대 수명 (기본: 30분)

  # 연결 테스트
  connection-test-query: SELECT 1  # 연결 테스트 쿼리 (MySQL은 불필요)

  # 풀 이름
  pool-name: HikariPool-1      # 로그에 표시될 풀 이름
```

**주요 메트릭 의미:**
- `active`: 현재 사용 중인 커넥션 (높을수록 부하 증가)
- `idle`: 사용 가능한 유휴 커넥션 (0이면 위험)
- `waiting`: 커넥션을 기다리는 스레드 (0보다 크면 풀 부족)
- `total`: 전체 커넥션 수 (maximum-pool-size 이하)

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 커넥션 고갈이 발생하는 이유는?</summary>

**주요 원인:**
1. 풀 사이즈가 너무 작음 (동시 요청 > 풀 사이즈)
2. 느린 쿼리로 커넥션을 오래 점유
3. 트랜잭션이 너무 김 (외부 API 호출 포함)
4. 커넥션 누수 (반납 안 함)

**해결 방법:**
- 풀 사이즈 증가 (하지만 DB 부하 고려)
- 쿼리 최적화 (인덱스 추가)
- 트랜잭션 최소화 (외부 호출 제외)
- try-with-resources 사용

</details>

<details>
<summary>힌트 2: 적정 풀 사이즈 계산 공식</summary>

**기본 공식:**
```
풀 사이즈 = (CPU 코어 수 × 2) + 효과적인 스핀들 수
```

**예시:**
- CPU 4코어 + HDD 1개 = 4 × 2 + 1 = 9
- CPU 8코어 + SSD = 8 × 2 + 1 = 17

**실무 가이드:**
- 시작: 10 (기본값)
- OLTP (빠른 쿼리 많음): 10~20
- OLAP (느린 쿼리 많음): 20~50
- 모니터링 후 점진적 조정

**주의:**
- 너무 크면 DB 과부하
- 너무 작으면 타임아웃 에러
- DB max_connections 확인 필수

</details>

<details>
<summary>힌트 3: 커넥션 누수 방지 패턴</summary>

**좋은 패턴:**
```java
// 1. try-with-resources (자동 close)
try (Connection conn = dataSource.getConnection()) {
    // 사용
}

// 2. Spring @Transactional (자동 관리)
@Transactional
public void method() {
    // 커넥션 자동 관리
}

// 3. JPA/Repository 사용 (추상화)
userRepository.findById(id);
```

**나쁜 패턴:**
```java
// 1. 수동 close (예외 시 누수)
Connection conn = dataSource.getConnection();
// ... 예외 발생하면?
conn.close(); // 실행 안 됨!

// 2. 긴 트랜잭션
@Transactional
public void longTransaction() {
    // DB 작업
    externalApiCall(); // 5초
    // DB 작업
    // 커넥션을 5초 동안 점유!
}
```

</details>

<details>
<summary>힌트 4: 모니터링 구현 방법</summary>

**방법 1: HikariPoolMXBean 사용**
```java
@Autowired
private HikariDataSource dataSource;

@GetMapping("/pool-status")
public Map<String, Object> getStatus() {
    HikariPoolMXBean pool = dataSource.getHikariPoolMXBean();

    Map<String, Object> status = new HashMap<>();
    status.put("active", pool.getActiveConnections());
    status.put("idle", pool.getIdleConnections());
    status.put("total", pool.getTotalConnections());
    status.put("waiting", pool.getThreadsAwaitingConnection());

    return status;
}
```

**방법 2: Spring Actuator**
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics
  metrics:
    enable:
      hikaricp: true
```

**메트릭 확인:**
```
GET /actuator/metrics/hikaricp.connections.active
GET /actuator/metrics/hikaricp.connections.idle
GET /actuator/metrics/hikaricp.connections.pending
```

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 각 미션의 실행 결과와 스크린샷을 포함하세요
3. 성능 비교표와 메트릭 그래프를 작성하세요
4. 최적 설정과 근거를 정리하세요
5. 완료 후 Claude에게 피드백을 요청하세요!

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 20분 (커넥션 고갈 재현)
- 미션 2: 25분 (풀 사이즈 튜닝)
- 미션 3: 15분 (코드 분석)
- 미션 4: 20분 (모니터링 구축)
- **총 80분**

---

## 🎓 선택 사항: 추가 실습

### 고급 실습 1: 커넥션 누수 탐지
```java
// leak-detection-threshold 설정
spring.datasource.hikari.leak-detection-threshold=10000

// 10초 이상 반납 안 되면 경고 로그 출력
// [HikariPool-1] Connection leak detection triggered for ...
```

### 고급 실습 2: Prometheus + Grafana 연동
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### 고급 실습 3: 트랜잭션 타임아웃 설정
```java
@Transactional(timeout = 5) // 5초 제한
public void method() {
    // 긴 작업
}
```

---

## 🔧 부하 테스트 도구

### Apache Bench (간단)
```bash
ab -n 1000 -c 100 http://localhost:8080/api/users
```

### k6 (추천)
```javascript
import http from 'k6/http';

export default function() {
  http.get('http://localhost:8080/api/users');
}
```

### JMeter (GUI)
- 시나리오 기반 테스트
- 그래프 제공

---

## 📊 성공 기준 체크리스트

### 미션 완료 기준
- [ ] 커넥션 고갈 재현 성공
- [ ] 타임아웃 에러 로그 확인
- [ ] 최소 4가지 풀 사이즈 테스트
- [ ] 최적 풀 사이즈 결정
- [ ] 커넥션 누수 패턴 3가지 이상 식별
- [ ] 모니터링 API 구현
- [ ] 경고 임계값 설정

### 실무 적용 준비
- [ ] 현재 서비스 풀 설정 검토
- [ ] 모니터링 시스템 구축 계획
- [ ] 코드 리뷰 체크리스트 작성
- [ ] 장애 대응 매뉴얼 작성

---

**난이도:** ⭐⭐ 쉬움-중
**즉시 적용:** ✓
**ROI:** 높음 (장애 예방)

**시작 전 체크:**
- [ ] Spring Boot 프로젝트 실행
- [ ] MySQL Docker 컨테이너 실행
- [ ] 부하 테스트 도구 설치
- [ ] Postman 또는 curl 준비

**준비되셨나요? 그럼 시작!** 🚀
