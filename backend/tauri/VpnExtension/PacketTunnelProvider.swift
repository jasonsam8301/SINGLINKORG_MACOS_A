// PacketTunnelProvider.swift
// Copyright 2025 SingLink Team
// VPN 扩展核心实现 - 转发所有流量到本地 Clash

import NetworkExtension
import os.log

// TODO: 在 Xcode 中添加 Tun2socks framework 后取消注释
// @import Tun2socks;

/// Packet Tunnel Provider - 将系统流量转发到 Clash
/// 使用 Tun2socks 实现 TUN ↔ SOCKS5 桥接
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // MARK: - Properties
    
    private let logger = Logger(
        subsystem: "moe.elaina.clash.nyanpasu.vpn",
        category: "VPN"
    )
    
    // TODO: 集成 Tun2socks 后添加
    // private var tun2socksDevice: Tun2socksRemoteDevice?
    
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
        
        // 3. TODO: 集成 Tun2socks 后启用
        // 连接到本地 Clash SOCKS5
        // try await connectToClash(host: clashHost, port: clashPort)
        
        // 4. 开始读取数据包
        logger.info("📦 启动数据包处理...")
        startPacketReading()
        
        logger.info("🎉 VPN 隧道启动成功！")
        logger.info("💡 提示: 当前使用占位实现，集成 Tun2socks 后将实现真实流量转发")
    }
    
    /// 停止 VPN 隧道
    override func stopTunnel(with reason: NEProviderStopReason) async {
        logger.info("🛑 停止 VPN 隧道，原因: \(reason.rawValue)")
        
        // TODO: 集成 Tun2socks 后添加
        // tun2socksDevice?.close()
        // tun2socksDevice = nil
        
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
    
    /// 读取数据包的递归函数
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            
            if !packets.isEmpty {
                self.logger.debug("📦 收到 \(packets.count) 个数据包")
                
                // TODO: 集成 Tun2socks 后实现真实转发
                // for packet in packets {
                //     var n: Int = 0
                //     self.tun2socksDevice?.write(packet, ret0_: &n, error: nil)
                // }
            }
            
            // 继续读取下一批
            self.packetQueue.async {
                self.readPackets()
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

// MARK: - TODO: Tun2socks 集成

/*
集成 Tun2socks 后的完整实现：

import Tun2socks

extension PacketTunnelProvider: Tun2socksTunWriter {
    
    /// 连接到 Clash SOCKS5
    private func connectToClash(host: String, port: Int) async throws {
        logger.info("🔗 连接到 Clash SOCKS5...")
        
        let clientConfig = Tun2socksClientConfig()
        clientConfig.socksServerHost = host
        clientConfig.socksServerPort = Int32(port)
        
        let result = Tun2socksConnectRemoteDevice(clientConfig)
        
        guard let device = result.device, result.error == nil else {
            let errorMsg = result.error?.error ?? "未知错误"
            logger.error("❌ 连接失败: \(errorMsg)")
            throw NSError(domain: "VPN", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "无法连接到 Clash: \(errorMsg)"
            ])
        }
        
        self.tun2socksDevice = device
        logger.info("✅ 已连接到 Clash")
        
        // 启动 Tun2socks → Clash 的流量转发
        let relayError = Tun2socksGoRelayTrafficOneWay(self, device)
        if let error = relayError {
            logger.error("❌ 流量转发启动失败: \(error.error)")
            throw NSError(domain: "VPN", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "流量转发失败"
            ])
        }
        
        logger.info("✅ Tun2socks 流量转发已启动")
    }
    
    /// Tun2socksTunWriter 协议实现 - 将数据包写回系统
    func write(_ packet: Data, n: UnsafeMutablePointer<Int>) -> Bool {
        packetFlow.writePackets([packet], withProtocols: [AF_INET as NSNumber])
        n.pointee = packet.count
        return true
    }
    
    /// 读取数据包并转发到 Tun2socks（真实实现）
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self,
                  let device = self.tun2socksDevice else {
                self?.packetQueue.async {
                    self?.readPackets()
                }
                return
            }
            
            // 将数据包写入 Tun2socks（会转发到 Clash）
            for packet in packets {
                var bytesWritten: Int = 0
                device.write(packet, ret0_: &bytesWritten, error: nil)
            }
            
            // 继续读取
            self.packetQueue.async {
                self.readPackets()
            }
        }
    }
}
*/

