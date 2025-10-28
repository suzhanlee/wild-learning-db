# Week 8 답안: 커넥션 풀 관리

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: 커넥션 고갈 재현 및 분석

### 1-1. 환경 설정

#### HikariCP 설정
```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: ___
      connection-timeout: ___
      pool-name: ___

# 설정 이유:
```

#### 느린 쿼리 API 구현
```java
// TestController.java
@RestController
public class TestController {

    @GetMapping("/slow-query")
    public String slowQuery() {
        // 구현 코드
    }
}
```

---

### 1-2. 부하 테스트 실행

#### 테스트 명령어
```bash
# 사용한 도구: _____
# 명령어:


# 테스트 조건:
# - 총 요청 수: ___
# - 동시 요청 수: ___
# - 예상 소요 시간: ___초
```

---

### 1-3. 결과 분석

#### 에러 로그
```
# 발생한 에러 로그 붙여넣기



```

#### 성공/실패 통계
| 항목 | 값 |
|------|-----|
| 총 요청 수 | ___ |
| 성공 | ___ |
| 실패 (타임아웃) | ___ |
| 실패율 | ___% |

#### 원인 분석
**왜 커넥션 고갈이 발생했나?**
1. 풀 사이즈: ___개
2. 동시 요청: ___개
3. 각 요청 소요 시간: ___초
4. 결론: ___

---

### 1-4. 풀 상태 메트릭

#### 정상 상태 (부하 전)
```json
{
  "active": ___,
  "idle": ___,
  "total": ___,
  "waiting": ___
}
```

#### 부하 상태 (부하 중)
```json
{
  "active": ___,
  "idle": ___,
  "total": ___,
  "waiting": ___
}
```

**메트릭 분석:**
- active 커넥션이 ___ → ___ 로 변화
- idle 커넥션이 ___ → ___ 로 변화
- waiting 스레드가 ___ 발생
- 문제점: ___

---

## 미션 2: 적정 풀 사이즈 찾기

### 2-1. 테스트 환경

**API 엔드포인트:**
```java
@GetMapping("/api/users")
public List<User> getUsers() {
    // 평균 100ms 쿼리
    return userRepository.findAll(PageRequest.of(0, 100));
}
```

**테스트 조건:**
- 총 요청 수: 1000
- 동시 사용자: 100
- 각 요청 평균 처리 시간: ~100ms

---

### 2-2. 테스트 1: Pool Size = 5

#### 설정
```yaml
spring.datasource.hikari.maximum-pool-size: 5
```

#### 실행 결과
```bash
# 부하 테스트 명령어



# 결과 요약

```

#### 성능 메트릭
| 항목 | 값 |
|------|-----|
| 평균 응답 시간 | ___ms |
| 최소 응답 시간 | ___ms |
| 최대 응답 시간 | ___ms |
| 실패율 | ___% |
| 처리량 (req/sec) | ___ |

#### 풀 상태
- active (평균): ___
- waiting (최대): ___
- DB CPU 사용률: ___%

**문제점:**
- [ ] 타임아웃 에러 발생
- [ ] 응답 시간 느림
- [ ] 대기 스레드 증가

---

### 2-3. 테스트 2: Pool Size = 10

#### 설정
```yaml
spring.datasource.hikari.maximum-pool-size: 10
```

#### 성능 메트릭
| 항목 | 값 |
|------|-----|
| 평균 응답 시간 | ___ms |
| 최소 응답 시간 | ___ms |
| 최대 응답 시간 | ___ms |
| 실패율 | ___% |
| 처리량 (req/sec) | ___ |

#### 풀 상태
- active (평균): ___
- waiting (최대): ___
- DB CPU 사용률: ___%

**개선 사항:**
- Test 1 대비 응답 시간 ___% 개선
- 타임아웃 에러 ___

---

### 2-4. 테스트 3: Pool Size = 20

#### 설정
```yaml
spring.datasource.hikari.maximum-pool-size: 20
```

#### 성능 메트릭
| 항목 | 값 |
|------|-----|
| 평균 응답 시간 | ___ms |
| 최소 응답 시간 | ___ms |
| 최대 응답 시간 | ___ms |
| 실패율 | ___% |
| 처리량 (req/sec) | ___ |

#### 풀 상태
- active (평균): ___
- waiting (최대): ___
- DB CPU 사용률: ___%

**특이사항:**
- DB 리소스: ___
- 개선 효과: ___

---

### 2-5. 테스트 4: Pool Size = 50

#### 설정
```yaml
spring.datasource.hikari.maximum-pool-size: 50
```

#### 성능 메트릭
| 항목 | 값 |
|------|-----|
| 평균 응답 시간 | ___ms |
| 최소 응답 시간 | ___ms |
| 최대 응답 시간 | ___ms |
| 실패율 | ___% |
| 처리량 (req/sec) | ___ |

#### 풀 상태
- active (평균): ___
- waiting (최대): ___
- DB CPU 사용률: ___%

**문제점:**
- [ ] DB CPU 과부하
- [ ] Context Switching 증가
- [ ] 응답 시간 개선 미미

---

### 2-6. 성능 비교 종합

| Pool Size | 응답시간 (ms) | 실패율 (%) | 처리량 (req/s) | DB CPU (%) | 최적? |
|-----------|--------------|-----------|---------------|-----------|-------|
| 5 | | | | | |
| 10 | | | | | |
| 20 | | | | | ✅ |
| 50 | | | | | |

**그래프 (선택):**
```
[여기에 응답 시간 그래프 스크린샷 또는 ASCII 그래프]
```

---

### 2-7. 최적 풀 사이즈 결정

**최종 선택:** ___개

**선택 근거:**
1. 응답 시간: ___
2. 실패율: ___
3. DB 리소스: ___
4. 여유 있는 설정: ___

**계산 공식 검증:**
- CPU 코어 수: ___
- 공식 계산값: (___  × 2) + 1 = ___
- 실제 최적값: ___
- 차이 이유: ___

---

## 미션 3: 커넥션 누수 찾기

### 3-1. 코드 A 분석 (수동 커넥션 관리)

```java
public void codeA() {
    Connection conn = dataSource.getConnection();
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");

    // 데이터 처리

    conn.close();
}
```

**문제점:**
- [ ] 커넥션 누수 가능
- [ ] 리소스 누수 가능
- [ ] 예외 처리 누락

**상세 분석:**
1. 예외 발생 시: ___
2. close() 실행 보장: ___
3. 위험도: ___

**개선된 코드:**
```java




```

---

### 3-2. 코드 B 분석 (try-with-resources)

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
- [ ] 안전함
- [ ] 커넥션 자동 반납
- [ ] 예외 처리 완벽

**장점:**
1.
2.
3.

---

### 3-3. 코드 C 분석 (긴 트랜잭션)

```java
@Transactional
public void codeC(Long orderId) {
    Order order = orderRepository.findById(orderId);

    // 외부 API 호출 (5초 소요)
    paymentService.charge(order);

    // 알림 발송 (3초 소요)
    notificationService.send(order);

    orderRepository.save(order);
}
```

**문제점:**
- [ ] 커넥션 오래 점유
- [ ] 트랜잭션 너무 김
- [ ] 외부 호출 포함

**상세 분석:**
- 트랜잭션 시작: ___
- 외부 API 시간: ___초
- 알림 발송 시간: ___초
- 총 커넥션 점유 시간: ___초
- 풀 사이즈 10일 때 영향: ___

**개선된 코드:**
```java





```

**개선 효과:**
- Before: 커넥션 점유 ___초
- After: 커넥션 점유 ___초
- 개선율: ___%

---

### 3-4. 코드 D 분석 (트랜잭션 최소화)

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
- [ ] 우수함
- [ ] 트랜잭션 최소화
- [ ] 외부 호출 분리

**장점:**
1.
2.
3.

**주의사항:**
-

---

### 3-5. 커넥션 누수/장시간 점유 요약

| 코드 | 커넥션 누수 위험 | 점유 시간 | 평가 |
|------|---------------|---------|------|
| A | | | |
| B | | | ✅ |
| C | | | ❌ |
| D | | | ✅ |

---

## 미션 4: 모니터링 및 알람 구축

### 4-1. 모니터링 API 구현

```java
@RestController
public class PoolMonitorController {

    @Autowired
    private HikariDataSource dataSource;

    @GetMapping("/pool-status")
    public Map<String, Object> getPoolStatus() {
        // 구현 코드






    }
}
```

---

### 4-2. 메트릭 수집 결과

#### 정상 상태 (부하 없음)
```bash
curl http://localhost:8080/pool-status
```

**응답:**
```json
{
  "active": ___,
  "idle": ___,
  "total": ___,
  "waiting": ___,
  "status": "___"
}
```

---

#### 중간 부하 상태
**응답:**
```json
{
  "active": ___,
  "idle": ___,
  "total": ___,
  "waiting": ___,
  "status": "___"
}
```

---

#### 고부하 상태
**응답:**
```json
{
  "active": ___,
  "idle": ___,
  "total": ___,
  "waiting": ___,
  "status": "___"
}
```

---

### 4-3. 경고 임계값 설정

#### Warning 임계값
| 메트릭 | 임계값 | 이유 |
|--------|-------|------|
| active / total | > 80% | |
| waiting threads | > 0 | |
| idle connections | < 2 | |

#### Critical 임계값
| 메트릭 | 임계값 | 이유 |
|--------|-------|------|
| active / total | > 95% | |
| waiting threads | > 5 | |
| idle connections | = 0 | |

---

### 4-4. Spring Actuator 설정 (선택)

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: ___
  metrics:
    enable:
      hikaricp: ___
```

**메트릭 확인:**
```bash
# Active connections
curl http://localhost:8080/actuator/metrics/hikaricp.connections.active

# 결과:



# Idle connections
curl http://localhost:8080/actuator/metrics/hikaricp.connections.idle

# 결과:


```

---

### 4-5. 부하 테스트 중 메트릭 변화

**테스트 시나리오:**
- 동시 사용자: 100명
- 지속 시간: 1분
- 풀 사이즈: ___

**메트릭 변화 그래프:**
```
시간 | Active | Idle | Waiting
-----|--------|------|--------
0s   |        |      |
10s  |        |      |
20s  |        |      |
30s  |        |      |
40s  |        |      |
50s  |        |      |
60s  |        |      |
```

**관찰 내용:**
- Active 최대값: ___
- Waiting 발생 여부: ___
- 임계값 초과 여부: ___

---

## 학습 정리

### 배운 핵심 개념 5가지
1.
2.
3.
4.
5.

### 커넥션 풀 설정 체크리스트 (내가 정리한 기준)
- [ ] maximum-pool-size: ___
- [ ] minimum-idle: ___
- [ ] connection-timeout: ___
- [ ] 모니터링 시스템 구축
- [ ] 경고 알람 설정
- [ ] 코드 리뷰 (try-with-resources 확인)
- [ ] 긴 트랜잭션 점검

### 커넥션 고갈 원인 Top 3
1.
2.
3.

---

## 실무 적용 계획

### 즉시 적용할 부분

**현재 회사/프로젝트:**
- 프로젝트명: ___
- 현재 풀 사이즈: ___
- 동시 접속자 수: ___

**액션 1: 현재 설정 검토**
```yaml
# 현재 설정
spring.datasource.hikari:
  maximum-pool-size: ___
  connection-timeout: ___

# 개선할 설정


# 변경 근거:

```

**액션 2: 모니터링 구축**
```
1. [ ] /pool-status API 구현
2. [ ] Actuator 메트릭 활성화
3. [ ] 대시보드 구축 (Grafana/CloudWatch 등)
4. [ ] 알람 설정
```

**액션 3: 코드 리뷰**
```
점검할 코드 패턴:
1. [ ] 수동 커넥션 관리 (try-with-resources로 변경)
2. [ ] @Transactional 범위 확인
3. [ ] 외부 API 호출 위치 확인
4. [ ] 느린 쿼리 최적화
```

---

### 장애 대응 매뉴얼

**증상: Connection timeout 에러**

**1단계: 즉시 확인**
```bash
# 풀 상태 확인
curl /pool-status

# 활성 커넥션 수
# 대기 스레드 수
# DB 상태 확인
```

**2단계: 긴급 조치**
```yaml
# 풀 사이즈 임시 증가
spring.datasource.hikari.maximum-pool-size: ___ → ___

# 재시작 (다운타임 최소화)
```

**3단계: 근본 원인 분석**
```
1. [ ] 느린 쿼리 확인 (SHOW PROCESSLIST)
2. [ ] 최근 배포 확인
3. [ ] 트래픽 증가 확인
4. [ ] 코드 변경 확인
5. [ ] DB 리소스 확인
```

**4단계: 재발 방지**
```
1. [ ] 쿼리 최적화
2. [ ] 트랜잭션 최소화
3. [ ] 풀 사이즈 적정화
4. [ ] 모니터링 강화
```

---

## 트러블슈팅

### 겪은 문제 1
**문제:**


**시도한 방법:**


**해결:**


**배운 점:**


---

### 겪은 문제 2
**문제:**


**시도한 방법:**


**해결:**


**배운 점:**


---

## 추가 실험 (선택)

### 실험 1: leak-detection-threshold 테스트
```yaml
spring.datasource.hikari.leak-detection-threshold: 10000
```

**결과:**
```
# 로그 출력 확인


```

---

### 실험 2: 다양한 쿼리 패턴별 커넥션 점유 시간
| 쿼리 유형 | 점유 시간 | 풀 영향도 |
|----------|---------|---------|
| 단순 SELECT | | |
| 복잡한 JOIN | | |
| @Transactional | | |
| 긴 트랜잭션 | | |

---

## 다음 액션

### 팀 공유 내용
- 커넥션 풀 최적화 가이드
- 모니터링 대시보드 구축
- 코드 리뷰 체크리스트
- 장애 대응 매뉴얼

### 추가 학습 필요
- [ ] Prometheus + Grafana 연동
- [ ] DB max_connections 설정
- [ ] 커넥션 풀 고급 튜닝
- [ ] 다른 커넥션 풀 (c3p0, DBCP) 비교

### 실무 적용 기한
- [ ] 1주일 내: 현재 설정 검토 및 모니터링 구축
- [ ] 2주일 내: 코드 리뷰 및 개선
- [ ] 1달 내: 부하 테스트 및 최적화
- [ ] 결과 측정 및 팀 회고

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
- [ ] 실무 적용 결과 공유 완료
