// vpn-helper/main.swift
// Swift Helper 工具 - 用于 Rust 调用 macOS VPN API

import Foundation
import NetworkExtension

/// VPN 配置结构
struct VPNConfig: Codable {
    let name: String
    let clashHost: String
    let clashPort: Int
    let nodeName: String
}

/// VPN Helper 主程序
struct VPNHelper {
    static func run() async {
        let args = CommandLine.arguments
        
        guard args.count >= 2 else {
            printUsage()
            exit(1)
        }
        
        let action = args[1]
        
        do {
            switch action {
            case "install":
                try await installVPNConfiguration()
            case "update":
                try await updateVPNConfiguration()
            case "start":
                try await startVPN()
            case "stop":
                try await stopVPN()
            case "status":
                try await getVPNStatus()
            case "remove":
                try await removeVPNConfiguration()
            default:
                print("❌ 未知操作: \(action)")
                printUsage()
                exit(1)
            }
            exit(0)
        } catch {
            print("❌ 错误: \(error.localizedDescription)")
            exit(1)
        }
    }
    
    // MARK: - VPN Operations
    
    /// 安装 VPN 配置
    static func installVPNConfiguration() async throws {
        print("📥 安装 VPN 配置...")
        
        // 读取配置（从stdin或参数）
        let config = try readConfig()
        
        // 加载现有配置
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        // 创建或使用现有 manager
        let manager = managers.first ?? NETunnelProviderManager()
        
        // 配置 VPN
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "moe.elaina.clash.nyanpasu.VpnExtension"
        proto.serverAddress = config.clashHost
        proto.providerConfiguration = [
            "clashHost": config.clashHost,
            "clashPort": config.clashPort,
            "nodeName": config.nodeName
        ]
        
        manager.protocolConfiguration = proto
        manager.localizedDescription = config.name
        manager.isEnabled = true
        
        // 保存到系统
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        
        print("✅ VPN 配置已安装")
        print("💡 VPN 现在出现在: 系统设置 > 网络 > VPN")
    }
    
    /// 更新 VPN 配置
    static func updateVPNConfiguration() async throws {
        print("🔄 更新 VPN 配置...")
        
        let config = try readConfig()
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        guard let manager = managers.first else {
            throw NSError(domain: "VPN", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "VPN 配置不存在，请先安装"
            ])
        }
        
        // 更新配置
        if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol {
            proto.serverAddress = config.clashHost
            proto.providerConfiguration = [
                "clashHost": config.clashHost,
                "clashPort": config.clashPort,
                "nodeName": config.nodeName
            ]
        }
        
        manager.localizedDescription = config.name
        
        try await manager.saveToPreferences()
        
        print("✅ VPN 配置已更新")
    }
    
    /// 启动 VPN
    static func startVPN() async throws {
        print("🚀 启动 VPN...")
        
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        guard let manager = managers.first else {
            throw NSError(domain: "VPN", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "VPN 配置不存在"
            ])
        }
        
        try await manager.loadFromPreferences()
        try manager.connection.startVPNTunnel()
        
        print("✅ VPN 已启动")
    }
    
    /// 停止 VPN
    static func stopVPN() async throws {
        print("🛑 停止 VPN...")
        
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        guard let manager = managers.first else {
            print("⚠️ VPN 配置不存在")
            return
        }
        
        manager.connection.stopVPNTunnel()
        
        print("✅ VPN 已停止")
    }
    
    /// 获取 VPN 状态
    static func getVPNStatus() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        guard let manager = managers.first else {
            print("STATUS:not_installed")
            return
        }
        
        let status = manager.connection.status
        let statusString: String
        
        switch status {
        case .invalid:
            statusString = "invalid"
        case .disconnected:
            statusString = "disconnected"
        case .connecting:
            statusString = "connecting"
        case .connected:
            statusString = "connected"
        case .reasserting:
            statusString = "reasserting"
        case .disconnecting:
            statusString = "disconnecting"
        @unknown default:
            statusString = "unknown"
        }
        
        print("STATUS:\(statusString)")
    }
    
    /// 删除 VPN 配置
    static func removeVPNConfiguration() async throws {
        print("🗑️ 删除 VPN 配置...")
        
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        
        for manager in managers {
            // 先停止
            if manager.connection.status != .disconnected {
                manager.connection.stopVPNTunnel()
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            
            // 删除配置
            try await manager.removeFromPreferences()
        }
        
        print("✅ VPN 配置已删除")
    }
    
    // MARK: - Helper Functions
    
    /// 读取配置（从 stdin）
    static func readConfig() throws -> VPNConfig {
        let data = FileHandle.standardInput.availableData
        
        guard !data.isEmpty else {
            // 使用默认配置
            return VPNConfig(
                name: "Clash Nyanpasu VPN",
                clashHost: "127.0.0.1",
                clashPort: 7890,
                nodeName: "GLOBAL"
            )
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VPNConfig.self, from: data)
    }
    
    /// 打印使用说明
    static func printUsage() {
        print("""
        VPN Helper - Clash Nyanpasu VPN 管理工具
        
        用法: vpn-helper <action> [config_json]
        
        操作:
          install  - 安装 VPN 配置到系统
          update   - 更新 VPN 配置
          start    - 启动 VPN 连接
          stop     - 停止 VPN 连接
          status   - 获取 VPN 状态
          remove   - 删除 VPN 配置
          
        示例:
          echo '{"name":"Clash VPN","clashHost":"127.0.0.1","clashPort":7890,"nodeName":"GLOBAL"}' | vpn-helper install
          vpn-helper start
          vpn-helper status
          vpn-helper stop
        """)
    }
}

// 入口点 - 使用 RunLoop 运行异步任务
let semaphore = DispatchSemaphore(value: 0)

Task {
    await VPNHelper.run()
    semaphore.signal()
}

semaphore.wait()


