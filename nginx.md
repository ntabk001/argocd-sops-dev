Cập nhật ví dụ triển khai app Nginx với mã hóa file `nginx.conf` bằng SOPS và SopsSecretGenerator (tôi giả sử bạn đề cập đến `SopsSecretGenerator` từ goabout.com, như trong ví dụ trước). Tôi sẽ xây dựng trên cấu trúc hiện tại (Helm chart kết hợp Kustomize, với overlay cho dev/prod), thêm một Helm chart đơn giản cho Nginx. File `nginx.conf` sẽ được mã hóa thành `nginx.conf.sops` (sử dụng SOPS với GPG key), và SopsSecretGenerator sẽ generate một ConfigMap từ file đó để mount vào container Nginx.

### Lý do và Cách Tiếp Cận
- **Mã hóa `nginx.conf`**: File config này chứa cấu hình nhạy cảm (ví dụ: proxy settings, auth), nên mã hóa để an toàn trong Git. SOPS mã hóa selective (chỉ nội dung nhạy cảm nếu config regex).
- **SopsSecretGenerator**: Sẽ generate ConfigMap từ `nginx.conf.sops` (thay vì Secret như trước, vì đây là config file, không phải key-value pairs).
- **Cập nhật `values.yaml`**: Thêm field `configMapName: nginx-config` để reference ConfigMap do Kustomize generate, và mount vào Deployment Nginx.
- **Tích hợp với Helm/Kustomize**: Helm chart render Deployment Nginx với mount ConfigMap, Kustomize overlay generate ConfigMap từ file sops.
- **Môi trường phân tách**: Giữ nguyên dev/prod với `nginx.conf.sops` riêng (cấu hình khác nhau).

### Cấu Trúc Thư Mục Cập Nhật
Thêm chart Nginx vào `sops/helm-charts/nginx/`, và cập nhật overlays để bao gồm `nginx.conf.sops`.

```
sops/
├── helm-charts/
│   ├── opensearch/  # Giữ nguyên từ trước
│   └── nginx/
│       ├── Chart.yaml
│       ├── values.yaml  # Đã cập nhật để reference ConfigMap
│       └── templates/
│           └── deployment.yaml  # Deployment Nginx với mount ConfigMap
└── kustomize/
    ├── base/
    │   ├── kustomization.yaml
    │   └── helm-output/
    └── overlays/
        ├── dev/
        │   ├── kustomization.yaml
        │   ├── resources/
        │   │   └── generator.yaml  # Cập nhật để generate ConfigMap từ nginx.conf.sops
        │   └── secrets/
        │       └── sops/
        │           ├── .sops.yaml
        │           ├── secrets.env.sops  # Giữ nguyên
        │           └── nginx.conf.sops  # File mới mã hóa
        └── prod/
            ├── kustomization.yaml
            ├── resources/
            │   └── generator.yaml
            └── secrets/
                └── sops/
                    ├── .sops.yaml
                    ├── secrets.env.sops  # Giữ nguyên
                    └── nginx.conf.sops  # File mới cho prod
```

### Command Tạo File và Mã Hóa
Giả sử bạn ở thư mục gốc project (`~/project`). Các command dưới thêm chart Nginx, mã hóa `nginx.conf`, và cập nhật generator.

```bash
# Tạo thư mục cho Nginx
mkdir -p sops/helm-charts/nginx/templates
mkdir -p sops/kustomize/overlays/dev/secrets/sops  # Đã có, nhưng đảm bảo
mkdir -p sops/kustomize/overlays/prod/secrets/sops

# 1. Helm Chart cho Nginx: sops/helm-charts/nginx/
cd sops/helm-charts/nginx

cat << 'EOF' > Chart.yaml
apiVersion: v2
name: nginx
description: Helm chart for Nginx app
version: 0.1.0
EOF

# Cập nhật values.yaml để reference ConfigMap từ file nginx.conf.sops
cat << 'EOF' > values.yaml
image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

replicas: 1

configMapName: nginx-config  # Reference ConfigMap do Kustomize generate từ nginx.conf.sops

resources:
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector: {}  # Tùy chỉnh nếu cần
EOF

cat << 'EOF' > templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    app: nginx-app
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: nginx-app
  template:
    metadata:
      labels:
        app: nginx-app
    spec:
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: nginx
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: config-volume
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf  # Mount file từ ConfigMap vào đường dẫn config
      volumes:
        - name: config-volume
          configMap:
            name: {{ .Values.configMapName }}  # Reference từ values.yaml
EOF

# 2. Generate Helm template cho Nginx vào base (thêm vào helm-output)
cd ../../kustomize/base
helm template nginx ../../helm-charts/nginx --output-dir helm-output/nginx

# Cập nhật kustomization.yaml trong base để include Nginx
cat << 'EOF' > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - helm-output/opensearch/templates/deployment.yaml  # Giữ OpenSearch nếu cần
  - helm-output/opensearch/templates/pod-test.yaml
  - helm-output/nginx/templates/deployment.yaml  # Thêm Nginx
EOF

# 3. Overlay Dev: Cập nhật generator để generate ConfigMap từ nginx.conf.sops (thêm files)
cd ../overlays/dev/resources
cat << 'EOF' > generator.yaml
apiVersion: goabout.com/v1beta1
kind: SopsSecretGenerator
metadata:
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ../../SopsSecretGenerator
  name: opensearch-credentials  # Giữ cho secrets.env.sops
envs:
  - ../../secrets/sops/secrets.env.sops
disableNameSuffixHash: true
type: Opaque
---
apiVersion: goabout.com/v1beta1
kind: SopsSecretGenerator
metadata:
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ../../SopsSecretGenerator
  name: nginx-config  # Generate ConfigMap từ nginx.conf.sops
files:
  - ../../secrets/sops/nginx.conf.sops
disableNameSuffixHash: true
type: Opaque  # Sử dụng Opaque để generate ConfigMap (SopsSecretGenerator hỗ trợ files cho ConfigMap)
EOF
cd ..

# Mã hóa nginx.conf cho Dev
cd secrets/sops
cat << 'EOF' > .sops.yaml
creation_rules:
  - path_regex: .*\.conf$
    encrypted_regex: '^server_name|proxy_pass|auth_basic$'  # Chỉ mã hóa dòng nhạy cảm (tùy chỉnh regex cho nội dung nhạy cảm)
    pgp: <your-gpg-fingerprint>
EOF

cat << 'EOF' > nginx.conf
events {}
http {
    server {
        listen 80;
        server_name example.com;  # Sẽ mã hóa nếu match regex
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        location /api {
            proxy_pass http://backend:8080;  # Sẽ mã hóa nếu match
        }
    }
}
EOF

sops -e nginx.conf > nginx.conf.sops
rm nginx.conf  # Xóa file gốc

# 4. Overlay Prod: Tương tự Dev, nhưng nginx.conf khác
cd ../../../overlays/prod/resources
cat << 'EOF' > generator.yaml
apiVersion: goabout.com/v1beta1
kind: SopsSecretGenerator
metadata:
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ../../SopsSecretGenerator
  name: opensearch-credentials
envs:
  - ../../secrets/sops/secrets.env.sops
disableNameSuffixHash: true
type: Opaque
---
apiVersion: goabout.com/v1beta1
kind: SopsSecretGenerator
metadata:
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ../../SopsSecretGenerator
  name: nginx-config
files:
  - ../../secrets/sops/nginx.conf.sops
disableNameSuffixHash: true
type: Opaque
EOF
cd ..

cd secrets/sops
cat << 'EOF' > .sops.yaml
creation_rules:
  - path_regex: .*\.conf$
    encrypted_regex: '^server_name|proxy_pass|auth_basic$'
    pgp: <your-gpg-fingerprint>
EOF

cat << 'EOF' > nginx.conf
events {}
http {
    server {
        listen 80;
        server_name prod.example.com;  # Cấu hình khác cho prod
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        location /api {
            proxy_pass http://prod-backend:8080;
        }
    }
}
EOF

sops -e nginx.conf > nginx.conf.sops
rm nginx.conf

# 5. Giữ nguyên tải SopsSecretGenerator (nếu chưa có)
cd ../../../overlays/dev
curl -Lo SopsSecretGenerator https://github.com/goabout/kustomize-sopssecretgenerator/releases/download/v1.6.0/SopsSecretGenerator_1.6.0_linux_amd64
chmod +x SopsSecretGenerator
cp SopsSecretGenerator ../prod/
```

### Giải Thích Cập Nhật `values.yaml`
- **Field `configMapName: nginx-config`**: Đây là tên ConfigMap do SopsSecretGenerator generate từ `nginx.conf.sops`. Trong template `deployment.yaml`, field này được dùng để reference volume ConfigMap, mount file `nginx.conf` vào container Nginx (`mountPath: /etc/nginx/nginx.conf`).
- **Lý do chỉnh sửa**: `values.yaml` không chứa nội dung file `nginx.conf` (để tránh hardcode và lộ config), mà chỉ reference tên ConfigMap. Điều này cho phép Kustomize/SOPS xử lý mã hóa/decrypt ở cấp overlay (dev/prod riêng biệt).
- **Nếu cần override**: Trong môi trường khác, bạn có thể patch `values.yaml` qua Kustomize (ví dụ: thêm `valuesInline` trong `kustomization.yaml`), nhưng cách này đã đơn giản (môi trường-specific qua file sops).

### Test và Triển Khai
- **Local Test**: Từ `sops/kustomize/overlays/dev/`:
  ```bash:disable-run
  kustomize build --enable-alpha-plugins --enable-exec .
  ```
  - Kiểm tra output có ConfigMap `nginx-config` với nội dung decrypt từ `nginx.conf.sops`, và Deployment mount đúng.

- **ArgoCD**: Giữ Application như trước, nhưng thêm resource Nginx. Sync app để deploy, check config bằng:
  ```bash
  kubectl exec -it opensearch-nginx-... -n dev -- cat /etc/nginx/nginx.conf
  ```
  - Nên hiển thị nội dung decrypt.

Lưu ý: Nếu `nginx.conf` có nội dung nhạy cảm nhiều, chỉnh regex trong `.sops.yaml` để mã hóa toàn bộ (`encrypted_regex: '.*'`). Nếu cần tích hợp với OpenSearch (ví dụ: Nginx proxy cho OpenSearch), thêm vào template Deployment.

Nếu cần chỉnh thêm hoặc có lỗi, cung cấp chi tiết!
```