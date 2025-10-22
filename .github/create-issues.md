# GitHub Issues 생성 가이드

각 주차별로 아래 이슈를 생성하세요.

## Week 1: 인덱스 핵심 원리

```markdown
Title: [Week1] 인덱스 핵심 원리 학습
Labels: learning, week1, priority-high
Assignee: @yourself

## 📚 학습 목표
**"인덱스 보고 3초 안에 판단하기"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] B-Tree 구조 이해
- [ ] 인덱스 생성 기준 숙지 (Cardinality, WHERE/JOIN 조건)
- [ ] 복합 인덱스 순서 규칙 이해 (동등 조건 우선, ORDER BY 마지막)
- [ ] 안티패턴 암기 (함수 사용, 앞부분 와일드카드, OR 조건, NOT/!=, 타입 불일치)

### 실습 완료 (30분)
- [ ] 인덱스 있을 때 vs 없을 때 성능 비교 (100만 건)
- [ ] 복합 인덱스 순서 테스트 (올바른 순서 vs 잘못된 순서)
- [ ] 회사 코드에서 안티패턴 발견 (최소 3개)
- [ ] 개선 쿼리 작성 및 성능 측정

### 실무 적용
- [ ] 회사 주요 테이블 인덱스 검토
- [ ] 느린 쿼리 1개 이상 개선
- [ ] Before/After 성능 비교 문서화
- [ ] 팀원과 인덱스 전략 공유

## 📝 학습 노트

### 배운 핵심 3가지
1.
2.
3.

### 성능 개선 결과
- 개선한 쿼리:
- Before: ___ms, ___행 검사
- After: ___ms, ___행 검사
- 개선율: ___%

### 트러블슈팅
**문제:**

**해결:**

## 🔗 관련 링크
- 문서: [docs/week1-index-basics.md](../docs/week1-index-basics.md)
- Branch: `feature/week1-index-basics`

## 📅 완료 정보
- 예상 시간: 60분
- 실제 시간:
- 완료일:
```

---

## Week 2: EXPLAIN 실전 분석

```markdown
Title: [Week2] EXPLAIN 실전 분석 학습
Labels: learning, week2, priority-high

## 📚 학습 목표
**"EXPLAIN 보고 3초 안에 문제 발견"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] type 해석 (const > eq_ref > ref > range > index > ALL)
- [ ] rows 판단 기준 (100 이하 좋음, 10000+ 문제)
- [ ] Extra 해석 (Using index 좋음, Using filesort/temporary 나쁨)
- [ ] 실전 패턴 인식 (풀스캔, 인덱스 미사용, 정렬 문제)

### 실습 완료 (30분)
- [ ] type별 성능 실험 (const, ref, range, index, ALL)
- [ ] 회사 코드 쿼리 10개 EXPLAIN 분석
- [ ] 문제 있는 쿼리 3개 개선
- [ ] Before/After EXPLAIN 비교

### 실무 적용
- [ ] 주요 API 쿼리 EXPLAIN 검토
- [ ] type=ALL 쿼리 찾아서 개선
- [ ] rows 큰 쿼리 최적화
- [ ] 팀 코드 리뷰 시 EXPLAIN 확인 습관화

## 📝 학습 노트

### type별 성능 비교
| type | rows | 실행시간 | 비고 |
|------|------|---------|------|
| const | | | |
| ref | | | |
| range | | | |
| ALL | | | |

### 개선 사례
**쿼리 1:**
- Before: type=___, rows=___, Extra=___
- After: type=___, rows=___, Extra=___
- 개선율: ___%

## 🔗 관련 링크
- 문서: [docs/week2-explain-analysis.md](../docs/week2-explain-analysis.md)
- Branch: `feature/week2-explain-analysis`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 3: 쿼리 성능 비용 감각

```markdown
Title: [Week3] 쿼리 성능 비용 감각 학습
Labels: learning, week3, priority-high

## 📚 학습 목표
**"쿼리 보고 느릴지 예측"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] WHERE 비용 (O(1), O(log N), O(N))
- [ ] JOIN 비용 (Nested Loop, 인덱스 유무에 따른 차이)
- [ ] ORDER BY 비용 (인덱스 사용 여부)
- [ ] 서브쿼리 vs JOIN 비용

### 실습 완료 (30분)
- [ ] WHERE 비용 실험 (5가지 케이스)
- [ ] JOIN 비용 비교 (인덱스 없음/있음/WHERE 필터)
- [ ] 회사 쿼리 3개 비용 분석
- [ ] 개선 전후 성능 측정

### 실무 적용
- [ ] 코드 리뷰 시 쿼리 비용 체크
- [ ] 신규 쿼리 작성 시 비용 예측
- [ ] 느린 API 쿼리 비용 분석
- [ ] 최적화 우선순위 문서화

## 📝 학습 노트

### 비용 분석 사례
**쿼리:**
```sql
[쿼리]
```

**비용 계산:**
- WHERE: O(___)
- JOIN: O(___)
- ORDER BY: O(___)
- 총 예상: O(___)
- 실제 시간: ___ms

## 🔗 관련 링크
- 문서: [docs/week3-query-cost.md](../docs/week3-query-cost.md)
- Branch: `feature/week3-query-cost`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 4: 락과 데드락 처리

```markdown
Title: [Week4] 락과 데드락 처리 학습
Labels: learning, week4, priority-medium

## 📚 학습 목표
**"데드락 발생 시 당황하지 않고 해결하기"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] Shared Lock vs Exclusive Lock
- [ ] 데드락 발생 조건
- [ ] 데드락 로그 읽는 법
- [ ] 낙관적 락 vs 비관적 락 비교

### 실습 완료 (30분)
- [ ] 데드락 재현 실험
- [ ] 데드락 로그 분석
- [ ] 데드락 해결 방법 3가지 테스트
- [ ] 낙관적/비관적 락 성능 비교

### 실무 적용
- [ ] 데드락 발생 시 대응 프로세스 정리
- [ ] 동시성 제어 전략 수립
- [ ] 재고 관리 등 핵심 로직 락 전략 검토

## 📝 학습 노트

### 데드락 대응 체크리스트
1. [ ] 로그 확인
2. [ ] 충돌 테이블/쿼리 파악
3. [ ] 락 순서 확인
4. [ ] 해결 방법 적용
5. [ ] 재발 방지 문서화

## 🔗 관련 링크
- 문서: [docs/week4-lock-deadlock.md](../docs/week4-lock-deadlock.md)
- Branch: `feature/week4-lock-deadlock`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 5: 트랜잭션 격리 수준

```markdown
Title: [Week5] 트랜잭션 격리 수준 학습
Labels: learning, week5, priority-medium

## 📚 학습 목표
**"격리 수준을 상황에 맞게 선택하기"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] 4가지 격리 수준 (READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE)
- [ ] Dirty Read, Non-Repeatable Read, Phantom Read
- [ ] MySQL vs PostgreSQL 기본 격리 수준
- [ ] 각 격리 수준의 사용 사례

### 실습 완료 (30분)
- [ ] Dirty Read 재현
- [ ] Non-Repeatable Read 재현
- [ ] Phantom Read 테스트
- [ ] 격리 수준별 성능 비교

### 실무 적용
- [ ] 현재 서비스의 격리 수준 확인
- [ ] 격리 수준 관련 버그 검토
- [ ] 필요 시 격리 수준 변경 고려

## 📝 학습 노트

### 격리 수준 선택 가이드
| 상황 | 권장 격리 수준 | 이유 |
|------|---------------|------|
| 일반 웹 서비스 | READ COMMITTED | 성능/동시성 균형 |
| 금융 거래 | REPEATABLE READ | 일관성 중요 |

## 🔗 관련 링크
- 문서: [docs/week5-transaction-isolation.md](../docs/week5-transaction-isolation.md)
- Branch: `feature/week5-transaction-isolation`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 6: 페이지네이션 최적화

```markdown
Title: [Week6] 페이지네이션 최적화 학습
Labels: learning, week6, priority-high

## 📚 학습 목표
**"Offset 지옥 탈출"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] Offset 방식의 문제점 (성능, 중복/누락)
- [ ] Cursor 방식 원리
- [ ] Row Value Comparison 문법
- [ ] Cursor vs Offset 사용 사례 구분

### 실습 완료 (30분)
- [ ] Offset vs Cursor 성능 비교 (1, 100, 1000, 10000 페이지)
- [ ] Cursor 페이지네이션 구현
- [ ] 복합 인덱스 생성 및 검증
- [ ] 회사 코드 개선 (있다면)

### 실무 적용
- [ ] 무한 스크롤 API를 Cursor 방식으로 전환
- [ ] 적절한 인덱스 추가
- [ ] API 문서 업데이트
- [ ] 프론트엔드와 협업

## 📝 학습 노트

### 성능 비교
| 페이지 | Offset | Cursor | 개선율 |
|--------|--------|--------|--------|
| 1 | | | |
| 100 | | | |
| 1000 | | | |
| 10000 | | | |

## 🔗 관련 링크
- 문서: [docs/week6-pagination.md](../docs/week6-pagination.md)
- Branch: `feature/week6-pagination`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 7: N+1 문제 해결

```markdown
Title: [Week7] N+1 문제 해결 학습
Labels: learning, week7, priority-high

## 📚 학습 목표
**"N+1 문제를 보는 즉시 발견하기"**

## ✅ 체크리스트

### 이론 학습 (30분)
- [ ] N+1 문제 정의
- [ ] select_related vs prefetch_related 차이
- [ ] N+1 발생 패턴 인식
- [ ] 해결 방법 3가지 (Eager Loading, 집계 쿼리, 배치 로딩)

### 실습 완료 (30분)
- [ ] N+1 재현 및 성능 측정 (100명)
- [ ] prefetch_related로 해결
- [ ] 중첩 N+1 해결 (3단계 관계)
- [ ] 회사 코드 3곳 이상 개선

### 실무 적용
- [ ] ORM 쿼리 로깅 활성화
- [ ] 주요 API N+1 점검
- [ ] 코드 리뷰 시 N+1 체크
- [ ] 팀원과 N+1 지식 공유

## 📝 학습 노트

### 성능 개선 결과
- N+1 방식: ___ 쿼리, ___초
- 개선 방식: ___ 쿼리, ___초
- 개선율: ___%

## 🔗 관련 링크
- 문서: [docs/week7-n-plus-1.md](../docs/week7-n-plus-1.md)
- Branch: `feature/week7-n-plus-1`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:
```

---

## Week 8: 커넥션 풀 관리

```markdown
Title: [Week8] 커넥션 풀 관리 학습
Labels: learning, week8, priority-medium

## 📚 학습 목표
**"커넥션 부족으로 서비스 다운 방지하기"**

## ✅ 체크리스트

### 이론 학습 (25분)
- [ ] 커넥션 풀 동작 원리
- [ ] HikariCP 주요 설정 (maximum-pool-size, connection-timeout)
- [ ] 적정 풀 사이즈 계산 방법
- [ ] 커넥션 누수 패턴

### 실습 완료 (20분)
- [ ] 커넥션 고갈 재현
- [ ] 풀 사이즈 튜닝 실험 (5, 10, 20, 50)
- [ ] 모니터링 대시보드 구축
- [ ] 알람 임계값 설정

### 실무 적용
- [ ] 현재 서비스 커넥션 풀 설정 검토
- [ ] 모니터링 시스템 구축
- [ ] 커넥션 누수 코드 패턴 점검
- [ ] 장애 대응 매뉴얼 작성

## 📝 학습 노트

### 적정 풀 사이즈 결정
- 테스트 결과: ___
- 선택한 값: ___
- 이유: ___

## 🔗 관련 링크
- 문서: [docs/week8-connection-pool.md](../docs/week8-connection-pool.md)
- Branch: `feature/week8-connection-pool`

## 📅 완료 정보
- 예상 시간: 45분
- 완료일:
```

---

## Week 9: 슬로우 쿼리 로그

```markdown
Title: [Week9] 슬로우 쿼리 로그 분석 학습
Labels: learning, week9, priority-medium

## 📚 학습 목표
**"진짜 병목을 데이터로 찾기"**

## ✅ 체크리스트

### 이론 학습 (20분)
- [ ] 슬로우 쿼리 로그 개념
- [ ] 주요 설정 파라미터
- [ ] 로그 필드 해석 (Query_time, Rows_examined, Rows_sent)
- [ ] 우선순위 판단 기준

### 실습 완료 (40분)
- [ ] 슬로우 쿼리 로그 활성화
- [ ] mysqldumpslow로 분석
- [ ] Top 3 느린 쿼리 개선
- [ ] 자동화 스크립트 작성

### 실무 적용
- [ ] 프로덕션 슬로우 쿼리 로그 활성화
- [ ] 주간 리포트 자동화
- [ ] 개선 작업 진행 (Top 5)
- [ ] 모니터링 대시보드 연동

## 📝 학습 노트

### 개선 우선순위
| 순위 | 쿼리 | 횟수 | 평균시간 | 누적시간 | 점수 |
|------|------|------|---------|---------|------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

### 총 개선 효과
- 개선한 쿼리: ___개
- 절감 시간: ___초/일
- 응답 시간 개선: ___%

## 🔗 관련 링크
- 문서: [docs/week9-slow-query-log.md](../docs/week9-slow-query-log.md)
- Branch: `feature/week9-slow-query-log`

## 📅 완료 정보
- 예상 시간: 60분
- 완료일:

---

## 🎉 축하합니다!
9주 과정을 모두 완료하셨습니다!
```

---

## 이슈 생성 방법

### GitHub UI 사용
1. Repository의 Issues 탭으로 이동
2. "New Issue" 클릭
3. 위의 템플릿 내용 복사 & 붙여넣기
4. Labels 추가 (learning, weekN)
5. Assignee 설정
6. "Create Issue" 클릭

### GitHub CLI 사용 (gh)
```bash
# Week 1 이슈 생성 예시
gh issue create \
  --title "[Week1] 인덱스 핵심 원리 학습" \
  --body-file week1-issue.md \
  --label "learning,week1,priority-high" \
  --assignee "@me"

# 나머지 주차도 동일하게 생성
```

### 자동화 스크립트
각 주차별 이슈를 한 번에 생성하려면 위의 명령어를 스크립트로 만들어 실행하세요.

---

**주의사항:**
- 각 이슈는 해당 주차 학습을 시작할 때 생성하는 것을 권장합니다.
- 학습 진행 중 체크리스트를 업데이트하세요.
- 완료 후 이슈를 Close하고, PR과 연결하세요.
