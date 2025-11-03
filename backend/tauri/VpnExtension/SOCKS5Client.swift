// SOCKS5Client.swift
// 纯 Swift 实现的 SOCKS5 客户端
// 用于将 VPN 流量转发到本地 Clash

import Foundation
import Network
import NetworkExtension

/// 简单的 SOCKS5 客户端
/// 连接到本地 Clash 并转发流量
class SOCKS5Client {
    
    private let clashHost: String
    private let clashPort: UInt16
    private var connection: NWConnection?
    
    init(host: String, port: UInt16) {
        self.clashHost = host
        self.clashPort = port
    }
    
    /// 连接到 Clash SOCKS5 服务器
    func connect() async throws {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(clashHost),
            port: NWEndpoint.Port(integerLiteral: clashPort)
        )
        
        let connection = NWConnection(
            to: endpoint,
            using: .tcp
        )
        
        self.connection = connection
        
        // 启动连接
        connection.start(queue: .main)
        
        // 等待连接就绪
        try await waitForReady(connection)
        
        print("✅ SOCKS5 客户端已连接到 \(clashHost):\(clashPort)")
    }
    
    /// 等待连接就绪
    private func waitForReady(_ connection: NWConnection) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: error)
                case .waiting(let error):
                    print("⚠️ 连接等待中: \(error)")
                default:
                    break
                }
            }
        }
    }
    
    /// 发送数据
    func send(_ data: Data) async throws {
        guard let connection = connection else {
            throw NSError(domain: "SOCKS5", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "连接未建立"
            ])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(
                content: data,
                completion: .contentProcessed { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            )
        }
    }
    
    /// 接收数据
    func receive(minimumLength: Int = 1, maximumLength: Int = 65536) async throws -> Data {
        guard let connection = connection else {
            throw NSError(domain: "SOCKS5", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "连接未建立"
            ])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(
                minimumIncompleteLength: minimumLength,
                maximumLength: maximumLength
            ) { data, _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "SOCKS5",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "未收到数据"]
                    ))
                }
            }
        }
    }
    
    /// 关闭连接
    func close() {
        connection?.cancel()
        connection = nil
    }
}

