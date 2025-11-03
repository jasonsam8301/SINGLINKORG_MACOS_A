# ✅ Clash Nyanpasu VPN 扩展配置

## 🎯 我刚才做了什么

为 Clash Nyanpasu 创建了一个**独立的 VPN Extension Xcode 项目**：

**位置**：
```
/Users/starwork/workspace/macosnewsinglinkv2/docs/clash-nyanpasu-main/backend/tauri/VpnExtension.xcodeproj
```

**已自动打开！** ✅

---

## 📋 现在需要你配置（5分钟）

### 在 Xcode 中：

#### 步骤 1: 配置签名

1. 左侧选择 **VpnExtension** 项目（蓝色图标）
2. 中间选择 **TARGETS > VpnExtension**
3. 切换到 **Signing & Capabilities** 标签
4. 配置：
   ```
   ✅ Automatically manage signing（勾选）
   Team: SINGAPORE SINGLINKTECH PTE. LTD.
   Bundle Identifier: moe.elaina.clash.nyanpasu.VpnExtension
   ```

#### 步骤 2: 添加 Network Extensions Capability

1. 仍在 **Signing & Capabilities** 标签
2. 点击 **+ Capability** 按钮
3. 搜索 **Network Extensions**
4. 双击添加
5. 勾选 **✅ Packet Tunnel**

#### 步骤 3: 编译测试

1. **Product > Clean Build Folder** (⌘⇧K)
2. **Product > Build** (⌘B)

---

## 🎯 编译成功后

告诉我："编译成功了！"

然后我会：
1. 修改 Tauri 配置，包含这个 VPN Extension
2. 集成到 Clash Nyanpasu
3. 完成最后的联调
4. 完成！

---

**现在请配置签名并编译！** 🚀

