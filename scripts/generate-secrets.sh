#!/bin/bash

# Script để generate secrets và config files cho dev

set -e

echo "Generating secrets for DEV environment..."

# Tạo thư mục nếu chưa tồn tại
mkdir -p "apps/dev"

# Generate base64 encoded secrets
DB_URL="postgresql://user:devpassword@dev-db:5432/devdb"
API_KEY="dev-api-key-1234567890"
CONFIG_JSON='{"environment":"dev","debug":true,"database":{"host":"dev-db","port":5432,"name":"devdb"}}'

# Tạo file secrets chưa mã hóa
cat > "apps/dev/sops-secrets.yaml" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: demo-app
type: Opaque
data:
  database-url: $(echo -n "$DB_URL" | base64 -w0)
  api-key: $(echo -n "$API_KEY" | base64 -w0)
stringData:
  config.json: |
    $CONFIG_JSON
EOF

# Tạo file config chưa mã hóa
cat > "apps/dev/sops-config.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: demo-app
data:
  environment: dev
  debug: "true"
  app-name: demo-app-dev
  database-host: dev-db
  database-port: "5432"
EOF

echo "Secrets generated for DEV environment"
echo "Files created:"
echo "  - apps/dev/sops-secrets.yaml"
echo "  - apps/dev/sops-config.yaml"
echo ""
echo "Now encrypt them with: ./scripts/encrypt-files.sh"
