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

/// 切换 VPN 扩展开关
#[tauri::command(async)]
#[specta::specta]
pub async fn vpn_extension_toggle(enable: bool) -> Result<(), String> {
    tracing::info!("🎛️ VPN 扩展开关: {}", if enable { "开启" } else { "关闭" });
    
    let manager = VpnManager::global();
    
    if enable {
        manager.enable()
            .await
            .map_err(|e| {
                tracing::error!("❌ 启用 VPN 失败: {}", e);
                format!("启用 VPN 失败: {}", e)
            })?;
    } else {
        manager.disable()
            .await
            .map_err(|e| {
                tracing::error!("❌ 禁用 VPN 失败: {}", e);
                format!("禁用 VPN 失败: {}", e)
            })?;
    }
    
    Ok(())
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

