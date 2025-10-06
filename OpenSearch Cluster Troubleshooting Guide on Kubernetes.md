# OpenSearch Cluster Troubleshooting Guide on Kubernetes

## Use Case 1: Pod Down/Not Ready

### Symptoms
- Pods in CrashLoopBackOff state
- Pods not starting properly
- Container restarts continuously

### Step-by-Step Troubleshooting

```bash
# Step 1: Check all OpenSearch pods status
kubectl get pods -n opensearch-namespace -l app=opensearch

# Step 2: Check pod events and logs
kubectl describe pod <opensearch-pod-name> -n opensearch-namespace

# Step 3: Check container logs
kubectl logs <opensearch-pod-name> -n opensearch-namespace
kubectl logs <opensearch-pod-name> -n opensearch-namespace --previous

# Step 4: Check resource limits and requests
kubectl get pod <opensearch-pod-name> -n opensearch-namespace -o yaml | grep -A 5 resources

# Step 5: Check node resources
kubectl top nodes
kubectl top pods -n opensearch-namespace
```

## Use Case 2: Cluster Status Yellow/Red

### Symptoms
- Cluster health shows YELLOW or RED
- Unassigned shards
- Index replication issues

### Step-by-Step Troubleshooting

```bash
# Step 1: Check cluster health 
kubectl get pod -n network-logging

# Step 2: Check cluster health
curl -u "admin:password" -XGET "https://localhost:9200/_cluster/health?pretty"

# Step 3: Check detailed cluster allocation explanation
curl -u "admin:password" -XGET "https://localhost:9200/_cluster/allocation/explain?pretty"

# Step 4: Check node stats
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats?pretty"

# Step 5: Check shard allocation
curl -u "admin:password" -XGET "https://localhost:9200/_cat/shards?v"

# Step 6: Check indices status
curl -u "admin:password" -XGET "https://localhost:9200/_cat/indices?v"

# Step 7: Check pending tasks
curl -u "admin:password" -XGET "https://localhost:9200/_cat/pending_tasks?v"
```

## Use Case 3: High JVM Memory Usage

### Symptoms
- High memory pressure
- GC overhead
- Performance degradation

### Step-by-Step Troubleshooting

```bash
# Step 1: Check JVM stats across all nodes
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/jvm?pretty"

# Step 2: Check memory pool details
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/jvm,os?pretty"

# Step 3: Check field data memory usage
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/indices/fielddata?pretty"

# Step 4: Check circuit breakers
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/breaker?pretty"

# Step 5: Check hot threads to identify problematic operations
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/hot_threads?pretty"

# Step 6: Check Kubernetes pod memory usage
kubectl top pods -n opensearch-namespace
```

## Use Case 4: Disk Space Issues

### Symptoms
- Disk usage above flood stage watermark
- Read-only indices
- Shard relocation failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check disk usage across nodes
curl -u "admin:password" -XGET "https://localhost:9200/_cat/allocation?v"

# Step 2: Check detailed disk stats
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/fs?pretty"

# Step 3: Check cluster disk settings and watermarks
curl -u "admin:password" -XGET "https://localhost:9200/_cluster/settings?include_defaults=true&pretty" | grep -A 10 -B 10 watermark

# Step 4: Check indices disk usage
curl -u "admin:password" -XGET "https://localhost:9200/_cat/indices?v&s=store.size:desc"

# Step 5: Check Kubernetes PVC usage
kubectl get pvc -n opensearch-namespace
kubectl describe pvc <pvc-name> -n opensearch-namespace
```

## Use Case 5: Network Connectivity Issues

### Symptoms
- Node disconnections
- Split-brain scenarios
- Unstable cluster

### Step-by-Step Troubleshooting

```bash
# Step 1: Check cluster state and master node
curl -u "admin:password" -XGET "https://localhost:9200/_cluster/state/master_node?pretty"

# Step 2: Check node connections
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/_all/info/http?pretty"

# Step 3: Check discovery and ping settings
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/settings?pretty" | grep -A 5 -B 5 discovery

# Step 4: Check Kubernetes network policies and services
kubectl get svc -n opensearch-namespace
kubectl describe svc <opensearch-service> -n opensearch-namespace

# Step 5: Check endpoints
kubectl get endpoints -n opensearch-namespace
```

## Use Case 6: High CPU Usage

### Symptoms
- Slow query performance
- High load averages
- Query timeouts

### Step-by-Step Troubleshooting

```bash
# Step 1: Check node CPU usage
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/os?pretty"

# Step 2: Check thread pool statistics
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/thread_pool?pretty"

# Step 3: Check task management for long-running tasks
curl -u "admin:password" -XGET "https://localhost:9200/_tasks?detailed=true&pretty"

# Step 4: Check search and index performance
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/indices/search?pretty"

# Step 5: Check Kubernetes node and pod CPU usage
kubectl top nodes
kubectl top pods -n opensearch-namespace
```

## Use Case 7: Indexing/Search Performance Issues

### Symptoms
- Slow indexing rates
- High query latency
- Bulk operation failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check index performance stats
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/indices/indexing?pretty"

# Step 2: Check search performance stats
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats/indices/search?pretty"

# Step 3: Check segment counts and sizes
curl -u "admin:password" -XGET "https://localhost:9200/_cat/segments?v"

# Step 4: Check index settings and mappings
curl -u "admin:password" -XGET "https://localhost:9200/<index-name>/_settings?pretty"
curl -u "admin:password" -XGET "https://localhost:9200/<index-name>/_mapping?pretty"

# Step 5: Check pending tasks
curl -u "admin:password" -XGET "https://localhost:9200/_cat/pending_tasks?v"
```

## Use Case 8: Authentication/Authorization Issues

### Symptoms
- Connection refused errors
- Permission denied errors
- SSL/TLS handshake failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Test basic connectivity without auth
curl -k -XGET "https://localhost:9200/"

# Step 2: Test with authentication
curl -u "admin:password" -XGET "https://localhost:9200/"

# Step 3: Check security plugin status
curl -u "admin:password" -XGET "https://localhost:9200/_plugins/_security/health?pretty"

# Step 4: Check Kubernetes secrets for credentials
kubectl get secrets -n opensearch-namespace
kubectl describe secret <opensearch-secret> -n opensearch-namespace

# Step 5: Check pod security context
kubectl describe pod <opensearch-pod> -n opensearch-namespace | grep -A 10 -B 10 "Security Context"
```

## Use Case 9: Backup/Restore Issues

### Symptoms
- Snapshot failures
- Restore operations stuck
- Repository connection issues

### Step-by-Step Troubleshooting

```bash
# Step 1: Check snapshot repository status
curl -u "admin:password" -XGET "https://localhost:9200/_snapshot?pretty"

# Step 2: Check snapshot status
curl -u "admin:password" -XGET "https://localhost:9200/_snapshot/_status?pretty"

# Step 3: Check ongoing snapshot operations
curl -u "admin:password" -XGET "https://localhost:9200/_snapshot/_all/_current?pretty"

# Step 4: Verify repository settings
curl -u "admin:password" -XGET "https://localhost:9200/_snapshot/<repository-name>?pretty"

# Step 5: Check Kubernetes PVC for backup storage
kubectl get pvc -n opensearch-namespace | grep backup
```

## Use Case 10: Log Analysis and Monitoring

### Symptoms
- Need to investigate historical issues
- Performance trend analysis
- Capacity planning

### Step-by-Step Troubleshooting

```bash
# Step 1: Export cluster settings for analysis
curl -u "admin:password" -XGET "https://localhost:9200/_cluster/settings?pretty" > cluster_settings.json

# Step 2: Export node stats for analysis
curl -u "admin:password" -XGET "https://localhost:9200/_nodes/stats?pretty" > node_stats.json

# Step 3: Check OpenSearch logs in Kubernetes
kubectl logs -f <opensearch-pod> -n opensearch-namespace

# Step 4: Check Kubernetes events
kubectl get events -n opensearch-namespace --sort-by=.metadata.creationTimestamp

# Step 5: Check resource utilization history
kubectl top pods -n opensearch-namespace --containers
```

## Quick Reference Commands

### Cluster Health Quick Check
```bash
# One-liner for cluster health check
kubectl port-forward svc/opensearch-cluster 9200:9200 -n opensearch-namespace & \
&& curl -u "admin:password" -s "https://localhost:9200/_cluster/health?pretty" \
&& curl -u "admin:password" -s "https://localhost:9200/_cat/nodes?v" \
&& pkill -f "port-forward"
```

### Pod Status Quick Check
```bash
# Comprehensive pod status check
kubectl get pods -n opensearch-namespace -o wide && \
kubectl top pods -n opensearch-namespace && \
kubectl get pvc -n opensearch-namespace
```

This guide provides comprehensive troubleshooting steps for common OpenSearch cluster issues in Kubernetes environments. Always ensure you have proper backups and test commands in a non-production environment first.