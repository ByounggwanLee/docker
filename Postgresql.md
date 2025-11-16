# PostgreSQL Database 생성 절차

## axcore 데이터베이스 구성 정보

- **Database Name**: axcore
- **계정(User)**: axcore
- **비밀번호**: axcore2025!
- **Tablespace**: axcore_space
- **Encoding**: UTF8

## 생성 절차

### 1. PostgreSQL 컨테이너 접속

```cmd
docker exec -it <container_name> psql -U postgres
```

또는 직접 bash 접속:

```cmd
docker exec -it <container_name> bash
psql -U postgres
```

### 2. Tablespace 디렉토리 생성 (컨테이너 내부)

먼저 PostgreSQL 컨테이너의 bash에 접속:

```cmd
docker exec -it <container_name> bash
```

디렉토리 생성 및 권한 설정:

```bash
# tablespace용 디렉토리 생성
# PostgreSQL 18+ 버전에서는 /var/lib/postgresql/data 대신 버전별 디렉토리 사용
mkdir -p /var/lib/postgresql/tablespaces/axcore_space

# postgres 사용자에게 소유권 부여
chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space

# 권한 설정
chmod 700 /var/lib/postgresql/tablespaces/axcore_space
```

### 3. PostgreSQL 접속 (postgres 유저로)

```bash
psql -U postgres
```

### 4. Tablespace 생성

```sql
-- axcore_space tablespace 생성
-- PostgreSQL 18+ 버전 호환 경로 사용
CREATE TABLESPACE axcore_space
  OWNER postgres
  LOCATION '/var/lib/postgresql/tablespaces/axcore_space';

-- tablespace 확인
\db
```

### 5. 사용자(Role) 생성

```sql
-- axcore 사용자 생성
CREATE USER axcore WITH
  LOGIN
  PASSWORD 'axcore2025!'
  CREATEDB
  VALID UNTIL 'infinity';

-- 사용자 확인
\du
```

### 6. 데이터베이스 생성

```sql
-- axcore 데이터베이스 생성
CREATE DATABASE axcore
  WITH
  OWNER = axcore
  ENCODING = 'UTF8'
  TABLESPACE = axcore_space
  LC_COLLATE = 'en_US.utf8'
  LC_CTYPE = 'en_US.utf8'
  CONNECTION LIMIT = -1
  TEMPLATE template0;

-- 데이터베이스 목록 확인
\l
```

### 7. 권한 부여

```sql
-- axcore 데이터베이스의 모든 권한을 axcore 사용자에게 부여
GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;

-- tablespace 권한 부여
GRANT CREATE ON TABLESPACE axcore_space TO axcore;

-- public 스키마 권한 부여
\c axcore
GRANT ALL ON SCHEMA public TO axcore;
```

### 8. 연결 테스트

PostgreSQL에서 나간 후 axcore 사용자로 접속:

```sql
-- 현재 세션 종료
\q
```

```bash
# axcore 사용자로 데이터베이스 접속
psql -U axcore -d axcore
```

또는 Docker 컨테이너 외부에서:

```cmd
docker exec -it <container_name> psql -U axcore -d axcore
```

### 9. 확인 명령어

axcore 데이터베이스에 접속한 상태에서:

```sql
-- 현재 데이터베이스 확인
SELECT current_database();

-- 현재 사용자 확인
SELECT current_user;

-- 데이터베이스 인코딩 확인
SHOW SERVER_ENCODING;

-- 데이터베이스 상세 정보
\l+ axcore

-- 테이블스페이스 확인
\db+

-- 현재 데이터베이스의 테이블스페이스 확인
SELECT
  datname AS database_name,
  spcname AS tablespace_name
FROM pg_database
JOIN pg_tablespace ON pg_database.dattablespace = pg_tablespace.oid
WHERE datname = 'axcore';
```

## 전체 스크립트 (한번에 실행)

### 방법 1: SQL 파일 생성 및 실행

`init_axcore.sql` 파일 생성:

```sql
-- Tablespace 생성
-- PostgreSQL 18+ 버전 호환 경로
CREATE TABLESPACE axcore_space
  OWNER postgres
  LOCATION '/var/lib/postgresql/tablespaces/axcore_space';

-- 사용자 생성
CREATE USER axcore WITH
  LOGIN
  PASSWORD 'axcore2025!'
  CREATEDB
  VALID UNTIL 'infinity';

-- 데이터베이스 생성
CREATE DATABASE axcore
  WITH
  OWNER = axcore
  ENCODING = 'UTF8'
  TABLESPACE = axcore_space
  LC_COLLATE = 'en_US.utf8'
  LC_CTYPE = 'en_US.utf8'
  CONNECTION LIMIT = -1
  TEMPLATE template0;

-- 권한 부여
GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;
GRANT CREATE ON TABLESPACE axcore_space TO axcore;
```

파일을 컨테이너로 복사 및 실행:

```cmd
REM SQL 파일을 컨테이너로 복사
docker cp init_axcore.sql <container_name>:/tmp/init_axcore.sql

REM tablespace 디렉토리 생성 (PostgreSQL 18+ 호환 경로)
docker exec <container_name> mkdir -p /var/lib/postgresql/tablespaces/axcore_space
docker exec <container_name> chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
docker exec <container_name> chmod 700 /var/lib/postgresql/tablespaces/axcore_space

REM SQL 파일 실행
docker exec -it <container_name> psql -U postgres -f /tmp/init_axcore.sql

REM public 스키마 권한 부여 (별도 실행 필요)
docker exec <container_name> psql -U postgres -d axcore -c "GRANT ALL ON SCHEMA public TO axcore;"
```

### 방법 2: 배치 파일로 자동화

`create_axcore_db.bat` 파일 생성:

```batch
@echo off
setlocal

set CONTAINER_NAME=postgres-container

echo Creating tablespace directory...
REM PostgreSQL 18+ uses /var/lib/postgresql (version-specific subdirectories)
docker exec %CONTAINER_NAME% mkdir -p /var/lib/postgresql/tablespaces/axcore_space
docker exec %CONTAINER_NAME% chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
docker exec %CONTAINER_NAME% chmod 700 /var/lib/postgresql/tablespaces/axcore_space

echo Creating tablespace...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE TABLESPACE axcore_space OWNER postgres LOCATION '/var/lib/postgresql/tablespaces/axcore_space';"

echo Creating user...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE USER axcore WITH LOGIN PASSWORD 'axcore2025!' CREATEDB VALID UNTIL 'infinity';"

echo Creating database...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE DATABASE axcore WITH OWNER = axcore ENCODING = 'UTF8' TABLESPACE = axcore_space LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' CONNECTION LIMIT = -1 TEMPLATE template0;"

echo Granting privileges...
docker exec %CONTAINER_NAME% psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;"
docker exec %CONTAINER_NAME% psql -U postgres -c "GRANT CREATE ON TABLESPACE axcore_space TO axcore;"
docker exec %CONTAINER_NAME% psql -U postgres -d axcore -c "GRANT ALL ON SCHEMA public TO axcore;"

echo Database creation completed!
echo.
echo Testing connection...
docker exec %CONTAINER_NAME% psql -U axcore -d axcore -c "SELECT current_database(), current_user;"

endlocal
```

실행:

```cmd
create_axcore_db.bat
```

## 데이터베이스 삭제 (필요시)

```sql
-- 활성 연결 종료
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'axcore' AND pid <> pg_backend_pid();

-- 데이터베이스 삭제
DROP DATABASE IF EXISTS axcore;

-- 사용자 삭제
DROP USER IF EXISTS axcore;

-- Tablespace 삭제
DROP TABLESPACE IF EXISTS axcore_space;
```

## 문제 해결

### Tablespace 디렉토리 권한 오류

```
ERROR: could not set permissions on directory "/var/lib/postgresql/tablespaces/axcore_space": Operation not permitted
```

**해결 방법:**

```bash
docker exec -it <container_name> bash
chown -R postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
chmod 700 /var/lib/postgresql/tablespaces/axcore_space
```

### 사용자가 이미 존재하는 경우

```sql
-- 사용자 존재 확인 후 생성
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'axcore') THEN
    CREATE USER axcore WITH LOGIN PASSWORD 'axcore2025!' CREATEDB;
  END IF;
END
$$;
```

### 데이터베이스가 이미 존재하는 경우

```sql
-- 데이터베이스 존재 확인
SELECT datname FROM pg_database WHERE datname = 'axcore';

-- 강제 삭제 후 재생성
DROP DATABASE IF EXISTS axcore;
```

## Docker Compose 예제

데이터베이스 초기화를 자동화하려면 `docker-compose.yml`에 init 스크립트를 포함:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:17  # PostgreSQL 18+ 사용 시 버전 변경
    container_name: postgres-axcore
    environment:
      POSTGRES_PASSWORD: postgres
    volumes:
      # PostgreSQL 18+ 권장: /var/lib/postgresql 마운트
      - postgres_data:/var/lib/postgresql
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

`init-scripts/01-init-axcore.sh` 파일:

```bash
#!/bin/bash
set -e

# Tablespace 디렉토리 생성
# PostgreSQL 18+ 버전 호환 경로
mkdir -p /var/lib/postgresql/tablespaces/axcore_space
chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
chmod 700 /var/lib/postgresql/tablespaces/axcore_space

# PostgreSQL 초기화
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE TABLESPACE axcore_space OWNER postgres LOCATION '/var/lib/postgresql/tablespaces/axcore_space';
    CREATE USER axcore WITH LOGIN PASSWORD 'axcore2025!' CREATEDB;
    CREATE DATABASE axcore WITH OWNER = axcore ENCODING = 'UTF8' TABLESPACE = axcore_space LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' TEMPLATE template0;
    GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;
    GRANT CREATE ON TABLESPACE axcore_space TO axcore;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "axcore" <<-EOSQL
    GRANT ALL ON SCHEMA public TO axcore;
EOSQL
```
