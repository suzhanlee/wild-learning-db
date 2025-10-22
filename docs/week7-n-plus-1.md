# Week 7: N+1 문제 해결 ⭐⭐

> "ORM 쿼리 지옥 탈출"

## 📋 목차
- [학습 목표](#학습-목표)
- [학습 내용](#학습-내용)
- [실습](#실습)
- [체크리스트](#체크리스트)
- [학습 노트](#학습-노트)

---

## 🎯 학습 목표

**"N+1 문제를 보는 즉시 발견하기"**

이번 주차를 완료하면:
- N+1 문제가 무엇인지 명확히 이해
- 코드 보고 N+1 발생 여부 판단
- Eager Loading으로 해결 가능
- 성능 100배 이상 개선 가능

---

## 📚 학습 내용

### 1. N+1 문제란? (15분)

#### 문제 상황
```python
# 사용자 10명 조회
users = User.objects.all()[:10]  # 1번 쿼리

# 각 사용자의 주문 조회
for user in users:
    orders = user.orders.all()  # 10번 쿼리
    print(f"{user.name}: {len(orders)} orders")

총 쿼리: 1 + 10 = 11번
N=10이면 11번, N=1000이면 1001번!
```

#### 실제 SQL
```sql
-- 1. 사용자 조회 (1번)
SELECT * FROM users LIMIT 10;

-- 2. 각 사용자의 주문 조회 (10번)
SELECT * FROM orders WHERE user_id = 1;
SELECT * FROM orders WHERE user_id = 2;
SELECT * FROM orders WHERE user_id = 3;
...
SELECT * FROM orders WHERE user_id = 10;

-- N+1 Problem!
-- N개 조회 → N+1번 쿼리
```

#### 왜 문제인가?
```
10명: 11번 쿼리 → 느림
100명: 101번 쿼리 → 매우 느림
1000명: 1001번 쿼리 → 서비스 다운!

각 쿼리마다:
- 네트워크 왕복 시간
- DB 파싱 시간
- 실행 계획 수립 시간
→ 누적되면 엄청남!
```

---

### 2. N+1 발견 방법 (15분)

#### 방법 1: ORM 쿼리 로그
```python
# Django
import logging
logging.basicConfig()
logging.getLogger('django.db.backends').setLevel(logging.DEBUG)

# 코드 실행
users = User.objects.all()[:10]
for user in users:
    print(user.orders.all())

# 로그 확인
# (0.001) SELECT * FROM users LIMIT 10
# (0.001) SELECT * FROM orders WHERE user_id = 1
# (0.001) SELECT * FROM orders WHERE user_id = 2
# ... (반복!)
```

#### 방법 2: 쿼리 카운트
```python
from django.db import connection

# 쿼리 카운트 초기화
connection.queries_log.clear()

# 코드 실행
users = User.objects.all()[:10]
for user in users:
    print(user.orders.all())

# 쿼리 개수 확인
print(f"Total queries: {len(connection.queries)}")
# Total queries: 11
```

#### 방법 3: 패턴 인식
```python
# ❌ N+1 발생 패턴
for user in users:
    user.orders.all()  # 루프 안에서 관계 접근
    user.profile.name  # 루프 안에서 관계 접근

# ❌ 템플릿에서도 발생
{% for user in users %}
    {{ user.orders.count }}  # N+1!
{% endfor %}
```

---

### 3. 해결 방법 1: Eager Loading (20분)

#### select_related (1:1, N:1)
```python
# ❌ N+1 발생
orders = Order.objects.all()[:100]
for order in orders:
    print(order.user.name)  # 100번 쿼리

# ✅ 해결: select_related (JOIN)
orders = Order.objects.select_related('user').all()[:100]
for order in orders:
    print(order.user.name)  # 1번 쿼리

# 실행되는 SQL
SELECT orders.*, users.*
FROM orders
JOIN users ON orders.user_id = users.id
LIMIT 100;
```

#### prefetch_related (1:N, M:N)
```python
# ❌ N+1 발생
users = User.objects.all()[:10]
for user in users:
    print(user.orders.all())  # 10번 쿼리

# ✅ 해결: prefetch_related (별도 쿼리 + 메모리 조인)
users = User.objects.prefetch_related('orders').all()[:10]
for user in users:
    print(user.orders.all())  # 2번 쿼리

# 실행되는 SQL
-- 1. 사용자 조회
SELECT * FROM users LIMIT 10;

-- 2. 모든 사용자의 주문 한 번에 조회
SELECT * FROM orders WHERE user_id IN (1,2,3,...,10);
```

#### select_related vs prefetch_related
```
select_related:
- 관계: 1:1, N:1 (ForeignKey, OneToOne)
- 방법: JOIN
- 쿼리: 1번
- 예: Order → User

prefetch_related:
- 관계: 1:N, M:N (ManyToMany, Reverse ForeignKey)
- 방법: IN 쿼리 + 메모리 조인
- 쿼리: 2번 (본체 + 관계)
- 예: User → Orders
```

---

### 4. 해결 방법 2: 집계 쿼리 (10분)

#### annotate로 집계
```python
# ❌ N+1 발생
users = User.objects.all()
for user in users:
    order_count = user.orders.count()  # N번 쿼리

# ✅ 해결: annotate
from django.db.models import Count

users = User.objects.annotate(
    order_count=Count('orders')
).all()

for user in users:
    print(user.order_count)  # 0번 추가 쿼리

# 실행되는 SQL
SELECT users.*, COUNT(orders.id) as order_count
FROM users
LEFT JOIN orders ON users.id = orders.user_id
GROUP BY users.id;
```

---

### 5. 해결 방법 3: 배치 로딩 (10분)

#### 수동 IN 쿼리
```python
# 사용자 조회
users = User.objects.all()[:100]

# 모든 사용자 ID 수집
user_ids = [user.id for user in users]

# 주문 한 번에 조회
orders = Order.objects.filter(user_id__in=user_ids)

# 메모리에서 매핑
orders_by_user = {}
for order in orders:
    if order.user_id not in orders_by_user:
        orders_by_user[order.user_id] = []
    orders_by_user[order.user_id].append(order)

# 사용
for user in users:
    user_orders = orders_by_user.get(user.id, [])
    print(f"{user.name}: {len(user_orders)} orders")
```

---

## 🔬 실습

### 실습 1: N+1 재현 및 측정 (20분)

```python
# 모델 (Django)
class User(models.Model):
    name = models.CharField(max_length=100)
    email = models.CharField(max_length=255)

class Order(models.Model):
    user = models.ForeignKey(User, related_name='orders')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

# 테스트 데이터: 사용자 100명, 주문 10000건

# 테스트 1: N+1 발생
import time
from django.db import connection, reset_queries

reset_queries()
start = time.time()

users = User.objects.all()[:100]
for user in users:
    orders = list(user.orders.all())

elapsed = time.time() - start
query_count = len(connection.queries)

print(f"N+1 방식")
print(f"  시간: {elapsed:.3f}초")
print(f"  쿼리: {query_count}개")

# 결과 기록
# 시간: _____초
# 쿼리: _____개

# 테스트 2: prefetch_related
reset_queries()
start = time.time()

users = User.objects.prefetch_related('orders').all()[:100]
for user in users:
    orders = list(user.orders.all())

elapsed = time.time() - start
query_count = len(connection.queries)

print(f"prefetch_related 방식")
print(f"  시간: {elapsed:.3f}초")
print(f"  쿼리: {query_count}개")

# 결과 기록
# 시간: _____초
# 쿼리: _____개
```

#### 성능 비교
| 방식 | 시간 | 쿼리 수 | 개선율 |
|------|------|---------|--------|
| N+1 | | 101 | - |
| prefetch_related | | 2 | % |

---

### 실습 2: 중첩 N+1 해결 (20분)

```python
# 사용자 → 주문 → 상품 (3단계 관계)

# ❌ N+1 발생 (매우 심각!)
users = User.objects.all()[:10]
for user in users:
    for order in user.orders.all():  # 10번
        for item in order.items.all():  # 100번?
            print(item.product.name)  # 1000번???

# 쿼리: 1 + 10 + 100 + 1000 = 1111번!

# ✅ 해결
users = User.objects.prefetch_related(
    'orders__items__product'  # 중첩 prefetch
).all()[:10]

for user in users:
    for order in user.orders.all():
        for item in order.items.all():
            print(item.product.name)

# 쿼리: 4번!
# 1. users
# 2. orders
# 3. items
# 4. products

# 실행 시간 측정
# Before: _____초
# After: _____초
# 개선율: _____%
```

---

### 실습 3: 회사 코드 개선 (20분)

```python
# 회사 코드에서 N+1 패턴 찾기

# 발견한 코드 1
# 파일: _________________
# 라인: _________________

# Before
[코드 붙여넣기]

# 쿼리 수: _____
# 실행 시간: _____ms

# After
[개선된 코드]

# 쿼리 수: _____
# 실행 시간: _____ms
# 개선율: _____%

# 발견한 코드 2-3 반복
```

---

## ✅ 체크리스트

### 이론 학습
- [ ] N+1 문제 정의 이해
- [ ] select_related vs prefetch_related 차이 숙지
- [ ] N+1 발생 패턴 인식 (루프 안 관계 접근)
- [ ] 해결 방법 3가지 학습

### 실습 완료
- [ ] N+1 재현 및 성능 측정
- [ ] prefetch_related로 해결
- [ ] 중첩 N+1 해결
- [ ] 회사 코드 3곳 이상 개선

### 실무 적용
- [ ] ORM 쿼리 로깅 활성화
- [ ] 주요 API N+1 점검
- [ ] 코드 리뷰 시 N+1 체크
- [ ] 팀원과 N+1 지식 공유

---

## 📝 학습 노트

### N+1 체크리스트
```python
# ❌ 위험 패턴
for obj in queryset:
    obj.related.all()  # N+1!
    obj.related.count()  # N+1!
    obj.foreignkey.field  # N+1!

# ✅ 안전 패턴
queryset.prefetch_related('related')
queryset.select_related('foreignkey')
queryset.annotate(count=Count('related'))
```

### 실무 적용 사례

**개선한 API:**
- 엔드포인트: _____
- Before:
  - 쿼리: _____개
  - 시간: _____ms
- After:
  - 쿼리: _____개
  - 시간: _____ms
- 개선율: _____%

---

## 📚 참고 자료

- Django 공식 문서: [select_related](https://docs.djangoproject.com/en/stable/ref/models/querysets/#select-related)
- Django 공식 문서: [prefetch_related](https://docs.djangoproject.com/en/stable/ref/models/querysets/#prefetch-related)
- [Bullet points on N+1 queries](https://stackoverflow.com/questions/97197/what-is-the-n1-selects-problem-in-orm-object-relational-mapping)

---

**학습 시간**: 60분 야생학습
**난이도**: ⭐⭐ 중
**즉시 적용**: ✓
**ROI**: 높음

**완료일**: ___________
