# Week 1: 인덱스 핵심 원리 - 실습 가이드

## 🎯 실습 목표

인덱스의 동작 원리를 직접 체험하고, 성능 차이를 측정하여 인덱스의 중요성을 이해합니다.

## 📁 파일 구조

```
week1/
├── README.md                           # 실습 가이드 (이 파일)
├── setup.sql                           # 환경 설정
├── practice1-index-performance.sql     # 실습 1: 인덱스 성능 비교
├── practice2-composite-index.sql       # 실습 2: 복합 인덱스 순서
└── practice3-anti-patterns.sql         # 실습 3: 안티패턴 발견
```

## 🚀 실습 진행 방법

### 사전 준비

1. MySQL 8.0 이상 설치 확인
2. MySQL 클라이언트 또는 워크벤치 실행
3. 충분한 디스크 공간 확보 (최소 2GB)

### 실습 1: 인덱스 성능 비교 (30분)

**목표**: 인덱스가 있을 때와 없을 때의 성능 차이를 직접 측정

```bash
# MySQL 접속
mysql -u root -p

# SQL 파일 실행
source C:/Users/USER/IdeaProjects/wild-learning-db/week1/setup.sql
source C:/Users/USER/IdeaProjects/wild-learning-db/week1/practice1-index-performance.sql
```

**예상 결과**:
- 인덱스 없음: 100-500ms (Full Scan)
- 인덱스 있음: 1-10ms (Index Scan)
- 성능 개선: 약 50-100배

**핵심 포인트**:
- `EXPLAIN`의 `type` 컬럼: `ALL` → `ref` 변화 확인
- `rows` 컬럼: 1,000,000 → 1 변화 확인
- 실행 시간의 극적인 차이 체감

### 실습 2: 복합 인덱스 순서 (30분)

**목표**: 복합 인덱스의 순서가 성능에 미치는 영향 이해

```bash
# SQL 파일 실행
source C:/Users/USER/IdeaProjects/wild-learning-db/week1/practice2-composite-index.sql
```

**예상 결과**:

| 인덱스 | 실행시간 | 비고 |
|--------|---------|------|
| 없음 | 200-800ms | Full Scan + filesort |
| 잘못된 순서 | 50-200ms | 부분 인덱스 사용 |
| 올바른 순서 | 1-10ms | 완전한 인덱스 사용 |

**핵심 포인트**:
- 복합 인덱스는 **왼쪽부터 순차적**으로 사용됨
- 동등 조건(=)을 범위 조건(<, >) 앞에 배치
- Cardinality가 높은 컬럼을 앞에 배치

### 실습 3: 안티패턴 발견 (30분)

**목표**: 인덱스를 무효화하는 쿼리 패턴 식별 및 개선

```bash
# SQL 파일 실행
source C:/Users/USER/IdeaProjects/wild-learning-db/week1/practice3-anti-patterns.sql
```

**점검 항목**:
- [ ] WHERE 절에 함수 사용
- [ ] 앞부분 와일드카드 (%keyword)
- [ ] 서로 다른 컬럼의 OR 조건
- [ ] NOT, != 연산자
- [ ] 타입 불일치
- [ ] 복합 인덱스 순서 무시

## 📊 실습 결과 기록

### 실습 1 결과

```
| 상황 | 실행시간 | rows 검사 | type | 비고 |
|------|---------|-----------|------|------|
| 인덱스 없음 |  |  |  |  |
| 인덱스 있음 |  |  |  |  |

성능 개선:  배
```

### 실습 2 결과

```
| 인덱스 | 실행시간 | type | key | Extra |
|--------|---------|------|-----|-------|
| 없음 |  |  |  |  |
| 잘못된 순서 |  |  |  |  |
| 올바른 순서 |  |  |  |  |
```

### 실습 3 발견 사항

```
안티패턴 발견:
1. 패턴:
   개선:

2. 패턴:
   개선:

3. 패턴:
   개선:
```

## 🎓 학습 정리

### 핵심 개념 3가지

1. **B-Tree 구조**
   - 균형 잡힌 트리로 O(log N) 시간 복잡도
   - Full Scan보다 수백~수천 배 빠름

2. **복합 인덱스 순서**
   - (동등조건, 동등조건, 정렬조건) 순서
   - Cardinality 높은 것 우선

3. **안티패턴 회피**
   - WHERE 절에 함수 사용 금지
   - 앞부분 와일드카드 금지
   - 타입 일치 필수

### 실무 적용 체크리스트

- [ ] 주요 테이블의 WHERE 절 분석
- [ ] 자주 사용되는 조회 쿼리 식별
- [ ] 복합 인덱스 순서 검토
- [ ] 안티패턴 쿼리 발견 및 개선
- [ ] EXPLAIN으로 실행 계획 검증

## 🔍 트러블슈팅

### 문제 1: 데이터 삽입이 너무 느림
**해결**: 100만 건 대신 10만 건으로 테스트 (프로시저 수정)

### 문제 2: 메모리 부족 에러
**해결**: MySQL 설정에서 innodb_buffer_pool_size 증가

### 문제 3: 인덱스를 만들었는데도 사용하지 않음
**해결**:
- ANALYZE TABLE 실행
- FORCE INDEX 힌트 사용
- 통계 정보 확인

## 📚 추가 학습 자료

- [MySQL 공식 문서 - Optimization and Indexes](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)
- [Use The Index, Luke!](https://use-the-index-luke.com/)
- Real MySQL 8.0 - 8장 인덱스

## ✅ 완료 체크리스트

- [ ] 실습 1 완료 및 결과 기록
- [ ] 실습 2 완료 및 결과 기록
- [ ] 실습 3 완료 및 안티패턴 발견
- [ ] 학습 노트 작성
- [ ] 실무 적용 계획 수립

---

**완료일**: __________
**소요 시간**: __________
**체감 난이도**: ⭐⭐⭐⭐⭐ (5점 만점)
