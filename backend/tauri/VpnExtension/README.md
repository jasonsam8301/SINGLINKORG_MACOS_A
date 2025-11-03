# VPN Extension for Clash Nyanpasu

## 概述

这是 Clash Nyanpasu 的 macOS Network Extension（系统 VPN）实现。

### 功能

- ✅ 在"系统设置 > 网络 > VPN"中显示
- ✅ 代理 macOS 系统的全部应用
- ✅ 支持所有 Clash 协议（SS、VMess、Trojan、Hysteria 等）
- ✅ 与 Nyanpasu 节点自动同步
- ✅ 一键开关，自动配置

### 技术实现

#### 流量路径
```
应用发送请求
    ↓
macOS 系统拦截（VPN 全局路由）
    ↓
PacketTunnelProvider 接收数据包
    ↓
Tun2socks 转换（TUN → SOCKS5）
    ↓
转发到 127.0.0.1:7890（Clash）
    ↓
Clash 根据当前节点和协议处理
    ↓
发送到代理服务器
    ↓
响应原路返回
```

#### 核心文件

- `PacketTunnelProvider.swift` - VPN 扩展主逻辑
- `Info.plist` - 扩展配置
- `VpnExtension.entitlements` - 权限配置

### 协议支持

**支持所有 Clash/Mihomo 支持的协议**：
- Shadowsocks (所有加密方式)
- VMess
- VLESS  
- Trojan
- Hysteria / Hysteria2
- TUIC
- WireGuard
- SSH
- 等等...

**原理**：
VPN 扩展使用 SOCKS5 协议与 Clash 通信，协议处理完全由 Clash 负责。

### 使用方法

1. 在 Nyanpasu 设置中找到"VPN 扩展"
2. 点击开关启用
3. 首次使用会弹出系统授权对话框
4. 点击"允许"
5. VPN 自动连接
6. 可以在"系统设置 > VPN"中查看

### 注意事项

- VPN 扩展与 TUN 模式互斥（会自动处理）
- 节点切换时 VPN 保持连接，无需断开
- 关闭 VPN 不会关闭 Clash 核心

### 开发者

- SingLink Team
- 基于 Outline Client 的 Tun2socks 技术
- 集成到 Clash Nyanpasu

### 许可证

GPL-3.0（与 Clash Nyanpasu 一致）

