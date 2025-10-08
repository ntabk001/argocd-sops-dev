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

# OpenSearch Dashboard Troubleshooting Guide on Kubernetes

## Use Case 1: OpenSearch Dashboard Pod Down/Not Ready

### Symptoms
- Dashboard pods in CrashLoopBackOff state
- Container restarts continuously
- Startup failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check all OpenSearch Dashboard pods status
kubectl get pods -n network-logging -l app=opensearch-dashboards

# Step 2: Check pod events and logs
kubectl describe pod <opensearch-dashboards-pod> -n network-logging

# Step 3: Check Dashboard logs
kubectl logs <opensearch-dashboards-pod> -n network-logging
kubectl logs <opensearch-dashboards-pod> -n network-logging --previous

# Step 4: Check resource limits
kubectl get pod <opensearch-dashboards-pod> -n network-logging -o yaml | grep -A 5 resources

# Step 5: Check node resources
kubectl top nodes
kubectl top pods -n network-logging
```

## Use Case 2: OpenSearch Connection Issues

### Symptoms
- "OpenSearch is still initializing" error
- Connection timeout to OpenSearch cluster
- Authentication failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check OpenSearch Dashboard configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml

# Step 2: Test OpenSearch connectivity from Dashboard pod
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200" -v

# Step 3: Check OpenSearch cluster health from Dashboard pod
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_cluster/health?pretty"

# Step 4: Verify OpenSearch endpoint resolution
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- nslookup opensearch-cluster

# Step 5: Check network connectivity
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- telnet opensearch-cluster 9200
```

## Use Case 3: Authentication & Security Issues

### Symptoms
- Login failures
- "Invalid credentials" errors
- SSL/TLS handshake failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check security configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml | grep -E "(opensearch_security|ssl|auth)"

# Step 2: Verify OpenSearch credentials
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  env | grep -E "(OPENSEARCH|USERNAME|PASSWORD)"

# Step 3: Check Kubernetes secrets for credentials
kubectl get secrets -n network-logging | grep -E "(opensearch|dashboards|auth)"
kubectl describe secret <opensearch-dashboards-secret> -n network-logging

# Step 4: Test authentication với different user
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "kibanaserver:kibanaserver" -k "https://opensearch-cluster:9200/_plugins/_security/authinfo"

# Step 5: Check security plugin status
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_plugins/_security/health?pretty"
```

## Use Case 4: Dashboard UI Issues

### Symptoms
- White screen on Dashboard
- JavaScript errors in browser
- Plugin loading failures

### Step-by-Step Troubleshooting

```bash
# Step 1: Check Dashboard server status
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/status

# Step 2: Check plugin status
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/status | jq '.status.plugins'

# Step 3: Verify installed plugins
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin list

# Step 4: Check UI logs
kubectl logs <opensearch-dashboards-pod> -n network-logging | grep -E "(error|ERROR|plugin|ui)"

# Step 5: Check browser console errors (from client-side)
# Access Dashboard and check browser developer tools
```

## Use Case 5: Performance Issues

### Symptoms
- Slow Dashboard loading
- High memory usage
- Search timeouts

### Step-by-Step Troubleshooting

```bash
# Step 1: Check Dashboard metrics
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/status | jq '.status.metrics'

# Step 2: Monitor memory usage
kubectl top pods -n network-logging -l app=opensearch-dashboards

# Step 3: Check Node.js process stats
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- ps aux | grep node

# Step 4: Check response times
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  time curl -s -o /dev/null -w "%{http_code}" http://localhost:5601

# Step 5: Check OpenSearch query performance
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_nodes/stats/indices/search?pretty"
```

## Use Case 6: Configuration Issues

### Symptoms
- Configuration changes not applied
- Environment variables not recognized
- Incorrect default settings

### Step-by-Step Troubleshooting

```bash
# Step 1: Check current configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml

# Step 2: Check environment variables
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- env | grep -i opensearch

# Step 3: Verify configuration mounts
kubectl describe pod <opensearch-dashboards-pod> -n network-logging | grep -A 10 -B 10 "Mounts"

# Step 4: Check configuration validation
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  /usr/share/opensearch-dashboards/bin/opensearch-dashboards --help

# Step 5: Compare with ConfigMap
kubectl get configmap -n network-logging | grep dashboards
kubectl describe configmap <opensearch-dashboards-config> -n network-logging
```

## Use Case 7: Index Pattern & Data Issues

### Symptoms
- Index patterns not found
- "No data available" messages
- Field mapping issues

### Step-by-Step Troubleshooting

```bash
# Step 1: Check available indices from Dashboard perspective
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_cat/indices?v" | grep -E "(logstash|kafka|app)"

# Step 2: Verify index patterns via API
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/saved_objects/_find?type=index-pattern

# Step 3: Check default index pattern
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/opensearch-dashboards/settings

# Step 4: Verify data existence in indices
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/logstash-*/_count?pretty"

# Step 5: Check index pattern field mappings
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/logstash-*/_mapping?pretty"
```

## Use Case 8: Tenant & Multi-tenancy Issues

### Symptoms
- Tenant access denied
- Private tenant not accessible
- Global tenant configuration problems

### Step-by-Step Troubleshooting

```bash
# Step 1: Check tenant configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml | grep -i tenant

# Step 2: Verify tenant API access
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_plugins/_security/api/tenants/"

# Step 3: Check user tenant mappings
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200/_plugins/_security/api/internalusers/"

# Step 4: Test tenant switching
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "user:password" -k "https://opensearch-cluster:9200/_plugins/_security/authinfo"

# Step 5: Check tenant-specific index patterns
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s -u "user:password" http://localhost:5601/api/saved_objects/index-pattern
```

## Use Case 9: Plugin & Extension Issues

### Symptoms
- Custom plugins not loading
- Plugin compatibility errors
- Missing features

### Step-by-Step Troubleshooting

```bash
# Step 1: List installed plugins
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin list

# Step 2: Check plugin health status
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/status | jq '.status.plugins'

# Step 3: Verify plugin directories
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  ls -la /usr/share/opensearch-dashboards/plugins/

# Step 4: Check plugin logs
kubectl logs <opensearch-dashboards-pod> -n network-logging | grep -E "(plugin|Plugin)"

# Step 5: Test specific plugin API
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/alerting/_settings
```

## Use Case 10: Backup & Restore Issues

### Symptoms
- Saved objects backup failures
- Configuration export problems
- Import/export functionality broken

### Step-by-Step Troubleshooting

```bash
# Step 1: Check saved objects count
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/saved_objects/_find?perPage=1 | jq '.total'

# Step 2: Test saved objects export
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/saved_objects/_export -H 'Content-Type: application/json' \
  -d '{"type": ["index-pattern", "visualization", "dashboard"]}' -o /tmp/export.ndjson

# Step 3: Verify export file
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- head -5 /tmp/export.ndjson

# Step 4: Check import capability
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s -X POST http://localhost:5601/api/saved_objects/_import -H "osd-xsrf: true" \
  --form file=@/tmp/export.ndjson

# Step 5: Verify backup permissions
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- ls -la /usr/share/opensearch-dashboards/data/
```

## Use Case 11: SSL/TLS Configuration Issues

### Symptoms
- HTTPS connection failures
- Certificate validation errors
- Mixed content warnings

### Step-by-Step Troubleshooting

```bash
# Step 1: Check SSL configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml | grep -E "(ssl|certificat|https)"

# Step 2: Verify certificate files
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  ls -la /usr/share/opensearch-dashboards/config/certs/

# Step 3: Test certificate validity
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  openssl x509 -in /usr/share/opensearch-dashboards/config/certs/tls.crt -text -noout

# Step 4: Check OpenSearch SSL configuration
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  cat /usr/share/opensearch-dashboards/config/opensearch_dashboards.yml | grep -A 10 "opensearch.ssl"

# Step 5: Verify TLS handshake
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  openssl s_client -connect opensearch-cluster:9200 -servername opensearch-cluster
```

## Use Case 12: Load Balancer & Ingress Issues

### Symptoms
- External access failures
- Ingress routing problems
- Load balancer timeouts

### Step-by-Step Troubleshooting

```bash
# Step 1: Check Kubernetes service
kubectl get svc -n network-logging | grep dashboards
kubectl describe svc opensearch-dashboards -n network-logging

# Step 2: Check ingress configuration
kubectl get ingress -n network-logging
kubectl describe ingress opensearch-dashboards -n network-logging

# Step 3: Verify service endpoints
kubectl get endpoints -n network-logging | grep dashboards

# Step 4: Test internal service access
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://opensearch-dashboards:5601

# Step 5: Check port forwarding for direct access
kubectl port-forward svc/opensearch-dashboards 5601:5601 -n network-logging &
curl http://localhost:5601/api/status
```

## Quick Reference Commands

### Dashboard Health Quick Check
```bash
# One-liner for Dashboard health check
kubectl get pods -n network-logging -l app=opensearch-dashboards && \
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- curl -s http://localhost:5601/api/status | jq '{status: .status.overall.state, version: .version.number}'
```

### OpenSearch Connection Test
```bash
# Test OpenSearch connection from Dashboard pod
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -u "admin:password" -k "https://opensearch-cluster:9200" -w "HTTP %{http_code}\n"
```

### Plugin Status Check
```bash
# Check all plugins status
kubectl exec -it <opensearch-dashboards-pod> -n network-logging -- \
  curl -s http://localhost:5601/api/status | jq '.status.plugins | keys'
```

### Sample Configuration Files (reference)

#### opensearch_dashboards.yml
```yaml
server.host: "0.0.0.0"
server.port: 5601

opensearch.hosts: ["https://opensearch-cluster:9200"]
opensearch.ssl.verificationMode: none
opensearch.username: "admin"
opensearch.password: "password"
opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]

opensearch_security.multitenancy.enabled: true
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
```

#### Environment Variables
```bash
# Common environment variables
OPENSEARCH_HOSTS: "https://opensearch-cluster:9200"
OPENSEARCH_USERNAME: "admin"
OPENSEARCH_PASSWORD: "password"
OPENSEARCH_SSL_VERIFICATIONMODE: "none"
SERVER_HOST: "0.0.0.0"
SERVER_PORT: "5601"
```

