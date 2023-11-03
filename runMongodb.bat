@echo off
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull mongo

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run -e "TZ=Asia/Seoul" -p 1433:1433  -e MONGO_INITDB_ROOT_USERNAME=root -e MONGO_INITDB_ROOT_PASSWORD=qudrhks2!  --name mongodb --network dev-net --hostname mongodb -v d:\Docker\mount\mongodb\data:/data/db -d -p 27017:27017 mongo
