// setting-system-vpn.tsx
// Copyright 2025 SingLink Team
// VPN 扩展设置组件 - macOS Network Extension

import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { invoke } from '@tauri-apps/api/core'
import {
  Alert,
  Chip,
  List,
  ListItem,
  ListItemText,
  Typography,
} from '@mui/material'
import { BaseCard, SwitchItem } from '@nyanpasu/ui'

/// VPN 扩展状态
interface VpnExtensionStatus {
  supported: boolean
  installed: boolean
  status: 'disconnected' | 'connecting' | 'connected' | 'disconnecting' | 'invalid'
  node_name?: string
  clash_port?: number
}

export const SettingSystemVPN = () => {
  const { t } = useTranslation()
  
  // 状态管理
  const [enabled, setEnabled] = useState(false)
  const [loading, setLoading] = useState(false)
  const [status, setStatus] = useState<VpnExtensionStatus | null>(null)
  const [error, setError] = useState<string | null>(null)
  
  // 加载初始状态
  useEffect(() => {
    loadStatus()
    
    // 定时刷新状态（每3秒）
    const interval = setInterval(loadStatus, 3000)
    return () => clearInterval(interval)
  }, [])
  
  // 加载 VPN 状态
  const loadStatus = async () => {
    try {
      const result = await invoke<VpnExtensionStatus>('vpn_extension_status')
      setStatus(result)
      setEnabled(result.status === 'connected' || result.status === 'connecting')
    } catch (err) {
      console.error('获取 VPN 状态失败:', err)
    }
  }
  
  // 切换 VPN 开关
  const handleToggle = async (checked: boolean) => {
    setLoading(true)
    setError(null)
    
    try {
      await invoke('vpn_extension_toggle', { enable: checked })
      
      // 等待状态更新
      setTimeout(loadStatus, 1000)
      
      setEnabled(checked)
    } catch (err) {
      console.error('VPN 操作失败:', err)
      setError(String(err))
      setEnabled(!checked)  // 回滚状态
    } finally {
      setLoading(false)
    }
  }
  
  // 如果不支持（非 macOS），不显示
  if (status && !status.supported) {
    return null
  }
  
  // 获取状态显示
  const getStatusChip = () => {
    if (!status) return null
    
    const statusConfig = {
      connected: { label: '已连接', color: 'success' as const },
      connecting: { label: '连接中', color: 'warning' as const },
      disconnected: { label: '未连接', color: 'default' as const },
      disconnecting: { label: '断开中', color: 'warning' as const },
      invalid: { label: '配置无效', color: 'error' as const },
    }
    
    const config = statusConfig[status.status] || statusConfig.disconnected
    
    return <Chip size="small" label={config.label} color={config.color} />
  }
  
  return (
    <BaseCard label={t('VPN Extension')}>
      <List disablePadding>
        {/* 主开关 */}
        <SwitchItem
          label={t('Enable VPN Extension')}
          checked={enabled}
          onChange={(e) => handleToggle(e.target.checked)}
          disabled={loading}
        />
        
        {/* 说明文字 */}
        <ListItem>
          <Typography variant="caption" color="textSecondary">
            💡 VPN 扩展会代理 macOS 系统的<strong>全部应用</strong>，
            在"系统设置 &gt; 网络 &gt; VPN"中可见。
            支持所有 Clash 协议（SS、VMess、Trojan 等）。
          </Typography>
        </ListItem>
        
        {/* 状态显示 */}
        {enabled && status && (
          <>
            <ListItem>
              <ListItemText
                primary="状态"
                secondary={getStatusChip()}
              />
            </ListItem>
            
            {status.node_name && (
              <ListItem>
                <ListItemText
                  primary="当前节点"
                  secondary={status.node_name}
                />
              </ListItem>
            )}
            
            {status.clash_port && (
              <ListItem>
                <ListItemText
                  primary="Clash 端口"
                  secondary={`127.0.0.1:${status.clash_port} (SOCKS5)`}
                />
              </ListItem>
            )}
          </>
        )}
        
        {/* 首次使用提示 */}
        {!status?.installed && (
          <ListItem>
            <Alert severity="info" sx={{ width: '100%' }}>
              <strong>首次使用说明：</strong><br />
              1. 点击开关启用 VPN 扩展<br />
              2. 系统会弹出授权对话框<br />
              3. 点击"允许"完成配置<br />
              4. VPN 会出现在"系统设置 &gt; 网络 &gt; VPN"中
            </Alert>
          </ListItem>
        )}
        
        {/* 错误提示 */}
        {error && (
          <ListItem>
            <Alert severity="error" sx={{ width: '100%' }}>
              {error}
            </Alert>
          </ListItem>
        )}
        
        {/* 使用提示 */}
        {enabled && status?.status === 'connected' && (
          <ListItem>
            <Alert severity="success" sx={{ width: '100%' }}>
              <strong>✅ VPN 已连接！</strong><br />
              • 所有应用流量正在走代理<br />
              • 切换节点会自动生效，无需断开 VPN<br />
              • 可以在系统设置中查看 VPN 状态
            </Alert>
          </ListItem>
        )}
      </List>
    </BaseCard>
  )
}

export default SettingSystemVPN

