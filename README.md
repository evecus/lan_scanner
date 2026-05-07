# 📡 LAN Scanner

局域网设备扫描工具，支持 Android & iOS。无需 Root。

## 功能

- 🔍 输入 CIDR 网段（如 `192.168.1.0/24`）扫描所有在线设备
- 📡 自动填充当前 WiFi 网段
- 🔌 支持自定义端口，留空使用默认 13 个常用端口
- 🏷️ 自动解析设备主机名
- 📋 点击复制 IP 地址
- 📤 导出/分享扫描结果
- 🌙 暗色主题

## 默认扫描端口

| 端口 | 服务 |
|------|------|
| 21 | FTP |
| 22 | SSH |
| 23 | Telnet |
| 80 | HTTP |
| 443 | HTTPS |
| 445 | SMB (Windows 共享) |
| 1883 | MQTT (IoT) |
| 3389 | RDP (远程桌面) |
| 5000 | UPnP |
| 5555 | ADB (Android 调试) |
| 8080 | HTTP 备用 |
| 8443 | HTTPS 备用 |
| 9100 | 打印机 |

## 编译方法

### 方法一：GitHub Actions（推荐）

1. Fork 本仓库到你的 GitHub 账号
2. 进入 Actions 页面，启用 Workflows
3. Push 代码或手动触发 `workflow_dispatch`
4. 在 Actions → 构建完成后下载 Artifacts

**发布 Release：**
```bash
git tag v1.0.0
git push origin v1.0.0
```
Actions 会自动创建 Release 并上传 APK/IPA。

### 方法二：本地编译

```bash
# 安装 Flutter: https://flutter.dev/docs/get-started/install
flutter pub get

# Android
flutter build apk --release

# iOS (需要 macOS + Xcode)
flutter build ios --release --no-codesign
```

## iOS 安装说明

GitHub Actions 编译的 IPA 为**未签名版本**，有以下安装方式：

- **[AltStore](https://altstore.io/)** — 免费，需要每7天重签
- **[Sideloadly](https://sideloadly.io/)** — 免费，支持 Windows/Mac
- **企业证书** — 需要付费苹果开发者账号

## 权限说明

| 权限 | 用途 |
|------|------|
| `INTERNET` | TCP 端口扫描 |
| `ACCESS_WIFI_STATE` | 读取当前 WiFi IP |
| `CHANGE_WIFI_MULTICAST_STATE` | mDNS 设备发现 |

## 技术说明

扫描原理：对每个 IP 并发尝试 TCP 连接到指定端口。
- 连接**成功** → 端口开放，设备在线
- 连接**被拒绝(RST)** → 端口关闭，但设备在线
- **超时** → 设备可能离线

并发数：80 个协程，/24 网段约 15-30 秒完成。

## 免责声明

本工具仅供网络管理和学习用途，请勿扫描未授权的网络。
