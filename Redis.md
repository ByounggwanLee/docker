# Docker를 활용한 Redis 설치 및 구성 가이드

## 목차
1. [Redis 소개](#1-redis-소개)
2. [Redis Docker 이미지 다운로드](#2-redis-docker-이미지-다운로드)
3. [Redis 컨테이너 실행](#3-redis-컨테이너-실행)
4. [Redis 설정 파일 생성](#4-redis-설정-파일-생성)
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

## 1. Redis 소개

Redis(Remote Dictionary Server)는 오픈 소스 인메모리 데이터 구조 저장소로, 데이터베이스, 캐시, 메시지 브로커로 사용됩니다. 고성능과 다양한 데이터 구조를 지원하여 널리 사용됩니다.

### Redis 구성 정보

- **Admin 암호**: redis1225!
- **업무 계정(User)**: axcore
- **비밀번호**: axcore1225!
- **볼륨 위치**: D:\Docker\mount\Redis
- **Encoding**: UTF8 (바이너리 세이프, 자동 지원)
- **기본 포트**: 6379

---

## 2. Redis Docker 이미지 다운로드

### 2.1 최신 버전 다운로드

```cmd
REM Alpine 버전 다운로드 (권장)
docker pull redis:7.2-alpine
```

### 2.2 버전 비교
- `redis:7.2-alpine` - **권장**, 경량화 버전 (약 30MB), 프로덕션 환경에 적합
- `redis:latest` - 최신 안정 버전 (약 150MB), 전체 기능 포함
- `redis:7.2` - 특정 버전, 전체 기능 포함

**Alpine vs 일반 버전:**
| 특징 | Alpine | 일반 |
|------|--------|------|
| 이미지 크기 | ~30MB | ~150MB |
| 보안 | 공격 표면 최소화 | 더 많은 패키지 |
| 성능 | 동일 | 동일 |
| 디버깅 도구 | 최소화 | 전체 포함 |
| 권장 용도 | 프로덕션 | 개발/디버깅 |

---

## 2. Redis 컨테이너 실행

### 2.1 네트워크 생성 (필요시)

```cmd
docker network create dev-net
```

### 2.2 데이터 및 설정 디렉토리 생성

```cmd
REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\Redis\data

REM 설정 파일 디렉토리 생성
mkdir D:\Docker\mount\Redis\conf
```

---

## 3. Redis 설정 파일 생성

`D:\Docker\mount\Redis\conf\redis.conf` 파일 생성:
```prompt
- D:\Docker\mount\Redis\conf\redis.conf 주석 한글화
- D:\Docker\mount\Redis\conf\redis.conf 설정정보 반영해줘
```

```conf
# 기본 설정
bind 0.0.0.0
protected-mode yes
port 6379

# 인증 설정
requirepass redis1225!

# 데이터 영속성 설정 (RDB)
save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
dir /data

# AOF 설정 (더 높은 데이터 안정성)
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# 메모리 설정
maxmemory 2gb
maxmemory-policy allkeys-lru

# 로그 설정
loglevel notice
logfile ""

# 클라이언트 설정
timeout 300
tcp-keepalive 300

# 슬로우 로그
slowlog-log-slower-than 10000
slowlog-max-len 128

# UTF-8 인코딩 (Redis는 기본적으로 바이너리 세이프)
# 별도 설정 불필요

# ACL 사용자 설정 (Redis 6.0+)
# admin 사용자 (모든 권한)
user default on >redis1225! ~* &* +@all

# biz 사용자 (일반 읽기/쓰기 권한)
user biz on >biz1225! ~* +@all -@dangerous
```

**설정 파일 다운로드 (기본 템플릿):**

```cmd
REM 공식 Redis 설정 파일 다운로드
curl -o D:\Docker\mount\Redis\conf\redis.conf https://raw.githubusercontent.com/redis/redis/7.2/redis.conf
```

---

## 4. Redis 컨테이너 실행

### 4.1 기본 실행 명령어

```cmd
docker run -d ^
    --name redis ^
    -p 6379:6379 ^
    --network dev-net ^
    -v D:\Docker\mount\Redis\data:/data ^
    -v D:\Docker\mount\Redis\conf\redis.conf:/usr/local/etc/redis/redis.conf ^
    -e TZ=Asia/Seoul ^
    --restart unless-stopped ^
    redis:7.2-alpine redis-server /usr/local/etc/redis/redis.conf
```

### 4.2 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `TZ` | 타임존 설정 | UTC |
| `--restart unless-stopped` | 자동 재시작 정책 | no |

### 4.3 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/data` | 데이터 디렉토리 | RDB, AOF 파일 저장 |
| `/usr/local/etc/redis/redis.conf` | 설정 파일 | Redis 구성 파일 |

### 4.4 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps -a --filter "name=redis"

REM 로그 확인
docker logs redis

REM 실시간 로그 모니터링
docker logs -f redis

REM 컨테이너 정보 확인
docker inspect redis
```

---

## 5. Redis 접속 테스트

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| 호스트 | localhost (또는 Docker 호스트 IP) |
| 포트 | 6379 |
| Admin 비밀번호 | redis1225! |
| 업무 사용자 | biz |
| 업무 비밀번호 | biz1225! |

### 5.2 CLI 접속

```cmd
REM Admin(default) 사용자로 접속
docker exec -it redis redis-cli -a redis1225!
````

REM 로그 확인
docker logs redis

REM 실시간 로그 모니터링
docker logs -f redis
```

## Redis 연결 및 사용

### 1. redis-cli를 통한 접속

```cmd
REM 컨테이너 내부 redis-cli 실행
docker exec -it redis redis-cli

REM 인증
AUTH redis1225!

REM 기본 명령어 테스트
PING
SET test "Hello Redis"
GET test
```

### 2. biz 사용자로 접속

```cmd
REM biz 사용자로 인증
docker exec -it redis redis-cli
AUTH biz biz1225!

REM 권한 테스트
SET mykey "value"
GET mykey
```

### 3. 외부에서 직접 명령어 실행

```cmd
REM 단일 명령어 실행
docker exec redis redis-cli -a redis1225! PING

REM biz 사용자로 명령어 실행
docker exec redis redis-cli --user biz --pass biz1225! GET mykey
```

### 4. 데이터베이스 선택

Redis는 기본적으로 16개의 데이터베이스를 제공합니다 (0-15):

```cmd
REM 데이터베이스 1번으로 전환
SELECT 1

REM 현재 DB의 모든 키 조회
KEYS *

REM 키 개수 확인
DBSIZE
```

## 주요 Redis 명령어

### 기본 키-값 작업

```bash
# 문자열 저장/조회
SET key "value"
GET key
DEL key
EXISTS key

# 만료 시간 설정 (초)
SETEX key 3600 "value"  # 1시간 후 만료
TTL key  # 남은 시간 확인

# 숫자 증가/감소
INCR counter
DECR counter
INCRBY counter 10
```

### 리스트 작업

```bash
# 리스트 추가
LPUSH mylist "item1"
RPUSH mylist "item2"

# 리스트 조회
LRANGE mylist 0 -1

# 리스트 길이
LLEN mylist
```

### 해시 작업

```bash
# 해시 저장
HSET user:1 name "John"
HSET user:1 age "30"

# 해시 조회
HGET user:1 name
HGETALL user:1

# 여러 필드 한번에 저장
HMSET user:2 name "Jane" age "25" city "Seoul"
```

### 셋 작업

```bash
# 셋 추가
SADD tags "redis" "database" "cache"

# 셋 조회
SMEMBERS tags

# 셋 크기
SCARD tags
```

### 정렬된 셋 (Sorted Set)

```bash
# 정렬된 셋 추가 (점수와 함께)
ZADD leaderboard 100 "player1"
ZADD leaderboard 200 "player2"
ZADD leaderboard 150 "player3"

# 순위 조회 (낮은 점수부터)
ZRANGE leaderboard 0 -1 WITHSCORES

# 순위 조회 (높은 점수부터)
ZREVRANGE leaderboard 0 -1 WITHSCORES
```

## 데이터 백업 및 복원

### 방법 1: RDB 스냅샷 (기본)

```cmd
REM 수동 스냅샷 생성
docker exec redis redis-cli -a redis1225! SAVE

REM 백그라운드 스냅샷 생성 (권장)
docker exec redis redis-cli -a redis1225! BGSAVE

REM 스냅샷 파일 복사
docker cp redis:/data/dump.rdb D:\Docker\backup\redis_dump_%date:~0,4%%date:~5,2%%date:~8,2%.rdb
```

### 방법 2: AOF (Append Only File)

AOF는 설정 파일에서 `appendonly yes`로 활성화되어 있으면 자동으로 작동합니다.

```cmd
REM AOF 파일 복사
docker cp redis:/data/appendonly.aof D:\Docker\backup\redis_aof_%date:~0,4%%date:~5,2%%date:~8,2%.aof

REM AOF 재작성 (압축)
docker exec redis redis-cli -a redis1225! BGREWRITEAOF
```

### 복원 방법

```cmd
REM 1. 컨테이너 중지
docker stop redis

REM 2. 백업 파일을 데이터 디렉토리로 복사
copy D:\Docker\backup\redis_dump.rdb D:\Docker\mount\Redis\data\dump.rdb

REM 3. 컨테이너 시작
docker start redis

REM 4. 데이터 확인
docker exec redis redis-cli -a redis1225! DBSIZE
```

## 자동화 스크립트

### runRedis.bat (통합 실행 스크립트)

```batch
@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=redis
set NETWORK_NAME=dev-net
set REDIS_PORT=6379
set DATA_DIR=D:\Docker\mount\Redis\data
set CONF_DIR=D:\Docker\mount\Redis\conf
set REDIS_PASSWORD=redis1225!

echo Starting Redis Docker Container Setup...
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
echo Pulling Redis image...
docker pull redis:7.2-alpine

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
echo Starting Redis container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p %REDIS_PORT%:6379 ^
    --network %NETWORK_NAME% ^
    -v %DATA_DIR%:/data ^
    -v %CONF_DIR%\redis.conf:/usr/local/etc/redis/redis.conf ^
    -e TZ=Asia/Seoul ^
    --restart unless-stopped ^
    redis:7.2-alpine redis-server /usr/local/etc/redis/redis.conf

if errorlevel 1 (
    echo Failed to start Redis container!
    exit /b 1
)

echo.
echo Redis container started successfully!
echo Container name: %CONTAINER_NAME%
echo Port: %REDIS_PORT%
echo Data directory: %DATA_DIR%
echo.
echo Waiting for Redis to be ready...
timeout /t 5 /nobreak >nul

REM -------------------------------
REM VERIFY CONNECTION
REM -------------------------------
echo Testing connection...
docker exec %CONTAINER_NAME% redis-cli -a %REDIS_PASSWORD% PING

if errorlevel 1 (
    echo Warning: Connection test failed. Check logs with: docker logs %CONTAINER_NAME%
) else (
    echo Redis is ready!
    echo Connection string: redis://:redis1225!@localhost:%REDIS_PORT%
)

echo.
endlocal
```

### backup_redis.bat (백업 스크립트)

```batch
@echo off
setlocal

set CONTAINER_NAME=redis
set BACKUP_DIR=D:\Docker\backup\redis
set REDIS_PASSWORD=redis1225!
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%

echo Redis Backup Script
echo.

REM 백업 디렉토리 생성
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM RDB 스냅샷 생성
echo Creating RDB snapshot...
docker exec %CONTAINER_NAME% redis-cli -a %REDIS_PASSWORD% --no-auth-warning BGSAVE

REM 완료 대기
timeout /t 3 /nobreak >nul

REM 백업 파일 복사
echo Copying backup files...
docker cp %CONTAINER_NAME%:/data/dump.rdb "%BACKUP_DIR%\dump_%DATE_STAMP%.rdb"

if exist "%BACKUP_DIR%\dump_%DATE_STAMP%.rdb" (
    echo Backup completed successfully!
    echo Location: %BACKUP_DIR%\dump_%DATE_STAMP%.rdb
) else (
    echo Backup failed!
    exit /b 1
)

REM 오래된 백업 삭제 (30일 이상)
echo Cleaning old backups...
forfiles /p "%BACKUP_DIR%" /m dump_*.rdb /d -30 /c "cmd /c del @path" 2>nul

echo.
echo Backup process completed!
endlocal
```

## Docker Compose 예제

`docker-compose.yml`:

```yaml
version: '3.8'

services:
  redis:
    image: redis:7.2-alpine
    container_name: redis
    hostname: redis-host
    ports:
      - "6379:6379"
    volumes:
      - D:\Docker\mount\Redis\data:/data
      - D:\Docker\mount\Redis\conf\redis.conf:/usr/local/etc/redis/redis.conf
    environment:
      - TZ=Asia/Seoul
    command: redis-server /usr/local/etc/redis/redis.conf
    restart: unless-stopped
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "redis1225!", "ping"]
      interval: 30s
      timeout: 3s
      retries: 5

networks:
  dev-net:
    driver: bridge
```

실행:

```cmd
docker-compose up -d
```

## 모니터링 및 관리

### 1. Redis 상태 확인

```cmd
REM 서버 정보 확인
docker exec redis redis-cli -a redis1225! INFO

REM 메모리 사용량
docker exec redis redis-cli -a redis1225! INFO memory

REM 연결된 클라이언트 확인
docker exec redis redis-cli -a redis1225! CLIENT LIST

REM 슬로우 로그 확인
docker exec redis redis-cli -a redis1225! SLOWLOG GET 10
```

### 2. 성능 모니터링

```cmd
REM 실시간 모니터링
docker exec -it redis redis-cli -a redis1225! --stat

REM 초당 명령어 수 모니터링
docker exec -it redis redis-cli -a redis1225! --latency

REM 키 분석
docker exec redis redis-cli -a redis1225! --bigkeys
```

### 3. 데이터베이스 관리

```cmd
REM 모든 키 삭제 (주의!)
docker exec redis redis-cli -a redis1225! FLUSHDB

REM 모든 데이터베이스 삭제 (주의!)
docker exec redis redis-cli -a redis1225! FLUSHALL

REM 키 개수 확인
docker exec redis redis-cli -a redis1225! DBSIZE
```

## 애플리케이션 연결 예제

### Python (redis-py)

```python
import redis

# 기본 연결
r = redis.Redis(
    host='localhost',
    port=6379,
    password='redis1225!',
    db=0,
    decode_responses=True
)

# biz 사용자로 연결
r_biz = redis.Redis(
    host='localhost',
    port=6379,
    username='biz',
    password='biz1225!',
    db=0,
    decode_responses=True
)

# 기본 작업
r.set('key', 'value')
value = r.get('key')
print(value)
```

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

// 기본 연결
const redis = new Redis({
  host: 'localhost',
  port: 6379,
  password: 'redis1225!',
  db: 0
});

// biz 사용자로 연결
const redisBiz = new Redis({
  host: 'localhost',
  port: 6379,
  username: 'biz',
  password: 'biz1225!',
  db: 0
});

// 기본 작업
await redis.set('key', 'value');
const value = await redis.get('key');
console.log(value);
```

### Java (Jedis)

```java
import redis.clients.jedis.Jedis;

// 기본 연결
Jedis jedis = new Jedis("localhost", 6379);
jedis.auth("redis1225!");
jedis.select(0);

// 기본 작업
jedis.set("key", "value");
String value = jedis.get("key");
System.out.println(value);

jedis.close();
```

### C# (.NET)

```csharp
using StackExchange.Redis;

// 기본 연결
var redis = ConnectionMultiplexer.Connect("localhost:6379,password=redis1225!");
var db = redis.GetDatabase();

// 기본 작업
db.StringSet("key", "value");
var value = db.StringGet("key");
Console.WriteLine(value);
```

## 문제 해결

### 1. 컨테이너가 시작되지 않는 경우

```cmd
REM 로그 확인
docker logs redis

REM 설정 파일 문법 확인
docker run --rm -v D:\Docker\mount\Redis\conf\redis.conf:/redis.conf redis:7.2-alpine redis-server /redis.conf --test-memory 1

REM 권한 문제 확인 (컨테이너 내부)
docker exec redis ls -la /data
```

### 2. 연결이 안 되는 경우

```cmd
REM Redis가 실행 중인지 확인
docker exec redis redis-cli -a redis1225! PING

REM 포트 바인딩 확인
docker port redis

REM 방화벽 확인 (Windows)
netsh advfirewall firewall add rule name="Redis" dir=in action=allow protocol=TCP localport=6379
```

### 3. 메모리 부족

```cmd
REM 현재 메모리 사용량 확인
docker exec redis redis-cli -a redis1225! INFO memory

REM maxmemory 설정 변경 (redis.conf)
REM maxmemory 4gb

REM 컨테이너 재시작
docker restart redis
```

### 4. 데이터가 저장되지 않는 경우

```cmd
REM RDB 설정 확인
docker exec redis redis-cli -a redis1225! CONFIG GET save

REM AOF 설정 확인
docker exec redis redis-cli -a redis1225! CONFIG GET appendonly

REM 수동 저장
docker exec redis redis-cli -a redis1225! SAVE

REM 볼륨 마운트 확인
docker inspect redis --format='{{json .Mounts}}' | jq
```

### 5. 성능 문제

```cmd
REM 슬로우 쿼리 확인
docker exec redis redis-cli -a redis1225! SLOWLOG GET 100

REM 클라이언트 연결 수 확인
docker exec redis redis-cli -a redis1225! INFO clients

REM 명령어 통계
docker exec redis redis-cli -a redis1225! INFO commandstats
```

## 보안 권장사항

### 1. 비밀번호 관리

- ✅ 강력한 비밀번호 사용
- ✅ 정기적으로 비밀번호 변경
- ✅ 환경 변수로 비밀번호 관리 (설정 파일에 하드코딩 금지)
- ⚠️ 프로덕션에서는 비밀번호를 설정 파일이 아닌 Docker Secret 사용

### 2. 네트워크 보안

- ✅ `protected-mode yes` 설정 유지
- ✅ `bind 0.0.0.0` 대신 특정 IP 바인딩 (프로덕션)
- ✅ 방화벽으로 포트 6379 접근 제한
- ⚠️ 외부 노출 시 SSL/TLS 사용 (Redis 6.0+)

### 3. ACL (Access Control List)

Redis 6.0부터 지원되는 ACL을 활용하여 세밀한 권한 관리:

```bash
# 사용자 목록 확인
ACL LIST

# 새 사용자 생성
ACL SETUSER newuser on >password ~* +@all

# 읽기 전용 사용자
ACL SETUSER readonly on >password ~* +@read

# 특정 키 패턴만 접근
ACL SETUSER limited on >password ~user:* +@all
```

### 4. 명령어 비활성화

위험한 명령어는 설정 파일에서 비활성화:

```conf
# redis.conf
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_b8f2a6d9e7c3"
rename-command SHUTDOWN "SHUTDOWN_a7c9e3d8f2b6"
```

## 유의사항 및 추천사항

### ✅ 권장사항

1. **데이터 영속성**
   - RDB와 AOF를 함께 사용하여 데이터 안정성 극대화
   - 정기적인 백업 스케줄 설정 (일일 또는 시간별)

2. **메모리 관리**
   - `maxmemory` 설정으로 메모리 제한
   - `maxmemory-policy`로 메모리 부족 시 동작 정의
   - 권장: `allkeys-lru` (최근 사용 안 한 키 삭제)

3. **모니터링**
   - Redis 명령어 통계 정기 확인
   - 슬로우 로그 모니터링
   - 메모리 사용량 추적

4. **성능 최적화**
   - 적절한 데이터 구조 선택 (String, Hash, List, Set, Sorted Set)
   - 큰 키 사용 자제 (KEYS 명령어 대신 SCAN 사용)
   - Pipeline 사용으로 네트워크 오버헤드 감소

5. **고가용성**
   - Redis Sentinel 또는 Redis Cluster 고려 (프로덕션)
   - 레플리케이션 설정으로 읽기 부하 분산

### ⚠️ 주의사항

1. **KEYS 명령어 사용 금지**
   - 프로덕션에서 `KEYS *` 절대 사용 금지 (블로킹)
   - 대신 `SCAN` 명령어 사용

2. **메모리 관리**
   - Redis는 인메모리 DB로 메모리 부족 시 성능 저하
   - 물리 메모리의 70-80% 이하로 사용 권장

3. **영속성 vs 성능**
   - AOF `appendfsync always`: 안전하지만 느림
   - AOF `appendfsync everysec`: 균형 (권장)
   - AOF `appendfsync no`: 빠르지만 데이터 손실 위험

4. **클러스터 모드**
   - 단일 노드는 개발/소규모 운영에만 적합
   - 대규모 서비스는 Redis Cluster 필수

5. **백업 주의**
   - `SAVE` 명령어는 블로킹 (사용 금지)
   - `BGSAVE` 사용 (백그라운드 저장)

## 연결 정보 요약

**Redis CLI:**
```cmd
docker exec -it redis redis-cli -a redis1225!
```

**연결 문자열 (admin):**
```
redis://:redis1225!@localhost:6379
```

**연결 문자열 (biz 사용자):**
```
redis://biz:biz1225!@localhost:6379
```

**설정 파일 위치:**
- 호스트: `D:\Docker\mount\Redis\conf\redis.conf`
- 컨테이너: `/usr/local/etc/redis/redis.conf`

**데이터 위치:**
- 호스트: `D:\Docker\mount\Redis\data`
- 컨테이너: `/data`

## 참고 자료

- [Redis 공식 문서](https://redis.io/documentation)
- [Redis 명령어 레퍼런스](https://redis.io/commands)
- [Redis Docker Hub](https://hub.docker.com/_/redis)
- [Redis 보안 가이드](https://redis.io/topics/security)
- [Redis 성능 최적화](https://redis.io/topics/benchmarks)
- [Redis ACL 가이드](https://redis.io/topics/acl)

## 추가 도구

### Redis GUI 도구

1. **RedisInsight** (공식, 무료)
   - [다운로드](https://redis.com/redis-enterprise/redis-insight/)
   - 시각적 데이터 탐색, 모니터링

2. **Another Redis Desktop Manager** (무료, 오픈소스)
   - [GitHub](https://github.com/qishibo/AnotherRedisDesktopManager)
   - 크로스 플랫폼 GUI

3. **Redis Commander** (웹 기반)
   ```cmd
   docker run -d --name redis-commander --link redis:redis -p 8081:8081 rediscommander/redis-commander
   ```
   - 브라우저에서 접속: http://localhost:8081

### Redis 클러스터 관리 도구

- **redis-trib**: Redis Cluster 관리
- **Redis Sentinel**: 고가용성 솔루션
- **Medis**: macOS용 GUI 클라이언트
