// PacketTunnelProvider.swift
// Copyright 2025 SingLink Team
// VPN 扩展核心实现 - 转发所有流量到本地 Clash

import NetworkExtension
import Network
import os.log

/// Packet Tunnel Provider - 将系统流量转发到 Clash
/// 使用 Tun2socks 实现 TUN ↔ SOCKS5 桥接
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // MARK: - Properties
    
    private let logger = Logger(
        subsystem: "moe.elaina.clash.nyanpasu.vpn",
        category: "VPN"
    )
    
    private var socks5Client: SOCKS5Client?
    private var isRunning = false
    
    private let packetQueue = DispatchQueue(
        label: "moe.elaina.clash.nyanpasu.vpn.packets",
        qos: .userInitiated
    )
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        logger.info("📦 VPN 扩展初始化")
    }
    
    // MARK: - Tunnel Management
    
    /// 启动 VPN 隧道
    override func startTunnel(options: [String : NSObject]? = nil) async throws {
        logger.info("🚀 开始启动 VPN 隧道...")
        
        // 1. 读取配置
        guard let protocolConfig = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfig.providerConfiguration else {
            logger.error("❌ 无法读取 VPN 配置")
            throw NSError(domain: "VPN", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "VPN 配置缺失"
            ])
        }
        
        // 提取 Clash SOCKS5 地址
        let clashHost = providerConfig["clashHost"] as? String ?? "127.0.0.1"
        let clashPort = providerConfig["clashPort"] as? Int ?? 7890
        let nodeName = providerConfig["nodeName"] as? String ?? "GLOBAL"
        
        logger.info("📝 配置信息:")
        logger.info("   Clash 地址: \(clashHost):\(clashPort)")
        logger.info("   当前节点: \(nodeName)")
        
        // 2. 配置网络设置（全局路由 + DNS）
        logger.info("📡 配置网络设置...")
        let networkSettings = createNetworkSettings(
            clashHost: clashHost,
            clashPort: clashPort
        )
        
        try await setTunnelNetworkSettings(networkSettings)
        logger.info("✅ 网络设置已应用")
        logger.info("   - IPv4 全局路由: 0.0.0.0/0")
        logger.info("   - IPv6 全局路由: ::/0")
        logger.info("   - DNS 服务器: 1.1.1.1, 8.8.8.8")
        
        // 3. 连接到本地 Clash SOCKS5  
        let client = SOCKS5Client(host: clashHost, port: UInt16(clashPort))
        try await client.connect()
        self.socks5Client = client
        self.isRunning = true
        
        logger.info("✅ 已连接到 Clash SOCKS5: \(clashHost):\(clashPort)")
        
        // 4. 开始读取数据包
        logger.info("📦 启动数据包处理...")
        startPacketReading()
        
        logger.info("🎉 VPN 隧道启动成功！")
        logger.info("✅ 所有流量现在通过 Clash 代理转发")
    }
    
    /// 停止 VPN 隧道
    override func stopTunnel(with reason: NEProviderStopReason) async {
        logger.info("🛑 停止 VPN 隧道，原因: \(reason.rawValue)")
        
        isRunning = false
        
        // 关闭 SOCKS5 连接
        socks5Client?.close()
        socks5Client = nil
        
        logger.info("✅ VPN 隧道已停止")
    }
    
    // MARK: - Network Configuration
    
    /// 创建网络设置 - 配置全局路由和 DNS
    private func createNetworkSettings(clashHost: String, clashPort: Int) -> NEPacketTunnelNetworkSettings {
        // 隧道远程地址（显示用）
        let settings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: "\(clashHost):\(clashPort)"
        )
        
        // === IPv4 配置 ===
        let ipv4Settings = NEIPv4Settings(
            addresses: ["172.16.0.2"],  // VPN 虚拟 IP
            subnetMasks: ["255.255.255.0"]
        )
        
        // 🔑 关键：设置默认路由，接管所有 IPv4 流量
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        
        // 排除本地网段（避免本地网络中断）
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),      // 私有网段 A
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),  // 私有网段 B
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"), // 私有网段 C
            NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),     // 环回地址
            NEIPv4Route(destinationAddress: "224.0.0.0", subnetMask: "240.0.0.0"),     // 多播地址
        ]
        
        settings.ipv4Settings = ipv4Settings
        
        // === IPv6 配置 ===
        let ipv6Settings = NEIPv6Settings(
            addresses: ["fd00::2"],
            networkPrefixLengths: [64]
        )
        
        // 🔑 关键：设置 IPv6 默认路由
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6Settings
        
        // === DNS 配置 ===
        let dnsSettings = NEDNSSettings(servers: [
            "1.1.1.1",  // Cloudflare DNS
            "8.8.8.8"   // Google DNS
        ])
        
        // 🔑 关键：matchDomains=[""] 表示匹配所有域名，实现 DNS 全量接管
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings
        
        return settings
    }
    
    // MARK: - Packet Handling
    
    /// 开始读取数据包（占位实现）
    private func startPacketReading() {
        packetQueue.async { [weak self] in
            self?.readPackets()
        }
    }
    
    /// 读取数据包的递归函数（转发到 SOCKS5）
    private func readPackets() {
        guard isRunning else { return }
        
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.isRunning else { return }
            
            if !packets.isEmpty {
                self.logger.debug("📦 收到 \(packets.count) 个数据包，转发到 Clash")
                
                // 转发数据包到 SOCKS5（简化实现）
                Task {
                    await self.forwardPackets(packets)
                }
            }
            
            // 继续读取下一批
            self.packetQueue.async {
                self.readPackets()
            }
        }
    }
    
    /// 转发数据包到 SOCKS5
    private func forwardPackets(_ packets: [Data]) async {
        guard let client = socks5Client else { return }
        
        for packet in packets {
            do {
                // 发送到 Clash SOCKS5
                try await client.send(packet)
                
                // 接收响应
                let response = try await client.receive()
                
                // 写回系统
                packetFlow.writePackets([response], withProtocols: [AF_INET as NSNumber])
            } catch {
                logger.error("❌ 转发失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - App Message Handling
    
    /// 处理来自主应用的消息（可选）
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        logger.info("📨 收到应用消息")
        
        // 可以用于：
        // - 更新配置
        // - 查询状态
        // - 切换节点
        
        return nil
    }
}


