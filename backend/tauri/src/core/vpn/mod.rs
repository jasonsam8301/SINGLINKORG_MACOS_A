// mod.rs
// Copyright 2025 SingLink Team  
// VPN 扩展管理模块

#[cfg(target_os = "macos")]
pub mod manager;

#[cfg(target_os = "macos")]
pub mod commands;

#[cfg(target_os = "macos")]
pub mod helper;

#[cfg(target_os = "macos")]
pub use manager::VpnManager;

#[cfg(target_os = "macos")]
pub use commands::*;

// 非 macOS 平台提供空实现
#[cfg(not(target_os = "macos"))]
pub mod commands {
    use serde::{Deserialize, Serialize};
    
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct VpnStatus {
        pub supported: bool,
    }
    
    #[tauri::command]
    pub async fn vpn_extension_toggle(_enable: bool) -> Result<(), String> {
        Err("VPN 扩展仅支持 macOS".to_string())
    }
    
    #[tauri::command]
    pub fn vpn_extension_status() -> VpnStatus {
        VpnStatus { supported: false }
    }
}

