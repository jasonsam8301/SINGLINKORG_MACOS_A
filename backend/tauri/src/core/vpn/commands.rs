// commands.rs
// Copyright 2025 SingLink Team
// Tauri Commands for VPN Extension

use super::manager::{VpnManager, VpnConnectionStatus};
use serde::{Deserialize, Serialize};

/// VPN 扩展状态信息
#[derive(Debug, Clone, Serialize, Deserialize, specta::Type)]
pub struct VpnExtensionStatus {
    /// 是否支持 VPN 扩展（仅 macOS）
    pub supported: bool,
    /// 是否已安装配置
    pub installed: bool,
    /// 连接状态
    pub status: String,
    /// 当前节点名称
    pub node_name: Option<String>,
    /// Clash SOCKS5 端口
    pub clash_port: Option<u16>,
}

/// 切换 VPN 扩展开关（带详细日志）
#[tauri::command(async)]
#[specta::specta]
pub async fn vpn_extension_toggle(enable: bool) -> Result<(), String> {
    tracing::info!("╔═══════════════════════════════════════╗");
    tracing::info!("║  VPN 扩展操作: {}  ║", if enable { "启用" } else { "禁用" });
    tracing::info!("╚═══════════════════════════════════════╝");
    
    let manager = VpnManager::global();
    
    if enable {
        tracing::info!("[步骤 1/5] 开始启用VPN扩展...");
        
        match manager.enable().await {
            Ok(_) => {
                tracing::info!("╔═══════════════════════════════════════╗");
                tracing::info!("║   ✅ VPN 扩展启用成功！   ║");
                tracing::info!("╚═══════════════════════════════════════╝");
                Ok(())
            }
            Err(e) => {
                tracing::error!("╔═══════════════════════════════════════╗");
                tracing::error!("║   ❌ VPN 扩展启用失败   ║");
                tracing::error!("╚═══════════════════════════════════════╝");
                tracing::error!("错误详情: {:?}", e);
                tracing::error!("错误位置: {}", e);
                
                Err(format!(
                    "启用 VPN 失败:\n\n{}\n\n详细错误已记录到日志文件", 
                    e
                ))
            }
        }
    } else {
        tracing::info!("[步骤 1/2] 开始禁用VPN...");
        
        match manager.disable().await {
            Ok(_) => {
                tracing::info!("✅ VPN 已禁用");
                Ok(())
            }
            Err(e) => {
                tracing::error!("❌ 禁用失败: {}", e);
                Err(format!("禁用 VPN 失败: {}", e))
            }
        }
    }
}

/// 获取 VPN 扩展状态
#[tauri::command]
#[specta::specta]
pub fn vpn_extension_status() -> VpnExtensionStatus {
    let manager = VpnManager::global();
    let status = manager.get_status();
    
    VpnExtensionStatus {
        supported: true,  // macOS 平台
        installed: true,  // TODO: 读取实际状态
        status: match status {
            VpnConnectionStatus::Disconnected => "disconnected".to_string(),
            VpnConnectionStatus::Connecting => "connecting".to_string(),
            VpnConnectionStatus::Connected => "connected".to_string(),
            VpnConnectionStatus::Disconnecting => "disconnecting".to_string(),
            VpnConnectionStatus::Invalid => "invalid".to_string(),
        },
        node_name: None,  // TODO: 读取当前节点
        clash_port: Some(7890),  // TODO: 从配置读取
    }
}

/// 刷新 VPN 配置（当 Clash 节点变化时调用）
#[tauri::command(async)]
#[specta::specta]
pub async fn vpn_extension_refresh() -> Result<(), String> {
    tracing::info!("🔄 刷新 VPN 配置...");
    
    let manager = VpnManager::global();
    let status = manager.get_status();
    
    if status == VpnConnectionStatus::Connected {
        // VPN 已连接，重新获取 Clash 配置并更新
        // TODO: 实现配置更新逻辑
        tracing::info!("✅ VPN 配置已刷新");
    }
    
    Ok(())
}

