# Docker

## Windows 환경에 Docker 설치하기

### 시스템 요구사항
- Windows 10 64-bit: Pro, Enterprise, 또는 Education (Build 19041 이상)
- Windows 11 64-bit: Home, Pro, Enterprise, 또는 Education
- BIOS에서 하드웨어 가상화 지원 활성화
- 최소 4GB RAM (8GB 이상 권장)

### 설치 절차

#### 1. WSL 2 설치 및 설정

**PowerShell을 관리자 권한으로 실행**하여 다음 명령어를 실행합니다:

```powershell
# WSL 활성화
wsl --install
```

시스템을 재시작한 후, WSL 2가 기본 버전으로 설정되었는지 확인합니다:

```powershell
wsl --set-default-version 2
```

#### 2. Docker Desktop 다운로드

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) 공식 페이지 방문
2. "Download for Windows" 버튼 클릭하여 설치 파일 다운로드
3. `Docker Desktop Installer.exe` 파일 다운로드 완료 대기

#### 3. Docker Desktop 설치

1. 다운로드한 `Docker Desktop Installer.exe` 파일을 **관리자 권한으로 실행**
2. 설치 중 다음 옵션 선택:
   - ✅ **Use WSL 2 instead of Hyper-V** (권장)
   - ✅ **Add shortcut to desktop** (선택사항)
3. "Ok" 버튼을 클릭하여 설치 진행
4. 설치 완료 후 시스템 재시작

#### 4. Docker Desktop 실행 및 초기 설정

1. Docker Desktop 애플리케이션 실행
2. Docker Desktop 서비스 약관 동의
3. Docker Desktop이 시작될 때까지 대기 (시스템 트레이에서 Docker 아이콘 확인)
4. 선택사항: Docker Hub 계정으로 로그인

#### 5. 설치 확인

**명령 프롬프트(CMD)** 또는 **PowerShell**을 열고 다음 명령어를 실행합니다:

```cmd
docker --version
```

예상 출력:
```
Docker version 24.x.x, build xxxxxxx
```

Docker가 정상적으로 작동하는지 테스트:

```cmd
docker run hello-world
```

성공 메시지가 출력되면 설치가 완료된 것입니다.

### 추가 설정 (선택사항)

#### Docker Desktop 설정 최적화

Docker Desktop 실행 후 Settings (⚙️) 메뉴에서:

1. **Resources > Advanced**
   - CPUs: 시스템 CPU의 절반 정도 할당
   - Memory: 4GB 이상 할당 (시스템 메모리에 따라 조정)
   - Disk image size: 필요에 따라 조정

2. **General**
   - ✅ Start Docker Desktop when you log in (자동 시작)
   - ✅ Use the WSL 2 based engine

3. **Resources > WSL Integration**
   - 사용하려는 WSL 배포판 활성화

#### 문제 해결

**Docker Desktop이 시작되지 않는 경우:**
- Windows 기능에서 "Virtual Machine Platform"과 "Windows Subsystem for Linux"가 활성화되어 있는지 확인
- BIOS에서 가상화 기술(VT-x/AMD-V)이 활성화되어 있는지 확인
- 최신 Windows 업데이트 설치

**WSL 2 관련 오류:**
```powershell
# WSL 업데이트
wsl --update
```

**Docker 서비스 재시작:**
- 시스템 트레이에서 Docker 아이콘 우클릭 > "Restart Docker Desktop"

### 유용한 Docker 명령어

```cmd
# Docker 버전 확인
docker --version

# Docker 정보 확인
docker info

# 실행 중인 컨테이너 목록
docker ps

# 모든 컨테이너 목록
docker ps -a

# 이미지 목록 확인
docker images

# 컨테이너 중지
docker stop <container_id>

# 컨테이너 제거
docker rm <container_id>

# 이미지 제거
docker rmi <image_id>
```

## Docker Network

Docker 네트워크는 컨테이너 간의 통신과 외부 네트워크와의 연결을 관리합니다. 각 컨테이너는 독립적인 네트워크 스택을 가지며, Docker 네트워크를 통해 다른 컨테이너와 안전하게 통신할 수 있습니다.

### Docker 네트워크 드라이버 종류

#### 1. Bridge (기본)
- 가장 일반적으로 사용되는 네트워크 드라이버
- 같은 호스트의 컨테이너 간 통신에 사용
- 기본적으로 생성되는 `bridge` 네트워크 또는 사용자 정의 bridge 네트워크
- 외부 네트워크와 통신 시 NAT 사용

**특징:**
- 컨테이너 이름으로 DNS 해석 가능 (사용자 정의 bridge)
- 네트워크 격리 제공
- 포트 매핑으로 외부 접근 가능

#### 2. Host
- 컨테이너가 호스트의 네트워크 스택을 직접 사용
- 네트워크 격리 없음
- 포트 매핑 불필요 (호스트 포트 직접 사용)
- 최고의 네트워크 성능

#### 3. None
- 네트워크 비활성화
- 컨테이너가 완전히 격리됨
- 네트워크가 필요 없는 경우에 사용

#### 4. Overlay
- 여러 Docker 데몬(호스트) 간 통신
- Docker Swarm 또는 Kubernetes 환경에서 사용
- 분산 네트워크 구성

#### 5. Macvlan
- 컨테이너에 MAC 주소를 할당
- 물리적 네트워크의 장치처럼 동작
- 레거시 애플리케이션 마이그레이션에 유용

### Docker 네트워크 명령어

#### 네트워크 목록 조회
```cmd
# 모든 네트워크 목록
docker network ls

# 네트워크 상세 정보
docker network inspect <network_name>
```

#### 네트워크 생성
```cmd
# 기본 bridge 네트워크 생성
docker network create my-network

# 특정 드라이버로 네트워크 생성
docker network create --driver bridge my-bridge-network

# 서브넷 지정하여 네트워크 생성
docker network create --subnet=172.18.0.0/16 my-custom-network

# 게이트웨이 지정
docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 my-network
```

#### 컨테이너를 네트워크에 연결
```cmd
# 컨테이너 실행 시 네트워크 지정
docker run --network=my-network --name my-container nginx

# 실행 중인 컨테이너를 네트워크에 연결
docker network connect my-network my-container

# 컨테이너를 네트워크에서 분리
docker network disconnect my-network my-container
```

#### 네트워크 제거
```cmd
# 특정 네트워크 제거
docker network rm my-network

# 사용하지 않는 모든 네트워크 제거
docker network prune
```

### 실용 예제

#### 예제 1: 사용자 정의 Bridge 네트워크로 컨테이너 연결

```cmd
# 1. 네트워크 생성
docker network create app-network

# 2. 데이터베이스 컨테이너 실행
docker run -d --name mysql-db --network app-network -e MYSQL_ROOT_PASSWORD=password mysql:8.0

# 3. 애플리케이션 컨테이너 실행 (컨테이너 이름으로 DB 접근 가능)
docker run -d --name my-app --network app-network -e DB_HOST=mysql-db my-application
```

#### 예제 2: 여러 네트워크에 컨테이너 연결

```cmd
# 프론트엔드 네트워크 생성
docker network create frontend-network

# 백엔드 네트워크 생성
docker network create backend-network

# 웹 서버 (프론트엔드만)
docker run -d --name web --network frontend-network nginx

# API 서버 (프론트엔드와 백엔드 모두)
docker run -d --name api --network backend-network my-api
docker network connect frontend-network api

# 데이터베이스 (백엔드만)
docker run -d --name db --network backend-network postgres
```

#### 예제 3: Host 네트워크 사용

```cmd
# 호스트 네트워크 모드로 실행 (포트 매핑 불필요)
docker run -d --network host nginx
```

### 네트워크 격리 및 보안

#### 포트 노출 제어
```cmd
# 특정 포트만 외부에 노출
docker run -d --name web -p 8080:80 --network my-network nginx

# 호스트 IP 지정하여 포트 바인딩
docker run -d --name web -p 127.0.0.1:8080:80 nginx
```

#### 컨테이너 간 통신 제한
```cmd
# 컨테이너 간 통신 비활성화 (기본 bridge)
docker network create --driver bridge --opt com.docker.network.bridge.enable_icc=false isolated-network
```

### 네트워크 문제 해결

#### 컨테이너 네트워크 정보 확인
```cmd
# 컨테이너의 IP 주소 확인
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_name>

# 컨테이너의 모든 네트워크 정보
docker inspect <container_name>
```

#### 연결 테스트
```cmd
# 컨테이너 내부에서 다른 컨테이너로 ping
docker exec <container_name> ping <target_container_name>

# 컨테이너 내부에서 네트워크 도구 사용
docker exec -it <container_name> sh
```

#### 네트워크 상태 진단
```cmd
# 네트워크에 연결된 컨테이너 확인
docker network inspect <network_name>

# 특정 네트워크의 서브넷 정보
docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' <network_name>
```

### Docker Compose에서 네트워크 사용

```yaml
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
    ports:
      - "80:80"
  
  app:
    image: my-app
    networks:
      - frontend
      - backend
    depends_on:
      - db
  
  db:
    image: postgres
    networks:
      - backend
    environment:
      POSTGRES_PASSWORD: password

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 외부 접근 차단
```

### 네트워크 성능 최적화

#### MTU 설정
```cmd
# MTU 크기 지정하여 네트워크 생성
docker network create --opt com.docker.network.driver.mtu=1450 my-network
```

#### DNS 설정
```cmd
# 사용자 정의 DNS 서버 사용
docker run --dns 8.8.8.8 --dns 8.8.4.4 nginx
```

### 참고 자료
- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Desktop for Windows 문서](https://docs.docker.com/desktop/install/windows-install/)
- [WSL 2 설치 가이드](https://docs.microsoft.com/ko-kr/windows/wsl/install)