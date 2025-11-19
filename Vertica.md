# Vertica Database 설치 및 생성 절차

## Vertica 소개

Vertica는 고성능 분석 데이터베이스로, 대용량 데이터 처리와 분석에 최적화되어 있습니다. Columnar 스토리지와 MPP(Massively Parallel Processing) 아키텍처를 사용합니다.

## axcore 데이터베이스 구성 정보

- **Database Name**: axcore
- **계정(User)**: axcore
- **비밀번호**: axcore2025!
- **Storage Location**: axcore_space
- **Encoding**: UTF8

## Docker 이미지 설치 및 실행

### 중요: Vertica Docker 이미지 정보

**⚠️ 주의:** OpenText Vertica의 공식 Docker 이미지(`vertica/vertica-ce`)는 더 이상 Docker Hub에서 직접 제공되지 않습니다. 

**대안 방법:**

#### 방법 1: 커뮤니티 이미지 사용 (권장)

```cmd
docker pull jbfavre/vertica:latest
```

또는 특정 버전:

```cmd
docker pull jbfavre/vertica:12.0.4-0
```

#### 방법 2: OpenText 공식 사이트에서 다운로드

1. [Vertica Community Edition 다운로드 페이지](https://www.vertica.com/download/vertica/community-edition/) 방문
2. 계정 생성 및 로그인
3. Docker 이미지 또는 RPM/DEB 패키지 다운로드
4. 수동으로 이미지 로드:

```cmd
REM 다운로드한 이미지 로드
docker load -i vertica-ce-image.tar
```

#### 방법 3: Dockerfile로 직접 빌드

`Dockerfile` 생성 후 빌드 (고급 사용자용)

### 1. Vertica Docker 이미지 다운로드

```cmd
REM 커뮤니티 이미지 사용 (권장)
docker pull jbfavre/vertica:latest
```

### 2. 네트워크 생성 (필요시)

```cmd
docker network create dev-net
```

### 3. 데이터 디렉토리 생성

```cmd
mkdir D:\Docker\mount\vertica\data
mkdir D:\Docker\mount\vertica\config
```

### 4. Vertica 컨테이너 실행

```cmd
docker run -d ^
    -p 5433:5433 ^
    -p 5444:5444 ^
    --name vertica ^
    --network dev-net ^
    -e TZ=Asia/Seoul ^
    -v D:\Docker\mount\vertica\data:/data ^
    jbfavre/vertica:latest
```

**포트 설명:**
- **5433**: Vertica 클라이언트 연결 포트
- **5444**: Vertica Management Console 포트

### 5. 컨테이너 시작 대기

Vertica는 초기 설정에 시간이 걸립니다 (약 1-2분):

```cmd
docker logs -f vertica
```

다음 메시지가 보이면 준비 완료:
```
Vertica is now running
```

## Vertica 데이터베이스 생성 절차

### 1. Vertica 컨테이너 접속

```cmd
docker exec -it vertica /bin/bash
```

### 2. dbadmin 사용자로 전환

```bash
su - dbadmin
```

기본 비밀번호: (없음 - 엔터 키 입력)

### 3. vsql 접속 (Vertica SQL 클라이언트)

```bash
/opt/vertica/bin/vsql -U dbadmin
```

또는 외부에서 직접 접속:

```cmd
docker exec -it vertica /opt/vertica/bin/vsql -U dbadmin
```

### 4. 데이터베이스 생성

Vertica는 기본적으로 VMart 샘플 데이터베이스가 생성됩니다. 새로운 데이터베이스를 생성하려면:

```sql
-- 현재 데이터베이스 확인
SELECT database_name, node_name FROM nodes;

-- 참고: Vertica는 단일 데이터베이스 인스턴스에서 스키마로 논리적 분리
-- 별도 데이터베이스 생성은 새로운 Vertica 인스턴스가 필요
```

### 5. 스키마 생성 (데이터베이스 논리적 분리)

```sql
-- axcore 스키마 생성
CREATE SCHEMA axcore;

-- 스키마 확인
SELECT schema_name FROM v_catalog.schemata;
```

### 6. Storage Location 생성

```sql
-- axcore_space storage location 생성
CREATE LOCATION axcore_space 
    PATH '/data/axcore_space' 
    USAGE 'DATA,TEMP';

-- storage location 확인
SELECT location_path, location_usage FROM storage_locations;
```

### 7. 사용자 생성

```sql
-- axcore 사용자 생성
CREATE USER axcore IDENTIFIED BY 'axcore2025!';

-- 사용자 확인
SELECT user_name FROM users;
```

### 8. 권한 부여

```sql
-- axcore 스키마의 모든 권한을 axcore 사용자에게 부여
GRANT ALL ON SCHEMA axcore TO axcore;

-- USAGE 권한 부여
GRANT USAGE ON SCHEMA axcore TO axcore;

-- CREATE 권한 부여
GRANT CREATE ON SCHEMA axcore TO axcore;

-- 기본 스키마 설정
ALTER USER axcore SET SEARCH_PATH TO axcore, public, v_catalog, v_monitor, v_internal;

-- 리소스 풀 권한 부여
GRANT USAGE ON RESOURCE POOL general TO axcore;
```

### 9. 연결 테스트

Vertica SQL에서 나간 후 axcore 사용자로 접속:

```sql
-- 현재 세션 종료
\q
```

```bash
# axcore 사용자로 접속
/opt/vertica/bin/vsql -U axcore
```

비밀번호 입력: `axcore2025!`

또는 Docker 컨테이너 외부에서:

```cmd
docker exec -it vertica /opt/vertica/bin/vsql -U axcore
```

### 10. 확인 명령어

axcore 사용자로 접속한 상태에서:

```sql
-- 현재 사용자 확인
SELECT current_user();

-- 현재 데이터베이스 확인
SELECT current_database();

-- 현재 스키마 확인
SELECT current_schema();

-- 모든 스키마 목록
SELECT schema_name, schema_owner FROM v_catalog.schemata;

-- Storage locations 확인
SELECT location_path, location_label, location_usage 
FROM storage_locations;

-- 사용자 권한 확인
SELECT * FROM grants WHERE grantee = 'axcore';

-- 테이블 생성 테스트
CREATE TABLE axcore.test_table (
    id INT,
    name VARCHAR(100)
);

-- 테이블 확인
SELECT table_schema, table_name FROM v_catalog.tables 
WHERE table_schema = 'axcore';
```

## 전체 스크립트 (한번에 실행)

### 방법 1: SQL 파일 생성 및 실행

`init_axcore.sql` 파일 생성:

```sql
-- axcore 스키마 생성
CREATE SCHEMA IF NOT EXISTS axcore;

-- Storage location 생성
CREATE LOCATION IF NOT EXISTS axcore_space 
    PATH '/data/axcore_space' 
    USAGE 'DATA,TEMP';

-- 사용자 생성
CREATE USER IF NOT EXISTS axcore IDENTIFIED BY 'axcore2025!';

-- 권한 부여
GRANT ALL ON SCHEMA axcore TO axcore;
GRANT USAGE ON SCHEMA axcore TO axcore;
GRANT CREATE ON SCHEMA axcore TO axcore;

-- 기본 스키마 설정
ALTER USER axcore SET SEARCH_PATH TO axcore, public, v_catalog, v_monitor, v_internal;

-- 리소스 풀 권한
GRANT USAGE ON RESOURCE POOL general TO axcore;

-- 확인
SELECT 'Schema created: ' || schema_name FROM v_catalog.schemata WHERE schema_name = 'axcore';
SELECT 'User created: ' || user_name FROM users WHERE user_name = 'axcore';
```

파일을 컨테이너로 복사 및 실행:

```cmd
REM Storage location 디렉토리 생성
docker exec vertica mkdir -p /data/axcore_space

REM SQL 파일을 컨테이너로 복사
docker cp init_axcore.sql vertica:/tmp/init_axcore.sql

REM SQL 파일 실행
docker exec vertica /opt/vertica/bin/vsql -U dbadmin -f /tmp/init_axcore.sql
```

### 방법 2: 배치 파일로 자동화

`create_axcore_db.bat` 파일 생성:

```batch
@echo off
setlocal

set CONTAINER_NAME=vertica

echo Creating storage location directory...
docker exec %CONTAINER_NAME% mkdir -p /data/axcore_space

echo Creating schema...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE SCHEMA IF NOT EXISTS axcore;"

echo Creating storage location...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE LOCATION IF NOT EXISTS axcore_space PATH '/data/axcore_space' USAGE 'DATA,TEMP';"

echo Creating user...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "CREATE USER IF NOT EXISTS axcore IDENTIFIED BY 'axcore2025!';"

echo Granting privileges...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "GRANT ALL ON SCHEMA axcore TO axcore;"
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "GRANT USAGE ON SCHEMA axcore TO axcore;"
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "GRANT CREATE ON SCHEMA axcore TO axcore;"
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "ALTER USER axcore SET SEARCH_PATH TO axcore, public, v_catalog, v_monitor, v_internal;"
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U dbadmin -c "GRANT USAGE ON RESOURCE POOL general TO axcore;"

echo Database setup completed!
echo.
echo Testing connection...
docker exec %CONTAINER_NAME% /opt/vertica/bin/vsql -U axcore -w axcore2025! -c "SELECT current_user(), current_schema();"

endlocal
```

실행:

```cmd
create_axcore_db.bat
```

### 방법 3: runVertica.bat (통합 스크립트)

`runVertica.bat` 파일 생성:

```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=vertica
set NETWORK_NAME=dev-net
set CLIENT_PORT=5433
set CONSOLE_PORT=5444
set DATA_PATH=D:\Docker\mount\vertica\data

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
REM CREATE DATA DIRECTORY
REM -------------------------------
echo Checking data directory: %DATA_PATH%
if not exist "%DATA_PATH%" (
    echo Creating data directory...
    mkdir "%DATA_PATH%"
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
    -v %DATA_PATH%:/data ^
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
echo Data path: %DATA_PATH%
echo.
echo Waiting for Vertica to be ready (this may take 1-2 minutes)...
timeout /t 60 /nobreak >nul

REM -------------------------------
REM VERIFY CONTAINER STATUS
REM -------------------------------
docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Vertica is ready!
echo Connection string: vertica://dbadmin@localhost:%CLIENT_PORT%/VMart
echo Management Console: http://localhost:%CONSOLE_PORT%
echo.
echo To create axcore database, run: create_axcore_db.bat
echo.

endlocal
```

## 스키마 및 사용자 삭제 (필요시)

```sql
-- 연결된 세션 확인
SELECT user_name, session_id FROM sessions WHERE user_name = 'axcore';

-- 스키마의 모든 객체 삭제
DROP SCHEMA axcore CASCADE;

-- 사용자 삭제
DROP USER axcore;

-- Storage location 삭제
DROP LOCATION axcore_space;
```

## 문제 해결

### 1. 컨테이너가 시작되지 않는 경우

```cmd
REM 로그 확인
docker logs vertica

REM 메모리 부족 시 (최소 2GB 필요)
REM Docker Desktop Settings에서 메모리 할당 증가
```

### 2. Storage Location 디렉토리 권한 오류

```bash
docker exec -it vertica bash
su - dbadmin
mkdir -p /data/axcore_space
chmod 755 /data/axcore_space
```

### 3. 사용자가 이미 존재하는 경우

```sql
-- 사용자 존재 확인
SELECT user_name FROM users WHERE user_name = 'axcore';

-- 기존 사용자 삭제 후 재생성
DROP USER IF EXISTS axcore;
CREATE USER axcore IDENTIFIED BY 'axcore2025!';
```

### 4. 스키마가 이미 존재하는 경우

```sql
-- 스키마 존재 확인
SELECT schema_name FROM v_catalog.schemata WHERE schema_name = 'axcore';

-- 강제 삭제 후 재생성
DROP SCHEMA IF EXISTS axcore CASCADE;
CREATE SCHEMA axcore;
```

### 5. vsql 연결 오류

```cmd
REM 컨테이너 내부에서 연결
docker exec -it vertica /opt/vertica/bin/vsql -U dbadmin

REM 외부에서 연결 (ODBC/JDBC)
REM Host: localhost
REM Port: 5433
REM Database: VMart (기본 데이터베이스)
REM User: axcore
REM Password: axcore2025!
```

## Docker Compose 예제

`docker-compose.yml`:

```yaml
version: '3.8'

services:
  vertica:
    image: jbfavre/vertica:latest
    container_name: vertica-axcore
    hostname: vertica-host
    ports:
      - "5433:5433"  # Client port
      - "5444:5444"  # Management Console
    environment:
      TZ: Asia/Seoul
    volumes:
      - vertica_data:/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "/opt/vertica/bin/vsql", "-U", "dbadmin", "-c", "SELECT 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

networks:
  dev-net:
    driver: bridge

volumes:
  vertica_data:
```

`init-scripts/01-init-axcore.sh`:

```bash
#!/bin/bash
set -e

# Wait for Vertica to be ready
sleep 30

# Create storage location directory
mkdir -p /data/axcore_space

# Initialize axcore database
/opt/vertica/bin/vsql -U dbadmin <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS axcore;
    CREATE LOCATION IF NOT EXISTS axcore_space PATH '/data/axcore_space' USAGE 'DATA,TEMP';
    CREATE USER IF NOT EXISTS axcore IDENTIFIED BY 'axcore2025!';
    GRANT ALL ON SCHEMA axcore TO axcore;
    GRANT USAGE ON SCHEMA axcore TO axcore;
    GRANT CREATE ON SCHEMA axcore TO axcore;
    ALTER USER axcore SET SEARCH_PATH TO axcore, public, v_catalog, v_monitor, v_internal;
    GRANT USAGE ON RESOURCE POOL general TO axcore;
EOSQL

echo "Axcore database setup completed!"
```

실행:

```cmd
docker-compose up -d
```

## Vertica vs PostgreSQL 주요 차이점

| 특징 | Vertica | PostgreSQL |
|------|---------|------------|
| 아키텍처 | Columnar (열 기반) | Row-based (행 기반) |
| 용도 | 분석(OLAP) | 트랜잭션(OLTP) |
| 스토리지 | 압축 columnar storage | 전통적 row storage |
| 데이터베이스 구조 | 단일 DB + 다중 스키마 | 다중 DB + 다중 스키마 |
| Tablespace | Storage Locations | Tablespaces |
| 기본 포트 | 5433 | 5432 |
| 적합 워크로드 | 대용량 분석, 집계 | 트랜잭션, CRUD |

## 연결 정보

**vsql (Command Line):**
```cmd
docker exec -it vertica /opt/vertica/bin/vsql -U axcore -w axcore2025!
```

**JDBC 연결 문자열:**
```
jdbc:vertica://localhost:5433/VMart?user=axcore&password=axcore2025!
```

**ODBC 연결 정보:**
- Driver: Vertica
- Server: localhost
- Port: 5433
- Database: VMart
- User: axcore
- Password: axcore2025!

## 참고 자료

- [Vertica Documentation](https://www.vertica.com/docs/)
- [Vertica Community Edition Download](https://www.vertica.com/download/vertica/community-edition/)
- [jbfavre/vertica Docker Hub](https://hub.docker.com/r/jbfavre/vertica)
- [Vertica Community Forum](https://forum.vertica.com/)
- [Vertica SQL Reference](https://www.vertica.com/docs/latest/HTML/Content/Authoring/SQLReferenceManual/SQLReferenceManual.htm)

## 추가 정보

### Vertica 이미지 선택 가이드

**jbfavre/vertica 이미지:**
- 커뮤니티에서 관리하는 안정적인 이미지
- 여러 버전 지원 (7.x ~ 12.x)
- 테스트 및 개발 환경에 적합

**프로덕션 환경:**
- OpenText 공식 사이트에서 라이선스 버전 사용 권장
- Enterprise Edition 고려
- 공식 지원 및 패치 제공

### Docker가 아닌 설치 방법

프로덕션 환경이나 성능이 중요한 경우 네이티브 설치 권장:

```cmd
REM Windows에서는 WSL2 또는 Linux VM 필요
REM Ubuntu/Debian:
REM wget https://www.vertica.com/...
REM dpkg -i vertica_xxx.deb

REM RHEL/CentOS:
REM rpm -Uvh vertica_xxx.rpm
```
