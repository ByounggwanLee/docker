# Docker를 활용한 Vertica 설치 및 구성 가이드

## 목차
1. [Vertica 소개](#1-vertica-소개)
2. [Vertica Docker 이미지 다운로드](#2-vertica-docker-이미지-다운로드)
3. [Vertica 컨테이너 실행](#3-vertica-컨테이너-실행)
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

## 1. Vertica 소개

Vertica는 고성능 분석 데이터베이스(OLAP)로, 대용량 데이터 처리와 분석에 최적화되어 있습니다. Columnar 스토리지와 MPP(Massively Parallel Processing) 아키텍처를 사용하여 빠른 쿼리 성능을 제공합니다.

### 1.1 docker 데이터베이스 구성 정보

- **관리자 계정**: dbadmin
- **관리자 비밀번호**: (없음)
- **Database Name**: docker (기본 데이터베이스)
- **Schema Name**: public
- **Encoding**: UTF8
- **기본 포트**: 5433 (Client), 5444 (Management Console)

**⚠️ 중요 제한사항:**
- `jbfavre/vertica` 커뮤니티 이미지는 컨테이너 재시작 시 카탈로그 충돌로 데이터 영속성 제한
- 컨테이너 삭제 후 재생성 시 모든 데이터 초기화
- 프로덕션 환경에서는 공식 Vertica Enterprise Edition 사용 권장
- SQL 덤프를 통한 백업/복원 필수

---

## 2. Vertica Docker 이미지 다운로드

### 2.1 이미지 선택 가이드

**⚠️ 주의:** OpenText Vertica의 공식 Docker 이미지(`vertica/vertica-ce`)는 더 이상 Docker Hub에서 직접 제공되지 않습니다.

### 2.2 커뮤니티 이미지 다운로드 (권장)

```cmd
REM 최신 버전
docker pull jbfavre/vertica:latest

REM 특정 버전
docker pull jbfavre/vertica:12.0.4-0
```

### 2.3 버전 비교

| 이미지 | 버전 | 크기 | 권장 용도 |
|--------|------|------|-----------|
| jbfavre/vertica:latest | 최신 | ~1.5GB | 개발/테스트 |
| jbfavre/vertica:12.0.4-0 | 12.0.4 | ~1.5GB | 안정성 요구 |
| jbfavre/vertica:11.1.1-0 | 11.1.1 | ~1.4GB | 레거시 호환 |

**공식 이미지 대안:**
1. [Vertica Community Edition](https://www.vertica.com/download/vertica/community-edition/)에서 직접 다운로드
2. 수동으로 Docker 이미지 빌드
3. Enterprise Edition 라이선스 구매

---

## 3. Vertica 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성 (선택사항)
mkdir D:\Docker\mount\Vertica\data
```

### 3.2 기본 실행 명령어

#### Windows (PowerShell)
```powershell
docker run -d `
  --name vertica-container `
  --network dev-net `
  -e TZ=Asia/Seoul `
  -p 5433:5433 `
  -p 5444:5444 `
  jbfavre/vertica:latest
```

#### Linux/Mac
```bash
docker run -d \
  --name vertica-container \
  --network dev-net \
  -e TZ=Asia/Seoul \
  -p 5433:5433 \
  -p 5444:5444 \
  jbfavre/vertica:latest
```

### 3.3 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `TZ` | 타임존 설정 | UTC |

**참고:** Vertica는 초기화에 1-2분 소요됩니다.

### 3.4 볼륨 마운트 경로

⚠️ **데이터 영속성 제한:** 볼륨 마운트를 사용해도 컨테이너 재시작 시 카탈로그 충돌로 정상 작동하지 않습니다.

| 컨테이너 경로 | 용도 | 제한사항 |
|---------------|------|----------|
| `/home/dbadmin` | 사용자 홈 디렉토리 | 재시작 시 사용 불가 |
| `/opt/vertica/config` | 설정 디렉토리 | 읽기 전용 권장 |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태
docker ps -a --filter "name=vertica-container"

REM 로그 확인 (초기화 진행 상황)
docker logs -f vertica-container

REM "Vertica is now running" 메시지가 보이면 준비 완료
```

---

## 4. 데이터베이스 생성 절차

### 4.1 docker 데이터베이스 구성

Vertica는 기본적으로 `docker`라는 데이터베이스가 자동 생성됩니다. 추가 데이터베이스는 새로운 Vertica 인스턴스(컨테이너)가 필요합니다.

**Vertica vs PostgreSQL 차이:**
- **PostgreSQL**: 단일 인스턴스에 여러 데이터베이스 생성 가능
- **Vertica**: 단일 인스턴스에 단일 데이터베이스, 스키마로 논리적 분리

### 4.2 컨테이너 접속

```cmd
REM 컨테이너 내부 접속
docker exec -it vertica-container /bin/bash

REM dbadmin 사용자로 전환
su - dbadmin
```

### 4.3 vsql 접속 (Vertica SQL 클라이언트)

```bash
# 컨테이너 내부에서
/opt/vertica/bin/vsql -U dbadmin

# 또는 외부에서 직접
docker exec -it vertica-container /opt/vertica/bin/vsql -U dbadmin
```

### 4.4 스키마 생성

```sql
-- 기본 스키마 확인
SELECT schema_name FROM v_catalog.schemata;

-- 새 스키마 생성
CREATE SCHEMA myapp;

-- 스키마 확인
\dn

-- 스키마에 테이블 생성
CREATE TABLE myapp.users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 테이블 확인
SELECT table_schema, table_name 
FROM v_catalog.tables 
WHERE table_schema = 'myapp';
```

### 4.5 전체 스크립트 (한번에 실행)

```sql
-- public 스키마에 테스트 테이블 생성
CREATE TABLE IF NOT EXISTS public.test_table (
    id INT,
    name VARCHAR(100)
);

-- 샘플 데이터 입력
INSERT INTO public.test_table VALUES (1, 'Test Record');
INSERT INTO public.test_table VALUES (2, 'Sample Data');

-- 확인
SELECT * FROM public.test_table;

-- 테이블 정보
SELECT table_schema, table_name, table_type
FROM v_catalog.tables 
WHERE table_schema = 'public';
```

### 4.6 배치 파일로 자동화

`create_docker_db.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica-container

echo Creating schema and tables...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE SCHEMA IF NOT EXISTS myapp;"
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE TABLE IF NOT EXISTS myapp.users (id INT PRIMARY KEY, name VARCHAR(100), email VARCHAR(255));"

echo Inserting sample data...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "INSERT INTO myapp.users VALUES (1, 'Admin', 'admin@example.com');"

echo Verifying...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "SELECT * FROM myapp.users;"

echo Setup completed!
endlocal
```

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 호스트 | localhost (또는 Docker 호스트 IP) |
| Client 포트 | 5433 |
| Console 포트 | 5444 |
| 관리자 계정 | dbadmin |
| 관리자 비밀번호 | (없음) |
| 데이터베이스 | docker |

### 5.2 연결 문자열

#### JDBC URL
```
jdbc:vertica://localhost:5433/docker?user=dbadmin
```

#### ODBC 설정
```
Driver=Vertica
Server=localhost
Port=5433
Database=docker
User=dbadmin
Password=
```

#### Python (vertica-python)
```python
import vertica_python

conn_info = {
    'host': 'localhost',
    'port': 5433,
    'user': 'dbadmin',
    'password': '',
    'database': 'docker',
    'autocommit': True
}

with vertica_python.connect(**conn_info) as conn:
    cur = conn.cursor()
    cur.execute("SELECT version()")
    print(cur.fetchone())
```

#### Node.js (vertica)
```javascript
const vertica = require('vertica');

const client = vertica.connect({
  host: 'localhost',
  port: 5433,
  user: 'dbadmin',
  database: 'docker'
});

client.query('SELECT version()', (err, result) => {
  console.log(result.rows);
});
```

### 5.3 CLI 접속

```cmd
REM vsql로 접속
docker exec -it vertica-container /opt/vertica/bin/vsql -U dbadmin

REM 단일 쿼리 실행
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -c "SELECT current_database();"
```

---

## 6. 백업 및 복원

### 6.1 SQL 덤프로 백업 (권장)

⚠️ **중요:** 볼륨 마운트가 작동하지 않으므로 SQL 덤프가 유일한 안정적인 백업 방법입니다.

```cmd
REM 스키마 구조 백업
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -c "SELECT export_objects('', 'public');" > D:\Docker\backup\vertica_schema_%date:~0,4%%date:~5,2%%date:~8,2%.sql

REM 테이블 데이터를 CSV로 백업
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -c "COPY public.users TO STDOUT DELIMITER ',' ENCLOSED BY '\"';" > D:\Docker\backup\users_%date:~0,4%%date:~5,2%%date:~8,2%.csv
```

### 6.2 전체 스키마 백업

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica-container
set BACKUP_DIR=D:\Docker\backup\vertica
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Backing up Vertica schema...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "SELECT export_objects('', 'public');" > "%BACKUP_DIR%\schema_%DATE_STAMP%.sql"

echo Backup completed: %BACKUP_DIR%\schema_%DATE_STAMP%.sql
endlocal
```

### 6.3 데이터베이스 복원

```cmd
REM SQL 파일을 컨테이너로 복사
docker cp D:\Docker\backup\vertica_schema.sql vertica-container:/tmp/restore.sql

REM SQL 파일 실행
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -f /tmp/restore.sql

REM CSV 데이터 복원
docker cp D:\Docker\backup\users.csv vertica-container:/tmp/
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -c "COPY public.users FROM '/tmp/users.csv' DELIMITER ',' ENCLOSED BY '\"';"
```

### 6.4 자동 백업 스크립트

`backup_vertica.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica-container
set BACKUP_DIR=D:\Docker\backup\vertica
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%

echo Vertica Backup Script
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 스키마 백업
echo Backing up schema...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "SELECT export_objects('', 'public');" > "%BACKUP_DIR%\schema_%DATE_STAMP%.sql" 2>nul

if exist "%BACKUP_DIR%\schema_%DATE_STAMP%.sql" (
    echo Schema backup completed!
) else (
    echo Schema backup failed!
    exit /b 1
)

REM 오래된 백업 삭제 (30일 이상)
echo Cleaning old backups...
forfiles /p "%BACKUP_DIR%" /m schema_*.sql /d -30 /c "cmd /c del @path" 2>nul

echo Backup process completed!
endlocal
```

---

## 7. 모니터링

### 7.1 시스템 상태 확인

```sql
-- 데이터베이스 정보
SELECT database_name, node_name, node_state 
FROM nodes;

-- 테이블 정보
SELECT table_schema, table_name, row_count
FROM v_monitor.tables
ORDER BY row_count DESC
LIMIT 10;

-- 스토리지 사용량
SELECT node_name, 
       disk_space_used_mb, 
       disk_space_free_mb,
       disk_space_used_mb + disk_space_free_mb AS total_mb
FROM disk_storage;
```

### 7.2 성능 모니터링

```sql
-- 실행 중인 쿼리
SELECT session_id, user_name, transaction_id, statement_id, 
       request, request_duration_ms
FROM v_monitor.sessions
WHERE is_executing = true;

-- 쿼리 히스토리 (최근 10개)
SELECT start_timestamp, user_name, request, 
       request_duration_ms, processed_row_count
FROM v_monitor.query_requests
ORDER BY start_timestamp DESC
LIMIT 10;

-- 리소스 사용량
SELECT * FROM v_monitor.resource_usage;
```

### 7.3 연결 정보

```sql
-- 활성 세션
SELECT session_id, user_name, client_hostname, 
       client_type, login_timestamp
FROM v_monitor.sessions
WHERE is_active = true;

-- 세션 수 통계
SELECT user_name, COUNT(*) as session_count
FROM v_monitor.sessions
GROUP BY user_name;
```

---

## 8. 문제 해결

### 8.1 컨테이너 재시작 실패

**문제:** `docker restart`로 컨테이너를 재시작하면 카탈로그 충돌 오류 발생

**해결방법:**
```cmd
REM 재시작 대신 컨테이너를 삭제하고 재생성
docker stop vertica-container
docker rm vertica-container

REM 새로 생성
docker run -d ^
    -p 5433:5433 ^
    -p 5444:5444 ^
    --name vertica-container ^
    --network dev-net ^
    -e TZ=Asia/Seoul ^
    jbfavre/vertica:latest

REM 백업한 스키마/데이터 복원 필요
```

### 8.2 컨테이너 초기화가 느린 경우

```cmd
REM 로그 모니터링
docker logs -f vertica-container

REM "Vertica is now running" 메시지 대기 (1-2분 소요)
REM Docker Desktop 메모리 할당 확인 (최소 2GB 권장)
```

### 8.3 메모리 부족

```cmd
REM Vertica 메모리 사용량 확인
docker stats vertica-container

REM Docker Desktop Settings에서 메모리 할당 증가
REM 권장: 4GB 이상
```

### 8.4 연결 오류

```cmd
REM 포트 확인
docker port vertica-container

REM 컨테이너 네트워크 확인
docker inspect vertica-container --format='{{.NetworkSettings.Networks}}'

REM vsql 연결 테스트
docker exec vertica-container /opt/vertica/bin/vsql -U dbadmin -c "SELECT 1;"
```

### 8.5 테이블이 사라진 경우

⚠️ **원인:** 컨테이너 재시작 또는 재생성으로 데이터 초기화

**해결방법:**
1. 백업한 SQL 파일에서 복원
2. Docker Compose + 초기화 스크립트 사용 (섹션 10 참조)
3. 정기적인 SQL 덤프 백업 자동화

### 8.6 일반적인 문제

```cmd
REM 1. POSTGRES_PASSWORD 미설정 (Vertica는 해당 없음)

REM 2. 포트 충돌
REM PostgreSQL(5432)과 Vertica(5433)는 다른 포트 사용

REM 3. 볼륨 권한 문제 (Linux/Mac)
REM 호스트 디렉토리 권한 확인
REM chmod 700 /docker/mount/Vertica/data
```

---

## 9. 자동화 스크립트

### 9.1 Vertica 컨테이너 실행 스크립트

`runVertica.bat`:

```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=vertica-container
set NETWORK_NAME=dev-net
set CLIENT_PORT=5433
set CONSOLE_PORT=5444

echo Starting Vertica Docker Container Setup...
echo.

REM -------------------------------
REM CREATE NETWORK IF NOT EXISTS
REM -------------------------------
echo Checking network: %NETWORK_NAME%
docker network inspect %NETWORK_NAME% >nul 2>&1
if errorlevel 1 (
    echo Creating network: %NETWORK_NAME%
    docker network create %NETWORK_NAME%
) else (
    echo Network %NETWORK_NAME% already exists
)

REM -------------------------------
REM PULL IMAGE
REM -------------------------------
echo Pulling Vertica image...
docker pull jbfavre/vertica:latest

REM -------------------------------
REM STOP AND REMOVE EXISTING CONTAINER
REM -------------------------------
echo Checking for existing container: %CONTAINER_NAME%
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /X %CONTAINER_NAME% >nul 2>&1
if not errorlevel 1 (
    echo Stopping existing container...
    docker stop %CONTAINER_NAME% >nul 2>&1
    echo Removing existing container...
    docker rm %CONTAINER_NAME% >nul 2>&1
)

REM -------------------------------
REM RUN CONTAINER
REM -------------------------------
echo Starting Vertica container...
docker run -d ^
    -p %CLIENT_PORT%:5433 ^
    -p %CONSOLE_PORT%:5444 ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e TZ=Asia/Seoul ^
    jbfavre/vertica:latest

if errorlevel 1 (
    echo Failed to start Vertica container!
    exit /b 1
)

echo.
echo Vertica container started successfully!
echo Container name: %CONTAINER_NAME%
echo Client port: %CLIENT_PORT%
echo Console port: %CONSOLE_PORT%
echo.
echo Waiting for Vertica to be ready (this may take 1-2 minutes)...
timeout /t 60 /nobreak >nul

REM -------------------------------
REM VERIFY CONTAINER STATUS
REM -------------------------------
echo Verifying connection...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "SELECT current_database(), current_user();" 2>nul

if errorlevel 1 (
    echo Warning: Connection test failed. Check logs with: docker logs %CONTAINER_NAME%
) else (
    echo.
    echo Vertica is ready!
    echo Connection string: vertica://dbadmin@localhost:%CLIENT_PORT%/docker
    echo Management Console: http://localhost:%CONSOLE_PORT%
)

echo.
endlocal
```

### 9.2 스키마 생성 스크립트

`create_docker_schema.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica-container

echo Creating schemas and tables...
echo.

REM myapp 스키마 생성
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE SCHEMA IF NOT EXISTS myapp;" 2>nul

REM 테이블 생성
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE TABLE IF NOT EXISTS myapp.users (id INT PRIMARY KEY, name VARCHAR(100), email VARCHAR(255), created_at TIMESTAMP DEFAULT NOW());" 2>nul

docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE TABLE IF NOT EXISTS myapp.orders (id INT PRIMARY KEY, user_id INT, amount DECIMAL(10,2), order_date TIMESTAMP DEFAULT NOW());" 2>nul

REM 샘플 데이터
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "INSERT INTO myapp.users (id, name, email) VALUES (1, 'Admin', 'admin@example.com');" 2>nul

echo.
echo Schema setup completed!
echo.
echo Verifying tables...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "SELECT table_schema, table_name FROM v_catalog.tables WHERE table_schema = 'myapp';"

echo.
echo Connection Information:
echo   Database: docker
echo   User: dbadmin
echo   JDBC URL: jdbc:vertica://localhost:5433/docker?user=dbadmin

endlocal
```

### 9.3 복원 스크립트

`restore_vertica.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica-container
set BACKUP_FILE=%1

if "%BACKUP_FILE%"=="" (
    echo Usage: restore_vertica.bat ^<backup_file.sql^>
    exit /b 1
)

if not exist "%BACKUP_FILE%" (
    echo Error: Backup file not found: %BACKUP_FILE%
    exit /b 1
)

echo Restoring from: %BACKUP_FILE%
echo.

REM 백업 파일을 컨테이너로 복사
docker cp "%BACKUP_FILE%" %CONTAINER_NAME%:/tmp/restore.sql

REM 복원 실행
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -f /tmp/restore.sql

if errorlevel 1 (
    echo Restore failed!
    exit /b 1
)

echo.
echo Restore completed successfully!
endlocal
```

---

## 10. Docker Compose 예제

### 10.1 docker-compose.yml

```yaml
version: '3.8'

services:
  vertica:
    image: jbfavre/vertica:latest
    container_name: vertica-docker
    hostname: vertica-host
    ports:
      - "5433:5433"
      - "5444:5444"
    environment:
      TZ: Asia/Seoul
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - dev-net
    restart: "no"
    healthcheck:
      test: ["CMD", "/opt/vertica/bin/vsql", "-U", "dbadmin", "-c", "SELECT 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

networks:
  dev-net:
    driver: bridge
```

### 10.2 초기화 스크립트

`init-scripts/01-init-schema.sh`:

```bash
#!/bin/bash
set -e

echo "Waiting for Vertica to be ready..."
sleep 60

echo "Creating schemas and tables..."

/opt/vertica/bin/vsql -U dbadmin <<-EOSQL
    -- 스키마 생성
    CREATE SCHEMA IF NOT EXISTS myapp;
    
    -- 테이블 생성
    CREATE TABLE IF NOT EXISTS myapp.users (
        id INT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(255),
        created_at TIMESTAMP DEFAULT NOW()
    );
    
    CREATE TABLE IF NOT EXISTS myapp.orders (
        id INT PRIMARY KEY,
        user_id INT,
        amount DECIMAL(10,2),
        order_date TIMESTAMP DEFAULT NOW()
    );
    
    -- 샘플 데이터
    INSERT INTO myapp.users (id, name, email) 
    VALUES (1, 'Admin', 'admin@example.com');
    
    INSERT INTO myapp.orders (id, user_id, amount) 
    VALUES (1, 1, 99.99);
EOSQL

echo "Schema initialization completed!"
```

### 10.3 자동 복원 스크립트

`init-scripts/02-restore-backup.sh`:

```bash
#!/bin/bash
set -e

if [ -f /backups/schema.sql ]; then
    echo "Restoring schema from backup..."
    /opt/vertica/bin/vsql -U dbadmin -f /backups/schema.sql
    echo "Schema restored successfully!"
fi

if [ -f /backups/data.csv ]; then
    echo "Restoring data from backup..."
    /opt/vertica/bin/vsql -U dbadmin -c "COPY public.users FROM '/backups/data.csv' DELIMITER ',' ENCLOSED BY '\"';"
    echo "Data restored successfully!"
fi
```

### 10.4 실행 방법

```cmd
REM 초기 실행
docker-compose up -d

REM 로그 확인
docker-compose logs -f vertica

REM 컨테이너 재생성 (데이터는 초기화됨, 초기화 스크립트로 자동 복원)
docker-compose down
docker-compose up -d

REM 완전 정리
docker-compose down -v
```

---

## 11. 보안 설정

### 11.1 사용자 생성 및 권한 관리

```sql
-- 새 사용자 생성
CREATE USER analyst IDENTIFIED BY 'password123';

-- 사용자 확인
SELECT user_name, is_locked FROM users;

-- 스키마 권한 부여
GRANT USAGE ON SCHEMA myapp TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA myapp TO analyst;

-- 특정 테이블에만 권한
GRANT SELECT, INSERT ON myapp.users TO analyst;

-- 권한 확인
SELECT * FROM grants WHERE grantee = 'analyst';
```

### 11.2 비밀번호 정책

```sql
-- 비밀번호 변경
ALTER USER analyst IDENTIFIED BY 'new_password456';

-- 사용자 잠금
ALTER USER analyst ACCOUNT LOCK;

-- 사용자 잠금 해제
ALTER USER analyst ACCOUNT UNLOCK;

-- 사용자 삭제
DROP USER IF EXISTS analyst;
```

### 11.3 감사 로그

```sql
-- 감사 로그 활성화
ALTER DATABASE docker SET AuditLogDatabase = 'docker';

-- 감사 로그 조회
SELECT audit_start_timestamp, user_name, session_id, 
       database_name, object_name, requested_action
FROM v_monitor.dc_audit_log
ORDER BY audit_start_timestamp DESC
LIMIT 10;
```

### 11.4 SSL/TLS 설정 (프로덕션 권장)

⚠️ **주의:** 커뮤니티 이미지에서는 SSL 설정이 제한적입니다. 프로덕션 환경에서는 공식 Vertica Enterprise Edition 사용을 권장합니다.

```sql
-- SSL 상태 확인
SELECT node_name, ssl_enabled FROM nodes;
```

---

## 12. 유용한 명령어 모음

### 12.1 데이터베이스 관리

```sql
-- 현재 데이터베이스 정보
SELECT current_database(), current_user(), current_schema();

-- 모든 스키마 목록
SELECT schema_name, schema_owner FROM v_catalog.schemata;

-- 모든 테이블 목록
SELECT table_schema, table_name, table_type
FROM v_catalog.tables
WHERE table_schema NOT IN ('v_catalog', 'v_monitor', 'v_internal');

-- 테이블 컬럼 정보
SELECT column_name, data_type, is_nullable
FROM v_catalog.columns
WHERE table_schema = 'myapp' AND table_name = 'users';

-- 테이블 크기 확인
SELECT anchor_table_schema, anchor_table_name, 
       used_bytes / 1024 / 1024 AS used_mb,
       ros_count, row_count
FROM v_monitor.projection_storage
GROUP BY anchor_table_schema, anchor_table_name, ros_count, row_count
ORDER BY used_bytes DESC
LIMIT 10;
```

### 12.2 성능 튜닝

```sql
-- 테이블 통계 업데이트
SELECT ANALYZE_STATISTICS('myapp.users');

-- 쿼리 프로파일링
SELECT * FROM query_profiles 
WHERE query ILIKE '%users%' 
ORDER BY query_start DESC 
LIMIT 5;

-- 슬로우 쿼리 확인
SELECT query_start, user_name, request, 
       request_duration_ms / 1000.0 AS duration_seconds
FROM v_monitor.query_requests
WHERE request_duration_ms > 1000
ORDER BY request_duration_ms DESC
LIMIT 10;

-- 실행 계획 확인
EXPLAIN SELECT * FROM myapp.users WHERE id = 1;
```

### 12.3 데이터 작업

```sql
-- 테이블 복사
CREATE TABLE myapp.users_backup AS SELECT * FROM myapp.users;

-- 테이블 비우기
TRUNCATE TABLE myapp.orders;

-- 테이블 삭제
DROP TABLE IF EXISTS myapp.users_backup CASCADE;

-- 스키마 삭제
DROP SCHEMA IF EXISTS myapp CASCADE;

-- 대용량 데이터 로드
COPY myapp.users FROM LOCAL '/path/to/data.csv' 
DELIMITER ',' ENCLOSED BY '"' 
SKIP 1;

-- 데이터 언로드
COPY myapp.users TO '/tmp/export.csv' 
DELIMITER ',' ENCLOSED BY '"';
```

### 12.4 시스템 정보

```sql
-- Vertica 버전
SELECT version();

-- 노드 정보
SELECT node_name, node_address, node_state, node_type
FROM v_catalog.nodes;

-- 라이선스 정보
SELECT GET_COMPLIANCE_STATUS();

-- 데이터베이스 크기
SELECT database_size_bytes / 1024 / 1024 / 1024 AS size_gb
FROM v_monitor.database_size;

-- 메모리 사용량
SELECT node_name, 
       total_memory_bytes / 1024 / 1024 / 1024 AS total_memory_gb,
       total_memory_free_bytes / 1024 / 1024 / 1024 AS free_memory_gb
FROM v_monitor.host_resources;
```

---

## 13. 참고 자료

### 13.1 공식 문서

- [Vertica Documentation](https://www.vertica.com/docs/)
- [Vertica SQL Reference](https://www.vertica.com/docs/latest/HTML/Content/Authoring/SQLReferenceManual/SQLReferenceManual.htm)
- [Vertica Administrator's Guide](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/AdministratorsGuide.htm)
- [Vertica Community Forum](https://forum.vertica.com/)

### 13.2 다운로드 및 이미지

- [Vertica Community Edition Download](https://www.vertica.com/download/vertica/community-edition/)
- [jbfavre/vertica Docker Hub](https://hub.docker.com/r/jbfavre/vertica)
- [Vertica GitHub](https://github.com/vertica)

### 13.3 학습 자료

- [Vertica Academy](https://www.vertica.com/academy/)
- [Vertica Quick Start Guide](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/GettingStartedGuide.htm)
- [Vertica Best Practices](https://www.vertica.com/docs/latest/HTML/Content/Authoring/BestPractices/BestPractices.htm)

### 13.4 비교 및 대안

**Vertica vs 다른 컬럼형 데이터베이스:**

| 특징 | Vertica | ClickHouse | DuckDB | PostgreSQL |
|------|---------|------------|---------|------------|
| 아키텍처 | MPP, Columnar | Columnar | In-process | Row-based |
| 용도 | Enterprise OLAP | 실시간 분석 | 임베디드 분석 | OLTP |
| 라이선스 | 상용/커뮤니티 | 오픈소스 | 오픈소스 | 오픈소스 |
| Docker 지원 | 제한적 | 완전 지원 | 완전 지원 | 완전 지원 |
| 데이터 영속성 | 제한적 (커뮤니티) | 완전 지원 | 완전 지원 | 완전 지원 |
| 기본 포트 | 5433 | 8123/9000 | N/A | 5432 |

**프로덕션 환경 권장:**
- Enterprise Edition 또는 공식 Vertica 설치
- ClickHouse (오픈소스 대안)
- PostgreSQL + Citus (분산 SQL)

### 13.5 GUI 도구

1. **DBeaver** (무료, 오픈소스)
   - [다운로드](https://dbeaver.io/)
   - Vertica JDBC 드라이버 지원

2. **DbVisualizer** (유료)
   - [다운로드](https://www.dbvis.com/)
   - Vertica 전용 기능 지원

3. **Vertica Management Console**
   - 브라우저: `http://localhost:5444`
   - 기본 모니터링 및 관리

### 13.6 추가 팁

**데이터 영속성 해결 방법:**
1. Docker Compose + 초기화 스크립트 (권장)
2. 정기적인 SQL 덤프 백업
3. 다른 컬럼형 DB 고려 (ClickHouse, DuckDB)
4. 프로덕션: 공식 Vertica Enterprise Edition

**개발 환경 최적화:**
- Docker 메모리: 최소 4GB 할당
- 초기화 스크립트 자동화
- 백업/복원 프로세스 문서화
- Git으로 스키마 버전 관리
