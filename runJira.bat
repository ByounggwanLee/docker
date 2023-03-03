@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull cptactionhank/atlassian-jira-software

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run --name "jira" --network dev-net -e TZ=Asia/Seoul -p "9082:8080" -v "D:\Docker\mount\jira:/var/atlassian/jira" -e "CATALINA_OPTS=-Xms1024m -Xmx2048m -Datlassian.plugins.enable.wait=300" -d cptactionhank/atlassian-jira-software:latest