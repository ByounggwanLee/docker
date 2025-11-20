# Docker를 활용한 MS SQL Server 설치 및 구성 가이드

## 목차
1. [MS SQL Server 소개](#1-ms-sql-server-소개)
2. [MS SQL Server Docker 이미지 다운로드](#2-ms-sql-server-docker-이미지-다운로드)
3. [MS SQL Server 컨테이너 실행](#3-ms-sql-server-컨테이너-실행)
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

## 1. MS SQL Server 소개

Microsoft SQL Server는 Microsoft에서 개발한 관계형 데이터베이스 관리 시스템(RDBMS)으로, 엔터프라이즈급 데이터 관리와 비즈니스 인텔리전스 솔루션을 제공합니다. T-SQL(Transact-SQL)을 지원하며, Windows와 Linux 환경에서 모두 실행 가능합니다.

### 1.1 axcore 데이터베이스 구성 정보

- **관리자 계정**: sa
- **관리자 비밀번호**: mssql1225!
- **Database Name**: axcore
- **계정(User)**: axcore
- **비밀번호**: axcore1225!
- **기본 Collation**: Korean_Wansung_CI_AS
- **Encoding**: UTF-8 (SQL Server 2019+)
- **기본 포트**: 1433

---

## 2. MS SQL Server Docker 이미지 다운로드

### 2.1 최신 버전 다운로드

```cmd
docker pull mcr.microsoft.com/mssql/server:2022-latest
```

### 2.2 버전 비교

| 버전 | 크기 | 설명 | 권장 용도 |
|------|------|------|-----------|
| mssql/server:2022-latest | ~1.5GB | 최신 안정 버전 | 프로덕션 환경 (권장) |
| mssql/server:2019-latest | ~1.4GB | 안정 버전 | 프로덕션 환경 |
| mssql/server:2017-latest | ~1.3GB | 이전 안정 버전 | 레거시 호환 |

**권장**: `mssql/server:2022-latest` (최신 기능 및 성능 개선)

**주요 기능 비교:**

| 기능 | SQL Server 2022 | SQL Server 2019 | SQL Server 2017 |
|------|----------------|----------------|----------------|
| UTF-8 지원 | 완전 지원 | 제한적 지원 | 미지원 |
| JSON 함수 | 확장됨 | 기본 지원 | 기본 지원 |
| 인텔리전트 쿼리 처리 | 고급 | 기본 | 제한적 |
| 컨테이너 지원 | 최적화 | 지원 | 지원 |

---

## 3. MS SQL Server 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\Mssql\data
mkdir D:\Docker\mount\Mssql\log
mkdir D:\Docker\mount\Mssql\secrets
```

### 3.2 기본 실행 명령어

#### Windows CMD
```cmd
docker run -d ^
  --name mssql-container ^
  --network dev-net ^
  --hostname mssql ^
  -e "ACCEPT_EULA=Y" ^
  -e "MSSQL_SA_PASSWORD=mssql1225!" ^
  -e "TZ=Asia/Seoul" ^
  --shm-size 1g ^
  -p 1433:1433 ^
  -v D:\Docker\mount\Mssql\data:/var/opt/mssql/data ^
  -v D:\Docker\mount\Mssql\log:/var/opt/mssql/log ^
  -v D:\Docker\mount\Mssql\secrets:/var/opt/mssql/secrets ^
  mcr.microsoft.com/mssql/server:2022-latest
```

#### Windows (PowerShell)
```powershell
docker run -d `
  --name mssql-container `
  --network dev-net `
  --hostname mssql `
  -e "ACCEPT_EULA=Y" `
  -e "MSSQL_SA_PASSWORD=mssql1225!" `
  -e "TZ=Asia/Seoul" `
  --shm-size 1g `
  -p 1433:1433 `
  -v D:\Docker\mount\Mssql\data:/var/opt/mssql/data `
  -v D:\Docker\mount\Mssql\log:/var/opt/mssql/log `
  -v D:\Docker\mount\Mssql\secrets:/var/opt/mssql/secrets `
  mcr.microsoft.com/mssql/server:2022-latest
```

#### Linux/Mac
```bash
docker run -d \
  --name mssql-container \
  --network dev-net \
  --hostname mssql \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=mssql1225!" \
  -e "TZ=Asia/Seoul" \
  --shm-size 1g \
  -p 1433:1433 \
  -v /docker/mount/Mssql/data:/var/opt/mssql/data \
  -v /docker/mount/Mssql/log:/var/opt/mssql/log \
  -v /docker/mount/Mssql/secrets:/var/opt/mssql/secrets \
  mcr.microsoft.com/mssql/server:2022-latest
```

### 3.3 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `ACCEPT_EULA` | 라이선스 동의 (Y 필수) | 필수 |
| `MSSQL_SA_PASSWORD` | SA 관리자 비밀번호 | 필수 (mssql1225!) |
| `MSSQL_PID` | 제품 에디션 (Express/Developer/Enterprise) | Developer |
| `MSSQL_COLLATION` | 기본 Collation | SQL_Latin1_General_CP1_CI_AS |
| `TZ` | 타임존 설정 | UTC |

**비밀번호 요구사항:**
- 최소 8자 이상
- 대문자, 소문자, 숫자, 특수문자 중 3가지 이상 포함

### 3.4 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/var/opt/mssql/data` | 데이터 파일 | .mdf, .ndf 파일 저장 |
| `/var/opt/mssql/log` | 로그 파일 | .ldf 파일 저장 |
| `/var/opt/mssql/secrets` | 인증서/키 | SSL 인증서 저장 |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps -a --filter "name=mssql-container"

REM 로그 확인
docker logs mssql-container

REM 실시간 로그 모니터링
docker logs -f mssql-container

REM 컨테이너 정보 확인
docker inspect mssql-container
```

---

## 4. 데이터베이스 생성 절차

### 4.1 axcore 데이터베이스 세부 구성

- **데이터베이스명**: axcore
- **Owner**: axcore
- **Collation**: Korean_Wansung_CI_AS
- **Recovery Model**: FULL (전체 복구 모드)
- **Compatibility Level**: 160 (SQL Server 2022)

### 4.2 생성 절차

#### 1. 컨테이너 접속

```cmd
REM sqlcmd로 접속
docker exec -it mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225!
```

#### 2. 데이터베이스 생성

```sql
-- axcore 데이터베이스 생성
CREATE DATABASE axcore
ON PRIMARY
(
    NAME = axcore_data,
    FILENAME = '/var/opt/mssql/data/axcore.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = axcore_log,
    FILENAME = '/var/opt/mssql/data/axcore_log.ldf',
    SIZE = 50MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10MB
)
COLLATE Korean_Wansung_CI_AS;
GO

-- 데이터베이스 확인
SELECT name, database_id, create_date, collation_name, state_desc
FROM sys.databases
WHERE name = 'axcore';
GO
```

#### 3. 사용자 생성 및 권한 부여

```sql
-- axcore 데이터베이스로 전환
USE axcore;
GO

-- SQL 로그인 생성
CREATE LOGIN axcore WITH PASSWORD = 'axcore1225!';
GO

-- 데이터베이스 사용자 생성
CREATE USER axcore FOR LOGIN axcore;
GO

-- 데이터베이스 소유자 권한 부여
ALTER ROLE db_owner ADD MEMBER axcore;
GO

-- 권한 확인
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    drm.role_principal_id,
    drm_role.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals drm_role ON drm.role_principal_id = drm_role.principal_id
WHERE dp.name = 'axcore';
GO
```

#### 4. 샘플 테이블 생성

```sql
-- 샘플 테이블 생성
CREATE TABLE dbo.Users
(
    UserId INT PRIMARY KEY IDENTITY(1,1),
    UserName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_Email UNIQUE (Email)
);
GO

-- 샘플 데이터 입력
INSERT INTO dbo.Users (UserName, Email)
VALUES ('Admin', 'admin@example.com');
GO

-- 테이블 확인
SELECT * FROM dbo.Users;
GO
```

#### 5. 종료

```sql
-- sqlcmd 종료
EXIT
```

### 4.3 전체 스크립트 (한번에 실행)

```sql
-- axcore 데이터베이스 생성
CREATE DATABASE axcore
ON PRIMARY
(
    NAME = axcore_data,
    FILENAME = '/var/opt/mssql/data/axcore.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = axcore_log,
    FILENAME = '/var/opt/mssql/data/axcore_log.ldf',
    SIZE = 50MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10MB
)
COLLATE Korean_Wansung_CI_AS;
GO

-- axcore 로그인 생성
CREATE LOGIN axcore WITH PASSWORD = 'axcore1225!';
GO

-- axcore 데이터베이스로 전환
USE axcore;
GO

-- 사용자 생성 및 권한 부여
CREATE USER axcore FOR LOGIN axcore;
ALTER ROLE db_owner ADD MEMBER axcore;
GO

-- 샘플 테이블 생성
CREATE TABLE dbo.Users
(
    UserId INT PRIMARY KEY IDENTITY(1,1),
    UserName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_Email UNIQUE (Email)
);
GO

-- 샘플 데이터
INSERT INTO dbo.Users (UserName, Email)
VALUES ('Admin', 'admin@example.com');
GO

-- 확인
SELECT 
    DB_NAME() AS CurrentDatabase,
    USER_NAME() AS CurrentUser,
    @@VERSION AS SQLServerVersion;
GO

SELECT * FROM dbo.Users;
GO
```

### 4.4 배치 파일로 자동화

`create_axcore_db.sql` 파일 생성 후:

```cmd
REM SQL 스크립트 실행
docker exec -i mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! < D:\workspace\docker\create_axcore_db.sql
```

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 호스트 | localhost (또는 Docker 호스트 IP) |
| 포트 | 1433 |
| 관리자 계정 | sa |
| 관리자 비밀번호 | mssql1225! |
| 데이터베이스 | axcore |
| 사용자 계정 | axcore |
| 사용자 비밀번호 | axcore1225! |

### 5.2 연결 문자열

#### ADO.NET (C#)
```csharp
// SA 계정으로 연결
Server=localhost,1433;Database=axcore;User Id=sa;Password=mssql1225!;TrustServerCertificate=True;

// axcore 사용자로 연결
Server=localhost,1433;Database=axcore;User Id=axcore;Password=axcore1225!;TrustServerCertificate=True;
```

#### JDBC (Java)
```java
// SA 계정
jdbc:sqlserver://localhost:1433;databaseName=axcore;user=sa;password=mssql1225!;encrypt=true;trustServerCertificate=true;

// axcore 사용자
jdbc:sqlserver://localhost:1433;databaseName=axcore;user=axcore;password=axcore1225!;encrypt=true;trustServerCertificate=true;
```

#### Python (pyodbc)
```python
import pyodbc

# SA 계정으로 연결
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=localhost,1433;'
    'DATABASE=axcore;'
    'UID=sa;'
    'PWD=mssql1225!;'
    'TrustServerCertificate=yes;'
)

# axcore 사용자로 연결
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=localhost,1433;'
    'DATABASE=axcore;'
    'UID=axcore;'
    'PWD=axcore1225!;'
    'TrustServerCertificate=yes;'
)
```

#### Node.js (mssql)
```javascript
const sql = require('mssql');

// SA 계정으로 연결
const config = {
  server: 'localhost',
  port: 1433,
  database: 'axcore',
  user: 'sa',
  password: 'mssql1225!',
  options: {
    encrypt: true,
    trustServerCertificate: true
  }
};

// axcore 사용자로 연결
const configUser = {
  server: 'localhost',
  port: 1433,
  database: 'axcore',
  user: 'axcore',
  password: 'axcore1225!',
  options: {
    encrypt: true,
    trustServerCertificate: true
  }
};

await sql.connect(config);
```

### 5.3 CLI 접속

```cmd
REM SA 계정으로 접속
docker exec -it mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225!

REM axcore 사용자로 접속
docker exec -it mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U axcore -P axcore1225! -d axcore

REM 단일 쿼리 실행
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "SELECT @@VERSION"
```

---

## 6. 백업 및 복원

### 6.1 전체 데이터베이스 백업

```cmd
REM 백업 디렉토리 생성
mkdir D:\Docker\backup\mssql

REM 전체 백업 수행
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "BACKUP DATABASE axcore TO DISK = '/var/opt/mssql/data/axcore_full.bak' WITH INIT, COMPRESSION, STATS = 10"

REM 백업 파일을 호스트로 복사
docker cp mssql-container:/var/opt/mssql/data/axcore_full.bak D:\Docker\backup\mssql\axcore_full_%date:~0,4%%date:~5,2%%date:~8,2%.bak
```

### 6.2 차등 백업

```cmd
REM 차등 백업 수행
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "BACKUP DATABASE axcore TO DISK = '/var/opt/mssql/data/axcore_diff.bak' WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10"

REM 백업 파일 복사
docker cp mssql-container:/var/opt/mssql/data/axcore_diff.bak D:\Docker\backup\mssql\axcore_diff_%date:~0,4%%date:~5,2%%date:~8,2%.bak
```

### 6.3 트랜잭션 로그 백업

```cmd
REM 로그 백업 수행
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "BACKUP LOG axcore TO DISK = '/var/opt/mssql/data/axcore_log.trn' WITH INIT, COMPRESSION, STATS = 10"

REM 백업 파일 복사
docker cp mssql-container:/var/opt/mssql/data/axcore_log.trn D:\Docker\backup\mssql\axcore_log_%date:~0,4%%date:~5,2%%date:~8,2%.trn
```

### 6.4 데이터베이스 복원

```cmd
REM 백업 파일을 컨테이너로 복사
docker cp D:\Docker\backup\mssql\axcore_full.bak mssql-container:/var/opt/mssql/data/

REM 기존 연결 종료
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "ALTER DATABASE axcore SET SINGLE_USER WITH ROLLBACK IMMEDIATE"

REM 복원 수행
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "RESTORE DATABASE axcore FROM DISK = '/var/opt/mssql/data/axcore_full.bak' WITH REPLACE, STATS = 10"

REM 다중 사용자 모드로 변경
docker exec mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225! -Q "ALTER DATABASE axcore SET MULTI_USER"
```

### 6.5 자동 백업 스크립트

`backup_mssql.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mssql-container
set BACKUP_DIR=D:\Docker\backup\mssql
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%
set SA_PASSWORD=mssql1225!

echo MS SQL Server Backup Script
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 전체 백업 수행
echo Performing full backup...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "BACKUP DATABASE axcore TO DISK = '/var/opt/mssql/data/axcore_full.bak' WITH INIT, COMPRESSION, STATS = 10"

if errorlevel 1 (
    echo Backup failed!
    exit /b 1
)

REM 백업 파일 복사
echo Copying backup file...
docker cp %CONTAINER_NAME%:/var/opt/mssql/data/axcore_full.bak "%BACKUP_DIR%\axcore_full_%DATE_STAMP%.bak"

if exist "%BACKUP_DIR%\axcore_full_%DATE_STAMP%.bak" (
    echo Backup completed successfully!
    echo Location: %BACKUP_DIR%\axcore_full_%DATE_STAMP%.bak
) else (
    echo Failed to copy backup file!
    exit /b 1
)

REM 오래된 백업 삭제 (30일 이상)
echo Cleaning old backups...
forfiles /p "%BACKUP_DIR%" /m axcore_full_*.bak /d -30 /c "cmd /c del @path" 2>nul

echo Backup process completed!
endlocal
```

---

## 7. 모니터링

### 7.1 성능 모니터링 쿼리

```sql
-- 데이터베이스 크기 확인
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2)) AS SizeMB
FROM sys.master_files
WHERE database_id = DB_ID('axcore')
GROUP BY database_id;
GO

-- 테이블 크기 확인
USE axcore;
GO

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS TotalSpaceMB,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS UsedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY t.Name, s.Name, p.Rows
ORDER BY TotalSpaceMB DESC;
GO

-- 현재 실행 중인 쿼리
SELECT 
    session_id,
    start_time,
    status,
    command,
    DB_NAME(database_id) AS DatabaseName,
    wait_type,
    wait_time,
    cpu_time,
    total_elapsed_time,
    TEXT AS QueryText
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)
WHERE session_id > 50
ORDER BY total_elapsed_time DESC;
GO

-- 대기 통계
SELECT TOP 10
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%'
ORDER BY wait_time_ms DESC;
GO
```

### 7.2 시스템 상태 확인

```sql
-- SQL Server 버전 및 에디션
SELECT 
    @@VERSION AS Version,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Edition') AS Edition;
GO

-- 데이터베이스 상태
SELECT 
    name,
    state_desc,
    recovery_model_desc,
    collation_name,
    compatibility_level
FROM sys.databases
WHERE name = 'axcore';
GO

-- 활성 연결 수
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) AS ConnectionCount
FROM sys.dm_exec_sessions
WHERE database_id IS NOT NULL
GROUP BY database_id;
GO

-- 메모리 사용량
SELECT 
    (physical_memory_in_use_kb / 1024) AS UsedMemoryMB,
    (locked_page_allocations_kb / 1024) AS LockedPagesMB,
    (total_virtual_address_space_kb / 1024) AS VirtualAddressSpaceMB,
    process_physical_memory_low,
    process_virtual_memory_low
FROM sys.dm_os_process_memory;
GO
```

### 7.3 인덱스 및 통계

```sql
-- 인덱스 사용 통계
USE axcore;
GO

SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE database_id = DB_ID('axcore')
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
GO

-- 인덱스 단편화 확인
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID('axcore'), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO
```

---

## 8. 문제 해결

### 8.1 컨테이너가 시작되지 않는 경우

```cmd
REM 로그 확인
docker logs mssql-container

REM 일반적인 문제:
REM 1. SA_PASSWORD 미설정 또는 약한 비밀번호
REM    해결: 비밀번호 요구사항 충족 (8자 이상, 대소문자+숫자+특수문자)

REM 2. ACCEPT_EULA=Y 미설정
REM    해결: 환경 변수 추가

REM 3. 메모리 부족
REM    해결: Docker Desktop Settings에서 메모리 증가 (최소 2GB)

REM 컨테이너 재시작
docker restart mssql-container
```

### 8.2 데이터베이스 연결 실패

```cmd
REM 1. 컨테이너 상태 확인
docker ps --filter "name=mssql-container"

REM 2. 포트 바인딩 확인
docker port mssql-container

REM 3. SA 비밀번호 확인
docker exec -it mssql-container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P mssql1225!

REM 4. 방화벽 확인 (Windows)
netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433
```

### 8.3 데이터베이스가 이미 존재하는 경우

```sql
-- 데이터베이스 존재 확인
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'axcore')
BEGIN
    PRINT 'Database axcore already exists'
    
    -- 삭제 후 재생성 (주의!)
    ALTER DATABASE axcore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE axcore;
END
GO
```

### 8.4 로그인이 이미 존재하는 경우

```sql
-- 로그인 존재 확인
IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'axcore')
BEGIN
    -- 로그인 삭제
    DROP LOGIN axcore;
END
GO

-- 새로 생성
CREATE LOGIN axcore WITH PASSWORD = 'axcore1225!';
GO
```

### 8.5 연결 제한 초과

```sql
-- 활성 연결 확인
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) AS ConnectionCount
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('axcore')
GROUP BY database_id;
GO

-- 특정 사용자의 연결 종료
DECLARE @session_id INT;
DECLARE session_cursor CURSOR FOR
SELECT session_id
FROM sys.dm_exec_sessions
WHERE login_name = 'axcore' AND database_id = DB_ID('axcore');

OPEN session_cursor;
FETCH NEXT FROM session_cursor INTO @session_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC('KILL ' + @session_id);
    FETCH NEXT FROM session_cursor INTO @session_id;
END

CLOSE session_cursor;
DEALLOCATE session_cursor;
GO
```

### 8.6 디스크 공간 부족

```sql
-- 데이터베이스 파일 크기 확인
SELECT 
    name,
    physical_name,
    CAST(size * 8.0 / 1024 AS DECIMAL(10,2)) AS SizeMB,
    CAST(max_size * 8.0 / 1024 AS DECIMAL(10,2)) AS MaxSizeMB
FROM sys.master_files
WHERE database_id = DB_ID('axcore');
GO

-- 로그 파일 축소
USE axcore;
GO

-- 체크포인트 생성
CHECKPOINT;
GO

-- 로그 파일 축소
DBCC SHRINKFILE (axcore_log, 50);
GO
```

---

## 9. 자동화 스크립트

### 9.1 MS SQL Server 컨테이너 실행 스크립트

`runMssql.bat`:

```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=mssql-container
set NETWORK_NAME=dev-net
set SA_PASSWORD=mssql1225!
set PORT=1433
set DATA_DIR=D:\Docker\mount\Mssql\data
set LOG_DIR=D:\Docker\mount\Mssql\log
set SECRETS_DIR=D:\Docker\mount\Mssql\secrets

echo Starting MS SQL Server Docker Container Setup...
echo.

REM -------------------------------
REM CREATE DIRECTORIES
REM -------------------------------
echo Creating data directories...
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%SECRETS_DIR%" mkdir "%SECRETS_DIR%"

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
echo Pulling MS SQL Server image...
docker pull mcr.microsoft.com/mssql/server:2022-latest

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
echo Starting MS SQL Server container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    --hostname mssql ^
    -e "ACCEPT_EULA=Y" ^
    -e "MSSQL_SA_PASSWORD=%SA_PASSWORD%" ^
    -e "TZ=Asia/Seoul" ^
    --shm-size 1g ^
    -p %PORT%:1433 ^
    -v %DATA_DIR%:/var/opt/mssql/data ^
    -v %LOG_DIR%:/var/opt/mssql/log ^
    -v %SECRETS_DIR%:/var/opt/mssql/secrets ^
    mcr.microsoft.com/mssql/server:2022-latest

if errorlevel 1 (
    echo Failed to start MS SQL Server container!
    exit /b 1
)

echo.
echo MS SQL Server container started successfully!
echo Container name: %CONTAINER_NAME%
echo Port: %PORT%
echo Data directory: %DATA_DIR%
echo.
echo Waiting for SQL Server to be ready...
timeout /t 15 /nobreak >nul

REM -------------------------------
REM VERIFY CONNECTION
REM -------------------------------
echo Testing connection...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "SELECT @@VERSION" 2>nul

if errorlevel 1 (
    echo Warning: Connection test failed. Check logs with: docker logs %CONTAINER_NAME%
) else (
    echo.
    echo MS SQL Server is ready!
    echo Connection string: Server=localhost,%PORT%;User Id=sa;Password=%SA_PASSWORD%;TrustServerCertificate=True;
)

echo.
endlocal
```

### 9.2 axcore 데이터베이스 생성 스크립트

`create_axcore_db.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mssql-container
set SA_PASSWORD=mssql1225!

echo Creating axcore database...
echo.

REM SQL 스크립트 생성
(
echo CREATE DATABASE axcore
echo ON PRIMARY
echo (
echo     NAME = axcore_data,
echo     FILENAME = '/var/opt/mssql/data/axcore.mdf',
echo     SIZE = 100MB,
echo     MAXSIZE = UNLIMITED,
echo     FILEGROWTH = 10MB
echo ^)
echo LOG ON
echo (
echo     NAME = axcore_log,
echo     FILENAME = '/var/opt/mssql/data/axcore_log.ldf',
echo     SIZE = 50MB,
echo     MAXSIZE = 2GB,
echo     FILEGROWTH = 10MB
echo ^)
echo COLLATE Korean_Wansung_CI_AS;
echo GO
echo.
echo CREATE LOGIN axcore WITH PASSWORD = 'axcore1225!';
echo GO
echo.
echo USE axcore;
echo GO
echo.
echo CREATE USER axcore FOR LOGIN axcore;
echo ALTER ROLE db_owner ADD MEMBER axcore;
echo GO
echo.
echo CREATE TABLE dbo.Users
echo (
echo     UserId INT PRIMARY KEY IDENTITY(1,1^),
echo     UserName NVARCHAR(100^) NOT NULL,
echo     Email NVARCHAR(255^) NOT NULL,
echo     CreatedAt DATETIME2 DEFAULT GETDATE(^),
echo     CONSTRAINT UQ_Email UNIQUE (Email^)
echo ^);
echo GO
echo.
echo INSERT INTO dbo.Users (UserName, Email^)
echo VALUES ('Admin', 'admin@example.com'^);
echo GO
) > create_axcore.sql

REM SQL 스크립트 실행
docker exec -i %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% < create_axcore.sql 2>nul

if errorlevel 1 (
    echo Failed to create database!
    del create_axcore.sql
    exit /b 1
)

echo.
echo Database created successfully!
echo.
echo Verifying database...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "SELECT name FROM sys.databases WHERE name = 'axcore'" 2>nul

echo.
echo Connection Information:
echo   Database: axcore
echo   User: axcore
echo   Password: axcore1225!
echo   Connection String: Server=localhost,1433;Database=axcore;User Id=axcore;Password=axcore1225!;TrustServerCertificate=True;

REM 임시 파일 삭제
del create_axcore.sql

endlocal
```

### 9.3 복원 스크립트

`restore_mssql.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mssql-container
set SA_PASSWORD=mssql1225!
set BACKUP_FILE=%1

if "%BACKUP_FILE%"=="" (
    echo Usage: restore_mssql.bat ^<backup_file.bak^>
    exit /b 1
)

if not exist "%BACKUP_FILE%" (
    echo Error: Backup file not found: %BACKUP_FILE%
    exit /b 1
)

echo Restoring from: %BACKUP_FILE%
echo.

REM 백업 파일을 컨테이너로 복사
echo Copying backup file to container...
docker cp "%BACKUP_FILE%" %CONTAINER_NAME%:/var/opt/mssql/data/restore.bak

REM 기존 연결 종료
echo Closing existing connections...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "ALTER DATABASE axcore SET SINGLE_USER WITH ROLLBACK IMMEDIATE" 2>nul

REM 복원 수행
echo Restoring database...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "RESTORE DATABASE axcore FROM DISK = '/var/opt/mssql/data/restore.bak' WITH REPLACE, STATS = 10"

if errorlevel 1 (
    echo Restore failed!
    exit /b 1
)

REM 다중 사용자 모드로 변경
echo Setting database to multi-user mode...
docker exec %CONTAINER_NAME% /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P %SA_PASSWORD% -Q "ALTER DATABASE axcore SET MULTI_USER" 2>nul

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
  mssql:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: mssql-axcore
    hostname: mssql
    restart: unless-stopped
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "mssql1225!"
      MSSQL_PID: "Developer"
      TZ: "Asia/Seoul"
    shm_size: 1g
    volumes:
      - mssql_data:/var/opt/mssql/data
      - mssql_log:/var/opt/mssql/log
      - mssql_secrets:/var/opt/mssql/secrets
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "1433:1433"
    networks:
      - dev-net
    healthcheck:
      test: ["/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "mssql1225!", "-Q", "SELECT 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

volumes:
  mssql_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Mssql\data
  mssql_log:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Mssql\log
  mssql_secrets:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Mssql\secrets

networks:
  dev-net:
    driver: bridge
```

### 10.2 초기화 스크립트

`init-scripts/01-create-axcore-db.sql`:

```sql
-- axcore 데이터베이스 생성
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'axcore')
BEGIN
    CREATE DATABASE axcore
    ON PRIMARY
    (
        NAME = axcore_data,
        FILENAME = '/var/opt/mssql/data/axcore.mdf',
        SIZE = 100MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 10MB
    )
    LOG ON
    (
        NAME = axcore_log,
        FILENAME = '/var/opt/mssql/data/axcore_log.ldf',
        SIZE = 50MB,
        MAXSIZE = 2GB,
        FILEGROWTH = 10MB
    )
    COLLATE Korean_Wansung_CI_AS;
    
    PRINT 'Database axcore created successfully';
END
ELSE
BEGIN
    PRINT 'Database axcore already exists';
END
GO

-- axcore 로그인 생성
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'axcore')
BEGIN
    CREATE LOGIN axcore WITH PASSWORD = 'axcore1225!';
    PRINT 'Login axcore created successfully';
END
ELSE
BEGIN
    PRINT 'Login axcore already exists';
END
GO

-- axcore 사용자 및 권한 설정
USE axcore;
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'axcore')
BEGIN
    CREATE USER axcore FOR LOGIN axcore;
    ALTER ROLE db_owner ADD MEMBER axcore;
    PRINT 'User axcore created and granted db_owner role';
END
ELSE
BEGIN
    PRINT 'User axcore already exists';
END
GO

-- 샘플 테이블 생성
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId INT PRIMARY KEY IDENTITY(1,1),
        UserName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NOT NULL,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT UQ_Email UNIQUE (Email)
    );
    
    INSERT INTO dbo.Users (UserName, Email)
    VALUES ('Admin', 'admin@example.com');
    
    PRINT 'Table Users created with sample data';
END
ELSE
BEGIN
    PRINT 'Table Users already exists';
END
GO
```

### 10.3 실행 방법

```cmd
REM 초기 실행
docker-compose up -d

REM 로그 확인
docker-compose logs -f mssql

REM 컨테이너 재시작
docker-compose restart mssql

REM 컨테이너 정지
docker-compose down

REM 완전 정리 (볼륨 삭제)
docker-compose down -v
```

---

## 11. 보안 설정

### 11.1 SA 계정 비밀번호 변경

```sql
-- SA 비밀번호 변경
ALTER LOGIN sa WITH PASSWORD = 'NewStrongPassword1!';
GO

-- 비밀번호 정책 확인
SELECT 
    name,
    is_policy_checked,
    is_expiration_checked
FROM sys.sql_logins
WHERE name = 'sa';
GO
```

### 11.2 사용자 권한 관리

```sql
-- 읽기 전용 사용자 생성
CREATE LOGIN readonly_user WITH PASSWORD = 'ReadOnly1225!';
GO

USE axcore;
GO

CREATE USER readonly_user FOR LOGIN readonly_user;
ALTER ROLE db_datareader ADD MEMBER readonly_user;
GO

-- 특정 테이블에만 권한 부여
CREATE LOGIN limited_user WITH PASSWORD = 'Limited1225!';
GO

USE axcore;
GO

CREATE USER limited_user FOR LOGIN limited_user;
GRANT SELECT, INSERT ON dbo.Users TO limited_user;
GO

-- 권한 확인
SELECT 
    USER_NAME(grantee_principal_id) AS UserName,
    permission_name,
    OBJECT_NAME(major_id) AS ObjectName
FROM sys.database_permissions
WHERE USER_NAME(grantee_principal_id) = 'limited_user';
GO
```

### 11.3 감사 설정

```sql
-- 서버 감사 생성
USE master;
GO

CREATE SERVER AUDIT axcore_audit
TO FILE
(
    FILEPATH = '/var/opt/mssql/data/audit/',
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10
);
GO

ALTER SERVER AUDIT axcore_audit WITH (STATE = ON);
GO

-- 데이터베이스 감사 사양 생성
USE axcore;
GO

CREATE DATABASE AUDIT SPECIFICATION axcore_db_audit
FOR SERVER AUDIT axcore_audit
ADD (SELECT, INSERT, UPDATE, DELETE ON DATABASE::axcore BY public)
WITH (STATE = ON);
GO

-- 감사 로그 조회
SELECT 
    event_time,
    session_id,
    action_id,
    statement,
    server_principal_name
FROM sys.fn_get_audit_file('/var/opt/mssql/data/audit/*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO
```

### 11.4 SSL/TLS 설정 (프로덕션 권장)

```cmd
REM 인증서 생성 (openssl 필요)
openssl req -x509 -nodes -newkey rsa:2048 -keyout mssql.key -out mssql.pem -days 365 -subj "/CN=mssql"

REM 인증서를 컨테이너로 복사
docker cp mssql.pem mssql-container:/var/opt/mssql/secrets/
docker cp mssql.key mssql-container:/var/opt/mssql/secrets/

REM 권한 설정
docker exec mssql-container bash -c "chown mssql:mssql /var/opt/mssql/secrets/mssql.* && chmod 600 /var/opt/mssql/secrets/mssql.*"
```

SQL Server 설정:
```sql
-- SSL/TLS 활성화 (재시작 필요)
EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib',
    N'Certificate',
    REG_SZ,
    N'/var/opt/mssql/secrets/mssql.pem';
GO

EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib',
    N'ForceEncryption',
    REG_DWORD,
    1;
GO
```

---

## 12. 유용한 명령어 모음

### 12.1 데이터베이스 관리

```sql
-- 모든 데이터베이스 목록
SELECT 
    name,
    database_id,
    create_date,
    state_desc,
    recovery_model_desc,
    collation_name
FROM sys.databases
ORDER BY name;
GO

-- 테이블 목록
USE axcore;
GO

SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    create_date,
    modify_date
FROM sys.tables
ORDER BY SchemaName, TableName;
GO

-- 컬럼 정보
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE object_id = OBJECT_ID('dbo.Users')
ORDER BY c.column_id;
GO

-- 인덱스 목록
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    type_desc,
    is_unique,
    is_primary_key
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Users')
ORDER BY name;
GO
```

### 12.2 성능 튜닝

```sql
-- 실행 계획 확인
SET SHOWPLAN_TEXT ON;
GO

SELECT * FROM dbo.Users WHERE UserId = 1;
GO

SET SHOWPLAN_TEXT OFF;
GO

-- 통계 정보 업데이트
UPDATE STATISTICS dbo.Users;
GO

-- 인덱스 재구성
ALTER INDEX ALL ON dbo.Users REBUILD;
GO

-- 인덱스 재구성 (온라인)
ALTER INDEX ALL ON dbo.Users REBUILD WITH (ONLINE = ON);
GO

-- 캐시 지우기 (테스트용)
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
GO
```

### 12.3 데이터 작업

```sql
-- 대량 데이터 삽입
BULK INSERT dbo.Users
FROM '/var/opt/mssql/data/users.csv'
WITH
(
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);
GO

-- 테이블 복사
SELECT * INTO dbo.Users_Backup FROM dbo.Users;
GO

-- 테이블 비우기
TRUNCATE TABLE dbo.Users_Backup;
GO

-- 테이블 삭제
DROP TABLE IF EXISTS dbo.Users_Backup;
GO

-- 데이터 내보내기 (BCP)
-- 명령 프롬프트에서 실행:
-- bcp "SELECT * FROM axcore.dbo.Users" queryout "users.csv" -S localhost,1433 -U sa -P mssql1225! -c
```

### 12.4 시스템 정보

```sql
-- SQL Server 구성 정보
SELECT 
    name,
    value,
    value_in_use,
    description
FROM sys.configurations
WHERE name IN ('max server memory (MB)', 'min server memory (MB)', 'max degree of parallelism')
ORDER BY name;
GO

-- 데이터베이스 파일 정보
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    name AS FileName,
    physical_name,
    CAST(size * 8.0 / 1024 AS DECIMAL(10,2)) AS SizeMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(10,2)) AS UsedMB
FROM sys.master_files
WHERE database_id = DB_ID('axcore')
ORDER BY type_desc;
GO

-- 트랜잭션 로그 사용량
DBCC SQLPERF(LOGSPACE);
GO

-- 잠금 정보
SELECT 
    request_session_id,
    resource_type,
    resource_database_id,
    DB_NAME(resource_database_id) AS DatabaseName,
    request_mode,
    request_status
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID('axcore');
GO
```

---

## 13. 참고 자료

### 13.1 공식 문서

- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [SQL Server on Linux](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-overview)
- [SQL Server Docker Container](https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker)
- [T-SQL Reference](https://docs.microsoft.com/en-us/sql/t-sql/language-reference)

### 13.2 다운로드 및 이미지

- [SQL Server Docker Hub](https://hub.docker.com/_/microsoft-mssql-server)
- [SQL Server Downloads](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- [SQL Server Management Studio (SSMS)](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)

### 13.3 학습 자료

- [SQL Server Tutorial](https://www.sqlservertutorial.net/)
- [Microsoft Learn - SQL Server](https://docs.microsoft.com/en-us/learn/browse/?products=sql-server)
- [SQL Server Blog](https://cloudblogs.microsoft.com/sqlserver/)

### 13.4 비교 및 대안

**SQL Server vs 다른 RDBMS:**

| 특징 | SQL Server | PostgreSQL | MySQL | Oracle |
|------|-----------|------------|-------|--------|
| 라이선스 | 상용/무료(Express) | 오픈소스 | 오픈소스 | 상용 |
| 플랫폼 | Windows/Linux | 모든 플랫폼 | 모든 플랫폼 | 모든 플랫폼 |
| T-SQL 지원 | 완전 | 부분(PL/pgSQL) | 부분 | PL/SQL |
| JSON 지원 | 우수 | 우수 | 양호 | 우수 |
| Docker 지원 | 완전 | 완전 | 완전 | 제한적 |
| 기본 포트 | 1433 | 5432 | 3306 | 1521 |

**에디션 비교:**

| 에디션 | 가격 | 메모리 제한 | CPU 제한 | 용도 |
|--------|------|-------------|----------|------|
| Express | 무료 | 1GB | 1 CPU, 4 Core | 개발/소규모 |
| Developer | 무료 | 무제한 | 무제한 | 개발/테스트 |
| Standard | 유료 | 128GB | 24 Core | 중소기업 |
| Enterprise | 유료 | 무제한 | 무제한 | 대기업 |

### 13.5 GUI 도구

1. **SQL Server Management Studio (SSMS)** (무료, Windows 전용)
   - [다운로드](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
   - 공식 관리 도구

2. **Azure Data Studio** (무료, 크로스 플랫폼)
   - [다운로드](https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio)
   - 현대적인 UI, SQL Server/PostgreSQL 지원

3. **DBeaver** (무료, 오픈소스)
   - [다운로드](https://dbeaver.io/)
   - 범용 데이터베이스 도구

4. **HeidiSQL** (무료, Windows)
   - [다운로드](https://www.heidisql.com/)
   - 경량 SQL 관리 도구

### 13.6 추가 팁

**프로덕션 환경 체크리스트:**
1. ✅ SA 계정 비밀번호 강화 및 정기 변경
2. ✅ 전용 사용자 계정 생성 (SA 직접 사용 금지)
3. ✅ 정기 백업 자동화 (전체/차등/로그)
4. ✅ 감사 로그 활성화
5. ✅ SSL/TLS 암호화 설정
6. ✅ 방화벽 규칙 설정 (포트 1433)
7. ✅ 모니터링 및 알림 설정
8. ✅ 복구 모델 설정 (FULL)
9. ✅ 정기적인 인덱스 유지보수
10. ✅ 트랜잭션 로그 관리

**개발 환경 최적화:**
- Docker 메모리: 최소 4GB 할당
- Developer Edition 사용 (무료, 전체 기능)
- 볼륨 마운트로 데이터 영속성 보장
- Docker Compose로 환경 자동화
- 초기화 스크립트로 데이터베이스 자동 생성

**성능 최적화:**
- 적절한 인덱스 설계
- 통계 정보 정기 업데이트
- 쿼리 실행 계획 분석
- 메모리 설정 최적화
- 트랜잭션 로그 관리
