# LockGuard

macOS 菜单栏工具，在锁屏状态下自动阻止系统休眠，确保后台任务（如 AI Agent、编译、下载等）不会因锁屏而中断。

## 使用场景

本地运行 AI Agent 时，一旦 Mac 息屏进入休眠，所有进程都会挂起。LockGuard 在检测到屏幕锁定后自动调用 `caffeinate` 阻止系统休眠，解锁后自动恢复正常，全程无需手动干预。

## 功能特性

- 锁屏时自动激活防休眠，解锁时自动恢复，无需手动操作
- 菜单栏显示盾牌图标，运行时即可确认服务状态
- 支持开机自启动（右键菜单栏图标设置）
- 纯原生 Swift 实现，资源占用极低
- 采用 `caffeinate -s -i` 策略：阻止系统休眠，但允许显示器正常息屏

## 系统要求

- macOS 12.0 及以上
- Apple Silicon (arm64)

## 安装

```bash
git clone git@github.com:zhouyandong/lock-guard.git
cd lock-guard
chmod +x install.sh
./install.sh
```

`install.sh` 会自动完成编译、签名、安装和启动。安装后菜单栏右侧会显示盾牌图标，LockGuard 即刻生效。

## 手动编译

```bash
./build.sh
open build/LockGuard.app
```

或手动拖入 `/Applications` 目录。

## 原理

LockGuard 通过 `DistributedNotificationCenter` 监听系统锁屏与解锁事件：

- 锁屏事件：`com.apple.screenIsLocked` → 启动 `caffeinate -s -i`
- 解锁事件：`com.apple.screenIsUnlocked` → 终止 caffeinate

同时以 CGSession 轮询作为备用检测机制，确保在通知丢失时也能正确响应。

## 项目结构

```
LockGuard/
├── install.sh                     # 一键安装脚本
├── build.sh                       # 单独编译脚本
├── README.md
├── LICENSE
└── LockGuard/
    ├── main.swift                 # 应用入口
    ├── AppDelegate.swift          # 应用代理
    ├── StatusBarController.swift  # 菜单栏与防休眠逻辑
    ├── Info.plist
    └── Resources/
        └── AppIcon.icns           # 应用图标
```
