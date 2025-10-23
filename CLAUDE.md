# 야생 DB 학습 로드맵 🚀

> "실무에서 바로 써먹는 DB 최적화 9주 과정"

## 📋 목차

- [빠른 시작](#빠른-시작)
- [학습 원칙](#학습-원칙)
- [전체 로드맵](#전체-로드맵)
- [주차별 학습 가이드](#주차별-학습-가이드)
- [브랜치 관리 전략](#브랜치-관리-전략)
- [체크리스트](#체크리스트)

---

## 🚀 빠른 시작

### Docker로 실습 환경 구축 (5분)

```bash
# 1. Docker Desktop 실행 확인

# 2. 프로젝트 루트에서 스크립트 실행
scripts\start.bat

# 3. MySQL 접속
scripts\connect.bat
```

**상세 가이드**: [DOCKER_GUIDE.md](./DOCKER_GUIDE.md)

**생성되는 데이터**:
- users 테이블: 1,000,000 건
- orders 테이블: 1,000,000 건
- MySQL 9.x (최신 버전)
- phpMyAdmin 포함 (http://localhost:8080)

---

## 🎯 학습 원칙

### 야생학습 3원칙
1. **즉시 적용 가능한 것만** - 당장 실무에서 쓸 수 있어야 함
2. **ROI가 높은 것부터** - 투자 시간 대비 효과가 큰 것 우선
3. **문제 해결 중심** - 이론보다 실전 문제 해결

### 학습 시간
- 주당 1시간 야생학습
- 실무 적용 시간 별도
- 총 9주 과정

---

## 🗺️ 전체 로드맵

| 주차 | 주제 | 난이도 | 즉시적용 | ROI | 완료 |
|------|------|--------|----------|-----|------|
| Week 1 | [인덱스 핵심 원리](./docs/week1-index-basics.md) | ⭐⭐ | ✓ | 매우높음 | ⬜ |
| Week 2 | [EXPLAIN 실전 분석](./docs/week2-explain-analysis.md) | ⭐⭐⭐ | ✓ | 매우높음 | ⬜ |
| Week 3 | [쿼리 성능 비용 감각](./docs/week3-query-cost.md) | ⭐⭐⭐ | ✓ | 매우높음 | ⬜ |
| Week 4 | [락과 데드락 처리](./docs/week4-lock-deadlock.md) | ⭐⭐⭐ | 상황발생시 | 높음 | ⬜ |
| Week 5 | [트랜잭션 격리 수준](./docs/week5-transaction-isolation.md) | ⭐⭐⭐ | △ | 중간 | ⬜ |
| Week 6 | [페이지네이션 최적화](./docs/week6-pagination.md) | ⭐⭐⭐ | ✓ | 높음 | ⬜ |
| Week 7 | [N+1 문제 해결](./docs/week7-n-plus-1.md) | ⭐⭐ | ✓ | 높음 | ⬜ |
| Week 8 | [커넥션 풀 관리](./docs/week8-connection-pool.md) | ⭐⭐ | ✓ | 높음 | ⬜ |
| Week 9 | [슬로우 쿼리 로그](./docs/week9-slow-query-log.md) | ⭐⭐ | ✓ | 중간 | ⬜ |

---

## 📚 주차별 학습 가이드

각 주차별 상세 학습 내용은 개별 문서를 참고하세요:

1. **[Week 1: 인덱스 핵심 원리](./docs/week1-index-basics.md)** - B-Tree 구조와 실전 인덱스 전략
2. **[Week 2: EXPLAIN 실전 분석](./docs/week2-explain-analysis.md)** - 쿼리 실행 계획 읽기와 문제 발견
3. **[Week 3: 쿼리 성능 비용 감각](./docs/week3-query-cost.md)** - 느린 쿼리 예측과 최적화
4. **[Week 4: 락과 데드락 처리](./docs/week4-lock-deadlock.md)** - 동시성 제어와 데드락 해결
5. **[Week 5: 트랜잭션 격리 수준](./docs/week5-transaction-isolation.md)** - 격리 수준별 문제와 해결
6. **[Week 6: 페이지네이션 최적화](./docs/week6-pagination.md)** - Offset 지옥 탈출 전략
7. **[Week 7: N+1 문제 해결](./docs/week7-n-plus-1.md)** - ORM 최적화와 쿼리 개선
8. **[Week 8: 커넥션 풀 관리](./docs/week8-connection-pool.md)** - 안정적인 DB 연결 관리
9. **[Week 9: 슬로우 쿼리 로그](./docs/week9-slow-query-log.md)** - 병목 찾기와 모니터링

---

## 🌿 브랜치 관리 전략

### 브랜치 구조
```
main
├── feature/week1-index-basics
├── feature/week2-explain-analysis
├── feature/week3-query-cost
├── feature/week4-lock-deadlock
├── feature/week5-transaction-isolation
├── feature/week6-pagination
├── feature/week7-n-plus-1
├── feature/week8-connection-pool
└── feature/week9-slow-query-log
```

### 작업 흐름
1. 각 주차별로 `feature/weekN-topic` 브랜치 생성
2. 해당 주차 학습 내용 실습 및 코드 작성
3. 체크리스트 완료 후 PR 생성
4. 리뷰 후 main에 머지

### 커밋 메시지 규칙
```
feat(weekN): 주제 - 상세 내용

예시:
feat(week1): 인덱스 - B-Tree 구조 학습 및 실습 완료
feat(week2): EXPLAIN - type별 성능 분석 실습
docs(week3): 쿼리 비용 계산 예제 추가
```

---

## ✅ 체크리스트

### 전체 진행률
- [ ] Week 1: 인덱스 핵심 원리
- [ ] Week 2: EXPLAIN 실전 분석
- [ ] Week 3: 쿼리 성능 비용 감각
- [ ] Week 4: 락과 데드락 처리
- [ ] Week 5: 트랜잭션 격리 수준
- [ ] Week 6: 페이지네이션 최적화
- [ ] Week 7: N+1 문제 해결
- [ ] Week 8: 커넥션 풀 관리
- [ ] Week 9: 슬로우 쿼리 로그

### 학습 완료 기준
각 주차는 다음을 모두 완료해야 합니다:
- [ ] 이론 학습 (30분)
- [ ] 실습 완료 (30분)
- [ ] 실무 적용 (상황별)
- [ ] 체크리스트 완료
- [ ] 학습 노트 작성
- [ ] 코드 예제 작성

---

## 📝 학습 노트

각 주차별 학습 후 다음을 기록하세요:

### 배운 점
- 핵심 개념
- 실무 적용 포인트
- 주의사항

### 실습 결과
- Before/After 비교
- 성능 개선 수치
- 트러블슈팅 경험

### 다음 액션
- 실무에 적용할 부분
- 추가 학습 필요 사항
- 팀 공유 내용

---

## 🎓 참고 자료

### 추천 도서
- Real MySQL 8.0
- High Performance MySQL

### 온라인 리소스
- MySQL 공식 문서
- Use The Index, Luke!
- Percona Blog

---

## 🤝 기여하기

학습하면서 발견한 좋은 팁이나 개선사항이 있다면:
1. 이슈 생성
2. 개선 내용 PR
3. 학습 노트 공유

---

## 📞 문의

- GitHub Issues로 질문 및 토론
- 학습 관련 피드백 환영

---

**시작일**: 2025-10-22
**목표 완료일**: 2025-12-24 (9주 후)
**현재 진행**: Week 0 - 준비 단계

---

> "DB 최적화는 마법이 아니라 기본기입니다. 차근차근 실전 경험을 쌓아가세요!" 🚀
