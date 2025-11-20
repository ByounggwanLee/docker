# Docker를 활용한 PostgreSQL 생성 절차

## 목차
1. [PostgreSQL 소개](#1-postgresql-소개)
2. [PostgreSQL Docker 이미지 다운로드](#2-postgresql-docker-이미지-다운로드)
3. [PostgreSQL 컨테이너 실행](#3-postgresql-컨테이너-실행)
4. [데이터베이스 생성 절차](#4-데이터베이스-생성-절차)
5. [접속 정보](#5-접속-정보)
6. [백업 및 복원](#6-백업-및-복원)
7. [모니터링](#7-모니터링)
8. [문제 해결](#8-문제-해결)
9. [자동화 스크립트](#9-자동화-스크립트)
10. [Docker Compose 예제](#10-docker-compose-예제)
11. [보안 설정](#11-보안-설정)
12. [유용한 명령어 모음](#12-유용한-명령어-모음)
13. [참고 자료](#13-참고-자료)

---

## 1. PostgreSQL 소개

PostgreSQL은 오픈 소스 객체-관계형 데이터베이스 시스템(ORDBMS)으로, 확장성과 표준 준수를 강조합니다. 30년 이상의 활발한 개발을 통해 안정성, 기능 완성도, 성능 면에서 뛰어난 평가를 받고 있습니다.

### 1.1 axcore 데이터베이스 구성 정보

- **관리자 계정**: postgres
- **관리자 비밀번호**: postgres1225!
- **Database Name**: axcore
- **계정(User)**: axcore
- **비밀번호**: axcore1225!
- **Tablespace**: axcore_space
- **Encoding**: UTF8
- **기본 포트**: 5432

---

## 2. PostgreSQL Docker 이미지 다운로드

### 2.1 최신 버전 다운로드

```cmd
docker pull postgres:17
```

### 2.2 버전 비교

| 버전 | 크기 | 설명 | 권장 용도 |
|------|------|------|-----------|
| postgres:17 | ~150MB | 최신 안정 버전 | 프로덕션 환경 |
| postgres:16 | ~150MB | 안정 버전 | 프로덕션 환경 |
| postgres:15 | ~145MB | 이전 안정 버전 | 레거시 호환 |
| postgres:17-alpine | ~80MB | 경량화 버전 | 리소스 제한 환경 |

**권장**: `postgres:17` (풍부한 진단 도구 포함)

---

## 3. PostgreSQL 컨테이너 실행

### 3.1 기본 실행 명령어

#### Windows (PowerShell)
```powershell
docker run -d `
  --name postgres-container `
  --network dev-net `
  -e POSTGRES_PASSWORD=postgres1225! `
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8" `
  -v D:\Docker\mount\Postgresql\data:/var/lib/postgresql/data `
  -v D:\Docker\mount\Postgresql\tablespaces:/var/lib/postgresql/tablespaces `
  -p 5432:5432 `
  postgres:17
```

#### Linux/Mac
```bash
docker run -d \
  --name postgres-container \
  --network dev-net \
  -e POSTGRES_PASSWORD=postgres1225! \
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8" \
  -v /docker/mount/Postgresql/data:/var/lib/postgresql/data \
  -v /docker/mount/Postgresql/tablespaces:/var/lib/postgresql/tablespaces \
  -p 5432:5432 \
  postgres:17
```

### 3.2 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `POSTGRES_PASSWORD` | postgres 관리자 비밀번호 | 필수 (postgres1225!) |
| `POSTGRES_USER` | 관리자 사용자명 | postgres |
| `POSTGRES_DB` | 기본 데이터베이스명 | $POSTGRES_USER |
| `POSTGRES_INITDB_ARGS` | initdb 초기화 옵션 | - |
| `PGDATA` | 데이터 디렉토리 경로 | /var/lib/postgresql/data |

### 3.3 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/var/lib/postgresql/data` | 데이터 디렉토리 | 데이터베이스 파일, WAL 로그 |
| `/var/lib/postgresql/tablespaces` | 테이블스페이스 | 사용자 정의 테이블스페이스 |
| `/docker-entrypoint-initdb.d` | 초기화 스크립트 | 자동 실행 SQL/Shell 스크립트 |

### 3.4 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps -a --filter "name=postgres-container"

REM 로그 확인
docker logs postgres-container

REM 실시간 로그 모니터링
docker logs -f postgres-container

REM 컨테이너 정보 확인
docker inspect postgres-container
```

---

## 4. 데이터베이스 생성 절차

### 4.1 axcore 데이터베이스 세부 구성

위의 PostgreSQL 소개 섹션에서 확인한 구성 정보를 바탕으로 데이터베이스를 생성합니다.

### 4.2 생성 절차

#### 1. PostgreSQL 컨테이너 접속

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

#### 4. Tablespace 생성

```sql
-- axcore_space tablespace 생성
-- PostgreSQL 18+ 버전 호환 경로 사용
CREATE TABLESPACE axcore_space
  OWNER postgres
  LOCATION '/var/lib/postgresql/tablespaces/axcore_space';

-- tablespace 확인
\db
```

#### 5. 사용자(Role) 생성

```sql
-- axcore 사용자 생성
CREATE USER axcore WITH
  LOGIN
  PASSWORD 'axcore1225!'
  CREATEDB
  VALID UNTIL 'infinity';

-- 사용자 확인
\du
```

#### 6. 데이터베이스 생성

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

#### 7. 권한 부여

```sql
-- axcore 데이터베이스의 모든 권한을 axcore 사용자에게 부여
GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;

-- tablespace 권한 부여
GRANT CREATE ON TABLESPACE axcore_space TO axcore;

-- public 스키마 권한 부여
\c axcore
GRANT ALL ON SCHEMA public TO axcore;
```

#### 8. 연결 테스트

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

#### 9. 확인 명령어

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

### 4.3 전체 스크립트 (한번에 실행)

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
  PASSWORD 'axcore1225!'
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
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE USER axcore WITH LOGIN PASSWORD 'axcore1225!' CREATEDB VALID UNTIL 'infinity';"

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

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 호스트 | localhost (또는 Docker 호스트 IP) |
| 포트 | 5432 |
| 관리자 계정 | postgres |
| 관리자 비밀번호 | postgres1225! |
| 데이터베이스 | axcore |
| 사용자 계정 | axcore |
| 사용자 비밀번호 | axcore1225! |

### 5.2 연결 문자열

#### PostgreSQL JDBC URL
```
jdbc:postgresql://localhost:5432/axcore?user=axcore&password=axcore1225!
```

#### Python (psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="axcore",
    user="axcore",
    password="axcore1225!"
)
```

#### Node.js (pg)
```javascript
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'axcore',
  user: 'axcore',
  password: 'axcore1225!'
});

await client.connect();
```

#### .NET (Npgsql)
```csharp
using Npgsql;

var connectionString = "Host=localhost;Port=5432;Database=axcore;Username=axcore;Password=axcore1225!";
using var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();
```

### 5.3 CLI 접속

```cmd
REM postgres 관리자로 접속
docker exec -it postgres-container psql -U postgres

REM axcore 사용자로 접속
docker exec -it postgres-container psql -U axcore -d axcore

REM 외부에서 직접 접속 (psql 설치 필요)
psql -h localhost -p 5432 -U axcore -d axcore
```

---

## 6. 백업 및 복원

### 6.1 전체 데이터베이스 백업

#### 논리 백업 (pg_dump)
```cmd
REM 단일 데이터베이스 백업
docker exec postgres-container pg_dump -U postgres axcore > D:\backup\axcore_backup_%date:~0,4%%date:~5,2%%date:~8,2%.sql

REM 압축 백업
docker exec postgres-container pg_dump -U postgres -Fc axcore > D:\backup\axcore_backup_%date:~0,4%%date:~5,2%%date:~8,2%.dump

REM 전체 클러스터 백업 (모든 DB)
docker exec postgres-container pg_dumpall -U postgres > D:\backup\full_backup_%date:~0,4%%date:~5,2%%date:~8,2%.sql
```

#### 물리 백업 (볼륨 복사)
```cmd
REM 컨테이너 중지
docker stop postgres-container

REM 데이터 디렉토리 복사
xcopy D:\Docker\mount\Postgresql\data D:\backup\postgresql_data_%date:~0,4%%date:~5,2%%date:~8,2%\ /E /I /H

REM 컨테이너 재시작
docker start postgres-container
```

### 6.2 데이터베이스 복원

#### SQL 파일 복원
```cmd
REM 데이터베이스 재생성
docker exec postgres-container psql -U postgres -c "DROP DATABASE IF EXISTS axcore;"
docker exec postgres-container psql -U postgres -c "CREATE DATABASE axcore WITH OWNER = axcore ENCODING = 'UTF8' TABLESPACE = axcore_space;"

REM 백업 파일 복원
type D:\backup\axcore_backup_20250120.sql | docker exec -i postgres-container psql -U postgres -d axcore
```

#### 압축 백업 복원
```cmd
docker exec -i postgres-container pg_restore -U postgres -d axcore < D:\backup\axcore_backup_20250120.dump
```

#### 전체 클러스터 복원
```cmd
type D:\backup\full_backup_20250120.sql | docker exec -i postgres-container psql -U postgres
```

### 6.3 자동 백업 스크립트

`backup_postgres.bat` 파일:

```batch
@echo off
setlocal enabledelayedexpansion

set CONTAINER_NAME=postgres-container
set BACKUP_DIR=D:\backup\postgresql
set DATE_STR=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set DATE_STR=%DATE_STR: =0%

REM 백업 디렉토리 생성
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo [%date% %time%] Starting PostgreSQL backup...

REM axcore 데이터베이스 백업
docker exec %CONTAINER_NAME% pg_dump -U postgres -Fc axcore > "%BACKUP_DIR%\axcore_%DATE_STR%.dump"

if %errorlevel% equ 0 (
    echo [%date% %time%] Backup completed successfully: axcore_%DATE_STR%.dump
) else (
    echo [%date% %time%] Backup failed!
    exit /b 1
)

REM 7일 이상 된 백업 파일 삭제
forfiles /P "%BACKUP_DIR%" /M *.dump /D -7 /C "cmd /c del @path" 2>nul

echo [%date% %time%] Old backups cleaned up.

endlocal
```

---

## 7. 모니터링

### 7.1 성능 모니터링 쿼리

```sql
-- 활성 연결 확인
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change,
  query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY query_start;

-- 데이터베이스 크기 확인
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- 테이블 크기 확인
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- 느린 쿼리 확인 (실행 시간 > 1초)
SELECT
  pid,
  now() - query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE (now() - query_start) > interval '1 second'
  AND state <> 'idle'
ORDER BY duration DESC;

-- 캐시 히트율 확인 (95% 이상 권장)
SELECT
  sum(heap_blks_read) AS heap_read,
  sum(heap_blks_hit) AS heap_hit,
  sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0) * 100 AS cache_hit_ratio
FROM pg_stattio_user_tables;

-- 인덱스 사용률 확인
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### 7.2 시스템 상태 확인

```cmd
REM 컨테이너 리소스 사용량
docker stats postgres-container --no-stream

REM 컨테이너 프로세스 확인
docker top postgres-container

REM PostgreSQL 버전 확인
docker exec postgres-container psql -U postgres -c "SELECT version();"

REM 설정 확인
docker exec postgres-container psql -U postgres -c "SHOW ALL;"
```

---

## 8. 문제 해결

### 8.1 데이터베이스 삭제 (필요시)

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

### 8.2 일반적인 문제

#### 문제: 컨테이너가 시작되지 않음
```cmd
REM 로그 확인
docker logs postgres-container

REM 일반적인 원인:
REM 1. POSTGRES_PASSWORD 미설정
REM 2. 포트 5432 이미 사용 중
REM 3. 데이터 디렉토리 권한 문제
```

**해결 방법:**
```cmd
REM 포트 충돌 확인
netstat -ano | findstr :5432

REM 기존 PostgreSQL 프로세스 종료 후 재시작
docker stop postgres-container
docker start postgres-container
```

#### 문제: 데이터 디렉토리 권한 오류
```
ERROR: data directory "/var/lib/postgresql/data" has wrong ownership
```

**해결 방법:**
```cmd
REM 컨테이너 삭제 후 재생성
docker rm -f postgres-container

REM 호스트 디렉토리 권한 확인 (Windows는 자동 처리됨)
REM Linux/Mac의 경우: chmod 700 /docker/mount/Postgresql/data
```

### 8.3 데이터베이스 삭제 (필요시)

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

### 8.4 Tablespace 디렉토리 권한 오류

```
ERROR: could not set permissions on directory "/var/lib/postgresql/tablespaces/axcore_space": Operation not permitted
```

**해결 방법:**

```bash
docker exec -it <container_name> bash
chown -R postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
chmod 700 /var/lib/postgresql/tablespaces/axcore_space
```

### 8.5 사용자가 이미 존재하는 경우

```sql
-- 사용자 존재 확인 후 생성
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'axcore') THEN
    CREATE USER axcore WITH LOGIN PASSWORD 'axcore1225!' CREATEDB;
  END IF;
END
$$;
```

### 8.6 데이터베이스가 이미 존재하는 경우

```sql
-- 데이터베이스 존재 확인
SELECT datname FROM pg_database WHERE datname = 'axcore';

-- 강제 삭제 후 재생성
DROP DATABASE IF EXISTS axcore;
```

### 8.7 연결 제한 초과
```
FATAL: sorry, too many clients already
```

**해결 방법:**
```sql
-- 현재 연결 수 확인
SELECT count(*) FROM pg_stat_activity;

-- 최대 연결 수 확인
SHOW max_connections;

-- 최대 연결 수 변경 (컨테이너 재시작 필요)
-- docker run 시 -c 옵션 추가:
-- -c max_connections=200
```

### 8.8 인코딩 오류
```
ERROR: encoding "UTF8" does not match locale "C"
```

**해결 방법:**
```cmd
REM 컨테이너 재생성 시 POSTGRES_INITDB_ARGS 추가
docker run -d ^
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8" ^
  ...
```

---

## 9. 자동화 스크립트

### 9.1 PostgreSQL 컨테이너 실행 스크립트

`runPostgres.bat` (이미 존재하는 파일 업데이트):

```batch
@echo off
setlocal

set CONTAINER_NAME=postgres-container
set NETWORK_NAME=dev-net
set POSTGRES_PASSWORD=postgres1225!
set DATA_DIR=D:\Docker\mount\Postgresql\data
set TABLESPACE_DIR=D:\Docker\mount\Postgresql\tablespaces
set PORT=5432

echo Checking if container already exists...
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /C:"%CONTAINER_NAME%" >nul

if %errorlevel% equ 0 (
    echo Container %CONTAINER_NAME% already exists.
    docker ps --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /C:"%CONTAINER_NAME%" >nul
    if %errorlevel% equ 0 (
        echo Container is already running.
    ) else (
        echo Starting existing container...
        docker start %CONTAINER_NAME%
    )
) else (
    echo Creating network if not exists...
    docker network create %NETWORK_NAME% 2>nul

    echo Creating data directories...
    if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
    if not exist "%TABLESPACE_DIR%" mkdir "%TABLESPACE_DIR%"

    echo Starting new PostgreSQL container...
    docker run -d ^
      --name %CONTAINER_NAME% ^
      --network %NETWORK_NAME% ^
      -e POSTGRES_PASSWORD=%POSTGRES_PASSWORD% ^
      -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.utf8" ^
      -v "%DATA_DIR%":/var/lib/postgresql/data ^
      -v "%TABLESPACE_DIR%":/var/lib/postgresql/tablespaces ^
      -p %PORT%:5432 ^
      postgres:17

    if %errorlevel% equ 0 (
        echo.
        echo PostgreSQL container started successfully!
        echo.
        echo Waiting for PostgreSQL to be ready...
        timeout /t 5 /nobreak >nul
        
        echo Connection Information:
        echo   Host: localhost
        echo   Port: %PORT%
        echo   User: postgres
        echo   Password: %POSTGRES_PASSWORD%
        echo   Database: postgres
        echo.
        echo To create axcore database, run: create_axcore_db.bat
    ) else (
        echo Failed to start PostgreSQL container!
        exit /b 1
    )
)

echo.
echo Checking container status...
docker ps --filter "name=%CONTAINER_NAME%"

endlocal
```

### 9.2 axcore 데이터베이스 생성 스크립트

`create_axcore_db.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=postgres-container

echo Waiting for PostgreSQL to be ready...
:wait_loop
docker exec %CONTAINER_NAME% pg_isready -U postgres >nul 2>&1
if %errorlevel% neq 0 (
    echo PostgreSQL is not ready yet, waiting...
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

echo PostgreSQL is ready!
echo.

echo Creating tablespace directory...
docker exec %CONTAINER_NAME% mkdir -p /var/lib/postgresql/tablespaces/axcore_space
docker exec %CONTAINER_NAME% chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
docker exec %CONTAINER_NAME% chmod 700 /var/lib/postgresql/tablespaces/axcore_space

echo Creating tablespace...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE TABLESPACE axcore_space OWNER postgres LOCATION '/var/lib/postgresql/tablespaces/axcore_space';" 2>nul
if %errorlevel% neq 0 (
    echo Tablespace may already exist, continuing...
)

echo Creating user...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE USER axcore WITH LOGIN PASSWORD 'axcore1225!' CREATEDB VALID UNTIL 'infinity';" 2>nul
if %errorlevel% neq 0 (
    echo User may already exist, continuing...
)

echo Creating database...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE DATABASE axcore WITH OWNER = axcore ENCODING = 'UTF8' TABLESPACE = axcore_space LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' CONNECTION LIMIT = -1 TEMPLATE template0;" 2>nul
if %errorlevel% neq 0 (
    echo Database may already exist, continuing...
)

echo Granting privileges...
docker exec %CONTAINER_NAME% psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;"
docker exec %CONTAINER_NAME% psql -U postgres -c "GRANT CREATE ON TABLESPACE axcore_space TO axcore;"
docker exec %CONTAINER_NAME% psql -U postgres -d axcore -c "GRANT ALL ON SCHEMA public TO axcore;"

echo.
echo Database setup completed!
echo.
echo Testing connection...
docker exec %CONTAINER_NAME% psql -U axcore -d axcore -c "SELECT 'Database: ' || current_database() AS info UNION ALL SELECT 'User: ' || current_user;"

echo.
echo Connection Information:
echo   Database: axcore
echo   User: axcore
echo   Password: axcore1225!
echo   JDBC URL: jdbc:postgresql://localhost:5432/axcore

endlocal
```

### 9.3 백업 자동화 스크립트

`backup_postgres.bat`:

```batch
@echo off
setlocal enabledelayedexpansion

set CONTAINER_NAME=postgres-container
set BACKUP_DIR=D:\backup\postgresql
set DATABASE=axcore
set DATE_STR=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set DATE_STR=%DATE_STR: =0%

REM 백업 디렉토리 생성
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo ============================================
echo PostgreSQL Backup Script
echo ============================================
echo Start Time: %date% %time%
echo Database: %DATABASE%
echo ============================================
echo.

REM 컨테이너 실행 확인
docker ps --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /C:"%CONTAINER_NAME%" >nul
if %errorlevel% neq 0 (
    echo ERROR: Container %CONTAINER_NAME% is not running!
    exit /b 1
)

REM 압축 포맷으로 백업
echo Backing up database...
docker exec %CONTAINER_NAME% pg_dump -U postgres -Fc %DATABASE% > "%BACKUP_DIR%\%DATABASE%_%DATE_STR%.dump"

if %errorlevel% equ 0 (
    echo SUCCESS: Backup completed successfully!
    echo File: %DATABASE%_%DATE_STR%.dump
    
    REM 백업 파일 크기 확인
    for %%A in ("%BACKUP_DIR%\%DATABASE%_%DATE_STR%.dump") do (
        echo Size: %%~zA bytes
    )
) else (
    echo ERROR: Backup failed!
    exit /b 1
)

echo.
echo Cleaning up old backups (keeping last 7 days)...
forfiles /P "%BACKUP_DIR%" /M *.dump /D -7 /C "cmd /c del @path" 2>nul
if %errorlevel% equ 0 (
    echo Old backups removed.
) else (
    echo No old backups to remove.
)

echo.
echo ============================================
echo Backup completed successfully!
echo End Time: %date% %time%
echo ============================================

endlocal
```

### 9.4 복원 스크립트

`restore_postgres.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=postgres-container
set DATABASE=axcore
set /p BACKUP_FILE="Enter backup file path (e.g., D:\backup\postgresql\axcore_20250120_143000.dump): "

if not exist "%BACKUP_FILE%" (
    echo ERROR: Backup file not found: %BACKUP_FILE%
    exit /b 1
)

echo ============================================
echo PostgreSQL Restore Script
echo ============================================
echo Database: %DATABASE%
echo Backup File: %BACKUP_FILE%
echo ============================================
echo.

echo WARNING: This will drop and recreate the database!
set /p CONFIRM="Continue? (yes/no): "
if /i not "%CONFIRM%"=="yes" (
    echo Restore cancelled.
    exit /b 0
)

echo.
echo Dropping existing database...
docker exec %CONTAINER_NAME% psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DATABASE%' AND pid <> pg_backend_pid();"
docker exec %CONTAINER_NAME% psql -U postgres -c "DROP DATABASE IF EXISTS %DATABASE%;"

echo Creating new database...
docker exec %CONTAINER_NAME% psql -U postgres -c "CREATE DATABASE %DATABASE% WITH OWNER = axcore ENCODING = 'UTF8' TABLESPACE = axcore_space LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';"

echo Restoring from backup...
type "%BACKUP_FILE%" | docker exec -i %CONTAINER_NAME% pg_restore -U postgres -d %DATABASE%

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo Restore completed successfully!
    echo ============================================
) else (
    echo.
    echo ERROR: Restore failed!
    exit /b 1
)

endlocal
```

---

## 10. Docker Compose 예제

데이터베이스 초기화를 자동화하려면 `docker-compose.yml`에 init 스크립트를 포함:

### 10.1 docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:17
    container_name: postgres-axcore
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: postgres1225!
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=en_US.utf8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - postgres_tablespaces:/var/lib/postgresql/tablespaces
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    networks:
      - dev-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Postgresql\data
  postgres_tablespaces:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Postgresql\tablespaces

networks:
  dev-net:
    external: true
```

### 10.2 초기화 스크립트

`init-scripts/01-init-axcore.sh` 파일:

```bash
#!/bin/bash
set -e

echo "Initializing axcore database..."

# Tablespace 디렉토리 생성
mkdir -p /var/lib/postgresql/tablespaces/axcore_space
chown postgres:postgres /var/lib/postgresql/tablespaces/axcore_space
chmod 700 /var/lib/postgresql/tablespaces/axcore_space

# PostgreSQL 초기화
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Tablespace 생성
    CREATE TABLESPACE axcore_space 
      OWNER postgres 
      LOCATION '/var/lib/postgresql/tablespaces/axcore_space';
    
    -- 사용자 생성
    CREATE USER axcore WITH 
      LOGIN 
      PASSWORD 'axcore1225!' 
      CREATEDB;
    
    -- 데이터베이스 생성
    CREATE DATABASE axcore 
      WITH 
      OWNER = axcore 
      ENCODING = 'UTF8' 
      TABLESPACE = axcore_space 
      LC_COLLATE = 'en_US.utf8' 
      LC_CTYPE = 'en_US.utf8' 
      TEMPLATE template0;
    
    -- 권한 부여
    GRANT ALL PRIVILEGES ON DATABASE axcore TO axcore;
    GRANT CREATE ON TABLESPACE axcore_space TO axcore;
EOSQL

# axcore 데이터베이스에 연결하여 스키마 권한 부여
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "axcore" <<-EOSQL
    GRANT ALL ON SCHEMA public TO axcore;
EOSQL

echo "axcore database initialized successfully!"
```

### 10.3 실행 방법

```cmd
REM Docker Compose로 시작
docker-compose up -d

REM 로그 확인
docker-compose logs -f postgres

REM 중지
docker-compose down

REM 볼륨까지 삭제
docker-compose down -v
```

---

## 11. 보안 설정

### 11.1 postgresql.conf 주요 설정

컨테이너 실행 시 설정 파일 마운트:

```cmd
docker run -d ^
  -v D:\Docker\mount\Postgresql\conf\postgresql.conf:/etc/postgresql/postgresql.conf ^
  -c config_file=/etc/postgresql/postgresql.conf ^
  ...
```

**권장 설정:**
```conf
# 연결 설정
listen_addresses = '*'
max_connections = 100
superuser_reserved_connections = 3

# 메모리 설정
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL 설정
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# 로깅
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# 성능
random_page_cost = 1.1
effective_io_concurrency = 200
```

### 11.2 pg_hba.conf 접근 제어

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# 로컬 연결
local   all             all                                     trust

# IPv4 로컬 연결
host    all             all             127.0.0.1/32            md5

# IPv4 Docker 네트워크
host    all             all             172.16.0.0/12           md5

# IPv6 로컬 연결
host    all             all             ::1/128                 md5

# 특정 IP만 허용
host    axcore          axcore          192.168.1.0/24          md5
```

### 11.3 SSL 설정 (프로덕션 권장)

```cmd
REM 인증서 생성
docker exec postgres-container openssl req -new -x509 -days 365 -nodes -text -out /var/lib/postgresql/data/server.crt -keyout /var/lib/postgresql/data/server.key -subj "/CN=postgres"

REM 권한 설정
docker exec postgres-container chmod 600 /var/lib/postgresql/data/server.key
docker exec postgres-container chown postgres:postgres /var/lib/postgresql/data/server.key

REM SSL 활성화
docker exec postgres-container psql -U postgres -c "ALTER SYSTEM SET ssl = on;"
docker restart postgres-container
```

---

## 12. 유용한 명령어 모음

### 12.1 데이터베이스 관리

```sql
-- 모든 데이터베이스 목록
\l

-- 현재 데이터베이스의 테이블 목록
\dt

-- 테이블 구조 확인
\d table_name

-- 사용자 목록
\du

-- 테이블스페이스 목록
\db

-- 스키마 목록
\dn

-- 함수 목록
\df

-- 뷰 목록
\dv

-- 인덱스 목록
\di

-- 시퀀스 목록
\ds
```

### 12.2 성능 튜닝

```sql
-- 쿼리 실행 계획
EXPLAIN ANALYZE SELECT * FROM table_name;

-- 인덱스 재구성
REINDEX DATABASE axcore;

-- 통계 정보 갱신
ANALYZE;

-- Vacuum (공간 회수)
VACUUM ANALYZE;

-- 테이블 잠금 확인
SELECT * FROM pg_locks WHERE NOT granted;

-- 데드락 확인
SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';
```

### 12.3 사용자 및 권한 관리

```sql
-- 새 사용자 생성
CREATE USER newuser WITH PASSWORD 'password';

-- 데이터베이스 권한 부여
GRANT ALL PRIVILEGES ON DATABASE dbname TO username;

-- 테이블 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON tablename TO username;

-- 스키마 권한 부여
GRANT ALL ON SCHEMA schemaname TO username;

-- 권한 확인
\z tablename

-- 사용자 비밀번호 변경
ALTER USER username WITH PASSWORD 'newpassword';

-- 사용자 삭제
DROP USER username;
```

---

## 13. 참고 자료

- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [PostgreSQL Wiki](https://wiki.postgresql.org/)
- [pgAdmin 4](https://www.pgadmin.org/) - GUI 관리 도구
- [DBeaver](https://dbeaver.io/) - 범용 데이터베이스 도구

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2025-01-20 | 1.0 | 초기 문서 작성 |
| 2025-11-20 | 2.0 | Docker 설치 절차 추가, 자동화 스크립트 추가 |

