@echo off
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull wurstmeister/kafka

REM -------------------------------
REM run IMAGE
REM -------------------------------
docker run  -e TZ=Asia/Seoul -e "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092" -e "KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092" -e "KAFKA_ADVERTISED_HOST_NAME=127.0.0.1" -e "KAFKA_ADVERTISED_PORT=9092" -e "KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181" -e "KAFKA_CREATE_TOPICS=javainuse-topic:1:1" -p 9092:9092 --name kafka --network dev-net -v D:\Docker\mount\kafka\docker.sock:/var/run/docker.sock -d wurstmeister/kafka
