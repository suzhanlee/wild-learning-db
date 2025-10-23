# IntelliJ Database 자동 연결 설정 ✨

> `.idea/dataSources.xml` 파일로 IntelliJ에서 자동으로 데이터베이스 연결 인식!

## 🎯 자동 설정 완료!

프로젝트를 IntelliJ에서 열면 다음이 자동으로 구성됩니다:

### ✅ 이미 설정된 것들
- ✅ DataSource: "Wild Learning DB (Docker)" 추가됨
- ✅ SQL Dialect: MySQL로 설정됨
- ✅ 연결 정보: localhost:3307 자동 인식

## 🚀 IntelliJ에서 사용하기

### 1. Database Tool 열기
```
View → Tool Windows → Database
또는
Alt + 1 (왼쪽 사이드바) → Database 탭
```

### 2. 데이터 소스 확인
Database 패널에서 다음이 보일 것입니다:
```
📁 Wild Learning DB (Docker)
   ↳ (비밀번호 입력 필요)
```

### 3. 비밀번호 입력 (최초 1회만)
```
1. "Wild Learning DB (Docker)" 우클릭
2. "Properties" 선택
3. General 탭에서:
   - User: root (이미 입력됨)
   - Password: wild123!@#
   - ☑ Save password
4. Test Connection → Succeeded 확인
5. OK
```

### 4. 연결 완료!
```
📁 Wild Learning DB (Docker)
   └── 📁 wild_learning_db
       └── 📁 tables
           ├── 📄 users (1,000,000 rows)
           └── 📄 orders
```

---

## 🎨 자동 완성 & 신택스 하이라이팅

`.sql` 파일을 열면 자동으로:
- ✅ MySQL 문법 하이라이팅
- ✅ 테이블명/컬럼명 자동 완성 (Ctrl+Space)
- ✅ EXPLAIN 결과 시각화
- ✅ 쿼리 실행 시간 표시

---

## 📊 빠른 쿼리 실행

### SQL Console 열기
```
Database 패널에서 "Wild Learning DB" 우클릭
→ New → Query Console
```

### 쿼리 실행 단축키
```
Ctrl+Enter        현재 쿼리 실행
Ctrl+Shift+Enter  전체 스크립트 실행
F4                선택한 테이블 정의 보기
Alt+Insert        새 쿼리 콘솔 생성
```

---

## 🔧 연결 정보 (참고용)

수동 설정이 필요한 경우:

```yaml
Host: localhost
Port: 3307
Database: wild_learning_db
User: root
Password: wild123!@#
JDBC URL: jdbc:mysql://localhost:3307/wild_learning_db
Driver: MySQL (com.mysql.cj.jdbc.Driver)
```

---

## 💡 유용한 기능

### 1. 테이블 데이터 보기
```
users 테이블 더블클릭
→ 1,000,000 rows 자동 페이징으로 표시
```

### 2. EXPLAIN 시각화
```sql
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```
→ 결과가 트리 구조로 시각화됨

### 3. 데이터 Export
```
쿼리 결과 우클릭
→ Export Data
→ CSV, JSON, SQL 등 선택
```

### 4. SQL 파일 실행
```
week1/practice1-index-performance.sql 열기
→ Ctrl+Shift+F10 (전체 실행)
```

### 5. 스키마 다이어그램
```
Database 패널에서 wild_learning_db 우클릭
→ Diagrams → Show Diagram
→ ER 다이어그램 자동 생성!
```

---

## 🎯 Week 1 실습 시작하기

### 방법 1: SQL Console 사용
```
1. Database 패널에서 Query Console 열기
2. 쿼리 입력 및 실행 (Ctrl+Enter)
```

### 방법 2: SQL 파일 직접 실행
```
1. week1/practice1-index-performance.sql 열기
2. 파일 우클릭 → Run (또는 Ctrl+Shift+F10)
```

### 방법 3: 대화형 실행
```
1. SQL 파일에서 쿼리 하나씩 선택
2. Ctrl+Enter로 단계별 실행
3. 결과 확인하며 학습
```

---

## 🐛 문제 해결

### "Cannot connect to database" 오류
```bash
# PowerShell에서 Docker 확인
docker-compose ps

# 컨테이너가 실행 중이 아니면
scripts\start.bat
```

### 비밀번호가 저장되지 않음
```
IntelliJ Settings
→ Appearance & Behavior
→ System Settings
→ Passwords
→ "In KeePass" 또는 "In native keychain" 선택
```

### SQL 파일 문법 인식 안 됨
```
파일 우클릭
→ Associate with File Type
→ SQL (MySQL)
```

---

## ✨ Pro Tips

### 멀티 커서로 빠른 편집
```
Alt + J: 다음 동일 텍스트 선택
Ctrl + Alt + Shift + J: 모든 동일 텍스트 선택
```

### Live Templates 활용
```
sel + Tab  → SELECT * FROM
ins + Tab  → INSERT INTO
upd + Tab  → UPDATE
```

### SQL 포맷팅
```
Ctrl + Alt + L: 자동 포맷팅
```

---

## 📚 추가 자료

- IntelliJ Database Tools 공식 문서: https://www.jetbrains.com/help/idea/relational-databases.html
- MySQL 9.x 새 기능: https://dev.mysql.com/doc/relnotes/mysql/9.0/en/

---

**설정 완료!** 🎉

이제 IntelliJ에서 Database 패널을 열고 비밀번호만 입력하면 바로 사용할 수 있습니다!
