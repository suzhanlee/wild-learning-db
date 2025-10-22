# Week 9: 슬로우 쿼리 로그 분석 ⭐⭐

> "병목 찾는 가장 확실한 방법"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"진짜 병목을 데이터로 찾기"**

이번 주차를 완료하면:
- 슬로우 쿼리 로그 설정 가능
- 로그 분석으로 병목 발견
- 개선 우선순위 판단 가능
- 지속적인 모니터링 체계 구축

---

## 📚 학습 내용

### 1. 슬로우 쿼리 로그란? (10분)

#### 개념
```
설정한 시간보다 오래 걸리는 쿼리를 자동으로 기록

예:
- 임계값: 1초
- 쿼리 실행 시간: 3초
→ 로그에 기록 ✅
```

#### 왜 필요한가?
```
✅ 장점:
- 실제 프로덕션 쿼리 분석
- 느린 쿼리 자동 발견
- 개선 우선순위 판단 (빈도 × 시간)

❌ 단점:
- 약간의 오버헤드 (1-2%)
- 디스크 공간 필요
- 로그 분석 필요
```

---

### 2. 슬로우 쿼리 로그 설정 (15분)

#### MySQL 설정

**확인**
```sql
-- 현재 설정 확인
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 결과 예시
+---------------------+--------------------------------+
| Variable_name       | Value                          |
+---------------------+--------------------------------+
| slow_query_log      | OFF                            |
| slow_query_log_file | /var/log/mysql/slow-query.log  |
| long_query_time     | 10.000000                      |
+---------------------+--------------------------------+
```

**활성화**
```sql
-- 런타임 설정 (재시작 없이)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- 1초 이상

-- 영구 설정 (my.cnf)
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 1
log_queries_not_using_indexes = 1  -- 인덱스 안 쓰는 쿼리도 로그
```

#### 추가 옵션
```sql
-- 관리 쿼리도 로깅 (ALTER, ANALYZE 등)
log_slow_admin_statements = 1

-- 로그 포맷 (파일 또는 테이블)
log_output = FILE  -- 또는 TABLE (mysql.slow_log)

-- 최소 검사 행 수
min_examined_row_limit = 1000  -- 1000행 이상 검사한 쿼리만
```

---

### 3. 슬로우 쿼리 로그 읽기 (15분)

#### 로그 예시
```
# Time: 2024-01-10T15:30:45.123456Z
# User@Host: myapp[myapp] @ localhost []
# Query_time: 3.123456  Lock_time: 0.000123 Rows_sent: 1000  Rows_examined: 1000000
SET timestamp=1704900645;
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC;
```

#### 주요 필드 해석
```
Query_time: 3.123456
  → 쿼리 실행 시간: 3.12초

Lock_time: 0.000123
  → 락 대기 시간: 0.12ms

Rows_sent: 1000
  → 클라이언트로 보낸 행 수: 1000

Rows_examined: 1000000
  → 검사한 행 수: 100만 (문제!)

효율:
  Rows_sent / Rows_examined = 1000 / 1000000 = 0.1%
  → 99.9% 버림! (매우 비효율적)
```

---

### 4. 로그 분석 도구 (15분)

#### mysqldumpslow (기본 도구)
```bash
# 가장 느린 쿼리 10개
mysqldumpslow -s t -t 10 /var/log/mysql/slow-query.log

# 가장 많이 실행된 쿼리 10개
mysqldumpslow -s c -t 10 /var/log/mysql/slow-query.log

# 평균 시간이 긴 쿼리 10개
mysqldumpslow -s at -t 10 /var/log/mysql/slow-query.log

# 출력 예시
Count: 1234  Time=2.34s (2889s)  Lock=0.00s (0s)  Rows=100.0 (123400)
  SELECT * FROM orders WHERE user_id=N

해석:
- 1234번 실행
- 평균 2.34초
- 총 누적 시간: 2889초 (48분!)
- 평균 100행 반환
```

#### pt-query-digest (고급 도구)
```bash
# 설치 (Percona Toolkit)
sudo apt-get install percona-toolkit

# 분석
pt-query-digest /var/log/mysql/slow-query.log

# 출력 예시 (요약)
# Profile
# Rank Query ID           Response time  Calls R/Call V/M   Item
# ==== ================== ============== ===== ====== ===== =====
#    1 0x1234567890ABCDEF  2889.0  45.2%  1234 2.3400  0.01 SELECT orders
#    2 0xFEDCBA0987654321  1500.0  23.5%   500 3.0000  0.05 SELECT users
# ...

# 상세 분석
# Query 1: 1234 QPS, ID 0x1234567890ABCDEF
# Attribute    total     min     max     avg     95%  stddev  median
# ============ ===== ======= ======= ======= ======= ======= =======
# Exec time     2889s   1.5s   5.0s   2.3s   3.8s   0.5s   2.2s
# Rows sent      123k     50    200    100    150     20     100
# Rows examine  1.2G   800k   2.0M   1.0M   1.5M   200k   1.0M

# 가장 느린 예시
SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at DESC;
```

---

### 5. 개선 우선순위 결정 (15분)

#### 우선순위 공식
```
우선순위 점수 = 실행 횟수 × 평균 시간

예시:
쿼리 A: 10회 × 10초 = 100점
쿼리 B: 1000회 × 0.2초 = 200점

→ 쿼리 B를 먼저 개선!
```

#### 실전 판단 기준
```
1. 누적 시간 (Total Time)
   - 전체 응답 시간에 가장 많이 기여
   - 우선순위 1순위

2. 실행 빈도 (Calls)
   - 자주 실행되는 쿼리
   - 조금만 개선해도 큰 효과

3. 평균 시간 (Avg Time)
   - 개별 쿼리가 느림
   - 사용자 체감 성능

4. 검사 행 비율 (Rows_examined / Rows_sent)
   - 비효율성 지표
   - 개선 가능성 높음
```

#### 개선 체크리스트
```
□ EXPLAIN 분석
□ 인덱스 확인
□ WHERE 조건 최적화
□ 불필요한 컬럼 제거
□ JOIN 최적화
□ 서브쿼리 제거
□ 페이지네이션 개선
```

---

## 🔬 실습

### 실습 1: 슬로우 쿼리 로그 활성화 (15분)

```sql
-- 1. 현재 설정 확인
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 결과 기록:
-- slow_query_log: _____
-- slow_query_log_file: _____
-- long_query_time: _____

-- 2. 활성화
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 0.1;  -- 0.1초 (테스트용)
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- 3. 확인
SHOW VARIABLES LIKE 'slow_query%';

-- 4. 느린 쿼리 실행 (테스트)
SELECT SLEEP(1);
SELECT * FROM orders WHERE created_at LIKE '%2024%';  -- 인덱스 못 탐

-- 5. 로그 확인
-- Linux/Mac
sudo tail -f /var/log/mysql/slow-query.log

-- Windows
-- MySQL 데이터 디렉토리에서 slow-query.log 확인

-- 로그 내용 붙여넣기:


```

---

### 실습 2: 로그 분석 (20분)

```bash
# 실제 프로덕션 로그 또는 샘플 로그

# mysqldumpslow로 분석
# 1. 가장 느린 10개
mysqldumpslow -s t -t 10 slow-query.log

# 결과 기록:
# 1위: _____
# 실행 횟수: _____
# 평균 시간: _____
# 쿼리: _____

# 2. 가장 많이 실행된 10개
mysqldumpslow -s c -t 10 slow-query.log

# 결과 기록:
# 1위: _____
# 실행 횟수: _____
# 평균 시간: _____
# 총 누적 시간: _____

# 3. pt-query-digest로 상세 분석 (설치된 경우)
pt-query-digest slow-query.log > report.txt

# Top 3 쿼리 추출
# 1. _____
# 2. _____
# 3. _____
```

---

### 실습 3: 개선 작업 (25분)

```sql
-- 슬로우 쿼리 로그에서 발견한 쿼리 개선

-- 쿼리 1
-- 원본 (로그에서 복사)
[느린 쿼리 붙여넣기]

-- 분석
-- Query_time: _____
-- Rows_examined: _____
-- Rows_sent: _____
-- 효율: _____%

-- EXPLAIN 분석
EXPLAIN [쿼리];

-- 문제점:
-- 1. _____
-- 2. _____

-- 개선
[개선된 쿼리]

-- 성능 비교
-- Before: _____ms, Rows_examined: _____
-- After: _____ms, Rows_examined: _____
-- 개선율: _____%

-- 쿼리 2-3 반복
```

---

### 실습 4: 지속적 모니터링 (10분)

```bash
# Cron으로 일일 리포트 자동화

# /etc/cron.daily/slow-query-report.sh
#!/bin/bash

LOG_FILE="/var/log/mysql/slow-query.log"
REPORT_FILE="/var/log/mysql/daily-report-$(date +%Y%m%d).txt"

# 리포트 생성
mysqldumpslow -s t -t 20 $LOG_FILE > $REPORT_FILE

# 이메일 전송 (선택)
mail -s "MySQL Slow Query Report" admin@example.com < $REPORT_FILE

# 로그 순환 (주간)
if [ $(date +%u) -eq 1 ]; then
    mv $LOG_FILE $LOG_FILE.$(date +%Y%m%d)
    touch $LOG_FILE
    chown mysql:mysql $LOG_FILE
fi

# 실행 권한
chmod +x /etc/cron.daily/slow-query-report.sh

# 테스트
/etc/cron.daily/slow-query-report.sh
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] 슬로우 쿼리 로그 개념 이해
- [ ] 주요 설정 파라미터 숙지
- [ ] 로그 필드 해석 방법 학습
- [ ] 우선순위 판단 기준 이해

### 실습 완료
- [ ] 슬로우 쿼리 로그 활성화
- [ ] mysqldumpslow로 분석
- [ ] Top 3 느린 쿼리 개선
- [ ] 자동화 스크립트 작성

### 실무 적용
- [ ] 프로덕션 슬로우 쿼리 로그 활성화
- [ ] 주간 리포트 자동화
- [ ] 개선 작업 진행
- [ ] 모니터링 대시보드 연동

---

## 📝 학습 노트

### 설정 체크리스트
```sql
-- 프로덕션 권장 설정
slow_query_log = ON
long_query_time = 1  -- 1초
log_queries_not_using_indexes = ON
min_examined_row_limit = 1000
log_output = FILE
```

### 개선 우선순위 리스트

| 순위 | 쿼리 | 실행 횟수 | 평균 시간 | 누적 시간 | 점수 |
|------|------|----------|----------|----------|------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

### 개선 결과

**총 개선 효과:**
- 개선한 쿼리 수: _____개
- 절감한 총 시간: _____초/일
- 응답 시간 개선: _____%

---

## 📚 참고 자료

- MySQL 공식 문서: [The Slow Query Log](https://dev.mysql.com/doc/refman/8.0/en/slow-query-log.html)
- Percona Toolkit: [pt-query-digest](https://www.percona.com/doc/percona-toolkit/LATEST/pt-query-digest.html)
- [mysqldumpslow 사용법](https://dev.mysql.com/doc/refman/8.0/en/mysqldumpslow.html)

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐ 중
**즉시 적용**: ✓
**ROI**: 중간

**완료일**: ___________

---

## 🎉 9주 과정 완료!

축하합니다! 야생 DB 학습 9주 과정을 모두 완료하셨습니다.

### 배운 내용 정리
- Week 1: 인덱스 핵심 원리
- Week 2: EXPLAIN 실전 분석
- Week 3: 쿼리 성능 비용 감각
- Week 4: 락과 데드락 처리
- Week 5: 트랜잭션 격리 수준
- Week 6: 페이지네이션 최적화
- Week 7: N+1 문제 해결
- Week 8: 커넥션 풀 관리
- Week 9: 슬로우 쿼리 로그

### 다음 단계
- [ ] 배운 내용 팀 공유
- [ ] 실무 프로젝트 적용
- [ ] 성능 개선 사례 문서화
- [ ] 심화 학습 계획 수립

**당신은 이제 DB 최적화 전문가입니다!** 🚀
