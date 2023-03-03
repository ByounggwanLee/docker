@echo off
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull mcr.microsoft.com/mssql/server:2022-latest

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=qudrhks2!" -e "TZ=Asia/Seoul" --shm-size 1g -p 1433:1433 --name mssql --network dev-net --hostname mssql -v d:\Docker\mount\mssql\data:/var/opt/mssql/data -v d:\Docker\mount\mssql\log:/var/opt/mssql/log -v d:\Docker\mount\mssql\secrets:/var/opt/mssql/secrets  -d mcr.microsoft.com/mssql/server:2022-latest
