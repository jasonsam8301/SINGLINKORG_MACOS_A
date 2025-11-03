#!/bin/bash
# build-vpn-extension.sh
# 在 Tauri 构建时编译和嵌入 VPN Extension

set -e

echo "🔨 构建 VPN Extension..."

cd "$(dirname "$0")"

# 编译 VPN Extension
xcodebuild -project VpnExtension.xcodeproj \
  -scheme VpnExtension \
  -configuration Release \
  build \
  -destination 'platform=macOS,name=My Mac' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo "✅ VPN Extension 编译成功"
else
    echo "❌ VPN Extension 编译失败"
    exit 1
fi

# 查找编译产物
VPN_EXT_PATH=$(find . -name "VpnExtension.appex" -type d | head -1)

if [ -n "$VPN_EXT_PATH" ]; then
    echo "✅ 找到 VPN Extension: $VPN_EXT_PATH"
    
    # 复制到资源目录
    mkdir -p resources
    cp -R "$VPN_EXT_PATH" resources/
    
    echo "✅ VPN Extension 已复制到资源目录"
else
    echo "❌ 未找到编译产物"
    exit 1
fi

echo "🎉 VPN Extension 构建完成！"

