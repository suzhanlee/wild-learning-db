# Week 9 답안: 슬로우 쿼리 로그 분석

> 이 파일을 복사해서 `ANSWER.md`로 저장하고 작성하세요!

**작성자:** [이름]
**작성일:** [날짜]

---

## 미션 1: 슬로우 쿼리 로그 활성화

### 1-1. 현재 설정 확인

```sql
-- 슬로우 쿼리 로그 설정 확인
SHOW VARIABLES LIKE 'slow_query%';

-- 결과:
```

| Variable_name | Value |
|---------------|-------|
| slow_query_log | |
| slow_query_log_file | |

```sql
-- 임계값 확인
SHOW VARIABLES LIKE 'long_query_time';

-- 결과: _____초
```

**현재 상태:**
- 슬로우 쿼리 로그: [ ] ON / [ ] OFF
- 로그 파일 위치: _____
- 임계값: _____초

---

### 1-2. 슬로우 쿼리 로그 활성화

```sql
-- 슬로우 쿼리 로그 활성화
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1.0;
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- 설정 확인
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 결과:
```

| Variable_name | Before | After |
|---------------|--------|-------|
| slow_query_log | | |
| long_query_time | | |
| log_queries_not_using_indexes | | |

---

### 1-3. 테스트 쿼리 실행

```sql
-- 테스트 쿼리 1: 강제 지연
SELECT SLEEP(2);

-- 실행 시간: _____초
```

```sql
-- 테스트 쿼리 2: 인덱스 미사용
SELECT * FROM users WHERE name = 'test';

-- 실행 시간: _____초
```

**로그 생성 확인:**
```bash
# 로그 파일 확인 명령어
tail -n 20 /var/log/mysql/slow-query.log

# 또는 Docker
docker exec -it wild-learning-mysql tail -n 20 /var/log/mysql/slow-query.log

# 결과: [ ] 로그 생성됨 / [ ] 로그 없음
```

---

## 미션 2: 느린 쿼리 발생시키기

### 2-1. 쿼리 1 실행

```sql
-- 인덱스 없는 LIKE 검색
SELECT * FROM users WHERE name LIKE '%김%';

-- 실행 시간: _____ms
-- 반환 행 수: _____
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT * FROM users WHERE name LIKE '%김%';
```

| type | rows | Extra |
|------|------|-------|
| | | |

---

### 2-2. 쿼리 2 실행

```sql
-- 함수 사용으로 인덱스 못 탐
SELECT * FROM users WHERE YEAR(created_at) = 2024;

-- 실행 시간: _____ms
-- 반환 행 수: _____
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT * FROM users WHERE YEAR(created_at) = 2024;
```

| type | rows | Extra |
|------|------|-------|
| | | |

---

### 2-3. 쿼리 3 실행

```sql
-- 대량 데이터 정렬
SELECT * FROM orders ORDER BY amount DESC LIMIT 100;

-- 실행 시간: _____ms
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT * FROM orders ORDER BY amount DESC LIMIT 100;
```

| type | rows | Extra |
|------|------|-------|
| | | |

---

### 2-4. 쿼리 4 실행

```sql
-- 비효율적 JOIN
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON CONCAT('user_', u.id) = o.user_note
WHERE u.status = 'active';

-- 실행 시간: _____ms
-- 반환 행 수: _____
```

---

### 2-5. 쿼리 5 실행

```sql
-- 전체 테이블 스캔
SELECT COUNT(*) FROM orders WHERE status != 'cancelled';

-- 실행 시간: _____ms
-- 결과: _____
```

**EXPLAIN 분석:**
```sql
EXPLAIN SELECT COUNT(*) FROM orders WHERE status != 'cancelled';
```

| type | rows | Extra |
|------|------|-------|
| | | |

---

### 2-6. 실행 요약

| 쿼리 | 실행 시간 | 예상 로그 기록 |
|------|-----------|----------------|
| 1. LIKE '%김%' | ___ms | [ ] YES / [ ] NO |
| 2. YEAR(created_at) | ___ms | [ ] YES / [ ] NO |
| 3. ORDER BY amount | ___ms | [ ] YES / [ ] NO |
| 4. 비효율적 JOIN | ___ms | [ ] YES / [ ] NO |
| 5. status != | ___ms | [ ] YES / [ ] NO |

---

## 미션 3: 로그 분석

### 3-1. 슬로우 쿼리 로그 확인

```bash
# 로그 파일 전체 보기
cat /var/log/mysql/slow-query.log

# 또는
docker exec -it wild-learning-mysql cat /var/log/mysql/slow-query.log
```

**로그에서 발견된 쿼리 개수:** _____개

---

### 3-2. mysqldumpslow 분석

#### 가장 느린 쿼리 Top 3

```bash
# 명령어
mysqldumpslow -s t -t 3 /var/log/mysql/slow-query.log

# 결과:
```

**1위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

**2위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

**3위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

---

#### 가장 많이 실행된 쿼리 Top 3

```bash
# 명령어
mysqldumpslow -s c -t 3 /var/log/mysql/slow-query.log

# 결과:
```

**1위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

**2위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

**3위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

---

#### 평균 시간이 긴 쿼리 Top 3

```bash
# 명령어
mysqldumpslow -s at -t 3 /var/log/mysql/slow-query.log

# 결과:
```

**1위:**
```
Count: ___  Time=___s (___s)  Lock=___s (___s)  Rows=___ (___)
[쿼리 붙여넣기]
```

---

### 3-3. 로그 원본 상세 분석

**대표 슬로우 쿼리 로그:**
```
# Time: _____
# User@Host: _____
# Query_time: ___  Lock_time: ___  Rows_sent: ___  Rows_examined: ___
SET timestamp=_____;
[쿼리 붙여넣기]
```

**효율성 계산:**
```
효율 = Rows_sent / Rows_examined
     = ___ / ___
     = ___%
```

**분석:**
- 검사한 행: _____
- 반환한 행: _____
- 버린 데이터: _____%
- 문제점: _____

---

## 미션 4: 개선 우선순위 결정

### 4-1. 우선순위 점수 계산

**우선순위 공식:** 실행 횟수 × 평균 실행 시간

| 순위 | 쿼리 (요약) | 실행 횟수 | 평균 시간 | 총 누적 시간 | 우선순위 점수 |
|------|------------|----------|----------|-------------|--------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

---

### 4-2. 우선순위 1위 선정

**선정된 쿼리:**
```sql
[쿼리 붙여넣기]
```

**선정 이유:**
1. 실행 횟수: _____회 (빈도가 _____함)
2. 평균 시간: _____초 (속도가 _____함)
3. 총 누적 시간: _____초 (전체 응답 시간의 _____%를 차지)
4. 효율성: _____%

**예상 개선 효과:**
- 일일 절감 시간: _____초
- 사용자 체감: _____
- 서버 부하 감소: _____%

---

### 4-3. 추가 고려사항

**Rows_examined / Rows_sent 비율:**

| 쿼리 | Rows_examined | Rows_sent | 비율 | 개선 가능성 |
|------|--------------|-----------|------|-------------|
| 쿼리 1 | | | | |
| 쿼리 2 | | | | |
| 쿼리 3 | | | | |

**비율이 높을수록 (= 버리는 데이터가 많을수록) 개선 여지가 큼**

---

## 미션 5: 쿼리 개선

### 5-1. 우선순위 1위 쿼리 분석

**원본 쿼리:**
```sql
[쿼리 붙여넣기]
```

**현재 성능:**
- 실행 시간: _____ms
- Rows_examined: _____
- Rows_sent: _____

---

### 5-2. EXPLAIN 분석 (Before)

```sql
EXPLAIN [원본 쿼리];
```

| id | select_type | table | type | possible_keys | key | rows | Extra |
|----|-------------|-------|------|---------------|-----|------|-------|
| | | | | | | | |

**문제점 파악:**
1. type: _____ (문제: _____)
2. rows: _____ (문제: _____)
3. key: _____ (문제: _____)
4. Extra: _____ (문제: _____)

**근본 원인:**
- [ ] 인덱스 누락
- [ ] 함수 사용
- [ ] 잘못된 JOIN
- [ ] SELECT *
- [ ] 비효율적 조건
- [ ] 기타: _____

---

### 5-3. 개선 방안

**방법 1: 인덱스 추가 (필요한 경우)**
```sql
-- 추가할 인덱스
CREATE INDEX _____ ON _____(______);

-- 인덱스를 추가하는 이유:
```

**방법 2: 쿼리 재작성**
```sql
-- 개선된 쿼리
[개선된 쿼리 붙여넣기]

-- 변경 사항:
1.
2.
3.
```

---

### 5-4. EXPLAIN 분석 (After)

```sql
EXPLAIN [개선된 쿼리];
```

| id | select_type | table | type | possible_keys | key | rows | Extra |
|----|-------------|-------|------|---------------|-----|------|-------|
| | | | | | | | |

**개선 내용:**
1. type: _____ → _____
2. rows: _____ → _____
3. key: _____ → _____
4. Extra: _____ → _____

---

### 5-5. 성능 비교

| 항목 | Before | After | 개선율 |
|------|--------|-------|--------|
| 실행 시간 | ___ms | ___ms | ___% |
| Rows_examined | | | ___% |
| Rows_sent | | | - |
| type | | | - |
| 인덱스 사용 | | | - |

**성공 여부:** [ ] 50% 이상 개선 달성

**실제 개선율:** _____%

---

### 5-6. 추가 개선 (선택)

**우선순위 2위 쿼리:**
```sql
-- Before
[원본 쿼리]

-- 문제점:

-- After
[개선된 쿼리]

-- 개선율: _____%
```

**우선순위 3위 쿼리:**
```sql
-- Before
[원본 쿼리]

-- 문제점:

-- After
[개선된 쿼리]

-- 개선율: _____%
```

---

## 미션 6: 모니터링 자동화 (선택)

### 6-1. 자동화 스크립트 작성

**스크립트 파일:** `slow-query-report.sh`

```bash
#!/bin/bash

# 슬로우 쿼리 로그 일일 리포트 생성
# 작성자: _____
# 작성일: _____

LOG_FILE="/var/log/mysql/slow-query.log"
REPORT_DIR="/var/log/mysql/reports"
REPORT_FILE="$REPORT_DIR/daily-report-$(date +%Y%m%d).txt"

# 디렉토리 생성
mkdir -p $REPORT_DIR

# 리포트 생성
echo "==================================" > $REPORT_FILE
echo "슬로우 쿼리 일일 리포트" >> $REPORT_FILE
echo "생성일: $(date)" >> $REPORT_FILE
echo "==================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Top 10 느린 쿼리
echo "### 가장 느린 쿼리 Top 10 ###" >> $REPORT_FILE
mysqldumpslow -s t -t 10 $LOG_FILE >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Top 10 많이 실행된 쿼리
echo "### 가장 많이 실행된 쿼리 Top 10 ###" >> $REPORT_FILE
mysqldumpslow -s c -t 10 $LOG_FILE >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 로그 순환 (주간)
if [ $(date +%u) -eq 1 ]; then
    mv $LOG_FILE $LOG_FILE.$(date +%Y%m%d)
    touch $LOG_FILE
    chown mysql:mysql $LOG_FILE
    echo "로그 순환 완료: $(date)" >> $REPORT_FILE
fi

echo "리포트 생성 완료: $REPORT_FILE"
```

---

### 6-2. 스크립트 테스트

```bash
# 실행 권한 부여
chmod +x slow-query-report.sh

# 테스트 실행
./slow-query-report.sh

# 결과 확인
cat /var/log/mysql/reports/daily-report-*.txt
```

**테스트 결과:**
- [ ] 리포트 파일 생성됨
- [ ] Top 10 쿼리 포함됨
- [ ] 날짜별 파일명 생성됨

---

### 6-3. Cron 등록 (선택)

```bash
# Cron 편집
crontab -e

# 매일 오전 9시 실행
0 9 * * * /path/to/slow-query-report.sh

# Cron 확인
crontab -l
```

**등록 여부:** [ ] 완료 / [ ] 미완료

---

## 학습 정리

### 배운 핵심 개념 3가지

1. **슬로우 쿼리 로그의 중요성**
   -

2. **로그 분석 방법**
   -

3. **개선 우선순위 결정**
   -

---

### 슬로우 쿼리 분석 체크리스트 (내가 정리한 기준)

**로그 활성화:**
- [ ] slow_query_log = ON
- [ ] long_query_time 설정 (프로덕션: 1초)
- [ ] log_queries_not_using_indexes = ON

**분석 단계:**
- [ ] mysqldumpslow로 Top 10 추출
- [ ] 실행 횟수 × 평균 시간으로 우선순위 계산
- [ ] Rows_examined / Rows_sent 비율 확인
- [ ] EXPLAIN으로 근본 원인 파악

**개선 체크:**
- [ ] 인덱스 추가/수정
- [ ] 함수 제거
- [ ] 불필요한 컬럼 제거
- [ ] 조건 최적화
- [ ] 50% 이상 개선 확인

---

### 흔한 성능 문제 패턴 (암기할 것!)

1. **인덱스 누락**
   - 증상: type = ALL, rows = 전체 행 수
   - 해결: 적절한 인덱스 추가

2. **함수 사용**
   - 증상: WHERE YEAR(date), UPPER(name)
   - 해결: 함수 제거, 범위 조건으로 변경

3. **SELECT ***
   - 증상: 불필요한 컬럼까지 조회
   - 해결: 필요한 컬럼만 명시

4. **비효율적 정렬**
   - 증상: Extra = Using filesort
   - 해결: 정렬 컬럼에 인덱스 추가

5. **부정 조건**
   - 증상: WHERE status != 'cancelled'
   - 해결: 긍정 조건으로 변경 (IN 사용)

---

## 실무 적용 계획

### 즉시 적용할 부분

**현재 회사/프로젝트:**
[프로젝트명]

**1단계: 슬로우 쿼리 로그 활성화**
- 대상 서버: _____
- 임계값: _____초
- 예상 일정: _____

**2단계: 일주일간 데이터 수집**
- 수집 기간: _____ ~ _____
- 분석 일정: _____

**3단계: 우선순위 Top 5 개선**
| 순위 | 쿼리 | 예상 개선율 | 담당자 | 완료 예정일 |
|------|------|------------|--------|------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

---

### 모니터링 체계 구축

**일일 리포트:**
- [ ] 자동화 스크립트 작성
- [ ] 담당자 메일 전송
- [ ] Slack 알림 연동

**주간 회의:**
- [ ] 느린 쿼리 리뷰
- [ ] 개선 작업 우선순위 결정
- [ ] 성과 측정

**월간 리포트:**
- [ ] 전체 성능 개선 효과
- [ ] 절감한 총 시간
- [ ] 다음 달 목표 설정

---

### 추가로 확인할 부분

1. **프로덕션 적용 시 주의사항**
   -

2. **팀 공유 내용**
   -

3. **심화 학습 필요 사항**
   -

---

## 트러블슈팅

### 겨운 문제 1: 로그가 생성되지 않음

**문제:**
슬로우 쿼리 로그를 활성화했는데 로그 파일이 비어있음

**시도한 방법:**
1.
2.
3.

**해결:**

**배운 점:**

---

### 겪은 문제 2: mysqldumpslow 명령어 없음

**문제:**
mysqldumpslow 명령어를 찾을 수 없음

**시도한 방법:**

**해결:**

**배운 점:**

---

### 겪은 문제 3: 로그 파일 권한 오류

**문제:**

**시도한 방법:**

**해결:**

**배운 점:**

---

## 추가 실험 (선택)

### 실험 1: long_query_time 변경 실험

```sql
-- 0.1초로 설정
SET GLOBAL long_query_time = 0.1;

-- 동일 쿼리 실행
[쿼리]

-- 결과:
-- 로그 기록 여부: [ ] YES / [ ] NO

-- 1초로 설정
SET GLOBAL long_query_time = 1.0;

-- 동일 쿼리 실행
[쿼리]

-- 결과:
-- 로그 기록 여부: [ ] YES / [ ] NO
```

**결론:**
임계값에 따라 로그 기록 여부가 달라짐. 프로덕션 권장값: _____초

---

### 실험 2: pt-query-digest 비교

```bash
# mysqldumpslow 결과
mysqldumpslow -s t -t 5 slow-query.log

# pt-query-digest 결과
pt-query-digest slow-query.log

# 차이점:
1.
2.
3.

# 더 유용한 도구: _____
# 이유: _____
```

---

## 9주 과정 완료 회고

### 전체 과정에서 가장 유용했던 주차 Top 3

1. **Week ___: _____**
   - 이유:
   - 실무 적용 사례:

2. **Week ___: _____**
   - 이유:
   - 실무 적용 사례:

3. **Week ___: _____**
   - 이유:
   - 실무 적용 사례:

---

### 9주 동안 배운 핵심 내용

| 주차 | 주제 | 핵심 내용 | 실무 적용 |
|------|------|-----------|----------|
| 1 | 인덱스 | | |
| 2 | EXPLAIN | | |
| 3 | 쿼리 비용 | | |
| 4 | 락/데드락 | | |
| 5 | 트랜잭션 격리 | | |
| 6 | 페이지네이션 | | |
| 7 | N+1 문제 | | |
| 8 | 커넥션 풀 | | |
| 9 | 슬로우 쿼리 | | |

---

### 실무 적용 성과

**개선한 쿼리 개수:** _____개

**총 성능 개선:**
- 평균 응답 시간: _____ms → _____ms (___% 개선)
- 서버 CPU 사용률: ____% → ____%
- DB 커넥션 수: ___개 → ___개

**경제적 효과:**
- 절감한 서버 비용: _____원/월
- 개선된 사용자 만족도: _____

---

### 다음 단계

**단기 (1개월):**
- [ ] 모든 슬로우 쿼리 개선
- [ ] 팀 지식 공유 세션
- [ ] 성능 모니터링 체계 구축

**중기 (3개월):**
- [ ] DB 최적화 가이드 문서화
- [ ] 코드 리뷰 체크리스트 작성
- [ ] 신규 기능 개발 시 성능 고려

**장기 (6개월):**
- [ ] DB 아키텍처 개선
- [ ] 샤딩/파티셔닝 검토
- [ ] 고급 최적화 기법 학습

---

## 다음 액션

### 팀 공유 계획

**발표 주제:** "9주간의 DB 최적화 여정"

**발표 내용:**
1. 배운 핵심 내용 요약
2. 실무 적용 사례 공유
3. 성능 개선 Before/After
4. 팀 적용 제안

**발표 일정:** _____

---

### 추가 학습 자료

**관심 주제:**
1.
2.
3.

**학습 계획:**
- [ ] Real MySQL 8.0 완독
- [ ] High Performance MySQL 읽기
- [ ] Percona Blog 구독
- [ ] MySQL 공식 문서 학습

---

**완료일:** ___________
**소요 시간:** ___________
**성취도:** _____ / 100

**피드백 요청:**
- [ ] Claude에게 피드백 요청 완료
- [ ] 팀 리뷰 완료
- [ ] 실무 적용 계획 공유 완료

---

## 🎉 축하합니다!

야생 DB 학습 9주 과정을 모두 완료하셨습니다!

**당신은 이제:**
- ✅ 인덱스 설계 전문가
- ✅ 쿼리 최적화 전문가
- ✅ DB 성능 튜닝 전문가
- ✅ 실전 문제 해결 능력 보유

**다음 도전:**
당신의 지식을 팀과 커뮤니티에 공유하고,
더 많은 사람들이 DB 최적화를 잘할 수 있도록 도와주세요!

**당신은 이제 DB 최적화 전문가입니다!** 🚀
