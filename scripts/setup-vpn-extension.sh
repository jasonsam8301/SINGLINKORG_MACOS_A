#!/bin/bash
# setup-vpn-extension.sh
# 自动配置 VPN 扩展的脚本

set -e

echo "🚀 开始配置 VPN 扩展..."

cd "$(dirname "$0")/.."

# 1. 检查 Tun2socks.xcframework
if [ ! -d "backend/tauri/Tun2socks.xcframework" ]; then
    echo "❌ Tun2socks.xcframework 不存在"
    exit 1
fi

echo "✅ Tun2socks.xcframework 已就绪"

# 2. 检查 VPN Helper
if [ ! -f "backend/tauri/vpn-helper/vpn-helper" ]; then
    echo "📦 编译 VPN Helper..."
    cd backend/tauri/vpn-helper
    swiftc -o vpn-helper main.swift -framework NetworkExtension -framework Foundation
    chmod +x vpn-helper
    cd ../../..
fi

echo "✅ VPN Helper 已就绪"

# 3. 创建资源目录
mkdir -p backend/tauri/resources/vpn

# 4. 复制 VPN Helper 到资源目录
cp backend/tauri/vpn-helper/vpn-helper backend/tauri/resources/vpn/

echo "✅ VPN Helper 已复制到资源目录"

# 5. 显示下一步操作
cat << 'EOF'

✅ 自动化配置完成！

📋 下一步（需要手动操作）：

由于 Tauri 使用自己的构建系统，需要在 Xcode 中手动添加 VPN Extension target。

我已经为你准备了详细的步骤文档：
  📄 VPN_EXTENSION_XCODE_SETUP.md

请按照文档操作（约10-15分钟）：
1. 运行 pnpm tauri build（生成 Xcode 项目）
2. 在 Xcode 中添加 Network Extension target
3. 配置签名
4. 编译运行

所有代码都已准备好，只需要配置！

EOF

echo ""
echo "🎊 准备工作全部完成！"
echo ""

