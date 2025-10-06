# Apache Kafka Cluster Troubleshooting Guide on Kubernetes (KRaft Mode với Authentication)

## Use Case 1: Broker Pod Down/Not Ready

### Symptoms
- Broker pods in CrashLoopBackOff state
- Controller connectivity issues
- Broker registration failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check all Kafka pods status
kubectl get pods -n network-logging -l app=kafka

# Step 2: Check pod events and logs
kubectl describe pod <kafka-broker-pod> -n network-logging

# Step 3: Check broker logs với authentication error
kubectl logs <kafka-broker-pod> -n network-logging | grep -i -E "(auth|ssl|sasl|error|exception)"

# Step 4: Check resource limits and persistent volumes
kubectl get pvc -n network-logging
kubectl describe pvc <kafka-pvc> -n network-logging

# Step 5: Check Kubernetes secrets for authentication
kubectl get secrets -n network-logging | grep kafka
kubectl describe secret <kafka-jaas-secret> -n network-logging
```

## Use Case 2: Authentication/Authorization Issues

### Symptoms
- SASL/SSL handshake failures
- ACL permission denied
- Client connection rejections

### Step-by-Step Troubleshooting

```bash
# Step 1: Check broker security configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/server.properties | grep -E "(sasl|ssl|security|listener)"

# Step 2: Test internal broker communication với SASL
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  bash -c 'echo "Q29uc3VtZXI6cGFzc3dvcmQK" | base64 -d | kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type users --describe'

# Step 3: Check JAAS configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/kafka_jaas.conf

# Step 4: Verify client configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/client.properties

# Step 5: Check ACL permissions với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-acls.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list

# Step 6: Test producer với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  bash -c 'echo "test-message" | kafka-console-producer.sh --bootstrap-server localhost:9092 --producer.config /etc/kafka/client.properties --topic test-topic'
```

## Use Case 3: KRaft Controller Issues với Authentication

### Symptoms
- No active controller
- Metadata propagation failures
- Election problems

### Step-by-Step Troubleshooting

```bash
# Step 1: Check controller status với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-metadata-quorum.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe

# Step 2: Check cluster ID với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-cluster.sh cluster-id --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties

# Step 3: Check broker configuration for controller settings
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/server.properties | grep -E "(process.roles|controller|node.id|sasl)"

# Step 4: Check inter-broker authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/server.properties | grep -E "(inter.broker.listener|sasl.mechanism)"
```

## Use Case 4: Topic Management với Authentication

### Symptoms
- Topic creation failures
- Permission denied errors
- Configuration update failures

### Step-by-Step Troubleshooting

```bash
# Step 1: List topics với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-topics.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list

# Step 2: Check topic description với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-topics.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe --topic <topic-name>

# Step 3: Check under-replicated partitions
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-topics.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe --under-replicated-partitions

# Step 4: Check topic configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type topics --entity-name <topic-name> --describe
```

## Use Case 5: Consumer Group Issues với Authentication

### Symptoms
- Consumer lag
- Rebalance problems
- Permission errors

### Step-by-Step Troubleshooting

```bash
# Step 1: Check consumer group lag với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe --all-groups

# Step 2: Check specific consumer group
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe --group <group-name>

# Step 3: Reset consumer group offset
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --group <group-name> --reset-offsets --to-earliest --execute --topic <topic-name>

# Step 4: Delete consumer group
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --group <group-name> --delete
```

## Use Case 6: User Management và ACL

### Symptoms
- User authentication failures
- ACL permission issues
- Access denied errors

### Step-by-Step Troubleshooting

```bash
# Step 1: List all users
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type users --describe

# Step 2: Check specific user
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type users --entity-name <username> --describe

# Step 3: List all ACLs
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-acls.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list

# Step 4: Check ACLs for specific topic
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-acls.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list --topic <topic-name>

# Step 5: Add ACL for user
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-acls.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --add \
  --allow-principal User:<username> \
  --operation Read --operation Write \
  --topic <topic-name> --group <group-name>
```

## Use Case 7: Producer/Consumer Testing với Authentication

### Symptoms
- Message production failures
- Consumption issues
- Authentication errors in clients

### Step-by-Step Troubleshooting

```bash
# Step 1: Test producer với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  bash -c 'for i in {1..10}; do echo "Test message $i" | kafka-console-producer.sh --bootstrap-server localhost:9092 --producer.config /etc/kafka/client.properties --topic test-topic; done'

# Step 2: Test consumer với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-console-consumer.sh --bootstrap-server localhost:9092 --consumer.config /etc/kafka/client.properties --topic test-topic --from-beginning --max-messages 10

# Step 3: Test with specific consumer group
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-console-consumer.sh --bootstrap-server localhost:9092 --consumer.config /etc/kafka/client.properties --topic test-topic --group test-group --from-beginning --timeout-ms 5000

# Step 4: Check message count in topic
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-run-class.sh kafka.tools.GetOffsetShell --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --topic test-topic --time -1
```

## Use Case 8: Monitoring và Metrics với Authentication

### Symptoms
- Metrics collection failures
- JMX authentication issues
- Monitoring gaps

### Step-by-Step Troubleshooting

```bash
# Step 1: Check broker metrics với authentication
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  curl -u client:password --connect-timeout 5 localhost:9090/metrics

# Step 2: Check JVM metrics
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  curl -u client:password localhost:9090/jmx

# Step 3: Check specific metric
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  curl -s -u client:password localhost:9090/metrics | grep kafka_server_brokertopicmetrics_bytesin_total

# Step 4: Check consumer group metrics
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  curl -s -u client:password localhost:9090/metrics | grep kafka_consumer_consumer_coordinator
```

## Use Case 9: Configuration Management

### Symptoms
- Configuration update failures
- Dynamic config propagation issues
- Security config errors

### Step-by-Step Troubleshooting

```bash
# Step 1: Check current broker configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type brokers --entity-default --describe

# Step 2: Check specific broker config
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type brokers --entity-name <broker-id> --describe

# Step 3: Update broker configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type brokers --entity-name <broker-id> --alter --add-config 'log.retention.hours=168'

# Step 4: Check log configuration
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type topics --entity-name <topic-name> --describe | grep -E "(retention|cleanup)"
```

## Use Case 10: Emergency Recovery

### Symptoms
- Cluster unavailable
- Authentication completely broken
- Need to reset security settings

### Step-by-Step Troubleshooting

```bash
# Step 1: Check pod status và logs
kubectl get pods -n network-logging
kubectl logs <kafka-broker-pod> -n network-logging --tail=50

# Step 2: Check Kubernetes secrets
kubectl get secrets -n network-logging
kubectl describe secret kafka-jaas-secret -n network-logging

# Step 3: Restart broker với debug mode
kubectl exec -it <kafka-broker-pod> -n network-logging -- cat /etc/kafka/log4j.properties | grep -i debug

# Step 4: Check persistent volumes
kubectl get pvc -n network-logging
kubectl describe pvc data-kafka-0 -n network-logging

# Step 5: Temporary disable security for recovery (use with caution)
kubectl exec -it <kafka-broker-pod> -n network-logging -- \
  sed -i 's/^sasl/#sasl/g' /etc/kafka/server.properties && \
  kill -TERM 1
```

## Quick Reference Commands

### Cluster Health Quick Check với Authentication
```bash
# One-liner for cluster health check
kubectl get pods -n network-logging && \
kubectl exec -it kafka-0 -n network-logging -- kafka-topics.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list && \
kubectl exec -it kafka-0 -n network-logging -- kafka-metadata-quorum.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe
```

### Consumer Lag Monitoring với Authentication
```bash
# Monitor all consumer groups lag
kubectl exec -it kafka-0 -n network-logging -- \
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --describe --all-groups | grep -v "CONSUMER-ID" | sort -k6 -n
```

### User và ACL Quick Check
```bash
# Check users and ACLs
kubectl exec -it kafka-0 -n network-logging -- \
  kafka-configs.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --entity-type users --describe && \
kubectl exec -it kafka-0 -n network-logging -- \
  kafka-acls.sh --bootstrap-server localhost:9092 --command-config /etc/kafka/client.properties --list
```

### Sample client.properties file (reference)
```properties
# /etc/kafka/client.properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="client" password="password";
```

This guide provides comprehensive troubleshooting steps for Apache Kafka clusters với SASL authentication trong KRaft mode trên Kubernetes namespace `network-logging`.