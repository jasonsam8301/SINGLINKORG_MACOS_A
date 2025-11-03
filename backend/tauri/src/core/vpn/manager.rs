// manager.rs
// Copyright 2025 SingLink Team
// VPN 扩展管理器 - 控制 macOS Network Extension

use anyhow::{Result, anyhow};
use serde::{Deserialize, Serialize};
use std::process::Command;
use std::sync::Arc;
use parking_lot::Mutex;
use once_cell::sync::OnceCell;

use crate::config::Config;
use crate::core::clash::ClashCore;

/// VPN 配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VpnConfig {
    pub clash_host: String,
    pub clash_port: u16,
    pub node_name: String,
}

/// VPN 状态
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum VpnConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Invalid,
}

/// VPN 管理器（单例）
pub struct VpnManager {
    /// 当前配置
    config: Arc<Mutex<Option<VpnConfig>>>,
    /// 连接状态
    status: Arc<Mutex<VpnConnectionStatus>>,
    /// 是否已安装配置
    installed: Arc<Mutex<bool>>,
}

impl VpnManager {
    /// 获取全局单例
    pub fn global() -> &'static VpnManager {
        static INSTANCE: OnceCell<VpnManager> = OnceCell::new();
        
        INSTANCE.get_or_init(|| {
            tracing::info!("🔧 初始化 VPN 管理器");
            
            VpnManager {
                config: Arc::new(Mutex::new(None)),
                status: Arc::new(Mutex::new(VpnConnectionStatus::Disconnected)),
                installed: Arc::new(Mutex::new(false)),
            }
        })
    }
    
    /// 启用 VPN 扩展
    pub async fn enable(&self) -> Result<()> {
        tracing::info!("🚀 启用 VPN 扩展...");
        
        // 步骤 1: 确保 Clash 核心正在运行
        self.ensure_clash_running().await?;
        
        // 步骤 2: 获取 Clash 配置
        let config = self.get_clash_config()?;
        
        tracing::info!("📝 VPN 配置:");
        tracing::info!("   Clash: {}:{}", config.clash_host, config.clash_port);
        tracing::info!("   节点: {}", config.node_name);
        
        // 步骤 3: 检查并处理 TUN 模式冲突
        self.handle_tun_conflict().await?;
        
        // 步骤 4: 安装或更新 VPN 配置
        if !*self.installed.lock() {
            tracing::info!("📥 首次使用，安装 VPN 配置...");
            self.install_vpn_config(&config).await?;
            *self.installed.lock() = true;
        } else {
            tracing::info!("🔄 更新 VPN 配置...");
            self.update_vpn_config(&config).await?;
        }
        
        // 步骤 5: 启动 VPN
        tracing::info!("🔗 启动 VPN 隧道...");
        self.start_vpn().await?;
        
        // 步骤 6: 更新状态
        *self.config.lock() = Some(config);
        *self.status.lock() = VpnConnectionStatus::Connected;
        
        tracing::info!("✅ VPN 扩展已启用");
        Ok(())
    }
    
    /// 禁用 VPN 扩展
    pub async fn disable(&self) -> Result<()> {
        tracing::info!("🛑 禁用 VPN 扩展...");
        
        *self.status.lock() = VpnConnectionStatus::Disconnecting;
        
        // 停止 VPN
        self.stop_vpn().await?;
        
        *self.status.lock() = VpnConnectionStatus::Disconnected;
        
        tracing::info!("✅ VPN 扩展已禁用");
        
        // 注意：不关闭 Clash 核心，保持其他功能可用
        Ok(())
    }
    
    /// 获取当前状态
    pub fn get_status(&self) -> VpnConnectionStatus {
        *self.status.lock()
    }
    
    // MARK: - Private Methods
    
    /// 确保 Clash 核心正在运行
    async fn ensure_clash_running(&self) -> Result<()> {
        use super::super::clash::ClashCore;
        
        // 检查 Clash 是否运行
        if !ClashCore::is_running() {
            tracing::info!("⚠️ Clash 未运行，正在启动...");
            
            // 启动 Clash
            ClashCore::global().run_core().await?;
            
            // 等待 Clash 就绪
            tokio::time::sleep(std::time::Duration::from_secs(3)).await;
        }
        
        // 验证 SOCKS5 端口可用
        verify_clash_port(7890)?;
        
        tracing::info!("✅ Clash 核心已就绪");
        Ok(())
    }
    
    /// 从 Clash 配置获取 VPN 所需信息
    fn get_clash_config(&self) -> Result<VpnConfig> {
        let clash_config = Config::clash().data();
        
        // 读取 SOCKS5 端口
        let port = clash_config
            .get("socks-port")
            .and_then(|v| v.as_u64())
            .unwrap_or_else(|| {
                // 降级到 mixed-port
                clash_config.get_mixed_port() as u64
            }) as u16;
        
        tracing::info!("📝 读取 Clash 配置:");
        tracing::info!("   SOCKS5 端口: {}", port);
        
        // 获取当前节点（从 Clash API）
        let node_name = self.get_current_node_name()
            .unwrap_or("GLOBAL".to_string());
        
        Ok(VpnConfig {
            clash_host: "127.0.0.1".to_string(),
            clash_port: port,
            node_name,
        })
    }
    
    /// 获取当前选中的节点名称
    fn get_current_node_name(&self) -> Option<String> {
        // TODO: 从 Clash API 查询当前代理
        // 当前返回配置中的信息
        Some("当前节点".to_string())
    }
    
    /// 处理与 TUN 模式的冲突
    async fn handle_tun_conflict(&self) -> Result<()> {
        use crate::config::Config;
        
        // 检查 TUN 是否启用
        let tun_enabled = {
            let verge = Config::verge().latest();
            verge.enable_tun_mode.unwrap_or(false)
        };
        
        if tun_enabled {
            tracing::warn!("⚠️ 检测到 TUN 模式已启用");
            tracing::info!("📝 VPN 扩展将接管流量，建议关闭 TUN 模式");
            
            // 自动关闭 TUN 模式
            let mut verge = Config::verge().latest().clone();
            verge.enable_tun_mode = Some(false);
            Config::verge().patch(verge).await?;
            
            tracing::info!("✅ TUN 模式已自动关闭");
            
            // 等待配置生效
            tokio::time::sleep(std::time::Duration::from_secs(1)).await;
        } else {
            tracing::info!("✅ TUN 模式未启用，无冲突");
        }
        
        Ok(())
    }
    
    /// 安装 VPN 配置到系统
    async fn install_vpn_config(&self, config: &VpnConfig) -> Result<()> {
        tracing::info!("📥 安装 VPN 配置到系统...");
        
        // TODO: 调用 Swift Helper 或使用 Objective-C bridge
        // 创建 NETunnelProviderManager
        
        self.call_vpn_helper("install", config).await?;
        
        tracing::info!("✅ VPN 配置已安装");
        tracing::info!("💡 VPN 配置现在出现在: 系统设置 > 网络 > VPN");
        
        Ok(())
    }
    
    /// 更新 VPN 配置
    async fn update_vpn_config(&self, config: &VpnConfig) -> Result<()> {
        tracing::info!("🔄 更新 VPN 配置...");
        
        self.call_vpn_helper("update", config).await?;
        
        tracing::info!("✅ VPN 配置已更新");
        Ok(())
    }
    
    /// 启动 VPN 隧道
    async fn start_vpn(&self) -> Result<()> {
        self.call_vpn_helper("start", &()).await?;
        Ok(())
    }
    
    /// 停止 VPN 隧道
    async fn stop_vpn(&self) -> Result<()> {
        self.call_vpn_helper("stop", &()).await?;
        Ok(())
    }
    
    /// 调用 VPN Helper
    async fn call_vpn_helper<T: Serialize>(&self, action: &str, config: &T) -> Result<()> {
        use tokio::process::Command;
        use tokio::io::AsyncWriteExt;
        
        tracing::info!("🔧 调用 VPN Helper: {}", action);
        
        // VPN Helper 工具路径（与 Tauri 应用打包在一起）
        let helper_path = std::env::current_exe()?
            .parent()
            .ok_or_else(|| anyhow!("无法获取应用目录"))?
            .join("vpn-helper");
        
        if !helper_path.exists() {
            return Err(anyhow!("VPN Helper 工具不存在: {:?}", helper_path));
        }
        
        // 准备配置 JSON
        let config_json = serde_json::to_string(config)?;
        
        // 执行 helper
        let mut child = Command::new(&helper_path)
            .arg(action)
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()?;
        
        // 写入配置到 stdin
        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(config_json.as_bytes()).await?;
            drop(stdin);  // 关闭 stdin
        }
        
        // 等待完成
        let output = child.wait_with_output().await?;
        
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            tracing::error!("❌ VPN Helper 失败: {}", stderr);
            return Err(anyhow!("VPN Helper 操作失败: {}", stderr));
        }
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        tracing::info!("✅ VPN Helper 成功: {}", stdout);
        
        Ok(())
    }
}

// MARK: - 辅助函数

/// 验证 Clash 端口是否可用
#[allow(dead_code)]
fn verify_clash_port(port: u16) -> Result<()> {
    use std::net::TcpStream;
    use std::time::Duration;
    
    let addr = format!("127.0.0.1:{}", port);
    
    match TcpStream::connect_timeout(
        &addr.parse().unwrap(),
        Duration::from_secs(2)
    ) {
        Ok(_) => {
            tracing::info!("✅ Clash 端口 {} 可用", port);
            Ok(())
        }
        Err(e) => {
            tracing::error!("❌ Clash 端口 {} 不可用: {}", port, e);
            Err(anyhow!("Clash 端口不可用，请确保 Clash 正在运行"))
        }
    }
}

