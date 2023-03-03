@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull elleflorio/svn-server

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name svn --network dev-net -e TZ=Asia/Seoul -v D:\Docker\mount\svn:/home/svn -d -p 7443:80 -p 3690:3690 elleflorio/svn-server 