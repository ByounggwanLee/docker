@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull postgres

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run -d -p 5432:5432 --name postgresql --network dev-net -e TZ=Asia/Seoul -e POSTGRES_PASSWORD=1234 -v D:\Docker\mount\postgres\data:/var/lib/postgres/data postgres
