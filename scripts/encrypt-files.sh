#!/bin/bash

# Script để mã hóa files với SOPS cho dev

set -e

echo "Encrypting files for DEV environment..."

# Kiểm tra file tồn tại
if [ ! -d "apps/dev" ]; then
    echo "Directory apps/dev does not exist!"
    exit 1
fi

# Mã hóa secrets file
if [ -f "apps/dev/sops-secrets.yaml" ]; then
    echo "Encrypting sops-secrets.yaml..."
    sops -e -i "apps/dev/sops-secrets.yaml"
    echo "✓ sops-secrets.yaml encrypted"
else
    echo "⚠️  sops-secrets.yaml not found"
fi

# Mã hóa config file
if [ -f "apps/dev/sops-config.yaml" ]; then
    echo "Encrypting sops-config.yaml..."
    sops -e -i "apps/dev/sops-config.yaml"
    echo "✓ sops-config.yaml encrypted"
else
    echo "⚠️  sops-config.yaml not found"
fi

# Kiểm tra encryption
echo ""
echo "Verifying encryption:"
for file in "apps/dev/sops-secrets.yaml" "apps/dev/sops-config.yaml"; do
    if [ -f "$file" ]; then
        if grep -q "ENC\[" "$file"; then
            echo "✓ $file is properly encrypted"
        else
            echo "❌ $file is NOT encrypted"
        fi
    fi
done

echo ""
echo "Encryption completed for DEV environment!"
