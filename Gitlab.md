# Docker를 활용한 GitLab 설치 및 구성 가이드

## 목차
1. [GitLab 소개](#1-gitlab-소개)
2. [GitLab Docker 이미지 다운로드](#2-gitlab-docker-이미지-다운로드)
3. [GitLab 컨테이너 실행](#3-gitlab-컨테이너-실행)
4. [초기 설정 절차](#4-초기-설정-절차)
5. [접속 정보](#5-접속-정보)
6. [백업 및 복원](#6-백업-및-복원)
7. [모니터링](#7-모니터링)
8. [문제 해결](#8-문제-해결)
9. [자동화 스크립트](#9-자동화-스크립트)
10. [Docker Compose 예제](#10-docker-compose-예제)
11. [보안 설정](#11-보안-설정)
12. [고급 기능](#12-고급-기능)
13. [참고 자료](#13-참고-자료)

---

## 1. GitLab 소개

GitLab은 Git 기반의 웹 기반 DevOps 플랫폼으로, 소스 코드 관리(SCM), CI/CD, 이슈 추적, 프로젝트 관리 등 소프트웨어 개발 라이프사이클 전반을 지원합니다. GitLab Community Edition(CE)과 Enterprise Edition(EE) 두 가지 버전을 제공합니다.

### 1.1 GitLab 구성 정보

- **관리자 계정**: root
- **관리자 초기 비밀번호**: gitlab1225!
- **HTTP 포트**: 9080 (호스트) → 80 (컨테이너)
- **HTTPS 포트**: 9443 (호스트) → 443 (컨테이너)
- **SSH 포트**: 9022 (호스트) → 22 (컨테이너)
- **호스트명**: gitlab.lbg.com
- **기본 URL**: http://gitlab.lbg.com:9080

### 1.2 주요 기능

- **소스 코드 관리**: Git 저장소 호스팅, 브랜치 관리, Merge Request
- **CI/CD**: GitLab Runner를 통한 자동화된 빌드/테스트/배포
- **이슈 추적**: 버그 추적, 작업 관리, 마일스톤
- **프로젝트 관리**: 칸반 보드, 위키, 스니펫
- **Container Registry**: Docker 이미지 저장소
- **패키지 레지스트리**: Maven, npm, NuGet, PyPI 등

---

## 2. GitLab Docker 이미지 다운로드

### 2.1 최신 버전 다운로드

```cmd
docker pull gitlab/gitlab-ce:latest
```

### 2.2 버전 비교

| 버전 | 크기 | 설명 | 권장 용도 |
|------|------|------|-----------|
| gitlab/gitlab-ce:latest | ~2.8GB | Community Edition 최신 버전 | 일반 개발팀 (권장) |
| gitlab/gitlab-ee:latest | ~2.9GB | Enterprise Edition 최신 버전 | 대규모 조직 |
| gitlab/gitlab-ce:16.11.0-ce.0 | ~2.8GB | 특정 버전 고정 | 프로덕션 안정성 |
| gitlab/gitlab-ce:16.10.0-ce.0 | ~2.8GB | 이전 안정 버전 | 레거시 호환 |

**권장**: `gitlab/gitlab-ce:latest` (Community Edition)

**에디션 비교:**

| 기능 | Community (CE) | Enterprise (EE) |
|------|----------------|-----------------|
| Git 저장소 관리 | ✓ | ✓ |
| CI/CD | ✓ | ✓ |
| 이슈/위키 | ✓ | ✓ |
| Container Registry | ✓ | ✓ |
| LDAP 인증 | 기본 | 고급 |
| 고가용성(HA) | - | ✓ |
| 감사 로그 | - | ✓ |
| 고급 보안 스캔 | - | ✓ |

---

## 3. GitLab 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\gitlab\config
mkdir D:\Docker\mount\gitlab\logs
mkdir D:\Docker\mount\gitlab\data
```

### 3.2 기본 실행 명령어

#### Windows CMD
```cmd
docker run -d ^
  --name gitlab ^
  --hostname gitlab.lbg.com ^
  --network dev-net ^
  --restart always ^
  -e TZ=Asia/Seoul ^
  -e GITLAB_ROOT_PASSWORD=gitlab1225! ^
  -e GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.lbg.com:9080'; gitlab_rails['time_zone'] = 'Asia/Seoul';" ^
  -p 9080:80 ^
  -p 9443:443 ^
  -p 9022:22 ^
  --shm-size 2g ^
  -v D:\Docker\mount\gitlab\config:/etc/gitlab ^
  -v D:\Docker\mount\gitlab\logs:/var/log/gitlab ^
  -v D:\Docker\mount\gitlab\data:/var/opt/gitlab ^
  gitlab/gitlab-ce:latest
```

#### Windows (PowerShell)
```powershell
docker run -d `
  --name gitlab `
  --hostname gitlab.lbg.com `
  --network dev-net `
  --restart always `
  -e TZ=Asia/Seoul `
  -e GITLAB_ROOT_PASSWORD=gitlab1225! `
  -e GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.lbg.com:9080'; gitlab_rails['time_zone'] = 'Asia/Seoul';" `
  -p 9080:80 `
  -p 9443:443 `
  -p 9022:22 `
  --shm-size 2g `
  -v D:\Docker\mount\gitlab\config:/etc/gitlab `
  -v D:\Docker\mount\gitlab\logs:/var/log/gitlab `
  -v D:\Docker\mount\gitlab\data:/var/opt/gitlab `
  gitlab/gitlab-ce:latest
```

#### Linux/Mac
```bash
docker run -d \
  --name gitlab \
  --hostname gitlab.lbg.com \
  --network dev-net \
  --restart always \
  -e TZ=Asia/Seoul \
  -e GITLAB_ROOT_PASSWORD=gitlab1225! \
  -e GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.lbg.com:9080'; gitlab_rails['time_zone'] = 'Asia/Seoul';" \
  -p 9080:80 \
  -p 9443:443 \
  -p 9022:22 \
  --shm-size 2g \
  -v /docker/mount/gitlab/config:/etc/gitlab \
  -v /docker/mount/gitlab/logs:/var/log/gitlab \
  -v /docker/mount/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

### 3.3 환경 변수 설명

| 환경 변수 | 설명 | 기본값 |
|-----------|------|--------|
| `GITLAB_ROOT_PASSWORD` | root 계정 초기 비밀번호 | 자동 생성 |
| `GITLAB_OMNIBUS_CONFIG` | GitLab 설정 (external_url 등) | 없음 |
| `TZ` | 타임존 설정 | UTC |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN` | Runner 등록 토큰 | 자동 생성 |

**비밀번호 요구사항:**
- 최소 8자 이상
- 복잡도: 대문자, 소문자, 숫자, 특수문자 조합 권장

### 3.4 볼륨 마운트 경로

| 컨테이너 경로 | 용도 | 설명 |
|---------------|------|------|
| `/etc/gitlab` | 설정 파일 | gitlab.rb 등 설정 저장 |
| `/var/log/gitlab` | 로그 파일 | 모든 GitLab 서비스 로그 |
| `/var/opt/gitlab` | 데이터 파일 | Git 저장소, DB, 업로드 파일 |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps -a --filter "name=gitlab"

REM 로그 확인 (초기 시작 시 5-10분 소요)
docker logs -f gitlab

REM GitLab 서비스 상태 확인
docker exec -it gitlab gitlab-ctl status

REM 헬스 체크
docker exec -it gitlab gitlab-rake gitlab:check
```

### 3.6 초기 시작 대기

GitLab은 초기 시작 시 **5-10분** 정도 소요됩니다.

```cmd
REM 시작 완료 대기
docker exec -it gitlab gitlab-ctl tail

REM 웹 UI 접근 가능 확인
curl http://localhost:9080
```

---

## 4. 초기 설정 절차

### 4.1 root 관리자 계정 설정

#### 방법 1: 환경 변수로 설정 (권장)
컨테이너 실행 시 `GITLAB_ROOT_PASSWORD=gitlab1225!` 환경 변수로 설정.

#### 방법 2: 초기 비밀번호 확인
환경 변수를 설정하지 않은 경우, 자동 생성된 비밀번호 확인:

```cmd
docker exec -it gitlab cat /etc/gitlab/initial_root_password
```

**출력 예:**
```
Password: 자동생성된비밀번호
NOTE: This file will be cleaned up in first reconfigure run after 24 hours.
```

### 4.2 웹 UI 접속

1. 브라우저에서 접속: `http://gitlab.lbg.com:9080` 또는 `http://localhost:9080`
2. 로그인:
   - Username: `root`
   - Password: `gitlab1225!` (또는 자동 생성 비밀번호)

### 4.3 초기 설정

#### 1. 프로필 설정
- **Settings** → **Profile** → 이름, 이메일 설정

#### 2. 관리자 영역 설정
- **Admin Area** (좌측 하단 렌치 아이콘)
- **Settings** → **General**:
  - Sign-up restrictions: 회원가입 제한 설정
  - Sign-in restrictions: 로그인 제한 설정
  - Account and limit: 프로젝트 크기 제한

#### 3. 이메일 알림 설정
`/etc/gitlab/gitlab.rb` 편집:

```cmd
docker exec -it gitlab vi /etc/gitlab/gitlab.rb
```

```ruby
# SMTP 설정 (Gmail 예제)
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "your-email@gmail.com"
gitlab_rails['smtp_password'] = "your-app-password"
gitlab_rails['smtp_domain'] = "gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# 발신자 이메일
gitlab_rails['gitlab_email_from'] = 'gitlab@lbg.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@lbg.com'
```

설정 적용:
```cmd
docker exec -it gitlab gitlab-ctl reconfigure
```

#### 4. 첫 프로젝트 생성

1. **Create a project** 클릭
2. 프로젝트명, 가시성(Private/Internal/Public) 설정
3. **Create project** 클릭

---

## 5. 접속 정보

### 5.1 웹 UI 접속

| 항목 | 정보 |
|------|------|
| URL | http://gitlab.lbg.com:9080 |
| 관리자 계정 | root |
| 관리자 비밀번호 | gitlab1225! |
| HTTPS URL | https://gitlab.lbg.com:9443 (SSL 설정 시) |

### 5.2 Git 저장소 클론

#### HTTP 방식
```bash
git clone http://gitlab.lbg.com:9080/username/project.git
```

#### SSH 방식
```bash
# SSH 키 등록 후
git clone ssh://git@gitlab.lbg.com:9022/username/project.git
```

### 5.3 Personal Access Token 생성

1. **User Settings** → **Access Tokens**
2. Token name 입력, Scopes 선택 (api, read_repository, write_repository 등)
3. **Create personal access token** 클릭
4. 생성된 토큰 복사 (재확인 불가)

**API 사용 예:**
```bash
# 프로젝트 목록 조회
curl --header "PRIVATE-TOKEN: your-token" http://gitlab.lbg.com:9080/api/v4/projects

# 프로젝트 생성
curl --header "PRIVATE-TOKEN: your-token" \
  -X POST "http://gitlab.lbg.com:9080/api/v4/projects" \
  --form "name=my-project" \
  --form "visibility=private"
```

### 5.4 SSH 키 등록

```bash
# SSH 키 생성 (클라이언트)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 공개 키 복사
cat ~/.ssh/id_ed25519.pub
```

GitLab에서 등록:
1. **User Settings** → **SSH Keys**
2. 공개 키 붙여넣기
3. **Add key** 클릭

### 5.5 Container Registry 접속

```bash
# Docker 로그인
docker login gitlab.lbg.com:9080

# 이미지 푸시
docker tag my-image gitlab.lbg.com:9080/username/project/my-image:latest
docker push gitlab.lbg.com:9080/username/project/my-image:latest
```

---

## 6. 백업 및 복원

### 6.1 수동 백업

#### 전체 백업 생성
```cmd
REM GitLab 백업 실행
docker exec -it gitlab gitlab-backup create

REM 백업 파일 확인
docker exec -it gitlab ls -lh /var/opt/gitlab/backups
```

백업 파일 형식: `{timestamp}_gitlab_backup.tar`

#### 백업 파일 추출
```cmd
REM 호스트로 복사
docker cp gitlab:/var/opt/gitlab/backups/1732089600_2025_11_20_16.11.0_gitlab_backup.tar D:\Docker\backup\
```

#### 설정 파일 백업
```cmd
REM gitlab.rb 및 secrets 백업
docker exec -it gitlab tar -czf /tmp/gitlab-config-backup.tar.gz /etc/gitlab
docker cp gitlab:/tmp/gitlab-config-backup.tar.gz D:\Docker\backup\
```

### 6.2 자동 백업 스크립트

`backup-gitlab.bat`:
```batch
@echo off
REM GitLab 자동 백업 스크립트

SET BACKUP_DIR=D:\Docker\backup\gitlab
SET TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ====================================
echo GitLab 백업 시작: %TIMESTAMP%
echo ====================================

REM 백업 디렉토리 생성
if not exist "%BACKUP_DIR%\%TIMESTAMP%" mkdir "%BACKUP_DIR%\%TIMESTAMP%"

REM GitLab 데이터 백업
echo 1. GitLab 데이터 백업 중...
docker exec gitlab gitlab-backup create

REM 최신 백업 파일 복사
for /f "delims=" %%i in ('docker exec gitlab ls -t /var/opt/gitlab/backups ^| findstr /R "[0-9].*_gitlab_backup.tar"') do (
    set LATEST_BACKUP=%%i
    goto :found
)
:found

docker cp gitlab:/var/opt/gitlab/backups/%LATEST_BACKUP% "%BACKUP_DIR%\%TIMESTAMP%\"

REM 설정 파일 백업
echo 2. 설정 파일 백업 중...
docker exec gitlab tar -czf /tmp/gitlab-config-%TIMESTAMP%.tar.gz /etc/gitlab
docker cp gitlab:/tmp/gitlab-config-%TIMESTAMP%.tar.gz "%BACKUP_DIR%\%TIMESTAMP%\"
docker exec gitlab rm /tmp/gitlab-config-%TIMESTAMP%.tar.gz

REM 로그 파일 백업 (선택사항)
echo 3. 로그 파일 백업 중...
xcopy D:\Docker\mount\gitlab\logs "%BACKUP_DIR%\%TIMESTAMP%\logs" /E /I /H /Y

echo ====================================
echo 백업 완료: %BACKUP_DIR%\%TIMESTAMP%
echo ====================================
pause
```

### 6.3 백업 복원

#### 1. 데이터 복원
```cmd
REM 백업 파일을 컨테이너로 복사
docker cp D:\Docker\backup\1732089600_2025_11_20_16.11.0_gitlab_backup.tar gitlab:/var/opt/gitlab/backups/

REM GitLab 서비스 중지
docker exec -it gitlab gitlab-ctl stop puma
docker exec -it gitlab gitlab-ctl stop sidekiq

REM 복원 실행
docker exec -it gitlab gitlab-backup restore BACKUP=1732089600_2025_11_20_16.11.0

REM GitLab 서비스 재시작
docker exec -it gitlab gitlab-ctl restart
docker exec -it gitlab gitlab-rake gitlab:check SANITIZE=true
```

#### 2. 설정 파일 복원
```cmd
REM 설정 백업 파일 복사
docker cp D:\Docker\backup\gitlab-config-backup.tar.gz gitlab:/tmp/

REM 압축 해제
docker exec -it gitlab tar -xzf /tmp/gitlab-config-backup.tar.gz -C /

REM 재구성
docker exec -it gitlab gitlab-ctl reconfigure
docker exec -it gitlab gitlab-ctl restart
```

### 6.4 백업 보관 정책

`/etc/gitlab/gitlab.rb`에서 설정:

```ruby
# 백업 보관 기간 (초 단위, 7일 = 604800초)
gitlab_rails['backup_keep_time'] = 604800

# 백업 경로
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"

# 백업에서 제외할 항목
gitlab_rails['backup_archive_permissions'] = 0644
gitlab_rails['backup_upload_connection'] = {}
```

설정 적용:
```cmd
docker exec -it gitlab gitlab-ctl reconfigure
```

---

## 7. 모니터링

### 7.1 시스템 상태 확인

```cmd
REM 모든 서비스 상태
docker exec -it gitlab gitlab-ctl status

REM 개별 서비스 상태
docker exec -it gitlab gitlab-ctl status nginx
docker exec -it gitlab gitlab-ctl status postgresql
docker exec -it gitlab gitlab-ctl status redis
docker exec -it gitlab gitlab-ctl status sidekiq
```

### 7.2 로그 모니터링

```cmd
REM 모든 로그 실시간 보기
docker exec -it gitlab gitlab-ctl tail

REM 특정 서비스 로그
docker exec -it gitlab gitlab-ctl tail nginx
docker exec -it gitlab gitlab-ctl tail postgresql
docker exec -it gitlab gitlab-ctl tail sidekiq
docker exec -it gitlab gitlab-ctl tail puma

REM 컨테이너 로그
docker logs -f gitlab
```

### 7.3 성능 모니터링

#### GitLab 내장 메트릭
1. **Admin Area** → **Monitoring** → **System Info**
2. CPU, 메모리, 디스크 사용량 확인

#### Prometheus 메트릭 (기본 활성화)
```cmd
REM Prometheus 메트릭 확인
curl http://gitlab.lbg.com:9080/-/metrics
```

#### 데이터베이스 상태
```cmd
docker exec -it gitlab gitlab-psql -c "SELECT * FROM pg_stat_activity;"
```

#### Redis 상태
```cmd
docker exec -it gitlab gitlab-redis-cli INFO
```

### 7.4 디스크 사용량

```cmd
REM GitLab 데이터 디스크 사용량
docker exec -it gitlab du -sh /var/opt/gitlab/*

REM 저장소 크기 확인
docker exec -it gitlab du -sh /var/opt/gitlab/git-data/repositories

REM 호스트 마운트 디렉토리 크기
du -sh D:\Docker\mount\gitlab\data
```

### 7.5 헬스 체크

```cmd
REM 전체 헬스 체크
docker exec -it gitlab gitlab-rake gitlab:check

REM 환경 정보 확인
docker exec -it gitlab gitlab-rake gitlab:env:info

REM Geo 노드 상태 (EE만 해당)
docker exec -it gitlab gitlab-rake gitlab:geo:check
```

---

## 8. 문제 해결

### 8.1 컨테이너 시작 실패

#### 증상
```
Error response from daemon: driver failed programming external connectivity
```

#### 원인
- 포트 충돌 (9080, 9443, 9022 포트가 이미 사용 중)

#### 해결
```cmd
REM 포트 사용 확인
netstat -ano | findstr :9080

REM 포트 변경하여 재실행
docker run -p 10080:80 -p 10443:443 -p 10022:22 ...
```

### 8.2 502 Bad Gateway

#### 증상
- 웹 UI 접속 시 502 에러

#### 원인
- GitLab 서비스가 아직 시작 중이거나 메모리 부족

#### 해결
```cmd
REM 서비스 상태 확인
docker exec -it gitlab gitlab-ctl status

REM Puma 재시작
docker exec -it gitlab gitlab-ctl restart puma

REM 메모리 확인 (최소 4GB 권장)
docker stats gitlab
```

### 8.3 Git Push 실패

#### 증상
```
fatal: unable to access 'http://gitlab.lbg.com:9080/project.git/':
Failed to connect to gitlab.lbg.com port 9080
```

#### 원인
- 네트워크 연결 문제 또는 방화벽

#### 해결
```cmd
REM GitLab 컨테이너 핑 테스트
ping gitlab.lbg.com

REM 포트 접근 테스트
telnet gitlab.lbg.com 9080

REM 방화벽 규칙 추가 (관리자 권한)
netsh advfirewall firewall add rule name="GitLab HTTP" dir=in action=allow protocol=TCP localport=9080
```

### 8.4 SSH Clone 실패

#### 증상
```
ssh: connect to host gitlab.lbg.com port 9022: Connection refused
```

#### 원인
- SSH 포트가 올바르게 매핑되지 않음

#### 해결
```cmd
REM SSH 설정 확인
docker exec -it gitlab cat /assets/sshd_config

REM 포트 매핑 확인
docker port gitlab

REM ~/.ssh/config에 호스트 추가
Host gitlab.lbg.com
  Hostname gitlab.lbg.com
  Port 9022
  User git
  IdentityFile ~/.ssh/id_ed25519
```

### 8.5 메모리 부족

#### 증상
- 서비스가 자주 죽거나 느림
- OOMKilled 로그

#### 해결
```cmd
REM 메모리 사용량 확인
docker stats gitlab

REM 메모리 제한 증가 (최소 4GB, 권장 8GB)
docker update --memory 8g gitlab

REM 또는 재생성
docker rm gitlab
docker run --memory 8g ...
```

### 8.6 데이터베이스 손상

#### 증상
- 500 Internal Server Error
- 데이터베이스 연결 오류

#### 해결
```cmd
REM 데이터베이스 체크
docker exec -it gitlab gitlab-rake gitlab:db:check

REM 데이터베이스 복구
docker exec -it gitlab gitlab-psql -c "REINDEX DATABASE gitlabhq_production;"

REM 마이그레이션 재실행
docker exec -it gitlab gitlab-rake db:migrate
```

---

## 9. 자동화 스크립트

### 9.1 컨테이너 실행 스크립트

`runGitlab.bat`:
```batch
@echo off
REM GitLab 컨테이너 실행 스크립트

echo ====================================
echo GitLab 컨테이너 실행
echo ====================================

REM 기존 컨테이너 확인
docker ps -a --filter "name=gitlab" --format "{{.Names}}" | findstr "gitlab" >nul
if %errorlevel% equ 0 (
    echo 기존 GitLab 컨테이너 발견. 제거 여부를 선택하세요.
    set /p REMOVE="기존 컨테이너 제거? (y/n): "
    if /i "%REMOVE%"=="y" (
        echo 기존 컨테이너 중지 및 제거 중...
        docker stop gitlab
        docker rm gitlab
    ) else (
        echo 기존 컨테이너 시작 중...
        docker start gitlab
        goto :end
    )
)

REM 네트워크 생성 (없을 경우)
docker network inspect dev-net >nul 2>&1
if %errorlevel% neq 0 (
    echo dev-net 네트워크 생성 중...
    docker network create dev-net
)

REM 디렉토리 생성
if not exist D:\Docker\mount\gitlab\config mkdir D:\Docker\mount\gitlab\config
if not exist D:\Docker\mount\gitlab\logs mkdir D:\Docker\mount\gitlab\logs
if not exist D:\Docker\mount\gitlab\data mkdir D:\Docker\mount\gitlab\data

REM GitLab 컨테이너 실행
echo GitLab 컨테이너 시작 중...
docker run -d ^
  --name gitlab ^
  --hostname gitlab.lbg.com ^
  --network dev-net ^
  --restart always ^
  -e TZ=Asia/Seoul ^
  -e GITLAB_ROOT_PASSWORD=gitlab1225! ^
  -e GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.lbg.com:9080'; gitlab_rails['time_zone'] = 'Asia/Seoul';" ^
  -p 9080:80 ^
  -p 9443:443 ^
  -p 9022:22 ^
  --shm-size 2g ^
  -v D:\Docker\mount\gitlab\config:/etc/gitlab ^
  -v D:\Docker\mount\gitlab\logs:/var/log/gitlab ^
  -v D:\Docker\mount\gitlab\data:/var/opt/gitlab ^
  gitlab/gitlab-ce:latest

if %errorlevel% equ 0 (
    echo.
    echo ====================================
    echo GitLab 컨테이너 시작 완료!
    echo ====================================
    echo.
    echo 초기 시작 시 5-10분 정도 소요됩니다.
    echo 로그 확인: docker logs -f gitlab
    echo 접속 URL: http://gitlab.lbg.com:9080
    echo 관리자: root / gitlab1225!
    echo.
) else (
    echo.
    echo GitLab 컨테이너 시작 실패!
    echo.
)

:end
pause
```

### 9.2 백업 스크립트

위 섹션 6.2 참조: `backup-gitlab.bat`

### 9.3 복원 스크립트

`restore-gitlab.bat`:
```batch
@echo off
REM GitLab 복원 스크립트

SET BACKUP_FILE=%1

if "%BACKUP_FILE%"=="" (
    echo 사용법: restore-gitlab.bat [백업파일명]
    echo 예: restore-gitlab.bat 1732089600_2025_11_20_16.11.0_gitlab_backup.tar
    exit /b 1
)

echo ====================================
echo GitLab 복원 시작
echo ====================================
echo 백업 파일: %BACKUP_FILE%

REM 백업 파일 복사
echo 1. 백업 파일 복사 중...
docker cp "%BACKUP_FILE%" gitlab:/var/opt/gitlab/backups/

REM 파일명에서 확장자 제거
for %%F in ("%BACKUP_FILE%") do set BACKUP_NAME=%%~nF
set BACKUP_TIMESTAMP=%BACKUP_NAME:_gitlab_backup=%

REM GitLab 서비스 중지
echo 2. GitLab 서비스 중지 중...
docker exec gitlab gitlab-ctl stop puma
docker exec gitlab gitlab-ctl stop sidekiq

REM 복원 실행
echo 3. 데이터 복원 중...
docker exec gitlab gitlab-backup restore BACKUP=%BACKUP_TIMESTAMP% --force

REM GitLab 재시작
echo 4. GitLab 서비스 재시작 중...
docker exec gitlab gitlab-ctl restart
docker exec gitlab gitlab-rake gitlab:check SANITIZE=true

echo ====================================
echo 복원 완료!
echo ====================================
pause
```

### 9.4 헬스 체크 스크립트

`check-gitlab-health.bat`:
```batch
@echo off
REM GitLab 헬스 체크 스크립트

echo ====================================
echo GitLab 헬스 체크
echo ====================================

echo 1. 컨테이너 상태:
docker ps --filter "name=gitlab" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo 2. GitLab 서비스 상태:
docker exec gitlab gitlab-ctl status

echo.
echo 3. 디스크 사용량:
docker exec gitlab du -sh /var/opt/gitlab/git-data
docker exec gitlab du -sh /var/opt/gitlab/postgresql

echo.
echo 4. 메모리 사용량:
docker stats gitlab --no-stream

echo.
echo 5. GitLab 체크:
docker exec gitlab gitlab-rake gitlab:check

echo ====================================
echo 헬스 체크 완료
echo ====================================
pause
```

---

## 10. Docker Compose 예제

### 10.1 기본 Compose 파일

`docker-compose-gitlab.yml`:
```yaml
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: gitlab.lbg.com
    restart: always
    networks:
      - dev-net
    environment:
      TZ: Asia/Seoul
      GITLAB_ROOT_PASSWORD: gitlab1225!
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.lbg.com:9080'
        gitlab_rails['time_zone'] = 'Asia/Seoul'
        gitlab_rails['gitlab_shell_ssh_port'] = 9022
    ports:
      - "9080:80"
      - "9443:443"
      - "9022:22"
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
    shm_size: '2gb'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/-/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 300s

volumes:
  gitlab_config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\config
  gitlab_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\logs
  gitlab_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\data

networks:
  dev-net:
    external: true
```

실행:
```cmd
docker-compose -f docker-compose-gitlab.yml up -d
```

### 10.2 GitLab + GitLab Runner Compose

`docker-compose-gitlab-runner.yml`:
```yaml
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: gitlab.lbg.com
    restart: always
    networks:
      - dev-net
    environment:
      TZ: Asia/Seoul
      GITLAB_ROOT_PASSWORD: gitlab1225!
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.lbg.com:9080'
        gitlab_rails['time_zone'] = 'Asia/Seoul'
    ports:
      - "9080:80"
      - "9443:443"
      - "9022:22"
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
    shm_size: '2gb'

  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    networks:
      - dev-net
    volumes:
      - gitlab_runner_config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - gitlab
    environment:
      TZ: Asia/Seoul

volumes:
  gitlab_config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\config
  gitlab_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\logs
  gitlab_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab\data
  gitlab_runner_config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\gitlab-runner\config

networks:
  dev-net:
    external: true
```

Runner 등록:
```cmd
docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab.lbg.com:9080/" \
  --registration-token "YOUR_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "docker,linux" \
  --run-untagged="true" \
  --locked="false"
```

---

## 11. 보안 설정

### 11.1 HTTPS 설정 (자체 서명 인증서)

#### 1. 인증서 생성
```cmd
docker exec -it gitlab mkdir -p /etc/gitlab/ssl

docker exec -it gitlab openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
  -keyout /etc/gitlab/ssl/gitlab.lbg.com.key ^
  -out /etc/gitlab/ssl/gitlab.lbg.com.crt ^
  -subj "/C=KR/ST=Seoul/L=Seoul/O=LBG/OU=IT/CN=gitlab.lbg.com"
```

#### 2. GitLab 설정 수정
```cmd
docker exec -it gitlab vi /etc/gitlab/gitlab.rb
```

```ruby
# HTTPS 설정
external_url 'https://gitlab.lbg.com:9443'
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.lbg.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.lbg.com.key"
```

#### 3. 설정 적용
```cmd
docker exec -it gitlab gitlab-ctl reconfigure
docker exec -it gitlab gitlab-ctl restart nginx
```

### 11.2 사용자 인증 강화

#### 2단계 인증 (2FA) 강제
`/etc/gitlab/gitlab.rb`:
```ruby
gitlab_rails['require_two_factor_authentication'] = true
gitlab_rails['two_factor_grace_period'] = 168  # 7일
```

#### 비밀번호 정책
```ruby
gitlab_rails['password_authentication_enabled_for_web'] = true
gitlab_rails['password_authentication_enabled_for_git'] = true

# 비밀번호 복잡도
gitlab_rails['password_minimum_length'] = 10
```

### 11.3 IP 화이트리스트

```ruby
# 관리자 영역 접근 제한
gitlab_rails['admin_restricted_visibility_levels'] = ['public']

# Rack Attack 설정 (브루트 포스 방어)
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => ["127.0.0.1", "192.168.1.0/24"],
  'maxretry' => 10,
  'findtime' => 60,
  'bantime' => 3600
}
```

### 11.4 감사 로그 (EE만 해당)

```ruby
# 감사 이벤트 로깅
gitlab_rails['audit_events_enabled'] = true
```

### 11.5 LDAP/AD 통합

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
  main:
    label: 'LDAP'
    host: 'ldap.example.com'
    port: 389
    uid: 'sAMAccountName'
    bind_dn: 'CN=admin,DC=example,DC=com'
    password: 'password'
    encryption: 'plain'
    verify_certificates: true
    active_directory: true
    base: 'DC=example,DC=com'
EOS
```

설정 적용:
```cmd
docker exec -it gitlab gitlab-ctl reconfigure
docker exec -it gitlab gitlab-rake gitlab:ldap:check
```

---

## 12. 고급 기능

### 12.1 GitLab CI/CD 파이프라인

`.gitlab-ci.yml` 예제:
```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: gitlab.lbg.com:9080/project/app

build:
  stage: build
  image: maven:3.9-openjdk-17
  script:
    - mvn clean package -DskipTests
  artifacts:
    paths:
      - target/*.jar
    expire_in: 1 hour

test:
  stage: test
  image: maven:3.9-openjdk-17
  script:
    - mvn test
  dependencies:
    - build

deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHORT_SHA
  only:
    - main
```

### 12.2 Container Registry 설정

`/etc/gitlab/gitlab.rb`:
```ruby
registry_external_url 'http://gitlab.lbg.com:5050'
gitlab_rails['registry_enabled'] = true
```

재구성:
```cmd
docker exec -it gitlab gitlab-ctl reconfigure
```

이미지 푸시:
```bash
docker login gitlab.lbg.com:5050
docker tag my-app gitlab.lbg.com:5050/project/my-app:latest
docker push gitlab.lbg.com:5050/project/my-app:latest
```

### 12.3 Package Registry

#### Maven 패키지 배포
`pom.xml`:
```xml
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>http://gitlab.lbg.com:9080/api/v4/projects/PROJECT_ID/packages/maven</url>
  </repository>
</distributionManagement>
```

`settings.xml`:
```xml
<servers>
  <server>
    <id>gitlab-maven</id>
    <configuration>
      <httpHeaders>
        <property>
          <name>Private-Token</name>
          <value>YOUR_PERSONAL_ACCESS_TOKEN</value>
        </property>
      </httpHeaders>
    </configuration>
  </server>
</servers>
```

배포:
```bash
mvn deploy
```

#### npm 패키지 배포
`.npmrc`:
```
@myorg:registry=http://gitlab.lbg.com:9080/api/v4/projects/PROJECT_ID/packages/npm/
//gitlab.lbg.com:9080/api/v4/projects/PROJECT_ID/packages/npm/:_authToken=YOUR_TOKEN
```

배포:
```bash
npm publish
```

### 12.4 Wiki 및 문서화

- 각 프로젝트마다 내장 Wiki 제공
- Markdown 지원
- 버전 관리 (Git 기반)

Wiki Clone:
```bash
git clone http://gitlab.lbg.com:9080/username/project.wiki.git
```

### 12.5 프로젝트 미러링

#### Push Mirror (다른 Git 서버로 자동 푸시)
1. **Settings** → **Repository** → **Mirroring repositories**
2. Git repository URL 입력 (예: `https://github.com/user/repo.git`)
3. Mirror direction: **Push**
4. Authentication method 선택

#### Pull Mirror (다른 Git 서버에서 자동 풀)
- GitLab EE 전용 기능

### 12.6 Auto DevOps

Auto DevOps 활성화:
1. **Settings** → **CI/CD** → **Auto DevOps**
2. **Default to Auto DevOps pipeline** 체크
3. Base domain 설정 (Kubernetes 배포 시)

`.gitlab-ci.yml` 없이도 자동으로 빌드/테스트/배포 파이프라인 생성.

### 12.7 폐쇄망 구성

#### 폐쇄망 환경 개요
- 인터넷 접속이 차단된 환경에서 GitLab 운영
- Docker 이미지, Runner, 패키지 미러링 필요

#### 1. 인터넷 환경에서 준비

```bash
# GitLab 이미지 다운로드 및 저장
docker pull gitlab/gitlab-ce:latest
docker save -o gitlab-ce.tar gitlab/gitlab-ce:latest

# GitLab Runner 이미지
docker pull gitlab/gitlab-runner:latest
docker save -o gitlab-runner.tar gitlab/gitlab-runner:latest

# CI/CD에 필요한 이미지들
docker pull maven:3.9-openjdk-17
docker pull node:18
docker pull python:3.11
docker save -o ci-images.tar maven:3.9-openjdk-17 node:18 python:3.11
```

#### 2. USB/외장 하드로 전송

```
airgap-bundle/
├── docker-images/
│   ├── gitlab-ce.tar
│   ├── gitlab-runner.tar
│   └── ci-images.tar
├── configs/
│   ├── gitlab.rb
│   └── docker-compose.yml
└── scripts/
    ├── install-gitlab.sh
    └── register-runner.sh
```

#### 3. 폐쇄망에서 설치

```bash
# Docker 이미지 로드
docker load -i airgap-bundle/docker-images/gitlab-ce.tar
docker load -i airgap-bundle/docker-images/gitlab-runner.tar
docker load -i airgap-bundle/docker-images/ci-images.tar

# GitLab 실행
docker run -d \
  --name gitlab \
  --hostname gitlab.local \
  -p 9080:80 \
  -v /opt/gitlab/config:/etc/gitlab \
  -v /opt/gitlab/logs:/var/log/gitlab \
  -v /opt/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

#### 4. 패키지 미러 설정

`/etc/gitlab/gitlab.rb`:
```ruby
# npm 레지스트리 프록시 비활성화 (폐쇄망)
gitlab_rails['packages_enabled'] = true

# Maven Central 미러링 비활성화
# 대신 내부 Nexus 사용 권장
```

---

## 13. 참고 자료

### 13.1 공식 문서

- **GitLab 공식 사이트**: https://about.gitlab.com/
- **GitLab 문서**: https://docs.gitlab.com/
- **GitLab Docker 설치 가이드**: https://docs.gitlab.com/ee/install/docker.html
- **GitLab CI/CD 문서**: https://docs.gitlab.com/ee/ci/
- **GitLab API**: https://docs.gitlab.com/ee/api/

### 13.2 Docker Hub

- **GitLab CE 이미지**: https://hub.docker.com/r/gitlab/gitlab-ce
- **GitLab EE 이미지**: https://hub.docker.com/r/gitlab/gitlab-ee
- **GitLab Runner 이미지**: https://hub.docker.com/r/gitlab/gitlab-runner

### 13.3 유용한 도구

| 도구 | 용도 | 다운로드 |
|------|------|----------|
| Git | 버전 관리 클라이언트 | https://git-scm.com/ |
| SourceTree | Git GUI 클라이언트 | https://www.sourcetreeapp.com/ |
| GitKraken | Git GUI 클라이언트 | https://www.gitkraken.com/ |
| Postman | API 테스트 | https://www.postman.com/ |
| VS Code | 코드 에디터 (GitLab 통합) | https://code.visualstudio.com/ |

### 13.4 GitLab vs 경쟁 제품 비교

| 기능 | GitLab CE | GitHub | Bitbucket | Gitea |
|------|-----------|--------|-----------|-------|
| 가격 | 무료 | 무료/유료 | 무료/유료 | 무료 |
| 자체 호스팅 | ✓ | - | ✓ (유료) | ✓ |
| CI/CD | ✓ | ✓ | ✓ | 제한적 |
| Container Registry | ✓ | ✓ | - | - |
| Wiki | ✓ | ✓ | ✓ | ✓ |
| 이슈 추적 | ✓ | ✓ | ✓ | ✓ |
| 프로젝트 관리 | ✓ | ✓ | 제한적 | 제한적 |
| 리소스 요구량 | 높음 | - | 중간 | 낮음 |

**GitLab 장점:**
- 완전한 DevOps 플랫폼 (소스-빌드-배포 통합)
- 강력한 CI/CD 기능
- 자체 호스팅 가능 (데이터 통제)
- Container Registry, Package Registry 내장

**GitLab 단점:**
- 높은 리소스 요구량 (최소 4GB RAM)
- 초기 시작 시간 길음
- 복잡한 설정

### 13.5 커뮤니티 및 지원

- **GitLab Forum**: https://forum.gitlab.com/
- **GitLab Issue Tracker**: https://gitlab.com/gitlab-org/gitlab/-/issues
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/gitlab
- **GitLab YouTube**: https://www.youtube.com/gitlab

### 13.6 라이선스

- **GitLab CE**: MIT 라이선스 (오픈소스)
- **GitLab EE**: 상용 라이선스

### 13.7 추가 학습 자료

- **GitLab CI/CD 튜토리얼**: https://docs.gitlab.com/ee/ci/quick_start/
- **GitLab Runner 가이드**: https://docs.gitlab.com/runner/
- **GitLab Flow**: https://docs.gitlab.com/ee/topics/gitlab_flow.html
- **GitLab Security**: https://docs.gitlab.com/ee/security/

---

**문서 작성일**: 2025-11-20  
**문서 버전**: 1.0  
**작성자**: ByounggwanLee
