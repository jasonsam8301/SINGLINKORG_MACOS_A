# 🔧 VPN 扩展 Xcode 配置指南

## ✅ 所有代码已完成！

所有 VPN 扩展的代码已经编写完成并推送到 GitHub。现在只需要在 Xcode 中进行最后的配置。

---

## 📋 配置步骤（约10-15分钟）

### 步骤 1: 生成 Xcode 项目

```bash
cd /Users/starwork/workspace/macosnewsinglinkv2/docs/clash-nyanpasu-main

# 构建项目（会生成 Xcode 项目）
pnpm tauri build
```

**这会生成**：
```
backend/tauri/target/release/bundle/macos/Clash Nyanpasu.app
```

以及相关的 Xcode 项目文件。

---

### 步骤 2: 打开 Xcode 项目

Tauri 会在构建时使用 Xcode。我们需要找到生成的项目：

**查找方式**：
```bash
# 查找 Xcode 项目
find backend/tauri/target -name "*.xcodeproj" 2>/dev/null
```

或者直接在构建日志中查找 Xcode 项目路径。

---

### 步骤 3: 在 Xcode 中添加 Network Extension Target

#### 3.1 打开项目
```bash
# 假设项目路径是（根据实际情况）
open backend/tauri/target/release/.../Clash\ Nyanpasu.xcodeproj
```

#### 3.2 添加 Extension Target

在 Xcode 中：

1. **File > New > Target**
2. 选择 **macOS**
3. 选择 **Network Extension**
4. 选择 **Packet Tunnel Provider**
5. 点击 **Next**

#### 3.3 配置 Target

```
Product Name: VpnExtension
Language: Swift
Project: Clash Nyanpasu
Embed in Application: Clash Nyanpasu
```

点击 **Finish**

#### 3.4 替换默认文件

Xcode 会生成一个默认的 PacketTunnelProvider.swift：

1. **删除**默认生成的文件
2. **添加**我们创建的文件：
   - 右键点击 VpnExtension group
   - Add Files to "Clash Nyanpasu"...
   - 选择 `backend/tauri/VpnExtension/PacketTunnelProvider.swift`
   - ✅ 勾选 VpnExtension target
   - 点击 Add

3. **替换** Info.plist 和 Entitlements
   - 用我们创建的文件替换默认文件

---

### 步骤 4: 添加 Tun2socks Framework

#### 4.1 添加到 VpnExtension Target

1. 选择 **VpnExtension** target
2. 切换到 **General** 标签
3. 滚动到 **Frameworks, Libraries, and Embedded Content**
4. 点击 **+** 按钮
5. 点击 **Add Other...** > **Add Files...**
6. 浏览到 `backend/tauri/Tun2socks.xcframework`
7. 点击 **Open**
8. 设置为 **Embed & Sign**

---

### 步骤 5: 配置 Bundle Identifiers

#### 主应用
- Bundle ID: `moe.elaina.clash.nyanpasu`（保持不变）

#### VPN 扩展
- Bundle ID: `moe.elaina.clash.nyanpasu.VpnExtension`

确保 VPN 扩展的 Bundle ID 是主应用 ID + `.VpnExtension`

---

### 步骤 6: 配置签名

#### 主应用（Clash Nyanpasu）
1. 选择 **Clash Nyanpasu** target
2. **Signing & Capabilities** 标签
3. **Team**: 选择你的团队
4. **✅ Automatically manage signing**
5. 添加 Capability: **Network Extensions**
   - 点击 **+ Capability**
   - 搜索 "Network Extensions"
   - 添加
   - 勾选 **Packet Tunnel**

#### VPN 扩展（VpnExtension）
1. 选择 **VpnExtension** target
2. **Signing & Capabilities** 标签
3. **Team**: 选择相同的团队
4. **✅ Automatically manage signing**
5. Network Extensions capability 应该自动添加
   - 确认勾选了 **Packet Tunnel**

---

### 步骤 7: 添加 VPN Helper 到 Resources

1. 在 Xcode 项目导航器中
2. 右键点击 **Clash Nyanpasu** target 的 Resources
3. Add Files...
4. 选择 `backend/tauri/resources/vpn/vpn-helper`
5. ✅ 勾选 Copy items if needed
6. ✅ 勾选 Clash Nyanpasu target
7. 点击 Add

---

### 步骤 8: 编译测试

#### 8.1 清理构建
**Product > Clean Build Folder** (⌘⇧K)

#### 8.2 选择目标
- **Scheme**: Clash Nyanpasu
- **Destination**: My Mac

#### 8.3 编译
**Product > Build** (⌘B)

如果编译成功，继续下一步。

#### 8.4 运行
**Product > Run** (⌘R)

---

### 步骤 9: 测试 VPN 扩展

应用启动后：

1. 打开 **设置** 页面
2. 找到 **"VPN 扩展"** 卡片
3. 点击开关 **启用 VPN 扩展**
4. 系统会弹出授权对话框
5. 点击 **"允许"**
6. VPN 配置会出现在"系统设置 > 网络 > VPN"
7. VPN 自动连接
8. 测试流量是否走代理：
   ```bash
   curl https://ifconfig.me
   # 应该显示代理服务器的 IP
   ```

---

## 🐛 可能遇到的问题

### 问题 1: 编译错误 - Tun2socks not found

**原因**：Framework 路径不对

**解决**：
1. 检查 Tun2socks.xcframework 是否在正确位置
2. 在 Build Settings 中检查 Framework Search Paths
3. 重新添加 Framework

---

### 问题 2: 签名错误

**错误**：`Provisioning profile doesn't include Network Extension`

**原因**：免费账号不支持 Network Extension

**解决**：
- 必须使用**付费 Apple Developer Program** 账号（$99/年）

---

### 问题 3: VPN 启动失败

**检查**：
1. Clash 是否正在运行？
2. Clash SOCKS5 端口是否是 7890？
3. VPN Helper 是否在应用包中？

**调试**：
```bash
# 查看 VPN 扩展日志
log stream --info --predicate 'subsystem contains "nyanpasu.vpn"'
```

---

## ✅ 成功标志

### 编译成功
看到：
```
Build Succeeded
```

### VPN 配置创建成功
在"系统设置 > 网络 > VPN"中看到：
```
📱 Clash Nyanpasu VPN - [节点名]
   状态: 已连接
```

### 流量真实走代理
```bash
# 连接前
curl https://ifconfig.me
# 显示你的真实 IP: xxx.xxx.xxx.xxx

# 连接 VPN 后
curl https://ifconfig.me
# 显示代理 IP: yyy.yyy.yyy.yyy

✅ 如果 IP 不同，说明 VPN 工作正常！
```

---

## 📚 参考资料

### 相关文档
- `VPN_EXTENSION_GUIDE.md` - 总体指南
- `backend/tauri/VpnExtension/README.md` - VPN 扩展说明
- `🎯_VPN扩展集成完成_最后配置步骤.md` - 当前文档

### Apple 官方文档
- [Network Extension Programming Guide](https://developer.apple.com/documentation/networkextension)
- [Creating a Packet Tunnel Provider](https://developer.apple.com/documentation/networkextension/packet_tunnel_provider)

---

## 🎊 完成后

配置完成并测试成功后，请告诉我：

✅ **"VPN 扩展配置成功！"**
- 我会创建最终的使用文档
- 推送所有更新到 GitHub
- 标记项目为完成状态

❌ **"遇到了问题：..."**
- 告诉我错误信息
- 我会帮你排查和解决

---

**祝配置顺利！** 🚀

