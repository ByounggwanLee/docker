@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull sonatype/nexus3

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name nexus --network dev-net -e TZ=Asia/Seoul -p "9083:8081" -v "D:\Docker\mount\nexus:/nexus-data" -d sonatype/nexus3