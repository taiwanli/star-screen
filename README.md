# 星映（StarScreen）

[![CI](https://github.com/taiwanli/star-screen/actions/workflows/ci.yml/badge.svg)](https://github.com/taiwanli/star-screen/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-see%20LICENSE-blue)](./LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)](https://flutter.dev)

开源、**内容中立**的多源影视聚合播放框架——一套代码三端（**Windows / 安卓手机 / Android TV**），液态玻璃界面、可切换播放内核、StarRule 统一源规则。

> ⚠️ **合规基线**：星映**不内置任何影视内容源**。用户需自行接入**自有合法**内容源（如自建 CMS、公有领域、个人网盘）。本项目不提供盗版源，不做网页嗅探。

---

## 功能特性

| 模块 | 能力 |
|---|---|
| **源引擎** | TVBox 订阅兼容 · **StarRule** 三端统一规则 · CMS JSON/XML · drpy 模板 · 本地文件/文件夹导入 |
| **播放** | **三内核**：libmpv / ExoPlayer / 外部播放器（mpv·VLC）· 断点续播 · 换源保进度 |
| **UI** | 液态玻璃 + 新拟态 · Hero 片墙 · 详情沉浸头图 · 玻璃 OSD · 真全屏 |
| **直播** | TXT / M3U 频道表 · EPG 模板 |
| **其它** | 聚合搜索 · 健康度熔断 · 批量测活 · 桌面 Jar 蜘蛛桥（捆绑 JRE） |

## 截图 / 演示

| 首页 | 播放 | 源管理 |
|---|---|---|
| Hero 续播 + 横滑片单 | 玻璃胶囊 OSD | 分组 / 批量 / 测活 |

（可将截图放入 `docs/assets/` 后在此引用）

## 快速开始

### 1. 下载

| 包 | 说明 |
|---|---|
| **开箱即用（推荐）** | `星映-Windows-开箱即用-*.zip` — 解压即用，无需装 JDK |
| 三端包 | Windows + Android APK + TV APK |
| 源码 | 本仓库 |

> 预编译包见 [Releases](https://github.com/taiwanli/star-screen/releases)。

### 2. 安装

**Windows（开箱包）**

1. 解压到任意目录  
2. 双击 `star_desktop.exe`  
3. 数据目录：`%APPDATA%\StarScreen`

**Android / TV**

```bash
adb install StarScreen-mobile-0.1.0-dev.45.apk
adb install StarScreen-tv-0.1.0-dev.45.apk
```

### 3. 源码构建

**环境**：Flutter 3.x · Dart ^3.13 · Windows 需 VS2022 C++ · Android 需 SDK 34+ ·（Jar 桥）JDK 17+

```bash
git clone https://github.com/taiwanli/star-screen.git
cd star-screen
flutter pub get

# 测试
dart test packages/domain packages/plugins

# 构建
cd apps/desktop && flutter build windows --release
cd apps/mobile && flutter build apk --release
cd apps/tv     && flutter build apk --release
```

Windows 中文路径可能导致 Android AOT 失败，请在 ASCII 路径下构建。

### 4. 使用（三分钟）

1. 打开 **源管理 → 添加内容源**  
2. 粘贴订阅 URL / 选本地 `.json` / 选文件夹  
3. **检测源** → 打开 **首页 / 分类** 浏览  
4. 点海报进详情 → **立即播放**  
5. 源管理 → **播放引擎** 可切换 libmpv / Exo / 外部播放器  

**自定义规则**见 [docs/17-源写规范.md](./docs/17-源写规范.md)（StarRule）。

## 运行前提

| 项 | Windows | Android/TV |
|---|---|---|
| 系统 | Win 10/11 x64 | Android 7+（TV 同） |
| 内存 | ≥ 4 GB | ≥ 2 GB |
| 网络 | 访问你的内容源 | 同左 |
| Java | **不需要**（已捆绑迷你 JRE） | 不需要 |
| 其它 | 极老系统可能需 VC++ 运行库 | — |

## 文档

| 文档 | 内容 |
|---|---|
| [docs/17-源写规范.md](./docs/17-源写规范.md) | **StarRule 源写规范**（作者必读） |
| [docs/20-源管理引擎深度文档.md](./docs/20-源管理引擎深度文档.md) | 源引擎架构与管线 |
| [docs/21-桌面Jar蜘蛛桥.md](./docs/21-桌面Jar蜘蛛桥.md) | 桌面 Jar 蜘蛛桥 |
| [docs/22-开箱即用离线安装方案.md](./docs/22-开箱即用离线安装方案.md) | 打包与依赖 |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | 如何参与贡献 |
| [SECURITY.md](./SECURITY.md) | 安全漏洞上报 |

## 项目结构

```text
apps/desktop|mobile|tv     三端应用
packages/domain            源契约 / StarRule / 健康度
packages/plugins           选择器与适配器执行
packages/player            三播放内核
packages/storage           本地数据库
packages/ui_kit            液态玻璃设计系统
docs/                      规格与深度文档
tools/                     打包、校验、Jar 桥
```

## 测试

```bash
dart test packages/domain packages/plugins packages/storage
flutter test packages/ui_kit apps/desktop
```

## 路线图

- [x] StarRule 三端统一源规则  
- [x] 三播放内核切换  
- [x] 桌面 Jar 桥 + 开箱即用包  
- [ ] 规则市场 manifest  
- [ ] 正式安装器（Inno Setup）  

## 贡献

欢迎 Issue 与 PR。请先读 [CONTRIBUTING.md](./CONTRIBUTING.md) 与 [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)。

## 许可证

见 [LICENSE](./LICENSE)。

## 免责

本软件仅提供技术框架。使用者须确保所接入内容源的合法性与授权状态；因滥用造成的后果由使用者自行承担。
