@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull mysql

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name mysql --network dev-net  -e TZ=Asia/Seoul -e MYSQL_ROOT_PASSWORD=qudrhks2! -v D:\Docker\mount\mysql:/var/lib/mysql  -d -p 3306:3306 mysql:latest
