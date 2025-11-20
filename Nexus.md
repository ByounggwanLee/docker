# Docker를 활용한 Nexus Repository 설치 및 구성 가이드

## 목차
1. [Nexus Repository 소개](#1-nexus-repository-소개)
2. [Nexus Docker 이미지 다운로드](#2-nexus-docker-이미지-다운로드)
3. [Nexus 컨테이너 실행](#3-nexus-컨테이너-실행)
4. [Repository 생성 및 구성](#4-repository-생성-및-구성)
5. [접속 정보](#5-접속-정보)
6. [백업 및 복원](#6-백업-및-복원)
7. [모니터링](#7-모니터링)
8. [문제 해결](#8-문제-해결)
9. [자동화 스크립트](#9-자동화-스크립트)
10. [Docker Compose 예제](#10-docker-compose-예제)
11. [보안 설정](#11-보안-설정)
12. [폐쇄망 구성](#12-폐쇄망-구성)
13. [참고 자료](#13-참고-자료)

---

## 1. Nexus Repository 소개

Nexus Repository Manager는 Sonatype에서 개발한 오픈소스 아티팩트 저장소 관리 도구입니다. Maven, npm, Docker, PyPI 등 다양한 형식의 패키지를 저장하고 배포할 수 있는 통합 저장소 솔루션입니다.

### 1.1 주요 특징

- **통합 저장소**: Maven, npm, Docker, PyPI, NuGet, Helm 등 다양한 포맷 지원
- **프록시 저장소**: 외부 저장소 캐싱으로 빌드 속도 향상
- **호스팅 저장소**: 내부 아티팩트 관리 및 배포
- **그룹 저장소**: 여러 저장소를 하나로 통합 관리
- **보안 관리**: Role 기반 접근 제어 (RBAC)
- **폐쇄망 지원**: 인터넷 없는 환경에서 패키지 관리

### 1.2 Repository 타입

| 타입 | 설명 | 사용 사례 |
|------|------|-----------|
| **Proxy** | 외부 저장소 프록시 | Maven Central, npm Registry 캐싱 |
| **Hosted** | 내부 아티팩트 저장 | 회사 내부 라이브러리, 빌드 산출물 |
| **Group** | 여러 저장소 통합 | 단일 엔드포인트로 여러 저장소 접근 |

### 1.3 기본 구성 정보

- **관리자 계정**: admin
- **초기 비밀번호**: /nexus-data/admin.password 파일에 저장
- **권장 비밀번호**: nexus1225!
- **기본 포트**: 8081 (컨테이너), 9083 (호스트)
- **데이터 경로**: /nexus-data

---

## 2. Nexus Docker 이미지 다운로드

### 2.1 이미지 다운로드

```cmd
REM Nexus 3 이미지 다운로드
docker pull sonatype/nexus3:latest
```

### 2.2 이미지 버전 비교

| 이미지 | 태그 | 크기 | 설명 | 권장 용도 |
|--------|------|------|------|-----------|
| sonatype/nexus3 | latest | ~600MB | 최신 Nexus 3 | 프로덕션 환경 (권장) |
| sonatype/nexus3 | 3.68.0 | ~600MB | 특정 버전 | 버전 고정 필요 시 |
| sonatype/nexus3 | 3.60.0 | ~580MB | 이전 안정 버전 | 호환성 필요 시 |

**권장**: `sonatype/nexus3:latest` (최신 기능 및 보안 패치)

**주요 버전별 기능:**

| 기능 | Nexus 3.68.x | Nexus 3.60.x | Nexus 3.50.x |
|------|-------------|-------------|-------------|
| Docker Registry | 지원 | 지원 | 지원 |
| npm Registry | 지원 | 지원 | 지원 |
| PyPI Repository | 지원 | 지원 | 지원 |
| Helm Repository | 지원 | 지원 | 제한적 |
| HA (High Availability) | Pro 버전 | Pro 버전 | Pro 버전 |

---

## 3. Nexus 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\nexus
```

### 3.2 기본 실행 명령어

#### Windows CMD
```cmd
docker run -d ^
  --name nexus ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -p 9083:8081 ^
  -v D:\Docker\mount\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

#### Windows (PowerShell)
```powershell
docker run -d `
  --name nexus `
  --network dev-net `
  -e TZ=Asia/Seoul `
  -p 9083:8081 `
  -v D:\Docker\mount\nexus:/nexus-data `
  sonatype/nexus3:latest
```

#### Linux/Mac
```bash
docker run -d \
  --name nexus \
  --network dev-net \
  -e TZ=Asia/Seoul \
  -p 9083:8081 \
  -v /docker/mount/nexus:/nexus-data \
  sonatype/nexus3:latest
```

### 3.3 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `TZ` | 타임존 설정 | UTC |
| `INSTALL4J_ADD_VM_PARAMS` | JVM 옵션 | -Xms2703m -Xmx2703m |
| `NEXUS_CONTEXT` | 컨텍스트 경로 | / |

**JVM 메모리 설정 (권장):**
```cmd
docker run -d ^
  --name nexus ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -e INSTALL4J_ADD_VM_PARAMS="-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g" ^
  -p 9083:8081 ^
  -v D:\Docker\mount\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

### 3.4 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/nexus-data` | 데이터 디렉토리 | 모든 저장소 데이터, 설정, 로그 |
| `/nexus-data/blobs` | 아티팩트 저장소 | 실제 파일 저장 위치 |
| `/nexus-data/db` | 메타데이터 DB | OrientDB 데이터베이스 |
| `/nexus-data/log` | 로그 디렉토리 | nexus.log, request.log |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps --filter "name=nexus"

REM 로그 확인
docker logs nexus

REM 실시간 로그 모니터링
docker logs -f nexus

REM 시작 완료 확인 (Started Sonatype Nexus OSS 메시지 대기)
docker logs nexus | findstr "Started Sonatype Nexus"
```

**시작 시간**: 최초 실행 시 1-3분 소요 (초기화 작업)

---

## 4. Repository 생성 및 구성

### 4.1 초기 로그인

1. 브라우저에서 `http://localhost:9083` 접속
2. 우측 상단 "Sign In" 클릭
3. 초기 비밀번호 확인:

```cmd
REM 초기 admin 비밀번호 확인
docker exec nexus cat /nexus-data/admin.password
```

4. 초기 설정 마법사 완료:
   - 새 비밀번호 설정 (권장: nexus1225!)
   - Anonymous Access 활성화 여부 선택

### 4.2 Maven Repository 생성

#### Proxy Repository (Maven Central)

1. **Settings (톱니바퀴)** → **Repository** → **Repositories**
2. **Create repository** 클릭
3. **maven2 (proxy)** 선택
4. 설정:
   - **Name**: maven-central
   - **Remote storage**: https://repo1.maven.org/maven2/
   - **Blob store**: default
5. **Create repository**

#### Hosted Repository (내부 라이브러리)

1. **Create repository** → **maven2 (hosted)**
2. 설정:
   - **Name**: maven-releases
   - **Version policy**: Release
   - **Blob store**: default
3. **Create repository**

Snapshot 저장소:
1. **Create repository** → **maven2 (hosted)**
2. 설정:
   - **Name**: maven-snapshots
   - **Version policy**: Snapshot
   - **Blob store**: default

#### Group Repository (통합)

1. **Create repository** → **maven2 (group)**
2. 설정:
   - **Name**: maven-public
   - **Member repositories**: maven-central, maven-releases, maven-snapshots
3. **Create repository**

### 4.3 npm Registry 생성

#### Proxy Repository

1. **Create repository** → **npm (proxy)**
2. 설정:
   - **Name**: npm-proxy
   - **Remote storage**: https://registry.npmjs.org
3. **Create repository**

#### Hosted Repository

1. **Create repository** → **npm (hosted)**
2. 설정:
   - **Name**: npm-private
3. **Create repository**

#### Group Repository

1. **Create repository** → **npm (group)**
2. 설정:
   - **Name**: npm-all
   - **Member repositories**: npm-proxy, npm-private

### 4.4 Docker Registry 생성

#### Hosted Repository

1. **Create repository** → **docker (hosted)**
2. 설정:
   - **Name**: docker-private
   - **HTTP**: 9084 (포트 추가 필요)
   - **Enable Docker V1 API**: 체크
3. **Create repository**

**Docker 포트 추가:**
```cmd
docker stop nexus
docker rm nexus

docker run -d ^
  --name nexus ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -p 9083:8081 ^
  -p 9084:9084 ^
  -v D:\Docker\mount\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

### 4.5 PyPI Repository 생성

#### Proxy Repository

1. **Create repository** → **pypi (proxy)**
2. 설정:
   - **Name**: pypi-proxy
   - **Remote storage**: https://pypi.org
3. **Create repository**

#### Hosted Repository

1. **Create repository** → **pypi (hosted)**
2. 설정:
   - **Name**: pypi-private

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 웹 UI | http://localhost:9083 |
| 관리자 계정 | admin |
| 관리자 비밀번호 | nexus1225! (변경 후) |
| Maven Repository | http://localhost:9083/repository/maven-public/ |
| npm Registry | http://localhost:9083/repository/npm-all/ |
| Docker Registry | localhost:9084 |

### 5.2 Maven 설정

#### settings.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>nexus1225!</password>
    </server>
    <server>
      <id>nexus-snapshots</id>
      <username>admin</username>
      <password>nexus1225!</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>http://localhost:9083/repository/maven-public/</url>
    </mirror>
  </mirrors>
  
  <profiles>
    <profile>
      <id>nexus</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
</settings>
```

#### pom.xml (배포 설정)
```xml
<distributionManagement>
  <repository>
    <id>nexus-releases</id>
    <name>Nexus Release Repository</name>
    <url>http://localhost:9083/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>nexus-snapshots</id>
    <name>Nexus Snapshot Repository</name>
    <url>http://localhost:9083/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>
```

### 5.3 npm 설정

```cmd
REM npm Registry 설정
npm config set registry http://localhost:9083/repository/npm-all/

REM 인증 설정
npm login --registry=http://localhost:9083/repository/npm-all/
Username: admin
Password: nexus1225!
Email: admin@example.com

REM .npmrc 파일 생성 (프로젝트별)
echo registry=http://localhost:9083/repository/npm-all/ > .npmrc
echo //localhost:9083/repository/npm-all/:_auth=YWRtaW46bmV4dXMxMjI1IQ== >> .npmrc

REM Base64 인코딩: admin:nexus1225!
```

### 5.4 Docker Registry 설정

```cmd
REM Docker 로그인
docker login localhost:9084
Username: admin
Password: nexus1225!

REM 이미지 태그
docker tag myapp:latest localhost:9084/myapp:latest

REM 이미지 푸시
docker push localhost:9084/myapp:latest

REM 이미지 풀
docker pull localhost:9084/myapp:latest
```

**Windows Docker Desktop 설정:**
1. Docker Desktop → Settings → Docker Engine
2. `insecure-registries` 추가:
```json
{
  "insecure-registries": ["localhost:9084"]
}
```

### 5.5 PyPI 설정

#### pip 설정
```cmd
REM pip.ini (Windows: %APPDATA%\pip\pip.ini)
[global]
index-url = http://admin:nexus1225!@localhost:9083/repository/pypi-all/simple
trusted-host = localhost
```

#### twine 배포 설정
```cmd
REM .pypirc (Windows: %USERPROFILE%\.pypirc)
[distutils]
index-servers =
    nexus

[nexus]
repository: http://localhost:9083/repository/pypi-private/
username: admin
password: nexus1225!
```

---

## 6. 백업 및 복원

### 6.1 전체 데이터 백업

```cmd
REM 백업 디렉토리 생성
mkdir D:\Docker\backup\nexus

REM Nexus 컨테이너 정지
docker stop nexus

REM 데이터 디렉토리 백업
xcopy D:\Docker\mount\nexus D:\Docker\backup\nexus\backup_%date:~0,4%%date:~5,2%%date:~8,2% /E /I /H /Y

REM Nexus 컨테이너 시작
docker start nexus
```

### 6.2 압축 백업

```cmd
REM Nexus 정지
docker stop nexus

REM 압축 백업
powershell -Command "Compress-Archive -Path 'D:\Docker\mount\nexus' -DestinationPath 'D:\Docker\backup\nexus\nexus_%date:~0,4%%date:~5,2%%date:~8,2%.zip' -Force"

REM Nexus 시작
docker start nexus
```

### 6.3 Blob Store 백업

```cmd
REM Blob Store만 백업 (대용량)
xcopy D:\Docker\mount\nexus\blobs D:\Docker\backup\nexus\blobs_%date:~0,4%%date:~5,2%%date:~8,2% /E /I /H /Y
```

### 6.4 데이터베이스 백업

Nexus는 OrientDB를 내부적으로 사용하며, 전체 데이터 디렉토리 백업으로 DB도 포함됩니다.

```cmd
REM DB 디렉토리 백업
xcopy D:\Docker\mount\nexus\db D:\Docker\backup\nexus\db_%date:~0,4%%date:~5,2%%date:~8,2% /E /I /H /Y
```

### 6.5 복원

```cmd
REM Nexus 컨테이너 정지 및 삭제
docker stop nexus
docker rm nexus

REM 기존 데이터 삭제
rmdir /S /Q D:\Docker\mount\nexus

REM 백업 복원
xcopy D:\Docker\backup\nexus\backup_20250120 D:\Docker\mount\nexus /E /I /H /Y

REM Nexus 컨테이너 재시작
docker run -d ^
  --name nexus ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -p 9083:8081 ^
  -v D:\Docker\mount\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

### 6.6 자동 백업 스크립트

`backup_nexus.bat`:
```batch
@echo off
setlocal

set CONTAINER_NAME=nexus
set BACKUP_DIR=D:\Docker\backup\nexus
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%

echo Nexus Backup Script
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Stopping Nexus...
docker stop %CONTAINER_NAME%

echo Performing backup...
powershell -Command "Compress-Archive -Path 'D:\Docker\mount\nexus' -DestinationPath '%BACKUP_DIR%\nexus_%DATE_STAMP%.zip' -Force"

if exist "%BACKUP_DIR%\nexus_%DATE_STAMP%.zip" (
    echo Backup completed successfully!
    echo Location: %BACKUP_DIR%\nexus_%DATE_STAMP%.zip
) else (
    echo Failed to create backup!
    exit /b 1
)

echo Starting Nexus...
docker start %CONTAINER_NAME%

REM 오래된 백업 삭제 (30일 이상)
echo Cleaning old backups...
forfiles /p "%BACKUP_DIR%" /m nexus_*.zip /d -30 /c "cmd /c del @path" 2>nul

echo Backup process completed!
endlocal
```

---

## 7. 모니터링

### 7.1 시스템 상태 확인

#### 웹 UI 모니터링
1. **Administration** → **System** → **Status**
2. 확인 항목:
   - Nexus Version
   - Database (OrientDB)
   - Blob Stores
   - Email Server

#### Health Check
```cmd
REM Health Check API
curl http://localhost:9083/service/rest/v1/status

REM Writable 확인
curl http://localhost:9083/service/rest/v1/status/writable

REM 자세한 상태
docker exec nexus cat /nexus-data/log/nexus.log | findstr "ERROR"
```

### 7.2 Repository 모니터링

#### Blob Store 용량 확인
1. **Administration** → **Repository** → **Blob Stores**
2. 각 Blob Store의 사용량 확인

#### Repository 통계
1. **Browse** → Repository 선택
2. Component 수, 용량 확인

### 7.3 로그 모니터링

```cmd
REM 전체 로그 확인
docker exec nexus tail -f /nexus-data/log/nexus.log

REM 에러 로그만 확인
docker exec nexus grep "ERROR" /nexus-data/log/nexus.log

REM 최근 100줄
docker exec nexus tail -100 /nexus-data/log/nexus.log

REM Request 로그
docker exec nexus tail -f /nexus-data/log/request.log
```

### 7.4 디스크 사용량 확인

```cmd
REM 컨테이너 내부 디스크 사용량
docker exec nexus df -h

REM Blob Store 크기
docker exec nexus du -sh /nexus-data/blobs

REM DB 크기
docker exec nexus du -sh /nexus-data/db

REM 전체 nexus-data 크기
docker exec nexus du -sh /nexus-data
```

### 7.5 성능 메트릭

#### JVM 모니터링
1. **Administration** → **System** → **Metrics**
2. 확인 항목:
   - Heap Memory Usage
   - Non-Heap Memory Usage
   - Thread Count
   - Garbage Collection

#### API를 통한 메트릭 조회
```cmd
REM Metrics API (인증 필요)
curl -u admin:nexus1225! http://localhost:9083/service/rest/v1/metrics
```

---

## 8. 문제 해결

### 8.1 컨테이너가 시작되지 않는 경우

```cmd
REM 로그 확인
docker logs nexus

REM 일반적인 문제:
REM 1. 메모리 부족
REM    해결: Docker Desktop 메모리 할당 증가 (최소 4GB)

REM 2. 포트 충돌 (9083)
REM    해결: 다른 포트 사용 (-p 9090:8081)

REM 3. 볼륨 권한 문제
REM    해결: Docker Desktop Settings에서 파일 공유 확인

REM 컨테이너 재시작
docker restart nexus
```

### 8.2 웹 UI 접속 불가

```cmd
REM 1. 컨테이너 상태 확인
docker ps --filter "name=nexus"

REM 2. 포트 바인딩 확인
docker port nexus

REM 3. 로그에서 "Started Sonatype Nexus" 확인
docker logs nexus | findstr "Started"

REM 4. 방화벽 확인 (Windows)
netsh advfirewall firewall add rule name="Nexus" dir=in action=allow protocol=TCP localport=9083
```

### 8.3 초기 비밀번호 분실

```cmd
REM admin.password 파일 확인
docker exec nexus cat /nexus-data/admin.password

REM 파일이 없는 경우 (이미 변경됨):
REM 1. 컨테이너 정지
docker stop nexus

REM 2. 데이터 디렉토리의 security 폴더 삭제
rmdir /S /Q D:\Docker\mount\nexus\security

REM 3. 컨테이너 재시작 (초기화)
docker start nexus

REM 4. 새로운 admin.password 파일 생성됨
```

### 8.4 Repository 접속 오류

```cmd
REM Maven 연결 테스트
curl http://localhost:9083/repository/maven-public/

REM npm 연결 테스트
curl http://localhost:9083/repository/npm-all/

REM 인증 확인
curl -u admin:nexus1225! http://localhost:9083/service/rest/v1/repositories
```

### 8.5 디스크 공간 부족

```cmd
REM Cleanup 작업 실행 (웹 UI)
REM Administration → System → Tasks → Create task → Admin - Compact blob store

REM 또는 불필요한 Component 삭제
REM Browse → Repository 선택 → Component 삭제

REM Blob Store 정리
docker exec nexus java -jar /opt/sonatype/nexus/lib/support/nexus-orient-console.jar
```

### 8.6 OrientDB 손상

```cmd
REM DB 복구 시도
docker exec -it nexus bash
cd /nexus-data/db
/opt/sonatype/nexus/bin/nexus backup

REM 백업에서 복원
docker stop nexus
rmdir /S /Q D:\Docker\mount\nexus\db
xcopy D:\Docker\backup\nexus\db_backup D:\Docker\mount\nexus\db /E /I /H /Y
docker start nexus
```

---

## 9. 자동화 스크립트

### 9.1 Nexus 실행 스크립트

`runNexus.bat`:
```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=nexus
set NETWORK_NAME=dev-net
set PORT=9083
set DOCKER_PORT=9084
set DATA_DIR=D:\Docker\mount\nexus

echo Starting Nexus Repository Docker Container Setup...
echo.

REM -------------------------------
REM CREATE DIRECTORIES
REM -------------------------------
echo Creating data directory...
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

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
echo Pulling Nexus image...
docker pull sonatype/nexus3:latest

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
echo Starting Nexus container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e TZ=Asia/Seoul ^
    -e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=2g" ^
    -p %PORT%:8081 ^
    -p %DOCKER_PORT%:9084 ^
    -v %DATA_DIR%:/nexus-data ^
    sonatype/nexus3:latest

if errorlevel 1 (
    echo Failed to start Nexus container!
    exit /b 1
)

echo.
echo Nexus container started successfully!
echo Container name: %CONTAINER_NAME%
echo Web UI: http://localhost:%PORT%
echo.
echo Waiting for Nexus to start (this may take 1-3 minutes)...
timeout /t 10 /nobreak >nul

REM -------------------------------
REM WAIT FOR NEXUS TO BE READY
REM -------------------------------
:WAIT_LOOP
docker logs %CONTAINER_NAME% 2>&1 | findstr "Started Sonatype Nexus" >nul 2>&1
if errorlevel 1 (
    echo Still starting...
    timeout /t 10 /nobreak >nul
    goto WAIT_LOOP
)

echo.
echo Nexus is ready!
echo.
echo Getting initial admin password...
docker exec %CONTAINER_NAME% cat /nexus-data/admin.password 2>nul
echo.
echo Web UI: http://localhost:%PORT%
echo Username: admin
echo Password: (see above)
echo.
echo Please change the password after first login!

endlocal
```

### 9.2 Repository 생성 스크립트

`create_repositories.sh` (Linux/Mac):
```bash
#!/bin/bash

NEXUS_URL="http://localhost:9083"
USERNAME="admin"
PASSWORD="nexus1225!"

# Maven Proxy Repository
curl -u $USERNAME:$PASSWORD -X POST "$NEXUS_URL/service/rest/v1/repositories/maven/proxy" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "maven-central",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    },
    "proxy": {
      "remoteUrl": "https://repo1.maven.org/maven2/",
      "contentMaxAge": 1440,
      "metadataMaxAge": 1440
    },
    "negativeCache": {
      "enabled": true,
      "timeToLive": 1440
    },
    "httpClient": {
      "blocked": false,
      "autoBlock": true
    },
    "maven": {
      "versionPolicy": "RELEASE",
      "layoutPolicy": "STRICT"
    }
  }'

echo "Maven Central proxy repository created"

# Maven Hosted Repository (Releases)
curl -u $USERNAME:$PASSWORD -X POST "$NEXUS_URL/service/rest/v1/repositories/maven/hosted" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "maven-releases",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW_ONCE"
    },
    "maven": {
      "versionPolicy": "RELEASE",
      "layoutPolicy": "STRICT"
    }
  }'

echo "Maven Releases repository created"

# npm Proxy Repository
curl -u $USERNAME:$PASSWORD -X POST "$NEXUS_URL/service/rest/v1/repositories/npm/proxy" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "npm-proxy",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    },
    "proxy": {
      "remoteUrl": "https://registry.npmjs.org",
      "contentMaxAge": 1440,
      "metadataMaxAge": 1440
    },
    "negativeCache": {
      "enabled": true,
      "timeToLive": 1440
    }
  }'

echo "npm proxy repository created"
```

---

## 10. Docker Compose 예제

### 10.1 docker-compose.yml

```yaml
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: unless-stopped
    environment:
      TZ: Asia/Seoul
      INSTALL4J_ADD_VM_PARAMS: "-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g"
    ports:
      - "9083:8081"
      - "9084:9084"
    volumes:
      - nexus_data:/nexus-data
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/service/rest/v1/status"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

volumes:
  nexus_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\nexus

networks:
  dev-net:
    driver: bridge
```

### 10.2 실행 방법

```cmd
REM 초기 실행
docker-compose up -d

REM 로그 확인
docker-compose logs -f nexus

REM 컨테이너 재시작
docker-compose restart nexus

REM 컨테이너 정지
docker-compose down

REM 완전 정리 (볼륨 삭제 - 주의!)
docker-compose down -v
```

---

## 11. 보안 설정

### 11.1 사용자 관리

#### 사용자 생성
1. **Administration** → **Security** → **Users**
2. **Create local user** 클릭
3. 설정:
   - **ID**: developer
   - **First name**: Developer
   - **Last name**: User
   - **Email**: developer@example.com
   - **Password**: dev1225!
   - **Status**: Active
   - **Roles**: nx-developer

#### 역할(Role) 관리
1. **Administration** → **Security** → **Roles**
2. **Create role** 클릭
3. 기본 역할:
   - **nx-admin**: 전체 관리자 권한
   - **nx-anonymous**: 익명 사용자
   - **nx-developer**: 개발자 (읽기/쓰기)
   - **nx-deployment**: 배포 전용

### 11.2 Repository 권한 설정

#### Privilege 생성
1. **Administration** → **Security** → **Privileges**
2. **Create privilege** → **Repository View**
3. 설정:
   - **Name**: maven-releases-all
   - **Repository**: maven-releases
   - **Actions**: READ, BROWSE, EDIT, ADD, DELETE

#### Role에 Privilege 할당
1. **Roles** → Role 선택
2. **Privileges** 탭에서 필요한 Privilege 추가

### 11.3 LDAP 연동

1. **Administration** → **Security** → **LDAP**
2. **Create connection** 클릭
3. 설정:
   - **Name**: company-ldap
   - **Protocol**: ldap://
   - **Hostname**: ldap.company.com
   - **Port**: 389
   - **Search base**: dc=company,dc=com
   - **Authentication method**: Simple Authentication
   - **Username**: cn=admin,dc=company,dc=com
   - **Password**: ldap_password

### 11.4 SSL/TLS 설정

#### HTTPS 활성화 (Reverse Proxy 권장)

`nginx.conf`:
```nginx
server {
    listen 443 ssl;
    server_name nexus.company.com;

    ssl_certificate /etc/nginx/ssl/nexus.crt;
    ssl_certificate_key /etc/nginx/ssl/nexus.key;

    location / {
        proxy_pass http://localhost:9083;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 11.5 Anonymous Access 비활성화

1. **Administration** → **Security** → **Anonymous Access**
2. **Allow anonymous users to access the server** 체크 해제
3. **Save**

### 11.6 Content Selectors

1. **Administration** → **Security** → **Content Selectors**
2. **Create selector** 클릭
3. 예시 (특정 그룹만 허용):
   - **Name**: allowed-groups
   - **Type**: CSEL
   - **Expression**: `coordinate.groupId =~ "^com\\.company\\..*"`

---

## 12. 폐쇄망 구성

### 12.1 폐쇄망 환경 개요

폐쇄망(Air-Gapped) 환경은 인터넷 접속이 불가능한 네트워크로, Nexus를 활용하여 외부 패키지를 관리할 수 있습니다.

**구성 요소:**
1. **인터넷 가능 환경**: 외부 패키지 다운로드 및 Nexus 백업
2. **폐쇄망 환경**: Nexus 복원 및 내부 패키지 관리

### 12.2 인터넷 환경에서 준비

#### 1단계: Nexus 설치 및 Repository 구성

```cmd
REM Nexus 설치
docker run -d ^
  --name nexus-staging ^
  -p 9083:8081 ^
  -v D:\Docker\staging\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

#### 2단계: Proxy Repository 생성 및 캐싱

1. **Maven Central Proxy** 생성
2. **npm Registry Proxy** 생성
3. **PyPI Proxy** 생성
4. **Docker Hub Proxy** 생성

#### 3단계: 패키지 다운로드 (캐싱)

**Maven 패키지:**
```cmd
REM settings.xml에 Nexus 설정 후
mvn dependency:go-offline -DexcludeGroupIds=com.yourcompany

REM 또는 특정 프로젝트 빌드
cd your-project
mvn clean install
```

**npm 패키지:**
```cmd
REM .npmrc 설정 후
npm config set registry http://localhost:9083/repository/npm-proxy/

REM 프로젝트 의존성 다운로드
cd your-project
npm install
```

**PyPI 패키지:**
```cmd
REM pip.ini 설정 후
pip download -r requirements.txt -d ./packages
pip install -r requirements.txt --no-index --find-links ./packages
```

**Docker 이미지:**
```cmd
REM Docker Registry Proxy 설정 후
docker pull localhost:9084/library/nginx:latest
docker pull localhost:9084/library/node:18
docker pull localhost:9084/library/python:3.11
```

#### 4단계: Nexus 백업

```cmd
REM Nexus 정지
docker stop nexus-staging

REM 전체 데이터 백업
powershell -Command "Compress-Archive -Path 'D:\Docker\staging\nexus' -DestinationPath 'D:\Docker\staging\nexus-airgap.zip' -Force"

REM 백업 파일을 USB 또는 외장 하드로 복사
copy D:\Docker\staging\nexus-airgap.zip E:\airgap\
```

### 12.3 폐쇄망 환경에서 구성

#### 1단계: 백업 파일 전송

```cmd
REM USB/외장 하드에서 백업 파일 복사
copy E:\airgap\nexus-airgap.zip D:\Docker\airgap\
```

#### 2단계: 백업 복원

```cmd
REM 백업 압축 해제
powershell -Command "Expand-Archive -Path 'D:\Docker\airgap\nexus-airgap.zip' -DestinationPath 'D:\Docker\mount' -Force"
```

#### 3단계: Nexus 실행

```cmd
docker run -d ^
  --name nexus ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -p 9083:8081 ^
  -p 9084:9084 ^
  -v D:\Docker\mount\nexus:/nexus-data ^
  sonatype/nexus3:latest
```

#### 4단계: Repository를 Hosted로 변경

폐쇄망에서는 Proxy Repository가 작동하지 않으므로 Hosted로 전환:

1. **Administration** → **Repository** → **Repositories**
2. Proxy Repository 삭제 (데이터는 Blob Store에 유지)
3. 동일한 이름으로 Hosted Repository 생성

**또는 Group Repository만 사용:**
- maven-public (Group) → maven-central-cached (Hosted)로 전환

### 12.4 클라이언트 설정 (폐쇄망)

#### Maven 설정
```xml
<!-- settings.xml -->
<mirrors>
  <mirror>
    <id>nexus-airgap</id>
    <mirrorOf>*</mirrorOf>
    <url>http://nexus-server:9083/repository/maven-public/</url>
  </mirror>
</mirrors>

<servers>
  <server>
    <id>nexus-airgap</id>
    <username>admin</username>
    <password>nexus1225!</password>
  </server>
</servers>
```

#### Gradle 설정

##### 프로젝트별 설정

`gradle.properties`:
```properties
# Nexus Repository 설정
nexusUrl=http://nexus-server:9083
nexusUsername=admin
nexusPassword=nexus1225!

# 오프라인 모드 (선택사항)
# org.gradle.offline=true

# 성능 최적화
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true
```

`build.gradle` (Groovy DSL):
```groovy
plugins {
    id 'java'
    id 'maven-publish'
}

repositories {
    // 폐쇄망에서는 Nexus만 사용
    maven {
        url "${nexusUrl}/repository/maven-public/"
        credentials {
            username nexusUsername
            password nexusPassword
        }
        allowInsecureProtocol = true
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web:3.2.0'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
}

// 배포 설정
publishing {
    publications {
        maven(MavenPublication) {
            from components.java
            
            groupId = 'com.example'
            artifactId = 'my-library'
            version = '1.0.0'
        }
    }
    
    repositories {
        maven {
            name = 'nexus'
            def releasesRepoUrl = "${nexusUrl}/repository/maven-releases/"
            def snapshotsRepoUrl = "${nexusUrl}/repository/maven-snapshots/"
            url = version.endsWith('SNAPSHOT') ? snapshotsRepoUrl : releasesRepoUrl
            
            credentials {
                username nexusUsername
                password nexusPassword
            }
            allowInsecureProtocol = true
        }
    }
}

// 의존성 확인 작업 추가
task checkDependencies {
    doLast {
        configurations.compileClasspath.each { println it }
    }
}
```

`build.gradle.kts` (Kotlin DSL):
```kotlin
plugins {
    java
    `maven-publish`
}

val nexusUrl: String by project
val nexusUsername: String by project
val nexusPassword: String by project

repositories {
    maven {
        url = uri("$nexusUrl/repository/maven-public/")
        credentials {
            username = nexusUsername
            password = nexusPassword
        }
        isAllowInsecureProtocol = true
    }
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web:3.2.0")
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.0")
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["java"])
            
            groupId = "com.example"
            artifactId = "my-library"
            version = "1.0.0"
        }
    }
    
    repositories {
        maven {
            name = "nexus"
            val releasesRepoUrl = "$nexusUrl/repository/maven-releases/"
            val snapshotsRepoUrl = "$nexusUrl/repository/maven-snapshots/"
            url = uri(if (version.toString().endsWith("SNAPSHOT")) snapshotsRepoUrl else releasesRepoUrl)
            
            credentials {
                username = nexusUsername
                password = nexusPassword
            }
            isAllowInsecureProtocol = true
        }
    }
}
```

`settings.gradle`:
```groovy
pluginManagement {
    repositories {
        maven {
            url "${nexusUrl}/repository/maven-public/"
            credentials {
                username nexusUsername
                password nexusPassword
            }
            allowInsecureProtocol = true
        }
    }
}

rootProject.name = 'my-project'
```

##### 전역 설정 (모든 프로젝트 적용)

**Windows**: `%USERPROFILE%\.gradle\init.gradle`  
**Linux/Mac**: `~/.gradle/init.gradle`

```groovy
allprojects {
    repositories {
        // 기존 원격 Repository 모두 제거
        all { ArtifactRepository repo ->
            if (repo instanceof MavenArtifactRepository) {
                def url = repo.url.toString()
                if (!url.startsWith('http://nexus-server') && !url.startsWith('file:')) {
                    println "Removing repository: $url"
                    remove repo
                }
            }
        }
        
        // Nexus Repository 추가
        maven {
            name = 'NexusMaven'
            url 'http://nexus-server:9083/repository/maven-public/'
            allowInsecureProtocol = true
            credentials {
                username 'admin'
                password 'nexus1225!'
            }
        }
    }
    
    buildscript {
        repositories {
            maven {
                url 'http://nexus-server:9083/repository/maven-public/'
                allowInsecureProtocol = true
                credentials {
                    username 'admin'
                    password 'nexus1225!'
                }
            }
        }
    }
}

// 플러그인 Repository 설정
settingsEvaluated { settings ->
    settings.pluginManagement {
        repositories {
            maven {
                url 'http://nexus-server:9083/repository/maven-public/'
                allowInsecureProtocol = true
                credentials {
                    username 'admin'
                    password 'nexus1225!'
                }
            }
        }
    }
}
```

##### Gradle Wrapper를 통한 배포

`gradle-wrapper.properties`:
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
# Nexus에서 Gradle 배포판 다운로드
distributionUrl=http://nexus-server:9083/repository/gradle-distributions/gradle-8.5-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

##### 오프라인 빌드

```cmd
REM 1. 의존성 다운로드 (인터넷 환경)
gradle build --refresh-dependencies

REM 2. 오프라인 빌드 (폐쇄망)
gradle build --offline

REM 또는 gradle.properties에 설정
REM org.gradle.offline=true
```

##### 의존성 사전 다운로드 스크립트

`download-dependencies.gradle`:
```groovy
// build.gradle에 추가
task downloadDependencies {
    doLast {
        configurations.each { config ->
            if (config.canBeResolved) {
                try {
                    config.resolve()
                    println "Downloaded dependencies for: ${config.name}"
                } catch (Exception e) {
                    println "Failed to resolve: ${config.name} - ${e.message}"
                }
            }
        }
    }
}
```

실행:
```cmd
REM 모든 의존성 다운로드
gradle downloadDependencies

REM 특정 구성만 다운로드
gradle dependencies --configuration compileClasspath
```

##### 검증 및 문제 해결

```cmd
REM Repository 연결 확인
gradle dependencies --refresh-dependencies

REM 캐시 정리
gradle clean cleanBuildCache
rmdir /s /q %USERPROFILE%\.gradle\caches

REM 의존성 트리 확인
gradle dependencies --configuration compileClasspath

REM 빌드 정보 확인
gradle -v
gradle properties
```

#### npm 설정
```cmd
npm config set registry http://nexus-server:9083/repository/npm-all/
npm config set strict-ssl false

REM 인증 설정
npm config set //nexus-server:9083/repository/npm-all/:_auth YWRtaW46bmV4dXMxMjI1IQ==
```

`.npmrc` (프로젝트별):
```
registry=http://nexus-server:9083/repository/npm-all/
//nexus-server:9083/repository/npm-all/:_auth=YWRtaW46bmV4dXMxMjI1IQ==
strict-ssl=false
```

#### NuGet 설정

`NuGet.config`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="Nexus-Private" value="http://nexus-server:9083/repository/nuget-all/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <Nexus-Private>
      <add key="Username" value="admin" />
      <add key="ClearTextPassword" value="nexus1225!" />
    </Nexus-Private>
  </packageSourceCredentials>
</configuration>
```

CLI 명령어:
```cmd
REM Source 추가
dotnet nuget add source http://nexus-server:9083/repository/nuget-all/index.json ^
  --name Nexus-Private ^
  --username admin ^
  --password nexus1225! ^
  --store-password-in-clear-text

REM 패키지 설치
dotnet add package PackageName --source Nexus-Private

REM 패키지 푸시
dotnet nuget push MyPackage.1.0.0.nupkg ^
  --source http://nexus-server:9083/repository/nuget-private/ ^
  --api-key admin:nexus1225!
```

#### Helm 설정

```cmd
REM Helm Repository 추가
helm repo add nexus-helm http://nexus-server:9083/repository/helm-private/ ^
  --username admin ^
  --password nexus1225!

REM Repository 목록 확인
helm repo list

REM Chart 검색
helm search repo nexus-helm

REM Chart 설치
helm install my-release nexus-helm/chart-name

REM Chart 푸시 (Helm Push Plugin 필요)
helm plugin install https://github.com/chartmuseum/helm-push
helm cm-push mychart-1.0.0.tgz nexus-helm ^
  --username admin ^
  --password nexus1225!
```

#### pip 설정
```ini
[global]
index-url = http://admin:nexus1225!@nexus-server:9083/repository/pypi-all/simple
trusted-host = nexus-server
```

#### Node.js (yarn) 설정

`.yarnrc`:
```
registry "http://nexus-server:9083/repository/npm-all/"
```

`yarn config`:
```cmd
yarn config set registry http://nexus-server:9083/repository/npm-all/
yarn config set strict-ssl false
```

### 12.5 정기 업데이트 전략

#### 방법 1: 증분 백업
```cmd
REM 인터넷 환경에서 새 패키지만 다운로드
REM 1. 날짜별로 blob 디렉토리 백업
REM 2. 폐쇄망에서 증분 복원

xcopy D:\Docker\staging\nexus\blobs D:\Docker\incremental\blobs_%date:~0,4%%date:~5,2%%date:~8,2% /E /I /H /D /Y
```

#### 방법 2: 전체 재동기화
```cmd
REM 월 1회 전체 백업 및 복원
REM 1. 인터넷 환경: 전체 백업
REM 2. 폐쇄망: 전체 복원
```

### 12.6 폐쇄망 Repository 구조

```
nexus-airgap/
├── maven-releases (Hosted) - 내부 개발 라이브러리
├── maven-snapshots (Hosted) - 내부 스냅샷
├── maven-central-cached (Hosted) - 인터넷에서 캐싱한 Maven 패키지
├── maven-public (Group) - 통합 Repository
│   ├── maven-releases
│   ├── maven-snapshots
│   └── maven-central-cached
├── npm-private (Hosted) - 내부 npm 패키지
├── npm-cached (Hosted) - 캐싱한 npm 패키지
├── npm-all (Group)
│   ├── npm-private
│   └── npm-cached
└── docker-private (Hosted) - 내부 Docker 이미지
```

### 12.7 폐쇄망 모니터링

```cmd
REM Blob Store 크기 확인
docker exec nexus du -sh /nexus-data/blobs

REM Repository 목록 확인
curl -u admin:nexus1225! http://localhost:9083/service/rest/v1/repositories

REM Component 수 확인
curl -u admin:nexus1225! "http://localhost:9083/service/rest/v1/search?repository=maven-central-cached" | grep "continuationToken"
```

### 12.8 폐쇄망 문제 해결

#### 외부 의존성 누락
```cmd
REM 1. 빌드 실패 로그에서 누락된 패키지 확인
REM 2. 인터넷 환경에서 해당 패키지 다운로드
mvn dependency:get -Dartifact=group:artifact:version

REM 3. 증분 백업 및 복원
```

#### Repository 손상
```cmd
REM Blob Store 재구축
docker exec nexus java -jar /opt/sonatype/nexus/lib/support/nexus-orient-console.jar
> rebuild-index
```

### 12.9 Docker 이미지 대량 전송

#### 인터넷 환경에서 이미지 수집

`collect-docker-images.sh`:
```bash
#!/bin/bash

# 필요한 Docker 이미지 목록
IMAGES=(
    "nginx:latest"
    "nginx:1.25"
    "node:18"
    "node:20-alpine"
    "python:3.11"
    "python:3.11-slim"
    "openjdk:17"
    "openjdk:21-jdk"
    "postgres:15"
    "mysql:8.0"
    "redis:7.2"
)

OUTPUT_DIR="./docker-images"
mkdir -p "$OUTPUT_DIR"

echo "Pulling Docker images..."
for IMAGE in "${IMAGES[@]}"; do
    echo "Pulling $IMAGE..."
    docker pull "$IMAGE"
done

echo "Saving Docker images to tar files..."
for IMAGE in "${IMAGES[@]}"; do
    FILENAME=$(echo "$IMAGE" | tr '/:' '_')
    echo "Saving $IMAGE to $FILENAME.tar..."
    docker save -o "$OUTPUT_DIR/${FILENAME}.tar" "$IMAGE"
done

echo "Creating archive..."
tar -czf docker-images-bundle.tar.gz "$OUTPUT_DIR"

echo "Docker images collected successfully!"
echo "Bundle location: docker-images-bundle.tar.gz"
```

Windows PowerShell 버전:
```powershell
# collect-docker-images.ps1
$images = @(
    "nginx:latest",
    "node:18",
    "python:3.11",
    "openjdk:17",
    "postgres:15",
    "mysql:8.0"
)

$outputDir = ".\docker-images"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Pulling Docker images..."
foreach ($image in $images) {
    Write-Host "Pulling $image..."
    docker pull $image
}

Write-Host "Saving Docker images..."
foreach ($image in $images) {
    $filename = $image -replace '[/:]', '_'
    Write-Host "Saving $image to $filename.tar..."
    docker save -o "$outputDir\$filename.tar" $image
}

Write-Host "Creating archive..."
Compress-Archive -Path $outputDir -DestinationPath "docker-images-bundle.zip" -Force

Write-Host "Docker images collected successfully!"
```

#### 폐쇄망에서 이미지 로드

`load-docker-images.sh`:
```bash
#!/bin/bash

BUNDLE_FILE="docker-images-bundle.tar.gz"
EXTRACT_DIR="./docker-images"

echo "Extracting bundle..."
tar -xzf "$BUNDLE_FILE"

echo "Loading Docker images..."
for TAR_FILE in "$EXTRACT_DIR"/*.tar; do
    echo "Loading $(basename $TAR_FILE)..."
    docker load -i "$TAR_FILE"
done

echo "Tagging and pushing to Nexus..."
NEXUS_REGISTRY="nexus-server:9084"

docker images --format "{{.Repository}}:{{.Tag}}" | while read IMAGE; do
    if [[ "$IMAGE" != "<none>:<none>" ]]; then
        NEW_TAG="${NEXUS_REGISTRY}/${IMAGE}"
        echo "Tagging $IMAGE as $NEW_TAG..."
        docker tag "$IMAGE" "$NEW_TAG"
        
        echo "Pushing $NEW_TAG..."
        docker push "$NEW_TAG"
    fi
done

echo "All images loaded and pushed to Nexus!"
```

Windows PowerShell 버전:
```powershell
# load-docker-images.ps1
param(
    [string]$NexusRegistry = "nexus-server:9084"
)

$bundleFile = ".\docker-images-bundle.zip"
$extractDir = ".\docker-images"

Write-Host "Extracting bundle..."
Expand-Archive -Path $bundleFile -DestinationPath "." -Force

Write-Host "Loading Docker images..."
Get-ChildItem -Path $extractDir -Filter "*.tar" | ForEach-Object {
    Write-Host "Loading $($_.Name)..."
    docker load -i $_.FullName
}

Write-Host "Tagging and pushing to Nexus..."
$images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -ne "<none>:<none>" }

foreach ($image in $images) {
    $newTag = "$NexusRegistry/$image"
    Write-Host "Tagging $image as $newTag..."
    docker tag $image $newTag
    
    Write-Host "Pushing $newTag..."
    docker push $newTag
}

Write-Host "All images loaded and pushed to Nexus!"
```

#### 자동화된 대량 전송

`sync-docker-images.sh`:
```bash
#!/bin/bash

SOURCE_REGISTRY="docker.io"
TARGET_REGISTRY="nexus-server:9084"
IMAGE_LIST_FILE="image-list.txt"

# image-list.txt 형식:
# library/nginx:latest
# library/node:18
# bitnami/postgresql:15

while IFS= read -r IMAGE; do
    echo "Syncing $IMAGE..."
    
    # Pull from source
    docker pull "$SOURCE_REGISTRY/$IMAGE"
    
    # Tag for target
    docker tag "$SOURCE_REGISTRY/$IMAGE" "$TARGET_REGISTRY/$IMAGE"
    
    # Push to target
    docker push "$TARGET_REGISTRY/$IMAGE"
    
    # Cleanup
    docker rmi "$SOURCE_REGISTRY/$IMAGE"
    
    echo "Synced $IMAGE successfully!"
done < "$IMAGE_LIST_FILE"
```

### 12.10 폐쇄망 네트워크 구성도

#### 구성도 1: 기본 폐쇄망 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                        인터넷 환경                                │
│                                                                   │
│  ┌──────────────┐         ┌─────────────────────────┐           │
│  │   개발자 PC   │────────▶│  Nexus Staging Server  │           │
│  │              │         │  - Proxy Repositories   │           │
│  │ - Maven      │         │  - Package Caching      │           │
│  │ - npm        │         │  - Docker Registry      │           │
│  │ - pip        │         └─────────────────────────┘           │
│  └──────────────┘                      │                         │
│                                        │                         │
│                                   [백업/전송]                    │
│                                        │                         │
│                              USB / 외장 하드                     │
│                                        │                         │
└────────────────────────────────────────┼─────────────────────────┘
                                         │
                    ═══════════════════════════════════
                           폐쇄망 경계 (Air Gap)
                    ═══════════════════════════════════
                                         │
┌────────────────────────────────────────┼─────────────────────────┐
│                        폐쇄망 환경                                │
│                                        │                         │
│                              USB / 외장 하드                     │
│                                        │                         │
│                                   [복원/설치]                    │
│                                        ▼                         │
│                          ┌─────────────────────────┐             │
│                          │  Nexus Production       │             │
│                          │  - Hosted Repositories  │             │
│                          │  - Cached Packages      │             │
│                          │  - Docker Registry      │             │
│                          └─────────────┬───────────┘             │
│                                        │                         │
│                      ┌─────────────────┼─────────────────┐       │
│                      │                 │                 │       │
│            ┌─────────▼────────┐ ┌─────▼──────┐ ┌───────▼─────┐ │
│            │  개발 서버 1       │ │  개발 서버 2│ │  빌드 서버   │ │
│            │  (Maven/Gradle)   │ │  (npm/pip) │ │  (CI/CD)    │ │
│            └───────────────────┘ └────────────┘ └─────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

#### 구성도 2: 다중 Nexus 구조 (대규모)

```
┌─────────────────────────────────────────────────────────────────┐
│                        폐쇄망 환경                                │
│                                                                   │
│                    ┌─────────────────────────┐                   │
│                    │  Nexus Master (Primary) │                   │
│                    │  - 모든 Repository 통합  │                   │
│                    │  - Docker Registry       │                   │
│                    └──────────┬──────────────┘                   │
│                               │                                   │
│         ┌─────────────────────┼─────────────────────┐            │
│         │                     │                     │            │
│  ┌──────▼────────┐    ┌──────▼────────┐    ┌──────▼────────┐   │
│  │ Nexus Mirror 1│    │ Nexus Mirror 2│    │ Nexus Mirror 3│   │
│  │ (개발팀 A)     │    │ (개발팀 B)     │    │ (운영팀)       │   │
│  └───────┬───────┘    └───────┬───────┘    └───────┬───────┘   │
│          │                    │                    │            │
│     [개발 서버들]          [개발 서버들]        [운영 서버들]    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

#### 네트워크 설정

`docker-compose-airgap.yml`:
```yaml
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus-airgap
    restart: unless-stopped
    environment:
      TZ: Asia/Seoul
      INSTALL4J_ADD_VM_PARAMS: "-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g"
    ports:
      - "9083:8081"    # HTTP
      - "9084:9084"    # Docker Registry
      - "9085:9085"    # npm Registry (optional)
    volumes:
      - nexus_data:/nexus-data
    networks:
      nexus_net:
        ipv4_address: 192.168.100.10
    extra_hosts:
      - "nexus-server:192.168.100.10"

volumes:
  nexus_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\nexus

networks:
  nexus_net:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.100.0/24
          gateway: 192.168.100.1
```

### 12.11 자동화 스크립트 (인터넷→폐쇄망)

#### 통합 자동화 스크립트

`nexus-airgap-prepare.sh`:
```bash
#!/bin/bash

# ========================================
# Nexus 폐쇄망 준비 자동화 스크립트
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/airgap-bundle"
NEXUS_CONTAINER="nexus-staging"
NEXUS_URL="http://localhost:9083"
NEXUS_USER="admin"
NEXUS_PASS="nexus1225!"

echo "======================================"
echo "Nexus 폐쇄망 준비 시작"
echo "======================================"

# 1. 디렉토리 생성
mkdir -p "$OUTPUT_DIR"/{nexus-data,docker-images,scripts,configs}

# 2. Nexus 데이터 백업
echo "Step 1: Nexus 데이터 백업..."
docker stop "$NEXUS_CONTAINER" || true
tar -czf "$OUTPUT_DIR/nexus-data/nexus-backup.tar.gz" \
    -C "$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/nexus-data"}}{{.Source}}{{end}}{{end}}' $NEXUS_CONTAINER)" .
docker start "$NEXUS_CONTAINER"

# 3. Repository 목록 추출
echo "Step 2: Repository 목록 추출..."
curl -u "$NEXUS_USER:$NEXUS_PASS" \
    "$NEXUS_URL/service/rest/v1/repositories" \
    > "$OUTPUT_DIR/configs/repositories.json"

# 4. Docker 이미지 수집
echo "Step 3: Docker 이미지 수집..."
cat > "$OUTPUT_DIR/configs/docker-images.txt" << EOF
nginx:latest
nginx:1.25-alpine
node:18
node:20-alpine
python:3.11
python:3.11-slim
openjdk:17
openjdk:21-jdk
postgres:15
mysql:8.0
redis:7.2
EOF

while IFS= read -r IMAGE; do
    echo "Pulling $IMAGE..."
    docker pull "$IMAGE"
    FILENAME=$(echo "$IMAGE" | tr '/:' '_')
    docker save -o "$OUTPUT_DIR/docker-images/${FILENAME}.tar" "$IMAGE"
done < "$OUTPUT_DIR/configs/docker-images.txt"

# 5. 설정 파일 복사
echo "Step 4: 설정 파일 생성..."

# Maven settings.xml
cat > "$OUTPUT_DIR/configs/maven-settings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>http://nexus-server:9083/repository/maven-public/</url>
    </mirror>
  </mirrors>
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>nexus1225!</password>
    </server>
  </servers>
</settings>
EOF

# Gradle init.gradle
cat > "$OUTPUT_DIR/configs/gradle-init.gradle" << 'EOF'
allprojects {
    repositories {
        all { ArtifactRepository repo ->
            if (repo instanceof MavenArtifactRepository) {
                def url = repo.url.toString()
                if (!url.startsWith('http://nexus-server')) {
                    remove repo
                }
            }
        }
        maven {
            url 'http://nexus-server:9083/repository/maven-public/'
            allowInsecureProtocol = true
        }
    }
}
EOF

# npm .npmrc
cat > "$OUTPUT_DIR/configs/npmrc" << 'EOF'
registry=http://nexus-server:9083/repository/npm-all/
strict-ssl=false
EOF

# 6. 복원 스크립트 생성
cat > "$OUTPUT_DIR/scripts/restore-nexus.sh" << 'RESTORE_EOF'
#!/bin/bash
set -e

echo "Nexus 폐쇄망 복원 스크립트"

# Nexus 데이터 복원
echo "Nexus 데이터 복원 중..."
tar -xzf nexus-data/nexus-backup.tar.gz -C /nexus-restore

# Nexus 컨테이너 시작
docker run -d \
  --name nexus \
  --network dev-net \
  -e TZ=Asia/Seoul \
  -p 9083:8081 \
  -p 9084:9084 \
  -v /nexus-restore:/nexus-data \
  sonatype/nexus3:latest

echo "Nexus 시작 대기 중..."
until curl -f http://localhost:9083 2>/dev/null; do
    sleep 5
done

# Docker 이미지 로드
echo "Docker 이미지 로드 중..."
for TAR_FILE in docker-images/*.tar; do
    echo "Loading $TAR_FILE..."
    docker load -i "$TAR_FILE"
done

# Docker 이미지 Nexus에 푸시
echo "Docker 이미지 Nexus에 푸시 중..."
docker login localhost:9084 -u admin -p nexus1225!

docker images --format "{{.Repository}}:{{.Tag}}" | \
while read IMAGE; do
    if [[ "$IMAGE" != "<none>:<none>" ]]; then
        NEW_TAG="localhost:9084/${IMAGE}"
        docker tag "$IMAGE" "$NEW_TAG"
        docker push "$NEW_TAG"
    fi
done

echo "복원 완료!"
RESTORE_EOF

chmod +x "$OUTPUT_DIR/scripts/restore-nexus.sh"

# 7. 최종 번들 생성
echo "Step 5: 최종 번들 생성..."
tar -czf "nexus-airgap-bundle-$(date +%Y%m%d).tar.gz" -C "$OUTPUT_DIR" .

echo ""
echo "======================================"
echo "폐쇄망 준비 완료!"
echo "======================================"
echo "번들 파일: nexus-airgap-bundle-$(date +%Y%m%d).tar.gz"
echo ""
echo "폐쇄망에서 실행:"
echo "1. 번들 파일 전송"
echo "2. tar -xzf nexus-airgap-bundle-*.tar.gz"
echo "3. cd scripts && ./restore-nexus.sh"
```

Windows PowerShell 버전:

`nexus-airgap-prepare.ps1`:
```powershell
# Nexus 폐쇄망 준비 자동화 스크립트 (Windows)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$OutputDir = "$ScriptDir\airgap-bundle"
$NexusContainer = "nexus-staging"
$NexusUrl = "http://localhost:9083"
$NexusUser = "admin"
$NexusPass = "nexus1225!"

Write-Host "======================================"
Write-Host "Nexus 폐쇄망 준비 시작"
Write-Host "======================================"

# 1. 디렉토리 생성
New-Item -ItemType Directory -Force -Path "$OutputDir\nexus-data" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\docker-images" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputDir\configs" | Out-Null

# 2. Nexus 데이터 백업
Write-Host "Step 1: Nexus 데이터 백업..."
docker stop $NexusContainer 2>$null
$nexusMount = docker inspect -f '{{range .Mounts}}{{if eq .Destination "/nexus-data"}}{{.Source}}{{end}}{{end}}' $NexusContainer
Compress-Archive -Path "$nexusMount\*" -DestinationPath "$OutputDir\nexus-data\nexus-backup.zip" -Force
docker start $NexusContainer

# 3. Repository 목록 추출
Write-Host "Step 2: Repository 목록 추출..."
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${NexusUser}:${NexusPass}"))
Invoke-RestMethod -Uri "$NexusUrl/service/rest/v1/repositories" `
    -Headers @{Authorization = "Basic $credentials"} `
    -OutFile "$OutputDir\configs\repositories.json"

# 4. Docker 이미지 수집
Write-Host "Step 3: Docker 이미지 수집..."
$images = @(
    "nginx:latest",
    "node:18",
    "python:3.11",
    "openjdk:17",
    "postgres:15",
    "mysql:8.0",
    "redis:7.2"
)

foreach ($image in $images) {
    Write-Host "Pulling $image..."
    docker pull $image
    $filename = $image -replace '[/:]', '_'
    docker save -o "$OutputDir\docker-images\$filename.tar" $image
}

# 5. 설정 파일 생성
Write-Host "Step 4: 설정 파일 생성..."

# Maven settings.xml
@'
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>http://nexus-server:9083/repository/maven-public/</url>
    </mirror>
  </mirrors>
</settings>
'@ | Out-File -FilePath "$OutputDir\configs\maven-settings.xml" -Encoding UTF8

# npm .npmrc
@'
registry=http://nexus-server:9083/repository/npm-all/
strict-ssl=false
'@ | Out-File -FilePath "$OutputDir\configs\npmrc" -Encoding UTF8

# 6. 복원 스크립트 생성
@'
# Nexus 폐쇄망 복원 스크립트 (Windows)
Write-Host "Nexus 폐쇄망 복원 시작..."

# Nexus 데이터 복원
Expand-Archive -Path "nexus-data\nexus-backup.zip" -DestinationPath "D:\Docker\mount\nexus" -Force

# Nexus 컨테이너 시작
docker run -d `
  --name nexus `
  -p 9083:8081 `
  -p 9084:9084 `
  -v D:\Docker\mount\nexus:/nexus-data `
  sonatype/nexus3:latest

Write-Host "Nexus 시작 대기 중..."
Start-Sleep -Seconds 60

# Docker 이미지 로드
Get-ChildItem -Path "docker-images\*.tar" | ForEach-Object {
    Write-Host "Loading $($_.Name)..."
    docker load -i $_.FullName
}

Write-Host "복원 완료!"
'@ | Out-File -FilePath "$OutputDir\scripts\restore-nexus.ps1" -Encoding UTF8

# 7. 최종 번들 생성
Write-Host "Step 5: 최종 번들 생성..."
$bundleName = "nexus-airgap-bundle-$(Get-Date -Format 'yyyyMMdd').zip"
Compress-Archive -Path "$OutputDir\*" -DestinationPath $bundleName -Force

Write-Host ""
Write-Host "======================================"
Write-Host "폐쇄망 준비 완료!"
Write-Host "======================================"
Write-Host "번들 파일: $bundleName"
Write-Host ""
Write-Host "폐쇄망에서 실행:"
Write-Host "1. 번들 파일 전송"
Write-Host "2. Expand-Archive -Path $bundleName -DestinationPath ."
Write-Host "3. .\scripts\restore-nexus.ps1"
```

---

## 13. 참고 자료

### 13.1 공식 문서

- [Nexus Repository Manager Documentation](https://help.sonatype.com/repomanager3)
- [Nexus Docker Hub](https://hub.docker.com/r/sonatype/nexus3)
- [Nexus REST API](https://help.sonatype.com/repomanager3/rest-and-integration-api)
- [Nexus Community](https://community.sonatype.com/)

### 13.2 학습 자료

- [Nexus Repository Manager Tutorial](https://www.sonatype.com/products/repository-oss-download)
- [Maven Repository Best Practices](https://maven.apache.org/repository/guide-central-repository-upload.html)
- [npm Private Registry Guide](https://docs.npmjs.com/misc/registry)

### 13.3 비교 및 대안

**Nexus vs 다른 Repository Manager:**

| 특징 | Nexus OSS | Artifactory OSS | GitLab Package Registry | GitHub Packages |
|------|-----------|-----------------|-------------------------|-----------------|
| 가격 | 무료 | 무료 (제한적) | 무료 (GitLab 포함) | 무료 (제한적) |
| Maven 지원 | 완전 지원 | 완전 지원 | 지원 | 지원 |
| npm 지원 | 완전 지원 | 완전 지원 | 지원 | 지원 |
| Docker Registry | 지원 | 지원 | 내장 | 내장 |
| PyPI 지원 | 지원 | 지원 | 지원 | 제한적 |
| 폐쇄망 지원 | 우수 | 우수 | 제한적 | 불가 |
| HA (고가용성) | Pro 버전 | Pro 버전 | 기본 제공 | 기본 제공 |

### 13.4 도구 및 플러그인

1. **Nexus Repository Manager Pro** (상용)
   - High Availability
   - Staging and Release
   - Advanced Security

2. **Maven Nexus Plugin**
   ```xml
   <plugin>
       <groupId>org.sonatype.plugins</groupId>
       <artifactId>nexus-staging-maven-plugin</artifactId>
   </plugin>
   ```

3. **Gradle Nexus Publish Plugin**
   ```groovy
   plugins {
       id 'io.github.gradle-nexus.publish-plugin' version '1.3.0'
   }
   ```

### 13.5 추가 팁

**프로덕션 환경 체크리스트:**
1. ✅ 충분한 메모리 할당 (최소 4GB)
2. ✅ 정기 백업 자동화 (일 1회)
3. ✅ 디스크 용량 모니터링 (Blob Store)
4. ✅ 사용자 권한 관리 (RBAC)
5. ✅ Anonymous Access 비활성화
6. ✅ HTTPS 설정 (Reverse Proxy)
7. ✅ Cleanup Policy 설정
8. ✅ Repository Health Check
9. ✅ LDAP 연동 (선택)
10. ✅ HA 구성 (Pro 버전, 선택)

**폐쇄망 환경 체크리스트:**
1. ✅ 인터넷 환경에서 충분한 패키지 캐싱
2. ✅ 전체 Nexus 백업 (blob + db)
3. ✅ 폐쇄망에서 Hosted Repository 구성
4. ✅ 클라이언트 설정 파일 배포
5. ✅ 정기 업데이트 프로세스 수립
6. ✅ 증분 백업 전략
7. ✅ 누락 패키지 처리 절차
8. ✅ Repository 무결성 검증

**개발 환경 최적화:**
- Docker Compose로 환경 자동화
- 개발자별 권한 설정
- Snapshot Repository 자동 삭제 정책
- 로컬 캐시 활용 (Maven .m2, npm cache)

**성능 최적화:**
- JVM Heap 크기 조정 (Xms, Xmx)
- Blob Store별 분리 (Maven, npm, Docker)
- Cleanup Task 정기 실행
- Component Database 최적화
- Reverse Proxy 캐싱 (nginx)
