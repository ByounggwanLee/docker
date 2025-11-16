@echo off
setlocal

REM -------------------------------
REM CONFIGURATION
REM -------------------------------
set CONTAINER_NAME=postgresql
set NETWORK_NAME=dev-net
set POSTGRES_PORT=5432
set POSTGRES_PASSWORD=1234
set POSTGRES_VERSION=17
REM PostgreSQL 18+ uses /var/lib/postgresql (without /data)
REM This allows pg_upgrade to work properly across versions
set DATA_PATH=D:\Docker\mount\postgres

echo Starting PostgreSQL Docker Container Setup...
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
echo Pulling PostgreSQL image...
docker pull postgres:%POSTGRES_VERSION%

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
echo Starting PostgreSQL container (version %POSTGRES_VERSION%)...
echo Note: Using /var/lib/postgresql mount for PostgreSQL 18+ compatibility
docker run -d ^
    -p %POSTGRES_PORT%:5432 ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e TZ=Asia/Seoul ^
    -e POSTGRES_PASSWORD=%POSTGRES_PASSWORD% ^
    -v %DATA_PATH%:/var/lib/postgresql ^
    postgres:%POSTGRES_VERSION%

if errorlevel 1 (
    echo Failed to start PostgreSQL container!
    exit /b 1
)

echo.
echo PostgreSQL container started successfully!
echo Container name: %CONTAINER_NAME%
echo Version: %POSTGRES_VERSION%
echo Port: %POSTGRES_PORT%
echo Password: %POSTGRES_PASSWORD%
echo Data path: %DATA_PATH%
echo Mount point: /var/lib/postgresql (PostgreSQL 18+ compatible)
echo.
echo Waiting for PostgreSQL to be ready...
timeout /t 5 /nobreak >nul

REM -------------------------------
REM VERIFY CONTAINER STATUS
REM -------------------------------
docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Connection string: postgresql://postgres:%POSTGRES_PASSWORD%@localhost:%POSTGRES_PORT%/postgres
echo.
echo NOTE: For PostgreSQL 18+, data is stored in /var/lib/postgresql/data
echo       This allows seamless pg_upgrade --link usage without mount boundary issues.
echo       See: https://github.com/docker-library/postgres/issues/37
echo.

endlocal
