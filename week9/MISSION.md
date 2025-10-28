# Week 9 미션: 슬로우 쿼리 로그로 병목 찾기 🎯

> "데이터로 증명하는 성능 개선"

---

## 📋 미션 개요

당신은 운영 중인 서비스의 성능 개선 담당자입니다.
최근 일부 API가 느려졌다는 제보가 들어왔지만, 정확히 어떤 쿼리가 문제인지 모릅니다.

**문제 상황:**
- 사용자들이 "가끔 느리다"고 불평
- 어떤 쿼리가 문제인지 추측만 가능
- 개선 우선순위를 정할 데이터가 없음

**당신의 임무:**
슬로우 쿼리 로그를 활용해서 **실제 병목을 찾고 개선**하세요!

---

## 🎯 미션 목표

### 미션 1: 슬로우 쿼리 로그 활성화 (필수)

**상황:**
현재 슬로우 쿼리 로그가 비활성화되어 있습니다.
운영 환경처럼 로그를 설정하세요.

**성공 기준:**
- [ ] 현재 슬로우 쿼리 설정 확인
- [ ] 슬로우 쿼리 로그 활성화
- [ ] 임계값 설정 (1초)
- [ ] 인덱스 미사용 쿼리도 로깅 설정
- [ ] 테스트 쿼리로 로그 생성 확인

**설정값:**
```sql
slow_query_log = ON
long_query_time = 1.0
log_queries_not_using_indexes = ON
```

---

### 미션 2: 느린 쿼리 발생시키기 (필수)

**상황:**
로그 분석 연습을 위해 의도적으로 느린 쿼리를 실행합니다.

**다음 쿼리들을 실행하세요:**

```sql
-- 쿼리 1: 인덱스 없는 조회
SELECT * FROM users WHERE name LIKE '%김%';

-- 쿼리 2: 함수 사용으로 인덱스 못 탐
SELECT * FROM users WHERE YEAR(created_at) = 2024;

-- 쿼리 3: 대량 데이터 정렬
SELECT * FROM orders ORDER BY amount DESC LIMIT 100;

-- 쿼리 4: 비효율적 JOIN
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';

-- 쿼리 5: 전체 테이블 스캔
SELECT COUNT(*) FROM orders WHERE status != 'cancelled';
```

**성공 기준:**
- [ ] 모든 쿼리 실행 완료
- [ ] 각 쿼리의 실행 시간 기록
- [ ] 슬로우 쿼리 로그에 기록 확인

---

### 미션 3: 로그 분석 (필수)

**상황:**
생성된 슬로우 쿼리 로그를 분석해서 가장 문제가 되는 쿼리를 찾으세요.

**성공 기준:**
- [ ] 슬로우 쿼리 로그 파일 위치 확인
- [ ] mysqldumpslow로 분석
- [ ] 가장 느린 쿼리 Top 3 추출
- [ ] 가장 많이 실행된 쿼리 Top 3 추출
- [ ] 총 누적 시간이 가장 긴 쿼리 찾기

**분석 명령어:**
```bash
# 가장 느린 쿼리
mysqldumpslow -s t -t 3 slow-query.log

# 가장 많이 실행된 쿼리
mysqldumpslow -s c -t 3 slow-query.log

# 평균 시간이 긴 쿼리
mysqldumpslow -s at -t 3 slow-query.log
```

---

### 미션 4: 개선 우선순위 결정 (필수)

**상황:**
분석 결과를 바탕으로 어떤 쿼리를 먼저 개선할지 결정하세요.

**우선순위 공식:**
```
점수 = 실행 횟수 × 평균 실행 시간
```

**성공 기준:**
- [ ] 각 느린 쿼리의 우선순위 점수 계산
- [ ] Top 3 우선순위 쿼리 선정
- [ ] 선정 이유 문서화

**고려사항:**
- 누적 시간 (Total Time)
- 실행 빈도 (Calls)
- 평균 시간 (Avg Time)
- 검사 행 수 비율 (Rows_examined / Rows_sent)

---

### 미션 5: 쿼리 개선 (필수)

**상황:**
우선순위 1위 쿼리를 실제로 개선하세요.

**성공 기준:**
- [ ] 원본 쿼리의 EXPLAIN 분석
- [ ] 문제점 파악 (인덱스, 함수, JOIN 등)
- [ ] 개선 방안 작성 (인덱스 추가, 쿼리 재작성)
- [ ] 개선된 쿼리 실행
- [ ] Before/After 성능 비교
- [ ] 최소 50% 이상 성능 개선

**개선 체크리스트:**
- [ ] EXPLAIN 분석 완료
- [ ] 필요한 인덱스 추가
- [ ] 함수 사용 제거
- [ ] 불필요한 컬럼 제거
- [ ] JOIN 최적화
- [ ] 성능 측정 및 기록

---

### 미션 6: 모니터링 자동화 (선택)

**상황:**
매일 슬로우 쿼리 로그를 분석하는 자동화 스크립트를 만드세요.

**성공 기준:**
- [ ] 일일 리포트 생성 스크립트 작성
- [ ] Top 10 느린 쿼리 추출
- [ ] 리포트 파일 자동 생성
- [ ] 로그 순환 (주간 단위)

**스크립트 요구사항:**
- 날짜별 리포트 파일 생성
- Top 10 느린 쿼리 포함
- 실행 횟수, 평균 시간, 총 시간 포함
- 일주일 지난 로그 자동 백업

---

## 💡 제공되는 환경

### 슬로우 쿼리 로그 위치

**Docker 환경:**
```bash
# 컨테이너 내부
/var/log/mysql/slow-query.log

# 확인 방법
docker exec -it wild-learning-mysql bash
tail -f /var/log/mysql/slow-query.log
```

**Windows 환경:**
```bash
# MySQL 데이터 디렉토리
# 보통 C:\ProgramData\MySQL\MySQL Server 8.0\Data\
```

### 로그 파일 읽기

```bash
# 전체 로그 보기
cat /var/log/mysql/slow-query.log

# 실시간 로그 보기
tail -f /var/log/mysql/slow-query.log

# 마지막 50줄
tail -n 50 /var/log/mysql/slow-query.log
```

---

## 🔍 참고: 슬로우 쿼리 로그 형식

### 로그 예시
```
# Time: 2025-10-23T10:30:45.123456Z
# User@Host: root[root] @ localhost []
# Query_time: 2.345678  Lock_time: 0.000123 Rows_sent: 100  Rows_examined: 1000000
SET timestamp=1729677045;
SELECT * FROM users WHERE name LIKE '%김%';
```

### 주요 필드 해석

**Query_time:** 쿼리 실행 시간
- 2.345678초 소요

**Lock_time:** 락 대기 시간
- 0.000123초 (무시 가능한 수준)

**Rows_sent:** 클라이언트로 보낸 행 수
- 100개 반환

**Rows_examined:** 검사한 행 수
- 1,000,000개 검사 (문제!)

**효율성 계산:**
```
효율 = Rows_sent / Rows_examined
     = 100 / 1,000,000
     = 0.01%
```
→ 99.99% 버림! 매우 비효율적

---

## 🔍 참고: mysqldumpslow 출력 해석

```
Count: 1234  Time=2.34s (2889s)  Lock=0.00s (0s)  Rows=100.0 (123400)
  SELECT * FROM orders WHERE user_id=N
```

**해석:**
- **Count: 1234** - 1234번 실행됨
- **Time=2.34s** - 평균 2.34초
- **(2889s)** - 총 누적 시간 2889초 (48분!)
- **Lock=0.00s** - 평균 락 시간
- **Rows=100.0** - 평균 100행 반환
- **(123400)** - 총 123,400행 반환
- **N** - 파라미터는 숫자로 통합됨

---

## 🤔 힌트 (막힐 때만 보세요!)

<details>
<summary>힌트 1: 슬로우 쿼리 로그가 생성 안 될 때</summary>

**확인 사항:**
1. slow_query_log가 ON인지 확인
   ```sql
   SHOW VARIABLES LIKE 'slow_query%';
   ```

2. long_query_time보다 오래 걸리는 쿼리를 실행했는지
   ```sql
   SELECT SLEEP(2);  -- 2초 대기
   ```

3. 로그 파일 권한 확인
   ```bash
   ls -l /var/log/mysql/slow-query.log
   ```

4. MySQL 재시작
   ```bash
   docker restart wild-learning-mysql
   ```

</details>

<details>
<summary>힌트 2: mysqldumpslow 옵션</summary>

**주요 옵션:**
- `-s t` - 실행 시간 순 정렬
- `-s c` - 실행 횟수 순 정렬
- `-s at` - 평균 시간 순 정렬
- `-s r` - Rows 순 정렬
- `-t 10` - Top 10만 표시
- `-a` - 숫자를 N으로 통합하지 않음

**조합 예시:**
```bash
# 가장 느린 10개, 숫자 그대로
mysqldumpslow -s t -t 10 -a slow-query.log
```

</details>

<details>
<summary>힌트 3: 우선순위 판단 기준</summary>

**시나리오 1: 빈도가 높음**
- 실행 횟수: 10,000회
- 평균 시간: 0.1초
- 총 시간: 1,000초
→ **우선순위 높음** (조금만 개선해도 큰 효과)

**시나리오 2: 시간이 김**
- 실행 횟수: 10회
- 평균 시간: 30초
- 총 시간: 300초
→ **우선순위 중간** (사용자 체감은 나쁨)

**시나리오 3: 둘 다 나쁨**
- 실행 횟수: 1,000회
- 평균 시간: 5초
- 총 시간: 5,000초
→ **우선순위 최고** (즉시 개선 필요)

</details>

<details>
<summary>힌트 4: 흔한 개선 방법</summary>

**패턴 1: 인덱스 누락**
```sql
-- Before
SELECT * FROM users WHERE email = 'test@example.com';
-- type: ALL, rows: 1,000,000

-- 해결
CREATE INDEX idx_email ON users(email);
-- type: ref, rows: 1
```

**패턴 2: 함수 사용**
```sql
-- Before
WHERE YEAR(created_at) = 2024

-- 해결
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01'
```

**패턴 3: SELECT ***
```sql
-- Before
SELECT * FROM orders  -- 50개 컬럼

-- 해결
SELECT id, user_id, amount, status  -- 필요한 것만
```

**패턴 4: 비효율적 정렬**
```sql
-- Before
ORDER BY created_at DESC  -- filesort

-- 해결
CREATE INDEX idx_created ON orders(created_at);
-- Using index
```

</details>

---

## 📝 답안 작성 방법

1. `ANSWER.md` 파일에 실습 결과를 작성하세요
2. 각 미션별로 실행한 명령어와 결과를 기록하세요
3. 로그 분석 결과를 표로 정리하세요
4. 개선 전후 성능 비교를 명확히 하세요
5. 완료 후 Claude에게 피드백을 요청하세요!

**답안 템플릿:** `ANSWER_TEMPLATE.md` 참고

---

## ⏱️ 예상 소요 시간

- 미션 1: 10분 (로그 활성화)
- 미션 2: 10분 (느린 쿼리 실행)
- 미션 3: 15분 (로그 분석)
- 미션 4: 10분 (우선순위 결정)
- 미션 5: 20분 (쿼리 개선)
- 미션 6: 15분 (자동화 - 선택)
- **총 60분 (선택 제외 시 50분)**

---

## 🎓 선택 사항: 고급 분석

### pt-query-digest 사용
Percona Toolkit의 고급 분석 도구를 사용해보세요.

```bash
# Docker 컨테이너에 설치
apt-get update
apt-get install percona-toolkit

# 분석
pt-query-digest /var/log/mysql/slow-query.log > report.txt
```

**제공하는 정보:**
- 쿼리별 상세 통계
- 95 percentile, 표준편차
- 쿼리 패턴 그룹핑
- 시간대별 분석

---

## 📊 성공 기준

### 필수 달성 목표
- [ ] 슬로우 쿼리 로그 활성화 완료
- [ ] 최소 5개 이상의 느린 쿼리 로그 생성
- [ ] mysqldumpslow로 Top 3 추출
- [ ] 우선순위 1위 쿼리 50% 이상 개선
- [ ] Before/After 데이터 기록

### 추가 달성 목표
- [ ] 우선순위 Top 3 모두 개선
- [ ] 자동화 스크립트 작성
- [ ] pt-query-digest 사용
- [ ] 실무 프로젝트 적용 계획 수립

---

**난이도:** ⭐⭐ 중
**즉시 적용:** ✓
**ROI:** 중간

**시작 전 체크:**
- [ ] Docker 환경 실행 중
- [ ] MySQL 접속 확인
- [ ] 테이블 데이터 확인 (users 100만, orders 100만)

**9주 과정의 마지막 미션입니다! 준비되셨나요?** 🚀

---

## 🎉 9주 과정 완료 후

이 미션을 완료하면 야생 DB 학습 9주 과정을 모두 마치게 됩니다!

**축하합니다!** 이제 당신은:
- 인덱스 설계 가능
- 쿼리 실행 계획 분석 가능
- 성능 병목 발견 가능
- 락/트랜잭션 문제 해결 가능
- 실전 최적화 경험 보유

**다음 단계:**
1. 배운 내용을 실무에 적용
2. 팀원들과 지식 공유
3. 성능 개선 사례 문서화
4. 지속적인 모니터링 체계 구축

**당신은 이제 DB 최적화 전문가입니다!** 🎓
