# 🔬 Clash Nyanpasu 技术栈说明

## 核心技术

### 🎨 前端技术栈
- **React 19.2.0** - 最新的 React 框架
- **TypeScript** - 类型安全
- **Material-UI 7.x** - Google Material You Design
- **Vite 7.x** - 超快的构建工具
- **TanStack Router** - 现代路由

### ⚙️ 后端技术栈
- **Rust** - 系统级编程语言
- **Tauri 2.8.5** - 轻量级桌面应用框架
- **Tokio** - 异步运行时

### 🌐 代理核心
- **Mihomo v1.19.15** (Go语言) - 推荐
- **Clash Premium** (Go语言)
- **Clash-rs** (Rust)

---

## 跨平台支持

### ✅ 完全支持
- **macOS** 12.6+ (Apple Silicon + Intel)
- **Windows** 10+ (x64 + arm64)
- **Linux** (多发行版)

### ❌ 不支持
- **Android** - Tauri 不支持移动端
- **iOS** - Tauri 不支持移动端

---

## 为什么选择 Tauri？

### vs Electron
- 📦 更小：~10 MB (vs ~100 MB)
- ⚡ 更快：启动 <1秒 (vs 3-5秒)
- 💾 更省：内存 ~100 MB (vs ~300 MB)

### vs 原生
- 🚀 开发更快：Web 技术栈
- 🌍 跨平台：一套代码，三个平台
- 🎨 UI 现代：Material Design

---

## 性能数据（M1 Mac）

```
应用大小: ~15 MB
内存占用: ~120 MB
启动时间: ~1 秒
CPU 空闲: ~0.5%
```

---

## SingLink 修改

### 我们修复的问题
- ✅ `backend/tauri/build.rs` - Git 信息获取错误
- ✅ 添加了安全的默认值处理

### 编译命令
```bash
pnpm install
pnpm check
pnpm tauri:dev   # 开发模式
pnpm build       # 发布版本
```

---

## 移动端方案

如需 Android/iOS，推荐：
- Android: Clash for Android
- iOS: Shadowrocket

---

© 2025 SingLink Team
基于 Clash Nyanpasu (GPL-3.0)

