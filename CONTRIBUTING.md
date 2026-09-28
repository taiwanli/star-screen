# 贡献指南 · Contributing

感谢你对 **星映 StarScreen** 的关注。本项目为开源、内容中立的三端影视聚合播放框架。

## 行为准则

参与讨论与贡献前请阅读 [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)。

## 开发环境

| 依赖 | 版本建议 |
|---|---|
| Flutter | 3.x（含 Windows desktop / Android） |
| Dart | SDK ^3.13 |
| JDK | 17+（仅构建 Jar 桥 / Android 时） |
| Visual Studio | 2022 + C++ 桌面开发（Windows 构建） |
| Android SDK | API 34+ |

```bash
git clone https://github.com/taiwanli/star-screen.git
cd star-screen
flutter pub get

# 质量门禁（提交前必须全绿）
dart analyze
dart test packages/domain packages/plugins packages/storage packages/player packages/lan
flutter test packages/ui_kit
flutter test apps/desktop
```

> **Windows 中文路径**：Android AOT 可能失败，请在纯 ASCII 路径（如 `C:\Build\star-screen`）下执行 `flutter build`。

## 目录结构

```text
apps/desktop|mobile|tv   # 三端壳
packages/domain         # 源契约、解析、StarRule、健康度
packages/plugins        # Pdfh / drpy / StarRuleSource
packages/player         # libmpv / Exo / 外部播放器
packages/storage        # drift 持久化
packages/ui_kit         # 液态玻璃组件
docs/                   # 设计与规范文档
tools/                  # 打包、lint、Jar 桥
```

## 分支与提交

- 主分支：`master`（受保护，禁止直推）
- 功能分支：`feat/<简述>` · 修复：`fix/<简述>` · 文档：`docs/<简述>`
- 提交信息：祈使句 + 范围，例如 `feat(player): 增加 Exo 内核切换`
- 遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 更新 `CHANGELOG.md`

## Pull Request

1. Fork 后从 `master` 拉分支
2. 保持单一主题；附「改了什么 / 为什么 / 怎么验证」
3. CI 必须通过；涉及 UI 请附截图
4. 破坏性变更请在 PR 标题标注 `BREAKING:`

使用 PR 模板：[.github/PULL_REQUEST_TEMPLATE.md](./.github/PULL_REQUEST_TEMPLATE.md)

## 提 Issue

- Bug / 功能建议请用 Issue 模板
- **安全漏洞不要公开提 Issue**，见 [SECURITY.md](./SECURITY.md)

## 架构红线

1. `star_domain` **禁止**依赖 Flutter / UI
2. 不内置任何影视内容源
3. 不做网页嗅探；`needsParse` 默认过滤
4. 设计令牌以 `packages/ui_kit/tokens` 为准

## 文档

编写规则、源引擎说明见 `docs/`（尤其 `17-源写规范.md`、`20-源管理引擎深度文档.md`）。

## 许可

贡献即表示同意以本仓库 [LICENSE](./LICENSE) 许可你的改动。
