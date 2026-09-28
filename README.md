# 星映（StarScreen）

开源、内容中立的多源影视聚合播放框架——一套代码三端（Windows 桌面 / 安卓手机 / Android TV），界面风格统一、操作各按其分。

> ⚠️ 合规基线：星映本身不内置任何影视内容源，用户需自行接入自有合法内容源。

## 📚 设计文档（当前阶段产出）

| 阶段 | 文档 | 内容 |
|---|---|---|
| 一、调研 | [docs/01-调研总结.md](./docs/01-调研总结.md) | TVBox / 影视仓 / 影迷 / 喵影视 / 可视TV 五款产品的功能、界面、交互调研；共性特点与优缺点；十条设计原则（P1–P10） |
| 二、规划 | [docs/02-功能规划.md](./docs/02-功能规划.md) | 产品定位与合规基线、P0/P1/P2 功能清单、三端功能矩阵、三端操作习惯适配、非功能需求、v0.1→v1.0 路线图 |
| 三、设计 | [docs/03-整体设计方案.md](./docs/03-整体设计方案.md) | 技术选型（Flutter + Exo/IJK/libmpv）、四层架构、模块职责与关系图、关键时序（聚合搜索/起播恢复）、源接入契约、数据模型、UI 设计规范、工程结构、风险对策 |
| 四、源专项调研 | [docs/04-订阅源规范深度调研.md](./docs/04-订阅源规范深度调研.md) | TVBox 单仓/多仓配置字段级规范（源码级验证）、蜘蛛子生态（csp jar/drpy/XPath/AppYs/AList/海阔）、苹果CMS API 规范（源码+实测）、直播/EPG 格式、LibreTV/MoonTV 订阅格式 |
| 五、源引擎开发报告 | [docs/05-源管理引擎开发报告.md](./docs/05-源管理引擎开发报告.md) | 兼容总矩阵（原生/转译/沙箱/服务器桥/不支持）、源引擎架构与解析管线、适配器规格、健康度引擎、jar 不加载决策记录、里程碑与工作量 |
| 六、测试资产 | [docs/06-测试源清单.md](./docs/06-测试源清单.md) | 2026-09-26 实测快照：34 接口测活（约七成失效）、苹果CMS 字段级验证、直播/EPG 验证、fixture 清单与开发测试组合 |
| 七、UI 设计 | [docs/07-三端UI界面设计.md](./docs/07-三端UI界面设计.md) · 视觉稿 [design/ui/index.html](./design/ui/index.html) | 依据《三端统一设计规范》v1.1 完成的三端高保真界面（桌面 7 屏 / 手机 6 屏+五态 / TV 7 屏）：设计决策、令牌映射、逐屏规格、规范符合性对照 |
| 八、开发指南 | [docs/08-开发实施指南.md](./docs/08-开发实施指南.md) | 环境搭建、workspace 结构、日常命令、令牌规则、分支/提交规范、质量门禁（含本机中文路径注意事项） |
| 九、任务队列 | [docs/09-v0.1-开发任务拆解.md](./docs/09-v0.1-开发任务拆解.md) | v0.1→v1.0 执行队列（M0–M5，含验收标准与当前状态总览） |
| 十、验收 | [docs/10-v0.1-验收走查清单.md](./docs/10-v0.1-验收走查清单.md) | v0.1 真机验收：自动化门禁 + 三端人工走查 + 跨端链路 + 合规红线复核 |
| 十一、源样本库 | [docs/11-源样本库与实测报告.md](./docs/11-源样本库与实测报告.md) | 63 主样本 + 内嵌端点共 106 条实测（✅81/⚠️10/❌15）：清单、状态、引擎打磨记录、兼容性结论 |

## 🧱 工程现状（2026-09-26）

pub workspace monorepo 已建立并可验证：`dart analyze` 零问题、单元测试 31+ 全绿、三端壳可运行。

```bash
# 依赖解析（网络受限先设代理 127.0.0.1:7890）
flutter pub get
# 质量门禁
dart analyze
dart test packages/domain && dart test packages/player
flutter test apps/desktop & flutter test apps/mobile & flutter test apps/tv
dart run tools/check_architecture.dart
```

| 包 | 内容 | 状态 |
|---|---|---|
| packages/domain | 统一源契约、领域模型、**M0 订阅解析管线 + 源注册表 + 订阅获取器（ETag/UA）**、**M1 cms_json/cms_xml 双适配器 + 播放地址解析 + PlaybackSession（续播/节流落库）**、**M2 聚合搜索/健康度探活/跨源换源 + 直播解析器** | ✅ `dart test` 全绿 |
| packages/ui_kit | 设计令牌（design-tokens.json + tokens.*.css + StarTheme/StarTokens/StarPoster） | ✅ |
| packages/player | PlayerController 抽象、内核枚举、失败回退链、**MediaKitPlayerController（libmpv 三端共享）** | ✅ 4 测试 |
| packages/plugins | **drpy 规则解析器**、JS 沙箱限额、drpy 契约接口、导入器接口 | ✅ 5 测试（沙箱运行时随 M3-4） |
| packages/storage | **drift 9 表接入**（与 schema.sql 一致）+ 源注册表/播放记录/KV 落地 + 备份抽象 | ✅ 5 测试 |
| apps/desktop | **真闭环可运行**：源管理（订阅导入/启停）→ 首页真实推荐 → 详情选集 → libmpv 播放 → 续播落库 | ✅ widget 测试 |
| apps/mobile | **真闭环可运行**：继续观看轨道 → 源推荐流 → 单源搜索 → 详情吸底播放 → 横屏播放页 → 我的源管理 | ✅ widget 测试 |
| apps/tv | **真闭环可运行**：真实轨道（焦点三重信号）→ 详情 35/65 → OSD 播放（进度默认焦点+剩余时间）→ 设置源管理 | ✅ widget 测试 |

## 🚦 当前状态

- [x] 竞品调研总结
- [x] 功能规划
- [x] 整体设计方案
- [x] 订阅源规范深度调研 + 源管理引擎开发报告 + 测试源清单
- [x] 三端 UI 界面设计（视觉稿 + 设计说明书）
- [x] 正式开发基础设施（monorepo / 令牌 / M0 解析管线 / 测试与 CI）
- [ ] 开发实现：按 [docs/09](./docs/09-v0.1-开发任务拆解.md) 队列推进（下一批 M0-3 drift → M1 cms_json 适配器 → v0.1 三端闭环）
