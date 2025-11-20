# Docker를 활용한 MySQL 설치 및 구성 가이드

## 목차
1. [MySQL 소개](#1-mysql-소개)
2. [MySQL Docker 이미지 다운로드](#2-mysql-docker-이미지-다운로드)
3. [MySQL 컨테이너 실행](#3-mysql-컨테이너-실행)
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

## 1. MySQL 소개

MySQL은 세계에서 가장 널리 사용되는 오픈 소스 관계형 데이터베이스 관리 시스템(RDBMS)입니다. Oracle Corporation이 개발 및 지원하며, 웹 애플리케이션과 임베디드 시스템에서 특히 인기가 높습니다. LAMP(Linux, Apache, MySQL, PHP/Python/Perl) 스택의 핵심 구성 요소입니다.

### 1.1 axcore 데이터베이스 구성 정보

- **관리자 계정**: root
- **관리자 비밀번호**: mysql1225!
- **Database Name**: axcore
- **계정(User)**: axcore
- **비밀번호**: axcore1225!
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci
- **기본 포트**: 3306

---

## 2. MySQL Docker 이미지 다운로드

### 2.1 최신 버전 다운로드

```cmd
docker pull mysql:latest
```

### 2.2 버전 비교

| 버전 | 크기 | 설명 | 권장 용도 |
|------|------|------|-----------|
| mysql:latest (8.4) | ~600MB | 최신 안정 버전 | 프로덕션 환경 (권장) |
| mysql:8.0 | ~580MB | LTS 버전 | 프로덕션 환경 |
| mysql:5.7 | ~500MB | 레거시 버전 | 레거시 호환 |

**권장**: `mysql:8.0` 또는 `mysql:latest` (최신 기능 및 성능 개선)

**주요 기능 비교:**

| 기능 | MySQL 8.4 | MySQL 8.0 | MySQL 5.7 |
|------|----------|----------|----------|
| JSON 지원 | 완전 지원 | 완전 지원 | 기본 지원 |
| Window Functions | 지원 | 지원 | 미지원 |
| CTE (Common Table Expressions) | 지원 | 지원 | 미지원 |
| 성능 스키마 개선 | 최신 | 개선 | 기본 |
| utf8mb4 기본값 | 기본값 | 기본값 | utf8 |

---

## 3. MySQL 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\Mysql\data
mkdir D:\Docker\mount\Mysql\conf
```

### 3.2 기본 실행 명령어

#### Windows CMD
```cmd
docker run -d ^
  --name mysql-container ^
  --network dev-net ^
  -e MYSQL_ROOT_PASSWORD=mysql1225! ^
  -e TZ=Asia/Seoul ^
  -p 3306:3306 ^
  -v D:\Docker\mount\Mysql\data:/var/lib/mysql ^
  -v D:\Docker\mount\Mysql\conf:/etc/mysql/conf.d ^
  mysql:8.0 ^
  --character-set-server=utf8mb4 ^
  --collation-server=utf8mb4_unicode_ci
```

#### Windows (PowerShell)
```powershell
docker run -d `
  --name mysql-container `
  --network dev-net `
  -e MYSQL_ROOT_PASSWORD=mysql1225! `
  -e TZ=Asia/Seoul `
  -p 3306:3306 `
  -v D:\Docker\mount\Mysql\data:/var/lib/mysql `
  -v D:\Docker\mount\Mysql\conf:/etc/mysql/conf.d `
  mysql:8.0 `
  --character-set-server=utf8mb4 `
  --collation-server=utf8mb4_unicode_ci
```

#### Linux/Mac
```bash
docker run -d \
  --name mysql-container \
  --network dev-net \
  -e MYSQL_ROOT_PASSWORD=mysql1225! \
  -e TZ=Asia/Seoul \
  -p 3306:3306 \
  -v /docker/mount/Mysql/data:/var/lib/mysql \
  -v /docker/mount/Mysql/conf:/etc/mysql/conf.d \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci
```

### 3.3 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `MYSQL_ROOT_PASSWORD` | root 관리자 비밀번호 | 필수 (mysql1225!) |
| `MYSQL_DATABASE` | 초기 생성할 데이터베이스명 | 선택 |
| `MYSQL_USER` | 초기 생성할 사용자명 | 선택 |
| `MYSQL_PASSWORD` | 초기 사용자 비밀번호 | 선택 |
| `TZ` | 타임존 설정 | UTC |

**비밀번호 요구사항:**
- 최소 8자 이상 권장
- 특수문자 포함 권장

### 3.4 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/var/lib/mysql` | 데이터 디렉토리 | 데이터베이스 파일 저장 |
| `/etc/mysql/conf.d` | 설정 파일 디렉토리 | my.cnf 설정 파일 |
| `/var/log/mysql` | 로그 디렉토리 | 에러 로그, 슬로우 쿼리 로그 |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps -a --filter "name=mysql-container"

REM 로그 확인
docker logs mysql-container

REM 실시간 로그 모니터링
docker logs -f mysql-container

REM 컨테이너 정보 확인
docker inspect mysql-container
```

---

## 4. 데이터베이스 생성 절차

### 4.1 axcore 데이터베이스 세부 구성

- **데이터베이스명**: axcore
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci
- **사용자**: axcore
- **권한**: ALL PRIVILEGES

### 4.2 생성 절차

#### 1. 컨테이너 접속

```cmd
REM MySQL 클라이언트로 접속
docker exec -it mysql-container mysql -uroot -pmysql1225!
```

#### 2. 데이터베이스 생성

```sql
-- axcore 데이터베이스 생성
CREATE DATABASE axcore
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- 데이터베이스 확인
SHOW DATABASES;

-- 데이터베이스 정보 확인
SELECT 
    SCHEMA_NAME AS DatabaseName,
    DEFAULT_CHARACTER_SET_NAME AS CharacterSet,
    DEFAULT_COLLATION_NAME AS Collation
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'axcore';
```

#### 3. 사용자 생성 및 권한 부여

```sql
-- axcore 사용자 생성 (모든 호스트에서 접속 가능)
CREATE USER 'axcore'@'%' IDENTIFIED BY 'axcore1225!';

-- 권한 부여
GRANT ALL PRIVILEGES ON axcore.* TO 'axcore'@'%';

-- 권한 적용
FLUSH PRIVILEGES;

-- 사용자 확인
SELECT User, Host FROM mysql.user WHERE User = 'axcore';

-- 권한 확인
SHOW GRANTS FOR 'axcore'@'%';
```

#### 4. 샘플 테이블 생성

```sql
-- axcore 데이터베이스 선택
USE axcore;

-- 샘플 테이블 생성
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 샘플 데이터 입력
INSERT INTO users (user_name, email)
VALUES ('Admin', 'admin@example.com');

-- 테이블 확인
SELECT * FROM users;

-- 테이블 구조 확인
DESCRIBE users;
```

#### 5. 종료

```sql
-- MySQL 클라이언트 종료
EXIT;
```

### 4.3 전체 스크립트 (한번에 실행)

```sql
-- axcore 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS axcore
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- axcore 사용자 생성
CREATE USER IF NOT EXISTS 'axcore'@'%' IDENTIFIED BY 'axcore1225!';

-- 권한 부여
GRANT ALL PRIVILEGES ON axcore.* TO 'axcore'@'%';
FLUSH PRIVILEGES;

-- axcore 데이터베이스 선택
USE axcore;

-- 샘플 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 샘플 데이터
INSERT INTO users (user_name, email)
VALUES ('Admin', 'admin@example.com')
ON DUPLICATE KEY UPDATE user_name = 'Admin';

-- 확인
SELECT 
    DATABASE() AS CurrentDatabase,
    USER() AS CurrentUser,
    VERSION() AS MySQLVersion;

SELECT * FROM users;
```

### 4.4 배치 파일로 자동화

`create_axcore_db.sql` 파일 생성 후:

```cmd
REM SQL 스크립트 실행
docker exec -i mysql-container mysql -uroot -pmysql1225! < D:\workspace\docker\create_axcore_db.sql
```

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 호스트 | localhost (또는 Docker 호스트 IP) |
| 포트 | 3306 |
| 관리자 계정 | root |
| 관리자 비밀번호 | mysql1225! |
| 데이터베이스 | axcore |
| 사용자 계정 | axcore |
| 사용자 비밀번호 | axcore1225! |

### 5.2 연결 문자열

#### JDBC (Java)
```java
// root 계정으로 연결
jdbc:mysql://localhost:3306/axcore?user=root&password=mysql1225!&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul

// axcore 사용자로 연결
jdbc:mysql://localhost:3306/axcore?user=axcore&password=axcore1225!&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul
```

#### Python (MySQL Connector)
```python
import mysql.connector

# root 계정으로 연결
conn = mysql.connector.connect(
    host='localhost',
    port=3306,
    user='root',
    password='mysql1225!',
    database='axcore',
    charset='utf8mb4'
)

# axcore 사용자로 연결
conn = mysql.connector.connect(
    host='localhost',
    port=3306,
    user='axcore',
    password='axcore1225!',
    database='axcore',
    charset='utf8mb4'
)
```

#### Python (PyMySQL)
```python
import pymysql

# root 계정으로 연결
conn = pymysql.connect(
    host='localhost',
    port=3306,
    user='root',
    password='mysql1225!',
    database='axcore',
    charset='utf8mb4'
)

# axcore 사용자로 연결
conn = pymysql.connect(
    host='localhost',
    port=3306,
    user='axcore',
    password='axcore1225!',
    database='axcore',
    charset='utf8mb4'
)
```

#### Node.js (mysql2)
```javascript
const mysql = require('mysql2');

// root 계정으로 연결
const connection = mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'mysql1225!',
  database: 'axcore',
  charset: 'utf8mb4'
});

// axcore 사용자로 연결
const connectionUser = mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: 'axcore',
  password: 'axcore1225!',
  database: 'axcore',
  charset: 'utf8mb4'
});

connection.connect();
```

#### PHP (mysqli)
```php
<?php
// root 계정으로 연결
$conn = new mysqli('localhost', 'root', 'mysql1225!', 'axcore', 3306);

// axcore 사용자로 연결
$conn = new mysqli('localhost', 'axcore', 'axcore1225!', 'axcore', 3306);

// UTF-8 설정
$conn->set_charset('utf8mb4');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
```

### 5.3 CLI 접속

```cmd
REM root 계정으로 접속
docker exec -it mysql-container mysql -uroot -pmysql1225!

REM axcore 사용자로 접속
docker exec -it mysql-container mysql -uaxcore -paxcore1225! axcore

REM 단일 쿼리 실행
docker exec mysql-container mysql -uroot -pmysql1225! -e "SELECT VERSION()"

REM 외부 MySQL 클라이언트로 접속 (MySQL 클라이언트 설치 필요)
mysql -h localhost -P 3306 -uroot -pmysql1225!
```

---

## 6. 백업 및 복원

### 6.1 전체 데이터베이스 백업 (mysqldump)

```cmd
REM 백업 디렉토리 생성
mkdir D:\Docker\backup\mysql

REM 단일 데이터베이스 백업
docker exec mysql-container mysqldump -uroot -pmysql1225! axcore > D:\Docker\backup\mysql\axcore_%date:~0,4%%date:~5,2%%date:~8,2%.sql

REM 모든 데이터베이스 백업
docker exec mysql-container mysqldump -uroot -pmysql1225! --all-databases > D:\Docker\backup\mysql\all_databases_%date:~0,4%%date:~5,2%%date:~8,2%.sql

REM 스키마만 백업 (데이터 제외)
docker exec mysql-container mysqldump -uroot -pmysql1225! --no-data axcore > D:\Docker\backup\mysql\axcore_schema_%date:~0,4%%date:~5,2%%date:~8,2%.sql

REM 데이터만 백업 (스키마 제외)
docker exec mysql-container mysqldump -uroot -pmysql1225! --no-create-info axcore > D:\Docker\backup\mysql\axcore_data_%date:~0,4%%date:~5,2%%date:~8,2%.sql
```

### 6.2 압축 백업

```cmd
REM gzip으로 압축하여 백업
docker exec mysql-container mysqldump -uroot -pmysql1225! axcore | gzip > D:\Docker\backup\mysql\axcore_%date:~0,4%%date:~5,2%%date:~8,2%.sql.gz
```

### 6.3 특정 테이블만 백업

```cmd
REM users 테이블만 백업
docker exec mysql-container mysqldump -uroot -pmysql1225! axcore users > D:\Docker\backup\mysql\axcore_users_%date:~0,4%%date:~5,2%%date:~8,2%.sql
```

### 6.4 데이터베이스 복원

```cmd
REM 백업 파일을 컨테이너로 복사
docker cp D:\Docker\backup\mysql\axcore_backup.sql mysql-container:/tmp/

REM 데이터베이스 복원
docker exec -i mysql-container mysql -uroot -pmysql1225! axcore < D:\Docker\backup\mysql\axcore_backup.sql

REM 또는 컨테이너 내부에서 복원
docker exec mysql-container mysql -uroot -pmysql1225! axcore -e "source /tmp/axcore_backup.sql"

REM 압축된 백업 복원
gunzip < D:\Docker\backup\mysql\axcore_backup.sql.gz | docker exec -i mysql-container mysql -uroot -pmysql1225! axcore
```

### 6.5 자동 백업 스크립트

`backup_mysql.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mysql-container
set BACKUP_DIR=D:\Docker\backup\mysql
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%
set ROOT_PASSWORD=mysql1225!

echo MySQL Backup Script
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 전체 백업 수행
echo Performing full backup...
docker exec %CONTAINER_NAME% mysqldump -uroot -p%ROOT_PASSWORD% axcore > "%BACKUP_DIR%\axcore_%DATE_STAMP%.sql"

if errorlevel 1 (
    echo Backup failed!
    exit /b 1
)

REM 압축
echo Compressing backup...
powershell -Command "Compress-Archive -Path '%BACKUP_DIR%\axcore_%DATE_STAMP%.sql' -DestinationPath '%BACKUP_DIR%\axcore_%DATE_STAMP%.zip' -Force"

REM 원본 SQL 파일 삭제
del "%BACKUP_DIR%\axcore_%DATE_STAMP%.sql"

if exist "%BACKUP_DIR%\axcore_%DATE_STAMP%.zip" (
    echo Backup completed successfully!
    echo Location: %BACKUP_DIR%\axcore_%DATE_STAMP%.zip
) else (
    echo Failed to create backup!
    exit /b 1
)

REM 오래된 백업 삭제 (30일 이상)
echo Cleaning old backups...
forfiles /p "%BACKUP_DIR%" /m axcore_*.zip /d -30 /c "cmd /c del @path" 2>nul

echo Backup process completed!
endlocal
```

---

## 7. 모니터링

### 7.1 성능 모니터링 쿼리

```sql
-- 데이터베이스 크기 확인
SELECT 
    table_schema AS DatabaseName,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS SizeMB
FROM information_schema.tables
WHERE table_schema = 'axcore'
GROUP BY table_schema;

-- 테이블 크기 확인
SELECT 
    table_name AS TableName,
    table_rows AS RowCount,
    ROUND(data_length / 1024 / 1024, 2) AS DataMB,
    ROUND(index_length / 1024 / 1024, 2) AS IndexMB,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS TotalMB
FROM information_schema.tables
WHERE table_schema = 'axcore'
ORDER BY (data_length + index_length) DESC;

-- 현재 실행 중인 쿼리
SELECT 
    id,
    user,
    host,
    db,
    command,
    time,
    state,
    info
FROM information_schema.processlist
WHERE command != 'Sleep'
ORDER BY time DESC;

-- 슬로우 쿼리 확인 (슬로우 쿼리 로그 활성화 필요)
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';
```

### 7.2 시스템 상태 확인

```sql
-- MySQL 버전 및 시스템 정보
SELECT VERSION() AS Version;
SHOW VARIABLES LIKE '%version%';

-- 데이터베이스 상태
SHOW DATABASES;

-- 활성 연결 수
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- 서버 상태 정보
SHOW STATUS;

-- 전역 변수 확인
SHOW VARIABLES;

-- InnoDB 상태
SHOW ENGINE INNODB STATUS\G

-- 테이블 상태
SHOW TABLE STATUS FROM axcore;
```

### 7.3 인덱스 및 통계

```sql
-- 테이블 인덱스 확인
SHOW INDEX FROM axcore.users;

-- 인덱스 사용 통계
SELECT 
    table_schema,
    table_name,
    index_name,
    seq_in_index,
    column_name,
    cardinality
FROM information_schema.statistics
WHERE table_schema = 'axcore'
ORDER BY table_name, index_name, seq_in_index;

-- 사용되지 않는 인덱스 찾기 (Performance Schema 필요)
SELECT 
    object_schema,
    object_name,
    index_name
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE index_name IS NOT NULL
    AND count_star = 0
    AND object_schema = 'axcore'
ORDER BY object_schema, object_name;

-- 테이블 분석 및 최적화
ANALYZE TABLE axcore.users;
OPTIMIZE TABLE axcore.users;
```

---

## 8. 문제 해결

### 8.1 컨테이너가 시작되지 않는 경우

```cmd
REM 로그 확인
docker logs mysql-container

REM 일반적인 문제:
REM 1. MYSQL_ROOT_PASSWORD 미설정
REM    해결: 환경 변수 추가

REM 2. 포트 충돌 (3306)
REM    해결: 다른 포트 사용 (-p 3307:3306)

REM 3. 볼륨 권한 문제
REM    해결: Docker Desktop Settings에서 파일 공유 확인

REM 컨테이너 재시작
docker restart mysql-container
```

### 8.2 데이터베이스 연결 실패

```cmd
REM 1. 컨테이너 상태 확인
docker ps --filter "name=mysql-container"

REM 2. 포트 바인딩 확인
docker port mysql-container

REM 3. root 비밀번호 확인
docker exec -it mysql-container mysql -uroot -pmysql1225!

REM 4. 방화벽 확인 (Windows)
netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
```

### 8.3 사용자 접속 오류

```sql
-- 사용자 호스트 확인
SELECT User, Host FROM mysql.user WHERE User = 'axcore';

-- 사용자가 '%' (모든 호스트)에서 접속 가능하도록 설정
CREATE USER 'axcore'@'%' IDENTIFIED BY 'axcore1225!';
GRANT ALL PRIVILEGES ON axcore.* TO 'axcore'@'%';
FLUSH PRIVILEGES;

-- 사용자 삭제 후 재생성
DROP USER IF EXISTS 'axcore'@'%';
CREATE USER 'axcore'@'%' IDENTIFIED BY 'axcore1225!';
GRANT ALL PRIVILEGES ON axcore.* TO 'axcore'@'%';
FLUSH PRIVILEGES;
```

### 8.4 "Public Key Retrieval is not allowed" 오류

연결 문자열에 `allowPublicKeyRetrieval=true` 추가:

```
jdbc:mysql://localhost:3306/axcore?allowPublicKeyRetrieval=true&useSSL=false
```

### 8.5 Character Set 오류

```sql
-- 데이터베이스 Character Set 변경
ALTER DATABASE axcore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 테이블 Character Set 변경
ALTER TABLE users CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 서버 기본 Character Set 확인
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';
```

### 8.6 연결 제한 초과

```sql
-- 최대 연결 수 확인
SHOW VARIABLES LIKE 'max_connections';

-- 최대 연결 수 변경 (임시)
SET GLOBAL max_connections = 500;

-- 현재 연결 확인
SHOW PROCESSLIST;

-- 특정 사용자 연결 종료
KILL <process_id>;
```

### 8.7 디스크 공간 부족

```sql
-- 바이너리 로그 확인
SHOW BINARY LOGS;

-- 오래된 바이너리 로그 삭제
PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 특정 바이너리 로그까지 삭제
PURGE BINARY LOGS TO 'mysql-bin.000010';

-- InnoDB 테이블 최적화
OPTIMIZE TABLE axcore.users;
```

---

## 9. 자동화 스크립트

### 9.1 MySQL 컨테이너 실행 스크립트

`runMysql.bat`:

```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=mysql-container
set NETWORK_NAME=dev-net
set ROOT_PASSWORD=mysql1225!
set PORT=3306
set DATA_DIR=D:\Docker\mount\Mysql\data
set CONF_DIR=D:\Docker\mount\Mysql\conf

echo Starting MySQL Docker Container Setup...
echo.

REM -------------------------------
REM CREATE DIRECTORIES
REM -------------------------------
echo Creating data and config directories...
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"

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
echo Pulling MySQL image...
docker pull mysql:8.0

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
echo Starting MySQL container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e MYSQL_ROOT_PASSWORD=%ROOT_PASSWORD% ^
    -e TZ=Asia/Seoul ^
    -p %PORT%:3306 ^
    -v %DATA_DIR%:/var/lib/mysql ^
    -v %CONF_DIR%:/etc/mysql/conf.d ^
    mysql:8.0 ^
    --character-set-server=utf8mb4 ^
    --collation-server=utf8mb4_unicode_ci

if errorlevel 1 (
    echo Failed to start MySQL container!
    exit /b 1
)

echo.
echo MySQL container started successfully!
echo Container name: %CONTAINER_NAME%
echo Port: %PORT%
echo Data directory: %DATA_DIR%
echo.
echo Waiting for MySQL to be ready...
timeout /t 15 /nobreak >nul

REM -------------------------------
REM VERIFY CONNECTION
REM -------------------------------
echo Testing connection...
docker exec %CONTAINER_NAME% mysql -uroot -p%ROOT_PASSWORD% -e "SELECT VERSION()" 2>nul

if errorlevel 1 (
    echo Warning: Connection test failed. Check logs with: docker logs %CONTAINER_NAME%
) else (
    echo.
    echo MySQL is ready!
    echo Connection string: jdbc:mysql://localhost:%PORT%/axcore?user=root^&password=%ROOT_PASSWORD%
)

echo.
endlocal
```

### 9.2 axcore 데이터베이스 생성 스크립트

`create_axcore_db.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mysql-container
set ROOT_PASSWORD=mysql1225!

echo Creating axcore database...
echo.

REM SQL 스크립트 생성
(
echo CREATE DATABASE IF NOT EXISTS axcore
echo CHARACTER SET utf8mb4
echo COLLATE utf8mb4_unicode_ci;
echo.
echo CREATE USER IF NOT EXISTS 'axcore'@'%%' IDENTIFIED BY 'axcore1225!';
echo.
echo GRANT ALL PRIVILEGES ON axcore.* TO 'axcore'@'%%';
echo FLUSH PRIVILEGES;
echo.
echo USE axcore;
echo.
echo CREATE TABLE IF NOT EXISTS users (
echo     user_id INT AUTO_INCREMENT PRIMARY KEY,
echo     user_name VARCHAR(100^) NOT NULL,
echo     email VARCHAR(255^) NOT NULL UNIQUE,
echo     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
echo     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
echo     INDEX idx_email (email^)
echo ^) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
echo.
echo INSERT INTO users (user_name, email^)
echo VALUES ('Admin', 'admin@example.com'^)
echo ON DUPLICATE KEY UPDATE user_name = 'Admin';
echo.
echo SELECT DATABASE(^) AS CurrentDatabase, USER(^) AS CurrentUser, VERSION(^) AS MySQLVersion;
echo SELECT * FROM users;
) > create_axcore.sql

REM SQL 스크립트 실행
docker exec -i %CONTAINER_NAME% mysql -uroot -p%ROOT_PASSWORD% < create_axcore.sql 2>nul

if errorlevel 1 (
    echo Failed to create database!
    del create_axcore.sql
    exit /b 1
)

echo.
echo Database created successfully!
echo.
echo Verifying database...
docker exec %CONTAINER_NAME% mysql -uroot -p%ROOT_PASSWORD% -e "SHOW DATABASES LIKE 'axcore'" 2>nul

echo.
echo Connection Information:
echo   Database: axcore
echo   User: axcore
echo   Password: axcore1225!
echo   Connection String: jdbc:mysql://localhost:3306/axcore?user=axcore^&password=axcore1225!

REM 임시 파일 삭제
del create_axcore.sql

endlocal
```

### 9.3 복원 스크립트

`restore_mysql.bat`:

```batch
@echo off
setlocal

set CONTAINER_NAME=mysql-container
set ROOT_PASSWORD=mysql1225!
set BACKUP_FILE=%1

if "%BACKUP_FILE%"=="" (
    echo Usage: restore_mysql.bat ^<backup_file.sql^>
    exit /b 1
)

if not exist "%BACKUP_FILE%" (
    echo Error: Backup file not found: %BACKUP_FILE%
    exit /b 1
)

echo Restoring from: %BACKUP_FILE%
echo.

REM 백업 파일이 압축된 경우 압축 해제
if "%BACKUP_FILE:~-4%"==".zip" (
    echo Extracting backup file...
    powershell -Command "Expand-Archive -Path '%BACKUP_FILE%' -DestinationPath '%TEMP%' -Force"
    set BACKUP_FILE=%TEMP%\axcore.sql
)

REM 복원 수행
echo Restoring database...
docker exec -i %CONTAINER_NAME% mysql -uroot -p%ROOT_PASSWORD% axcore < "%BACKUP_FILE%"

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
  mysql:
    image: mysql:8.0
    container_name: mysql-axcore
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: mysql1225!
      MYSQL_DATABASE: axcore
      MYSQL_USER: axcore
      MYSQL_PASSWORD: axcore1225!
      TZ: Asia/Seoul
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --default-authentication-plugin=mysql_native_password
    volumes:
      - mysql_data:/var/lib/mysql
      - mysql_config:/etc/mysql/conf.d
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-pmysql1225!"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

volumes:
  mysql_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Mysql\data
  mysql_config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\Mysql\conf

networks:
  dev-net:
    driver: bridge
```

### 10.2 초기화 스크립트

`init-scripts/01-init-axcore-db.sql`:

```sql
-- axcore 데이터베이스는 환경 변수로 자동 생성됨
-- 추가 설정만 수행

USE axcore;

-- 샘플 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 샘플 데이터
INSERT INTO users (user_name, email)
VALUES ('Admin', 'admin@example.com')
ON DUPLICATE KEY UPDATE user_name = 'Admin';

-- 추가 테이블 생성
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_order_status (order_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 10.3 설정 파일

`conf/my.cnf`:

```ini
[mysqld]
# 기본 설정
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-authentication-plugin=mysql_native_password

# 성능 설정
max_connections=500
innodb_buffer_pool_size=1G
innodb_log_file_size=256M

# 로그 설정
slow_query_log=1
slow_query_log_file=/var/lib/mysql/slow-query.log
long_query_time=2

# 바이너리 로그 (복제 및 백업용)
log_bin=/var/lib/mysql/mysql-bin
expire_logs_days=7
max_binlog_size=100M

[client]
default-character-set=utf8mb4
```

### 10.4 실행 방법

```cmd
REM 초기 실행
docker-compose up -d

REM 로그 확인
docker-compose logs -f mysql

REM 컨테이너 재시작
docker-compose restart mysql

REM 컨테이너 정지
docker-compose down

REM 완전 정리 (볼륨 삭제)
docker-compose down -v
```

---

## 11. 보안 설정

### 11.1 root 계정 비밀번호 변경

```sql
-- root 비밀번호 변경
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewStrongPassword1!';
FLUSH PRIVILEGES;

-- MySQL 8.0+ 비밀번호 정책 확인
SHOW VARIABLES LIKE 'validate_password%';

-- 비밀번호 정책 설정
SET GLOBAL validate_password.length = 8;
SET GLOBAL validate_password.number_count = 1;
SET GLOBAL validate_password.special_char_count = 1;
```

### 11.2 사용자 권한 관리

```sql
-- 읽기 전용 사용자 생성
CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'ReadOnly1225!';
GRANT SELECT ON axcore.* TO 'readonly_user'@'%';
FLUSH PRIVILEGES;

-- 특정 테이블에만 권한 부여
CREATE USER 'limited_user'@'%' IDENTIFIED BY 'Limited1225!';
GRANT SELECT, INSERT ON axcore.users TO 'limited_user'@'%';
FLUSH PRIVILEGES;

-- 권한 확인
SHOW GRANTS FOR 'limited_user'@'%';

-- 권한 취소
REVOKE INSERT ON axcore.users FROM 'limited_user'@'%';
FLUSH PRIVILEGES;

-- 사용자 삭제
DROP USER IF EXISTS 'limited_user'@'%';
```

### 11.3 원격 접속 제한

```sql
-- localhost에서만 접속 가능한 사용자
CREATE USER 'local_user'@'localhost' IDENTIFIED BY 'LocalOnly1225!';
GRANT ALL PRIVILEGES ON axcore.* TO 'local_user'@'localhost';

-- 특정 IP에서만 접속 가능
CREATE USER 'office_user'@'192.168.1.%' IDENTIFIED BY 'Office1225!';
GRANT ALL PRIVILEGES ON axcore.* TO 'office_user'@'192.168.1.%';

-- 모든 호스트에서 접속 가능 (개발 환경)
CREATE USER 'dev_user'@'%' IDENTIFIED BY 'Dev1225!';
GRANT ALL PRIVILEGES ON axcore.* TO 'dev_user'@'%';

FLUSH PRIVILEGES;
```

### 11.4 SSL/TLS 설정 (프로덕션 권장)

```cmd
REM 인증서 생성 (컨테이너 내부)
docker exec -it mysql-container bash

mysql_ssl_rsa_setup --datadir=/var/lib/mysql

REM SSL 확인
docker exec mysql-container mysql -uroot -pmysql1225! -e "SHOW VARIABLES LIKE '%ssl%'"
```

SQL에서 SSL 요구:
```sql
-- SSL 필수 사용자 생성
CREATE USER 'secure_user'@'%' IDENTIFIED BY 'Secure1225!' REQUIRE SSL;
GRANT ALL PRIVILEGES ON axcore.* TO 'secure_user'@'%';
FLUSH PRIVILEGES;

-- SSL 상태 확인
SHOW STATUS LIKE 'Ssl_cipher';
SHOW VARIABLES LIKE 'have_ssl';
```

### 11.5 감사 로그 (Enterprise Edition)

MySQL Community Edition에서는 General Log 사용:

```sql
-- General Log 활성화 (주의: 성능 영향)
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/lib/mysql/general.log';

-- 확인
SHOW VARIABLES LIKE 'general_log%';

-- 비활성화
SET GLOBAL general_log = 'OFF';
```

---

## 12. 유용한 명령어 모음

### 12.1 데이터베이스 관리

```sql
-- 모든 데이터베이스 목록
SHOW DATABASES;

-- 데이터베이스 생성
CREATE DATABASE test_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 데이터베이스 삭제
DROP DATABASE IF EXISTS test_db;

-- 데이터베이스 선택
USE axcore;

-- 현재 데이터베이스 확인
SELECT DATABASE();

-- 모든 테이블 목록
SHOW TABLES;

-- 테이블 구조 확인
DESCRIBE users;
SHOW CREATE TABLE users;

-- 테이블 삭제
DROP TABLE IF EXISTS users;

-- 모든 사용자 목록
SELECT User, Host FROM mysql.user;
```

### 12.2 성능 튜닝

```sql
-- 쿼리 실행 계획 확인
EXPLAIN SELECT * FROM users WHERE email = 'admin@example.com';
EXPLAIN FORMAT=JSON SELECT * FROM users WHERE email = 'admin@example.com';

-- 인덱스 추가
CREATE INDEX idx_created_at ON users(created_at);

-- 인덱스 삭제
DROP INDEX idx_created_at ON users;

-- 테이블 분석
ANALYZE TABLE users;

-- 테이블 최적화
OPTIMIZE TABLE users;

-- 테이블 복구
REPAIR TABLE users;

-- 캐시 지우기
RESET QUERY CACHE;
FLUSH TABLES;

-- 서버 상태 변수 확인
SHOW STATUS LIKE 'Innodb_buffer_pool%';
SHOW STATUS LIKE 'Threads%';
SHOW STATUS LIKE 'Questions';
```

### 12.3 데이터 작업

```sql
-- 데이터 삽입
INSERT INTO users (user_name, email) VALUES ('John', 'john@example.com');

-- 여러 행 삽입
INSERT INTO users (user_name, email) VALUES 
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');

-- 중복 키 처리
INSERT INTO users (user_name, email) 
VALUES ('Admin', 'admin@example.com')
ON DUPLICATE KEY UPDATE user_name = 'Admin Updated';

-- 데이터 업데이트
UPDATE users SET user_name = 'Administrator' WHERE user_id = 1;

-- 데이터 삭제
DELETE FROM users WHERE user_id = 1;

-- 테이블 비우기
TRUNCATE TABLE users;

-- 데이터 복사
CREATE TABLE users_backup AS SELECT * FROM users;

-- CSV 파일로 내보내기
SELECT * FROM users
INTO OUTFILE '/var/lib/mysql-files/users.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- CSV 파일에서 가져오기
LOAD DATA INFILE '/var/lib/mysql-files/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### 12.4 시스템 정보

```sql
-- MySQL 버전
SELECT VERSION();

-- 서버 시간
SELECT NOW(), CURRENT_DATE(), CURRENT_TIME();

-- 시스템 변수
SHOW VARIABLES;
SHOW VARIABLES LIKE '%timeout%';
SHOW VARIABLES LIKE '%buffer%';

-- 전역 상태
SHOW GLOBAL STATUS;
SHOW GLOBAL STATUS LIKE '%connection%';

-- 프로세스 목록
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- 스토리지 엔진 확인
SHOW ENGINES;

-- 플러그인 확인
SHOW PLUGINS;

-- 문자 집합 확인
SHOW CHARACTER SET;
SHOW COLLATION;

-- 권한 확인
SHOW PRIVILEGES;
```

---

## 13. 참고 자료

### 13.1 공식 문서

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
- [MySQL Docker Container](https://hub.docker.com/_/mysql)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

### 13.2 다운로드 및 도구

- [MySQL Community Downloads](https://dev.mysql.com/downloads/)
- [MySQL Workbench](https://www.mysql.com/products/workbench/)
- [MySQL Shell](https://dev.mysql.com/downloads/shell/)

### 13.3 학습 자료

- [MySQL Tutorial](https://www.mysqltutorial.org/)
- [MySQL Performance Blog](https://www.percona.com/blog/)
- [Planet MySQL](https://planet.mysql.com/)

### 13.4 비교 및 대안

**MySQL vs 다른 RDBMS:**

| 특징 | MySQL | PostgreSQL | SQL Server | MariaDB |
|------|-------|------------|------------|---------|
| 라이선스 | GPL/상용 | 오픈소스 | 상용 | 오픈소스 |
| 성능 | 우수 (읽기) | 우수 (쓰기) | 우수 | 우수 (읽기) |
| JSON 지원 | 양호 | 우수 | 우수 | 양호 |
| 복제 | 지원 | 지원 | 지원 | 지원 |
| 클러스터 | 제한적 | 확장 가능 | 우수 | 지원 |
| 기본 포트 | 3306 | 5432 | 1433 | 3306 |

**MySQL 에디션 비교:**

| 에디션 | 가격 | 기능 | 용도 |
|--------|------|------|------|
| Community | 무료 | 기본 기능 | 개발/중소규모 |
| Standard | 유료 | 고급 관리 | 중소기업 |
| Enterprise | 유료 | 전체 기능 | 대기업 |
| Cluster | 유료 | 고가용성 | 미션 크리티컬 |

### 13.5 GUI 도구

1. **MySQL Workbench** (무료, 공식)
   - [다운로드](https://www.mysql.com/products/workbench/)
   - 데이터베이스 디자인, SQL 개발, 관리

2. **phpMyAdmin** (무료, 웹 기반)
   - [다운로드](https://www.phpmyadmin.net/)
   - 웹 브라우저에서 MySQL 관리

3. **DBeaver** (무료, 오픈소스)
   - [다운로드](https://dbeaver.io/)
   - 범용 데이터베이스 도구

4. **HeidiSQL** (무료, Windows)
   - [다운로드](https://www.heidisql.com/)
   - 경량 MySQL 관리 도구

5. **Navicat** (유료)
   - [다운로드](https://www.navicat.com/)
   - 전문적인 데이터베이스 개발 도구

### 13.6 추가 팁

**프로덕션 환경 체크리스트:**
1. ✅ root 비밀번호 강화 및 정기 변경
2. ✅ 전용 사용자 계정 생성 (root 직접 사용 금지)
3. ✅ 정기 백업 자동화 (mysqldump)
4. ✅ 슬로우 쿼리 로그 활성화 및 모니터링
5. ✅ SSL/TLS 암호화 설정
6. ✅ 방화벽 규칙 설정 (포트 3306)
7. ✅ 모니터링 및 알림 설정
8. ✅ 바이너리 로그 관리 (디스크 공간)
9. ✅ 정기적인 테이블 최적화
10. ✅ 복제 설정 (고가용성)

**개발 환경 최적화:**
- Docker 메모리: 최소 2GB 할당
- Character Set: utf8mb4 사용 (이모지 지원)
- 볼륨 마운트로 데이터 영속성 보장
- Docker Compose로 환경 자동화
- 초기화 스크립트로 데이터베이스 자동 생성

**성능 최적화:**
- 적절한 인덱스 설계
- InnoDB 버퍼 풀 크기 조정
- 쿼리 캐시 설정 (MySQL 5.7)
- 슬로우 쿼리 분석 및 최적화
- 테이블 파티셔닝 (대용량 데이터)
- 읽기 복제 설정 (부하 분산)

**보안 모범 사례:**
- 원격 root 접속 비활성화
- 최소 권한 원칙 적용
- 정기적인 보안 업데이트
- 감사 로그 활성화 (Enterprise)
- SSL 연결 강제
- 비밀번호 정책 강화
