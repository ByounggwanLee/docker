@echo off
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull jenkins/jenkins

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name jenkins --network dev-net -e TZ=Asia/Seoul -p 9081:8080 -p 50000:50000 -d -v D:\Docker\mount\jenkins\var\run\docker.sock:/var/run/docker.sock -v D:\Docker\mount\jenkins:/var/jenkins_home -u root jenkins/jenkins:latest