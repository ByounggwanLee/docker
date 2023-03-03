@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull tomcat

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name tomcat --network dev-net -e TZ=Asia/Seoul -v D:\Docker\mount\tomcat\webapps:/usr/local/tomcat/webapps  -d -p 9080:8080 tomcat:9
