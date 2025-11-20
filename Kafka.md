# Docker를 활용한 Kafka 설치 및 구성 가이드

## 목차
1. [Kafka 소개](#1-kafka-소개)
2. [Kafka Docker 이미지 다운로드](#2-kafka-docker-이미지-다운로드)
3. [Kafka 컨테이너 실행](#3-kafka-컨테이너-실행)
4. [Topic 생성 및 관리](#4-topic-생성-및-관리)
5. [접속 정보](#5-접속-정보)
6. [백업 및 복원](#6-백업-및-복원)
7. [모니터링](#7-모니터링)
8. [문제 해결](#8-문제-해결)
9. [자동화 스크립트](#9-자동화-스크립트)
10. [Docker Compose 예제](#10-docker-compose-예제)
11. [보안 설정](#11-보안-설정)
12. [Spring Boot 연동](#12-spring-boot-연동)
13. [참고 자료](#13-참고-자료)

---

## 1. Kafka 소개

Apache Kafka는 LinkedIn에서 개발한 분산 스트리밍 플랫폼으로, 대용량 실시간 데이터 파이프라인과 스트리밍 애플리케이션을 구축하는 데 사용됩니다. 높은 처리량, 내결함성, 확장성을 제공하여 Pub/Sub 메시징 시스템으로 널리 사용됩니다.

### 1.1 주요 특징

- **높은 처리량**: 초당 수백만 건의 메시지 처리
- **확장성**: 클러스터 확장을 통한 수평 확장
- **내결함성**: 데이터 복제를 통한 안정성
- **영속성**: 디스크에 메시지 저장
- **실시간 처리**: 낮은 지연 시간

### 1.2 구성 요소

| 구성 요소 | 설명 | 역할 |
|-----------|------|------|
| **Broker** | Kafka 서버 | 메시지 저장 및 전달 |
| **Zookeeper** | 분산 코디네이터 | 클러스터 메타데이터 관리 |
| **Producer** | 메시지 생성자 | Topic에 메시지 발행 |
| **Consumer** | 메시지 소비자 | Topic에서 메시지 구독 |
| **Topic** | 메시지 카테고리 | 메시지 분류 단위 |

### 1.3 기본 구성 정보

- **Kafka 포트**: 9092
- **Zookeeper 포트**: 2181
- **네트워크**: dev-net
- **볼륨 마운트**: D:\Docker\mount\kafka, D:\Docker\mount\zookeeper

---

## 2. Kafka Docker 이미지 다운로드

### 2.1 이미지 선택

```cmd
REM Kafka 이미지 다운로드
docker pull wurstmeister/kafka:latest

REM Zookeeper 이미지 다운로드
docker pull wurstmeister/zookeeper:latest
```

### 2.2 이미지 버전 비교

| 이미지 | 태그 | 크기 | 설명 | 권장 용도 |
|--------|------|------|------|-----------|
| wurstmeister/kafka | latest | ~400MB | 최신 Kafka | 개발/프로덕션 |
| wurstmeister/kafka | 2.13-2.8.1 | ~400MB | Kafka 2.8.1 | 안정 버전 |
| bitnami/kafka | latest | ~600MB | Bitnami 버전 | 프로덕션 |
| confluentinc/cp-kafka | latest | ~800MB | Confluent Platform | 엔터프라이즈 |

| Zookeeper 이미지 | 태그 | 크기 | 설명 |
|------------------|------|------|------|
| wurstmeister/zookeeper | latest | ~150MB | 기본 Zookeeper |
| bitnami/zookeeper | latest | ~200MB | Bitnami 버전 |
| zookeeper | 3.7 | ~280MB | 공식 이미지 |

**권장**: `wurstmeister/kafka:latest` + `wurstmeister/zookeeper:latest` (경량, 사용 편리)

---

## 3. Kafka 컨테이너 실행

### 3.1 사전 준비

```cmd
REM 네트워크 생성
docker network create dev-net

REM 데이터 디렉토리 생성
mkdir D:\Docker\mount\kafka
mkdir D:\Docker\mount\zookeeper\data
mkdir D:\Docker\mount\zookeeper\logs
```

### 3.2 Zookeeper 실행

#### 단일 Zookeeper (개발 환경)

```cmd
docker run -d ^
  --name zookeeper ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -p 2181:2181 ^
  -v D:\Docker\mount\zookeeper\data:/data ^
  -v D:\Docker\mount\zookeeper\logs:/datalog ^
  wurstmeister/zookeeper:latest
```

#### Zookeeper 앙상블 (프로덕션 환경 - 3노드)

**Zookeeper 1:**
```cmd
docker run -d ^
  --name zookeeper1 ^
  --network dev-net ^
  -e ZOO_MY_ID=1 ^
  -e ZOO_SERVERS="server.1=0.0.0.0:2888:3888;2181 server.2=zookeeper2:2888:3888;2181 server.3=zookeeper3:2888:3888;2181" ^
  -e TZ=Asia/Seoul ^
  -p 2181:2181 ^
  -p 2888:2888 ^
  -p 3888:3888 ^
  -v D:\Docker\mount\zookeeper1\data:/data ^
  -v D:\Docker\mount\zookeeper1\logs:/datalog ^
  zookeeper:3.7
```

**Zookeeper 2:**
```cmd
docker run -d ^
  --name zookeeper2 ^
  --network dev-net ^
  -e ZOO_MY_ID=2 ^
  -e ZOO_SERVERS="server.1=zookeeper1:2888:3888;2181 server.2=0.0.0.0:2888:3888;2181 server.3=zookeeper3:2888:3888;2181" ^
  -e TZ=Asia/Seoul ^
  -p 2182:2181 ^
  -p 2889:2888 ^
  -p 3889:3888 ^
  -v D:\Docker\mount\zookeeper2\data:/data ^
  -v D:\Docker\mount\zookeeper2\logs:/datalog ^
  zookeeper:3.7
```

**Zookeeper 3:**
```cmd
docker run -d ^
  --name zookeeper3 ^
  --network dev-net ^
  -e ZOO_MY_ID=3 ^
  -e ZOO_SERVERS="server.1=zookeeper1:2888:3888;2181 server.2=zookeeper2:2888:3888;2181 server.3=0.0.0.0:2888:3888;2181" ^
  -e TZ=Asia/Seoul ^
  -p 2183:2181 ^
  -p 2890:2888 ^
  -p 3890:3888 ^
  -v D:\Docker\mount\zookeeper3\data:/data ^
  -v D:\Docker\mount\zookeeper3\logs:/datalog ^
  zookeeper:3.7
```

**Zookeeper 앙상블 환경 변수:**

| 환경 변수 | 설명 | 예시 |
|-----------|------|------|
| `ZOO_MY_ID` | Zookeeper 노드 ID | 1, 2, 3 |
| `ZOO_SERVERS` | 클러스터 노드 목록 | server.1=host:2888:3888 |
| `ZOO_TICK_TIME` | 기본 시간 단위 (ms) | 2000 |
| `ZOO_INIT_LIMIT` | 초기 동기화 시간 | 10 |
| `ZOO_SYNC_LIMIT` | 동기화 시간 제한 | 5 |

**Zookeeper 포트:**
- **2181**: 클라이언트 연결 포트
- **2888**: Follower가 Leader에 연결하는 포트
- **3888**: Leader 선출 포트

### 3.3 Kafka 실행

#### Windows CMD
```cmd
docker run -d ^
  --name kafka ^
  --network dev-net ^
  -e TZ=Asia/Seoul ^
  -e KAFKA_BROKER_ID=1 ^
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 ^
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 ^
  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 ^
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true ^
  -e KAFKA_LOG_RETENTION_HOURS=168 ^
  -p 9092:9092 ^
  -v D:\Docker\mount\kafka:/kafka ^
  wurstmeister/kafka:latest
```

#### Windows (PowerShell)
```powershell
docker run -d `
  --name kafka `
  --network dev-net `
  -e TZ=Asia/Seoul `
  -e KAFKA_BROKER_ID=1 `
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 `
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 `
  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 `
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true `
  -e KAFKA_LOG_RETENTION_HOURS=168 `
  -p 9092:9092 `
  -v D:\Docker\mount\kafka:/kafka `
  wurstmeister/kafka:latest
```

#### Linux/Mac
```bash
docker run -d \
  --name kafka \
  --network dev-net \
  -e TZ=Asia/Seoul \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
  -e KAFKA_LOG_RETENTION_HOURS=168 \
  -p 9092:9092 \
  -v /docker/mount/kafka:/kafka \
  wurstmeister/kafka:latest
```
  wurstmeister/kafka:latest
```

### 3.4 환경 변수 설명

| 환경 변수 | 설명 | 기본값 | 권장값 |
|-----------|------|--------|--------|
| `KAFKA_BROKER_ID` | Broker 고유 ID | 1 | 1 (단일), 1,2,3 (클러스터) |
| `KAFKA_ZOOKEEPER_CONNECT` | Zookeeper 연결 정보 | 필수 | zookeeper:2181 |
| `KAFKA_ADVERTISED_LISTENERS` | 외부 접속 주소 | 필수 | PLAINTEXT://localhost:9092 |
| `KAFKA_LISTENERS` | 내부 Listener 주소 | 필수 | PLAINTEXT://0.0.0.0:9092 |
| `KAFKA_AUTO_CREATE_TOPICS_ENABLE` | 자동 Topic 생성 | false | true (개발) |
| `KAFKA_LOG_RETENTION_HOURS` | 로그 보관 시간 | 168 | 168 (7일) |
| `KAFKA_NUM_PARTITIONS` | 기본 파티션 수 | 1 | 3 |
| `KAFKA_DEFAULT_REPLICATION_FACTOR` | 복제 팩터 | 1 | 1 (단일), 3 (클러스터) |

### 3.5 컨테이너 상태 확인

```cmd
REM 컨테이너 실행 상태 확인
docker ps --filter "name=zookeeper"
docker ps --filter "name=kafka"

REM Zookeeper 로그 확인
docker logs zookeeper

REM Kafka 로그 확인
docker logs kafka
docker logs -f kafka

REM 컨테이너 정보 확인
docker inspect kafka
```

---

## 4. Topic 생성 및 관리

### 4.1 Topic 생성

```cmd
REM 기본 Topic 생성
docker exec kafka kafka-topics.sh --create ^
  --topic test-topic ^
  --bootstrap-server localhost:9092 ^
  --partitions 3 ^
  --replication-factor 1

REM 설정 옵션이 있는 Topic 생성
docker exec kafka kafka-topics.sh --create ^
  --topic orders ^
  --bootstrap-server localhost:9092 ^
  --partitions 5 ^
  --replication-factor 1 ^
  --config retention.ms=604800000 ^
  --config segment.ms=86400000
```

### 4.2 Topic 목록 조회

```cmd
REM 모든 Topic 목록
docker exec kafka kafka-topics.sh --list ^
  --bootstrap-server localhost:9092

REM Topic 상세 정보
docker exec kafka kafka-topics.sh --describe ^
  --topic test-topic ^
  --bootstrap-server localhost:9092

REM 모든 Topic 상세 정보
docker exec kafka kafka-topics.sh --describe ^
  --bootstrap-server localhost:9092
```

### 4.3 Topic 수정

```cmd
REM 파티션 수 증가 (감소 불가)
docker exec kafka kafka-topics.sh --alter ^
  --topic test-topic ^
  --partitions 5 ^
  --bootstrap-server localhost:9092

REM Topic 설정 변경
docker exec kafka kafka-configs.sh --alter ^
  --entity-type topics ^
  --entity-name test-topic ^
  --add-config retention.ms=86400000 ^
  --bootstrap-server localhost:9092

REM 설정 조회
docker exec kafka kafka-configs.sh --describe ^
  --entity-type topics ^
  --entity-name test-topic ^
  --bootstrap-server localhost:9092
```

### 4.4 Topic 삭제

```cmd
REM Topic 삭제
docker exec kafka kafka-topics.sh --delete ^
  --topic test-topic ^
  --bootstrap-server localhost:9092
```

### 4.5 메시지 생성 및 소비 테스트

```cmd
REM Producer 테스트
docker exec -it kafka kafka-console-producer.sh ^
  --topic test-topic ^
  --bootstrap-server localhost:9092

REM 메시지 입력 후 Ctrl+C로 종료

REM Consumer 테스트 (처음부터 읽기)
docker exec -it kafka kafka-console-consumer.sh ^
  --topic test-topic ^
  --from-beginning ^
  --bootstrap-server localhost:9092

REM Consumer 테스트 (최신 메시지만)
docker exec -it kafka kafka-console-consumer.sh ^
  --topic test-topic ^
  --bootstrap-server localhost:9092
```

---

## 5. 접속 정보

### 5.1 기본 접속 정보

| 항목 | 값 |
|------|-----|
| Kafka 호스트 | localhost (또는 Docker 호스트 IP) |
| Kafka 포트 | 9092 |
| Zookeeper 호스트 | localhost |
| Zookeeper 포트 | 2181 |
| Bootstrap Servers | localhost:9092 |
| 네트워크 | dev-net |

### 5.2 Java (Spring Boot) 연결

#### application.yml
```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    consumer:
      group-id: my-consumer-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
```

#### pom.xml
```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

#### Producer 예제
```java
@Service
public class KafkaProducerService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void sendMessage(String topic, String message) {
        kafkaTemplate.send(topic, message);
    }
    
    public void sendMessageWithKey(String topic, String key, String message) {
        kafkaTemplate.send(topic, key, message);
    }
}
```

#### Consumer 예제
```java
@Service
public class KafkaConsumerService {
    
    @KafkaListener(topics = "test-topic", groupId = "my-consumer-group")
    public void consume(String message) {
        System.out.println("Consumed message: " + message);
    }
    
    @KafkaListener(topics = "orders", groupId = "order-consumer-group")
    public void consumeOrder(ConsumerRecord<String, String> record) {
        System.out.println("Key: " + record.key());
        System.out.println("Value: " + record.value());
        System.out.println("Partition: " + record.partition());
        System.out.println("Offset: " + record.offset());
    }
}
```

### 5.3 Python 연결

```python
from kafka import KafkaProducer, KafkaConsumer
import json

# Producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

producer.send('test-topic', {'message': 'Hello Kafka'})
producer.flush()

# Consumer
consumer = KafkaConsumer(
    'test-topic',
    bootstrap_servers=['localhost:9092'],
    auto_offset_reset='earliest',
    group_id='my-consumer-group',
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

for message in consumer:
    print(f"Received: {message.value}")
```

### 5.4 Node.js 연결

```javascript
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: ['localhost:9092']
});

// Producer
const producer = kafka.producer();
await producer.connect();
await producer.send({
  topic: 'test-topic',
  messages: [
    { key: 'key1', value: 'Hello Kafka' }
  ]
});
await producer.disconnect();

// Consumer
const consumer = kafka.consumer({ groupId: 'my-consumer-group' });
await consumer.connect();
await consumer.subscribe({ topic: 'test-topic', fromBeginning: true });

await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    console.log({
      value: message.value.toString(),
      key: message.key?.toString(),
    });
  },
});
```

---

## 6. 백업 및 복원

### 6.1 Topic 메타데이터 백업

```cmd
REM 백업 디렉토리 생성
mkdir D:\Docker\backup\kafka

REM Topic 목록 백업
docker exec kafka kafka-topics.sh --list ^
  --bootstrap-server localhost:9092 > D:\Docker\backup\kafka\topics_list_%date:~0,4%%date:~5,2%%date:~8,2%.txt

REM 모든 Topic 상세 정보 백업
docker exec kafka kafka-topics.sh --describe ^
  --bootstrap-server localhost:9092 > D:\Docker\backup\kafka\topics_describe_%date:~0,4%%date:~5,2%%date:~8,2%.txt
```

### 6.2 Consumer Offset 백업

```cmd
REM Consumer Group 목록
docker exec kafka kafka-consumer-groups.sh --list ^
  --bootstrap-server localhost:9092 > D:\Docker\backup\kafka\consumer_groups_%date:~0,4%%date:~5,2%%date:~8,2%.txt

REM Consumer Group Offset 조회
docker exec kafka kafka-consumer-groups.sh --describe ^
  --group my-consumer-group ^
  --bootstrap-server localhost:9092 > D:\Docker\backup\kafka\consumer_offsets_%date:~0,4%%date:~5,2%%date:~8,2%.txt
```

### 6.3 데이터 디렉토리 백업

```cmd
REM Kafka 컨테이너 정지
docker stop kafka

REM 데이터 디렉토리 백업
xcopy D:\Docker\mount\kafka D:\Docker\backup\kafka\data_%date:~0,4%%date:~5,2%%date:~8,2% /E /I /H /Y

REM Kafka 컨테이너 시작
docker start kafka
```

### 6.4 Topic 데이터 복원 스크립트

Topic 재생성 스크립트 예제:
```cmd
REM Topic 재생성
docker exec kafka kafka-topics.sh --create ^
  --topic test-topic ^
  --bootstrap-server localhost:9092 ^
  --partitions 3 ^
  --replication-factor 1
```

---

## 7. 모니터링

### 7.1 Broker 상태 확인

```cmd
REM Broker 정보
docker exec kafka kafka-broker-api-versions.sh ^
  --bootstrap-server localhost:9092

REM Broker 설정 확인
docker exec kafka kafka-configs.sh --describe ^
  --entity-type brokers ^
  --entity-name 1 ^
  --bootstrap-server localhost:9092
```

### 7.2 Topic 모니터링

```cmd
REM Topic 크기 확인 (로그 디렉토리)
docker exec kafka du -sh /kafka/kafka-logs-*

REM Topic 상세 정보
docker exec kafka kafka-topics.sh --describe ^
  --topic test-topic ^
  --bootstrap-server localhost:9092

REM 파티션별 메시지 수
docker exec kafka kafka-run-class.sh kafka.tools.GetOffsetShell ^
  --broker-list localhost:9092 ^
  --topic test-topic ^
  --time -1
```

### 7.3 Consumer Group 모니터링

```cmd
REM Consumer Group 목록
docker exec kafka kafka-consumer-groups.sh --list ^
  --bootstrap-server localhost:9092

REM Consumer Group 상세 정보 (Lag 확인)
docker exec kafka kafka-consumer-groups.sh --describe ^
  --group my-consumer-group ^
  --bootstrap-server localhost:9092

REM 모든 Consumer Group 상태
docker exec kafka kafka-consumer-groups.sh --all-groups --describe ^
  --bootstrap-server localhost:9092
```

### 7.4 성능 모니터링

```cmd
REM 메시지 생성 성능 테스트
docker exec kafka kafka-producer-perf-test.sh ^
  --topic test-topic ^
  --num-records 10000 ^
  --record-size 1024 ^
  --throughput -1 ^
  --producer-props bootstrap.servers=localhost:9092

REM 메시지 소비 성능 테스트
docker exec kafka kafka-consumer-perf-test.sh ^
  --topic test-topic ^
  --messages 10000 ^
  --bootstrap-server localhost:9092
```

### 7.5 Zookeeper 모니터링

#### Zookeeper 상태 확인

```cmd
REM Zookeeper 4글자 명령어 활성화 확인
docker exec zookeeper zkServer.sh status

REM Zookeeper 연결 테스트
docker exec -it zookeeper zkCli.sh -server localhost:2181

REM Zookeeper 노드 확인
docker exec zookeeper zkCli.sh -server localhost:2181 ls /
docker exec zookeeper zkCli.sh -server localhost:2181 ls /brokers/ids

REM Kafka Broker 등록 정보 확인
docker exec zookeeper zkCli.sh -server localhost:2181 get /brokers/ids/1
```

#### 4글자 명령어 (Four Letter Words)

```cmd
REM 서버 상태 (stat)
echo stat | docker exec -i zookeeper nc localhost 2181

REM 서버 설정 (conf)
echo conf | docker exec -i zookeeper nc localhost 2181

REM 연결 정보 (cons)
echo cons | docker exec -i zookeeper nc localhost 2181

REM 환경 변수 (envi)
echo envi | docker exec -i zookeeper nc localhost 2181

REM 간단한 상태 (ruok)
echo ruok | docker exec -i zookeeper nc localhost 2181
# 응답: imok (정상)

REM 모니터링 정보 (mntr)
echo mntr | docker exec -i zookeeper nc localhost 2181
```

**주요 메트릭:**
```
zk_version: Zookeeper 버전
zk_avg_latency: 평균 지연 시간
zk_max_latency: 최대 지연 시간
zk_packets_received: 수신 패킷 수
zk_packets_sent: 송신 패킷 수
zk_num_alive_connections: 활성 연결 수
zk_outstanding_requests: 대기 중인 요청 수
zk_server_state: 서버 상태 (leader/follower/standalone)
```

#### Zookeeper 앙상블 모니터링

```cmd
REM Leader 확인
echo stat | docker exec -i zookeeper1 nc localhost 2181 | grep Mode
echo stat | docker exec -i zookeeper2 nc localhost 2181 | grep Mode
echo stat | docker exec -i zookeeper3 nc localhost 2181 | grep Mode

REM 앙상블 동기화 상태
echo mntr | docker exec -i zookeeper1 nc localhost 2181 | grep zk_synced_followers

REM 각 노드 연결 수
echo mntr | docker exec -i zookeeper1 nc localhost 2181 | grep zk_num_alive_connections
echo mntr | docker exec -i zookeeper2 nc localhost 2181 | grep zk_num_alive_connections
echo mntr | docker exec -i zookeeper3 nc localhost 2181 | grep zk_num_alive_connections
```

---

## 8. 문제 해결

### 8.1 Zookeeper 연결 실패

```cmd
REM Zookeeper 상태 확인
docker logs zookeeper

REM Zookeeper 재시작
docker restart zookeeper

REM Kafka 재시작
docker restart kafka

REM 네트워크 연결 확인
docker exec kafka ping zookeeper
```

### 8.2 Kafka 연결 실패

```cmd
REM 1. 컨테이너 상태 확인
docker ps --filter "name=kafka"

REM 2. 로그 확인
docker logs kafka --tail 100

REM 3. 포트 바인딩 확인
docker port kafka

REM 4. 네트워크 확인
docker network inspect dev-net

REM 5. Listener 설정 확인
docker exec kafka cat /opt/kafka/config/server.properties | grep listeners
```

**일반적인 문제:**
- `KAFKA_ADVERTISED_LISTENERS` 설정 오류 → localhost:9092로 수정
- Zookeeper가 실행되지 않음 → Zookeeper 먼저 시작
- 포트 충돌 (9092) → 다른 포트 사용 (-p 9093:9092)

### 8.3 Topic 생성 실패

```cmd
REM Auto create 활성화 확인
docker exec kafka kafka-configs.sh --describe ^
  --entity-type brokers ^
  --entity-name 1 ^
  --bootstrap-server localhost:9092 | grep auto.create

REM 수동으로 Topic 생성
docker exec kafka kafka-topics.sh --create ^
  --topic test-topic ^
  --bootstrap-server localhost:9092 ^
  --partitions 1 ^
  --replication-factor 1
```

### 8.4 Consumer Lag 증가

```cmd
REM Consumer Lag 확인
docker exec kafka kafka-consumer-groups.sh --describe ^
  --group my-consumer-group ^
  --bootstrap-server localhost:9092

REM 해결 방법:
REM 1. Consumer 인스턴스 증가 (파티션 수만큼)
REM 2. Consumer 처리 로직 최적화
REM 3. 파티션 수 증가

REM 파티션 증가
docker exec kafka kafka-topics.sh --alter ^
  --topic test-topic ^
  --partitions 5 ^
  --bootstrap-server localhost:9092
```

### 8.5 디스크 공간 부족

```cmd
REM 로그 보관 시간 단축
docker exec kafka kafka-configs.sh --alter ^
  --entity-type topics ^
  --entity-name test-topic ^
  --add-config retention.ms=86400000 ^
  --bootstrap-server localhost:9092

REM 로그 삭제 (주의: 데이터 손실)
docker exec kafka kafka-topics.sh --delete ^
  --topic old-topic ^
  --bootstrap-server localhost:9092

REM 로그 디렉토리 정리
docker exec kafka rm -rf /kafka/kafka-logs-*/test-topic-*
```

---

## 9. 자동화 스크립트

### 9.1 Zookeeper 실행 스크립트

`runZookeeper.bat`:
```batch
@echo off
setlocal

set CONTAINER_NAME=zookeeper
set NETWORK_NAME=dev-net
set PORT=2181
set DATA_DIR=D:\Docker\mount\zookeeper\data
set LOG_DIR=D:\Docker\mount\zookeeper\logs

echo Starting Zookeeper Docker Container...
echo.

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

docker network inspect %NETWORK_NAME% >nul 2>&1
if errorlevel 1 (
    echo Creating network: %NETWORK_NAME%
    docker network create %NETWORK_NAME%
)

echo Pulling Zookeeper image...
docker pull wurstmeister/zookeeper:latest

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /X %CONTAINER_NAME% >nul 2>&1
if not errorlevel 1 (
    echo Stopping existing container...
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
)

echo Starting Zookeeper container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e TZ=Asia/Seoul ^
    -p %PORT%:2181 ^
    -v %DATA_DIR%:/data ^
    -v %LOG_DIR%:/datalog ^
    wurstmeister/zookeeper:latest

if errorlevel 1 (
    echo Failed to start Zookeeper container!
    exit /b 1
)

echo.
echo Zookeeper started successfully!
echo Container: %CONTAINER_NAME%
echo Port: %PORT%
echo.

timeout /t 5 /nobreak >nul
docker logs %CONTAINER_NAME% --tail 20

endlocal
```

### 9.2 Kafka 실행 스크립트

`runKafka.bat`:
```batch
@echo off
setlocal

set CONTAINER_NAME=kafka
set NETWORK_NAME=dev-net
set PORT=9092
set DATA_DIR=D:\Docker\mount\kafka

echo Starting Kafka Docker Container...
echo.

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

docker network inspect %NETWORK_NAME% >nul 2>&1
if errorlevel 1 (
    echo Network %NETWORK_NAME% not found! Please start Zookeeper first.
    exit /b 1
)

echo Checking Zookeeper...
docker ps --filter "name=zookeeper" --format "{{.Names}}" | findstr zookeeper >nul 2>&1
if errorlevel 1 (
    echo Zookeeper is not running! Please start Zookeeper first.
    exit /b 1
)

echo Pulling Kafka image...
docker pull wurstmeister/kafka:latest

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /X %CONTAINER_NAME% >nul 2>&1
if not errorlevel 1 (
    echo Stopping existing container...
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
)

echo Starting Kafka container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --network %NETWORK_NAME% ^
    -e TZ=Asia/Seoul ^
    -e KAFKA_BROKER_ID=1 ^
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 ^
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 ^
    -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 ^
    -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true ^
    -e KAFKA_LOG_RETENTION_HOURS=168 ^
    -e KAFKA_NUM_PARTITIONS=3 ^
    -p %PORT%:9092 ^
    -v %DATA_DIR%:/kafka ^
    wurstmeister/kafka:latest

if errorlevel 1 (
    echo Failed to start Kafka container!
    exit /b 1
)

echo.
echo Kafka started successfully!
echo Container: %CONTAINER_NAME%
echo Port: %PORT%
echo Bootstrap Servers: localhost:%PORT%
echo.

echo Waiting for Kafka to be ready...
timeout /t 10 /nobreak >nul

docker logs %CONTAINER_NAME% --tail 20

endlocal
```

### 9.3 Topic 생성 스크립트

`create_topics.bat`:
```batch
@echo off
setlocal

set CONTAINER_NAME=kafka

echo Creating Kafka Topics...
echo.

REM test-topic 생성
echo Creating test-topic...
docker exec %CONTAINER_NAME% kafka-topics.sh --create ^
  --topic test-topic ^
  --bootstrap-server localhost:9092 ^
  --partitions 3 ^
  --replication-factor 1

REM orders topic 생성
echo Creating orders topic...
docker exec %CONTAINER_NAME% kafka-topics.sh --create ^
  --topic orders ^
  --bootstrap-server localhost:9092 ^
  --partitions 5 ^
  --replication-factor 1 ^
  --config retention.ms=604800000

REM events topic 생성
echo Creating events topic...
docker exec %CONTAINER_NAME% kafka-topics.sh --create ^
  --topic events ^
  --bootstrap-server localhost:9092 ^
  --partitions 3 ^
  --replication-factor 1

echo.
echo Topic creation completed!
echo.

echo Topic List:
docker exec %CONTAINER_NAME% kafka-topics.sh --list ^
  --bootstrap-server localhost:9092

endlocal
```

### 9.4 백업 스크립트

`backup_kafka.bat`:
```batch
@echo off
setlocal

set CONTAINER_NAME=kafka
set BACKUP_DIR=D:\Docker\backup\kafka
set DATE_STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
set DATE_STAMP=%DATE_STAMP: =0%

echo Kafka Backup Script
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Backing up Topic metadata...
docker exec %CONTAINER_NAME% kafka-topics.sh --list ^
  --bootstrap-server localhost:9092 > "%BACKUP_DIR%\topics_list_%DATE_STAMP%.txt"

docker exec %CONTAINER_NAME% kafka-topics.sh --describe ^
  --bootstrap-server localhost:9092 > "%BACKUP_DIR%\topics_describe_%DATE_STAMP%.txt"

echo Backing up Consumer Groups...
docker exec %CONTAINER_NAME% kafka-consumer-groups.sh --list ^
  --bootstrap-server localhost:9092 > "%BACKUP_DIR%\consumer_groups_%DATE_STAMP%.txt"

echo.
echo Backup completed!
echo Location: %BACKUP_DIR%

endlocal
```

---

## 10. Docker Compose 예제

### 10.1 docker-compose.yml

```yaml
version: '3.8'

services:
  zookeeper:
    image: wurstmeister/zookeeper:latest
    container_name: zookeeper
    restart: unless-stopped
    environment:
      TZ: Asia/Seoul
    ports:
      - "2181:2181"
    volumes:
      - zookeeper_data:/data
      - zookeeper_logs:/datalog
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "2181"]
      interval: 30s
      timeout: 10s
      retries: 5

  kafka:
    image: wurstmeister/kafka:latest
    container_name: kafka
    restart: unless-stopped
    depends_on:
      - zookeeper
    environment:
      TZ: Asia/Seoul
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 1
      KAFKA_CREATE_TOPICS: "test-topic:3:1,orders:5:1,events:3:1"
    ports:
      - "9092:9092"
    volumes:
      - kafka_data:/kafka
    networks:
      - dev-net
    healthcheck:
      test: ["CMD", "kafka-topics.sh", "--list", "--bootstrap-server", "localhost:9092"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    restart: unless-stopped
    depends_on:
      - kafka
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    ports:
      - "8080:8080"
    networks:
      - dev-net

volumes:
  zookeeper_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\zookeeper\data
  zookeeper_logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\zookeeper\logs
  kafka_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: D:\Docker\mount\kafka

networks:
  dev-net:
    driver: bridge
```

### 10.2 실행 방법

```cmd
REM 초기 실행
docker-compose up -d

REM 로그 확인
docker-compose logs -f

REM 특정 서비스 로그
docker-compose logs -f kafka

REM 컨테이너 재시작
docker-compose restart

REM 컨테이너 정지
docker-compose down

REM 완전 정리 (볼륨 삭제)
docker-compose down -v
```

### 10.3 Kafka UI 접속

브라우저에서 `http://localhost:8080` 접속

**주요 기능:**
- Topic 목록 및 상세 정보
- Consumer Group 모니터링
- 메시지 검색 및 조회
- Broker 상태 확인

---

## 11. 보안 설정

### 11.1 SASL 인증 설정

Kafka 환경 변수 추가:
```yaml
environment:
  KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
  KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
  KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
  KAFKA_OPTS: "-Djava.security.auth.login.config=/opt/kafka/config/kafka_server_jaas.conf"
```

`kafka_server_jaas.conf`:
```
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="admin1225!"
    user_admin="admin1225!"
    user_producer="producer1225!"
    user_consumer="consumer1225!";
};
```

### 11.2 SSL/TLS 암호화

인증서 생성 및 설정 (프로덕션 환경):
```cmd
REM Keystore 생성
keytool -keystore kafka.server.keystore.jks -alias localhost -keyalg RSA -validity 365 -genkey

REM Truststore 생성
keytool -keystore kafka.server.truststore.jks -alias CARoot -importcert -file ca-cert
```

### 11.3 ACL (Access Control List) 설정

```cmd
REM ACL 활성화
docker exec kafka kafka-configs.sh --alter ^
  --add-config "authorizer.class.name=kafka.security.authorizer.AclAuthorizer" ^
  --entity-type brokers ^
  --entity-name 1 ^
  --bootstrap-server localhost:9092

REM Producer 권한 부여
docker exec kafka kafka-acls.sh --add ^
  --allow-principal User:producer ^
  --operation Write ^
  --topic orders ^
  --bootstrap-server localhost:9092

REM Consumer 권한 부여
docker exec kafka kafka-acls.sh --add ^
  --allow-principal User:consumer ^
  --operation Read ^
  --topic orders ^
  --group my-consumer-group ^
  --bootstrap-server localhost:9092

REM ACL 목록 조회
docker exec kafka kafka-acls.sh --list ^
  --bootstrap-server localhost:9092
```

---

## 12. Spring Boot 연동

### 12.1 의존성 추가

`pom.xml`:
```xml
<dependencies>
    <!-- Spring Kafka -->
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
    
    <!-- Spring Boot Starter -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

### 12.2 설정 파일

`application.yml`:
```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      acks: all
      retries: 3
      
    consumer:
      group-id: axcore-consumer-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "*"
    
    listener:
      ack-mode: manual
```

### 12.3 Kafka Configuration

```java
@Configuration
@EnableKafka
public class KafkaConfig {
    
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Bean
    public ProducerFactory<String, Object> producerFactory() {
        Map<String, Object> config = new HashMap<>();
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        config.put(ProducerConfig.ACKS_CONFIG, "all");
        config.put(ProducerConfig.RETRIES_CONFIG, 3);
        return new DefaultKafkaProducerFactory<>(config);
    }
    
    @Bean
    public KafkaTemplate<String, Object> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }
    
    @Bean
    public ConsumerFactory<String, Object> consumerFactory() {
        Map<String, Object> config = new HashMap<>();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "axcore-consumer-group");
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        config.put(JsonDeserializer.TRUSTED_PACKAGES, "*");
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        return new DefaultKafkaConsumerFactory<>(config);
    }
    
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, Object> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, Object> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        return factory;
    }
}
```

### 12.4 Producer Service

```java
@Service
@Slf4j
public class KafkaProducerService {
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    public void sendMessage(String topic, String message) {
        log.info("Sending message: {} to topic: {}", message, topic);
        kafkaTemplate.send(topic, message);
    }
    
    public void sendMessageWithKey(String topic, String key, Object message) {
        log.info("Sending message: {} with key: {} to topic: {}", message, key, topic);
        kafkaTemplate.send(topic, key, message);
    }
    
    public void sendOrder(Order order) {
        String topic = "orders";
        log.info("Sending order: {} to topic: {}", order, topic);
        
        ListenableFuture<SendResult<String, Object>> future = 
            kafkaTemplate.send(topic, order.getOrderId(), order);
        
        future.addCallback(
            result -> log.info("Order sent successfully: {}", order.getOrderId()),
            ex -> log.error("Failed to send order: {}", order.getOrderId(), ex)
        );
    }
}
```

### 12.5 Consumer Service

```java
@Service
@Slf4j
public class KafkaConsumerService {
    
    @KafkaListener(topics = "test-topic", groupId = "axcore-consumer-group")
    public void consumeMessage(String message) {
        log.info("Consumed message: {}", message);
        // 비즈니스 로직 처리
    }
    
    @KafkaListener(topics = "orders", groupId = "order-consumer-group")
    public void consumeOrder(ConsumerRecord<String, Order> record) {
        String key = record.key();
        Order order = record.value();
        int partition = record.partition();
        long offset = record.offset();
        
        log.info("Consumed order - Key: {}, Order: {}, Partition: {}, Offset: {}", 
                 key, order, partition, offset);
        
        // 주문 처리 로직
        processOrder(order);
    }
    
    @KafkaListener(topics = "events", groupId = "event-consumer-group",
                   containerFactory = "kafkaListenerContainerFactory")
    public void consumeEvent(ConsumerRecord<String, String> record,
                             Acknowledgment acknowledgment) {
        try {
            log.info("Processing event: {}", record.value());
            // 이벤트 처리 로직
            
            // 수동 커밋
            acknowledgment.acknowledge();
        } catch (Exception e) {
            log.error("Failed to process event", e);
            // 에러 처리 로직
        }
    }
    
    private void processOrder(Order order) {
        // 주문 처리 로직 구현
        log.info("Processing order: {}", order.getOrderId());
    }
}
```

### 12.6 REST Controller

```java
@RestController
@RequestMapping("/api/kafka")
@Slf4j
public class KafkaController {
    
    @Autowired
    private KafkaProducerService producerService;
    
    @PostMapping("/publish")
    public ResponseEntity<String> publishMessage(
            @RequestParam String topic,
            @RequestParam String message) {
        producerService.sendMessage(topic, message);
        return ResponseEntity.ok("Message published to topic: " + topic);
    }
    
    @PostMapping("/orders")
    public ResponseEntity<String> publishOrder(@RequestBody Order order) {
        producerService.sendOrder(order);
        return ResponseEntity.ok("Order published: " + order.getOrderId());
    }
}
```

### 12.7 도메인 모델

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Order {
    private String orderId;
    private String customerId;
    private BigDecimal totalAmount;
    private String status;
    private LocalDateTime createdAt;
}
```

---

## 13. 참고 자료

### 13.1 공식 문서

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kafka Docker Hub](https://hub.docker.com/r/wurstmeister/kafka)
- [Spring Kafka Documentation](https://docs.spring.io/spring-kafka/reference/html/)
- [Confluent Platform](https://docs.confluent.io/)

### 13.2 학습 자료

- [Kafka Tutorial](https://kafka.apache.org/quickstart)
- [Kafka Use Cases](https://kafka.apache.org/uses)
- [Kafka Performance](https://kafka.apache.org/performance)

### 13.3 비교 및 대안

**Kafka vs 다른 메시징 시스템:**

| 특징 | Kafka | RabbitMQ | ActiveMQ | Redis Pub/Sub |
|------|-------|----------|----------|---------------|
| 처리량 | 매우 높음 | 높음 | 중간 | 높음 |
| 영속성 | 디스크 저장 | 옵션 | 옵션 | 메모리 |
| 메시지 순서 | 파티션 내 보장 | 큐 내 보장 | 큐 내 보장 | 보장 안 함 |
| 확장성 | 수평 확장 | 수평 확장 | 제한적 | 제한적 |
| 사용 난이도 | 중간 | 쉬움 | 중간 | 쉬움 |
| 기본 포트 | 9092 | 5672 | 61616 | 6379 |

### 13.4 GUI 도구

1. **Kafka UI** (무료, 웹 기반)
   - [GitHub](https://github.com/provectus/kafka-ui)
   - Topic, Consumer Group 관리

2. **Kafka Tool (Offset Explorer)** (무료)
   - [다운로드](https://www.kafkatool.com/)
   - Desktop GUI 도구

3. **Conduktor** (유료)
   - [다운로드](https://www.conduktor.io/)
   - 전문적인 Kafka 개발 플랫폼

4. **Confluent Control Center** (상용)
   - Confluent Platform 포함
   - 엔터프라이즈급 모니터링

### 13.5 추가 팁

**프로덕션 환경 체크리스트:**
1. ✅ 복제 팩터 3 이상 설정
2. ✅ 최소 3개 Broker 클러스터 구성
3. ✅ 적절한 파티션 수 설계 (Consumer 수와 일치)
4. ✅ 로그 보관 정책 설정 (디스크 공간 관리)
5. ✅ Consumer Lag 모니터링 설정
6. ✅ SASL/SSL 보안 설정
7. ✅ ACL 권한 관리
8. ✅ 정기 백업 및 복원 테스트
9. ✅ Zookeeper 클러스터 구성 (3/5/7 노드)
10. ✅ 성능 튜닝 및 벤치마크

**개발 환경 최적화:**
- Docker Compose로 환경 자동화
- 자동 Topic 생성 활성화
- Kafka UI로 편리한 모니터링
- 로컬 테스트용 단일 Broker 사용

**성능 최적화:**
- 배치 처리 활성화 (linger.ms, batch.size)
- 압축 사용 (compression.type: lz4, snappy)
- Producer acks 설정 (acks=1 or all)
- Consumer fetch 설정 최적화
- 파티션 수와 Consumer 수 균형

**Spring Boot 개발 팁:**
- JsonSerializer/Deserializer 사용
- @KafkaListener로 간편한 Consumer 구현
- Manual Acknowledgment로 정확한 Offset 관리
- 에러 핸들링 및 재시도 로직 구현
- Topic별 Consumer Group 분리
