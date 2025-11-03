#!/usr/bin/env node
// tauri-build-vpn.mjs
// Tauri 构建钩子 - 编译并嵌入 VPN Extension

import { execSync } from 'child_process'
import { existsSync, cpSync, mkdirSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

console.log('🔨 开始构建 VPN Extension...')

try {
  // 1. 编译 VPN Extension
  console.log('📦 编译 VpnExtension.xcodeproj...')
  
  execSync(
    'xcodebuild -project VpnExtension.xcodeproj ' +
    '-scheme VpnExtension ' +
    '-configuration Release ' +
    'build ' +
    '-destination "platform=macOS,name=My Mac"',
    {
      cwd: __dirname,
      stdio: 'inherit'
    }
  )
  
  console.log('✅ VPN Extension 编译成功')
  
  // 2. 查找编译产物
  const derivedDataPath = execSync(
    'xcodebuild -project VpnExtension.xcodeproj -showBuildSettings | grep BUILD_DIR | head -1 | sed "s/.*= //"',
    { cwd: __dirname, encoding: 'utf-8' }
  ).trim()
  
  const vpnExtPath = join(derivedDataPath, 'Release/VpnExtension.appex')
  
  if (existsSync(vpnExtPath)) {
    console.log(`✅ 找到 VPN Extension: ${vpnExtPath}`)
    
    // 3. 复制到 Tauri 资源目录
    const resourcesDir = join(__dirname, 'gen/macos')
    mkdirSync(resourcesDir, { recursive: true })
    
    const targetPath = join(resourcesDir, 'VpnExtension.appex')
    cpSync(vpnExtPath, targetPath, { recursive: true })
    
    console.log(`✅ VPN Extension 已复制到: ${targetPath}`)
    console.log('🎉 VPN Extension 构建完成！')
  } else {
    console.error('❌ 未找到编译产物')
    process.exit(1)
  }
  
} catch (error) {
  console.error('❌ 构建失败:', error.message)
  process.exit(1)
}

