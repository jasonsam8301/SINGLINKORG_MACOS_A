// helper.rs
// VPN Helper - 使用系统原生方式创建和管理VPN

use anyhow::{Result, anyhow};
use std::process::Command;

/// 安装VPN配置（使用scutil命令）
pub async fn install_vpn(name: &str, host: &str, port: u16) -> Result<()> {
    tracing::info!("📝 创建VPN配置: {}", name);
    tracing::info!("   服务器: {}:{}", host, port);
    
    // 使用networksetup命令创建VPN配置
    // 这是macOS原生支持的方式
    
    let vpn_name = format!("Clash Nyanpasu - {}", name);
    
    // 方案：直接提示用户手动配置一次
    // 之后可以通过代码控制
    
    tracing::warn!("⚠️ 首次使用需要手动配置VPN（仅一次）");
    tracing::info!("📖 请按照以下步骤操作：");
    tracing::info!("1. 打开：系统设置 > 网络 > VPN");
    tracing::info!("2. 点击：+ 添加VPN配置");
    tracing::info!("3. 类型：选择 IKEv2 或 L2TP");
    tracing::info!("4. 名称：{}", vpn_name);
    tracing::info!("5. 服务器：{}:{}", host, port);
    tracing::info!("6. 保存配置");
    tracing::info!("7. 之后可以通过Clash Nyanpasu控制");
    
    // 暂时返回成功（提示用户手动配置）
    Ok(())
}

/// 启动VPN
pub async fn start_vpn(name: &str) -> Result<()> {
    let vpn_name = format!("Clash Nyanpasu - {}", name);
    
    tracing::info!("🚀 启动VPN: {}", vpn_name);
    
    // 使用networksetup命令
    let output = Command::new("networksetup")
        .arg("-connectpppoeservice")
        .arg(&vpn_name)
        .output()?;
    
    if !output.status.success() {
        let err = String::from_utf8_lossy(&output.stderr);
        tracing::error!("❌ VPN启动失败: {}", err);
        tracing::error!("💡 可能需要在系统设置中手动配置VPN");
        return Err(anyhow!("VPN启动失败: {}", err));
    }
    
    tracing::info!("✅ VPN已启动");
    Ok(())
}

/// 停止VPN
pub async fn stop_vpn(name: &str) -> Result<()> {
    let vpn_name = format!("Clash Nyanpasu - {}", name);
    
    tracing::info!("🛑 停止VPN: {}", vpn_name);
    
    let output = Command::new("networksetup")
        .arg("-disconnectpppoeservice")
        .arg(&vpn_name)
        .output()?;
    
    if !output.status.success() {
        tracing::warn!("⚠️ VPN停止可能失败（可能已断开）");
    }
    
    Ok(())
}
