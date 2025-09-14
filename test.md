```
#!/bin/bash

for file in *; do
    if [ -f "$file" ] && [ "$file" != "encode_all.sh" ] && [ "$file" != "decode_all.sh" ]; then
        encoded_data=$(base64 -w 0 "$file")
        for i in {2..10}; do
            encoded_data=$(echo -n "$encoded_data" | base64 -w 0)
        done
        echo -n "$encoded_data" > "encoded_$file"
    fi
done

```
```
# Exec vào pod
kubectl exec -it <kafka-pod-name> -- bash

# Xem file cấu hình server.properties
cat /opt/bitnami/kafka/config/server.properties

# Tìm các setting quan trọng
grep -i "zookeeper.connect" /opt/bitnami/kafka/config/server.properties
grep -i "controller" /opt/bitnami/kafka/config/server.properties
grep -i "process.roles" /opt/bitnami/kafka/config/server.properties

# Exec vào pod
kubectl exec -it <kafka-pod-name> -- bash

# Kiểm tra Java processes
ps aux | grep java

# Hoặc sử dụng jps (nếu có)
jps -l
```
