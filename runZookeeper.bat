@echo off
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull wurstmeister/zookeeper

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run  -e TZ=Asia/Seoul -p 2181:2181 --name zookeeper --network dev-net -d wurstmeister/zookeeper
