# 变更日志

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。
产品里程碑对应 docs/02-功能规划.md 第 8 节（v0.1 → v1.0）。

## [0.1.0-dev.45+playerv2]

### 播放器重构（docs/19）
- 顶栏白字+黑遮罩（修复黑场标题不可见）
- 单根进度条（去双条观感）+ 缓冲条
- 真全屏 window_manager.setFullScreen（双击/F/按钮）
- 控件 3s 自动隐藏；空格/方向键/F/M 快捷键
- 次要功能收进设置面板
- StarNetworkImage：Referer/UA/加载态/失败重试，海报链路修复

## [0.1.0-dev.45] - 2026-09-28

### 本地文件解析策略
- LocalFeedPolicy：路径/file://去引号/缺扩展名/UTF-16 BOM/大小限制
- 格式识别 StarRule / TVBox；目录批量导入（上限 50）
- FeedFetcher 与三端 importFromRef 均接入

### StarRule 核对修复
- detail：数字 id 走 `{vid}` 模板；模板自带扩展名时剥离 id 尾缀，避免叠拼
- XPath 转译：绝对路径忽略 root，相对路径 root 转 CSS 前缀（不再拼出非法选择器）
- 分页：`hasMore` 三种模式生效；模板无 `{catePg}` 时单页，防死循环
- 字段 `replace`：支持 `$1` 正则替换模板；无 regex 时按字面量剥离
- CMS 线路：`$$$` 分隔（兼容误写 `###`），与 docs/04 契约一致
- 聚合搜索跳过熔断冷却中的源（三端 SearchEngine.skipKeys）
- `{cateId}`/`{vid}` URL 编码

## [0.1.0-dev.44] - 2026-09-28

### StarRule P2：四链路测活 / 自动转译 / 深链 / 三端源页
- **SourceChecker 四链路**：CheckLevel（home/search/detailPlay）+ CheckFailCode 文案
- **XPath 自动转译**：导入 TVBox 时 `csp_XPath*` 内联 ext 自动变 StarRule（保留原 key）
- **starrule://import 深链**：`?url=` / `?src=` / `?inline=`，三端 importFromRef 已识别
- **手机源页**：类型徽章、分组、批量启用/停用
- **TV 源页**：类型徽章、分组、启停开关
- 测试：domain 129 全过（新增 source_check_v2 13 项）

## [0.1.0-dev.43] - 2026-09-28

### StarRule P1：写源工具 / 转换器 / 熔断 / 源页
- **starrule_lint**（`packages/domain/bin`）：单文件/目录校验，致命/警告分级
- **DrpyToStarRule**：纯模板 drpy 全自动转译；js: 字段进 script 逃生舱
- **HealthMonitor 阶梯熔断**：连续 5 次→30min、10 次→24h；成功/recover 清空
- **SearchEngine.skipKeys**：熔断中的源不参与聚合搜索
- **源页升级**：健康度点、分组筛选、批量启用/停用/删除、失败一键恢复
- 测试：domain 116 全过（含 health_ladder / drpy_to_star_rule）

## [0.1.0-dev.42] - 2026-09-28

### StarRule 三端统一源规则（docs/17 / docs/18）
- 新 SourceKind.starRule：声明式 JSON 规则，手机/桌面/TV 同一解释器
- **StarRule 模型/解析/校验**（domain）：字段表 + 选择器链 + 占位符，致命/警告分级
- **StarRuleSource**（plugins）：html/json/cms 模式，复用 PdfhEngine，纯 Dart 免 jar
- **XpathToStarRule**：TVBox csp_XPath* ext 自动转译（convertedFrom: tvbox-xpath）
- **StarRuleImporter**：规则包/单站点 → SourceDef，接入三端 importFromRef
- 源管理类型徽章「StarRule 三端源」；jar 仍仅安卓桥
- 文档：docs/17-源写规范.md、docs/18-源管理交互改造.md
- 测试：domain 11 + plugins 5 项，全库 107+35 通过

## [0.1.0-dev.41] - 2026-09-28

### 全库核查修复
- play_record save/import 先写 work_snapshot（FK）
- 收藏 dd 确保快照存在
- lineId 读写往返完整
- 继续观看过滤已看完（扩大窗口）
- LAN JSON 非对象返回 400；默认 token 生成
- 下载 copyWith 保留 error；CrashGuard 异常重抛
- 备份 _cardOf 空 sourceKey 容错
- ui_kit import 排序、清无用方法

## [0.1.0-dev.40] - 2026-09-28

### 测试整改（docs/16）
- P04 LAN：默认拒绝 /backup，请求体上限 413
- P05 播放记录写入 lineId
- P08 清晰度无数据不展示
- P09 证书错误文案如实
- P10 直播 tune_no 按导入序填充
- P13 进度时间戳节流
- P22 清理垃圾文件；P23 备份注释如实；P17 主题变更记录


## [0.1.0-dev.38] - 2026-09-27

### 全站 UI 换肤（液态玻璃 + 新拟态浅色）
- StarColors 全局切浅色玻璃；三端即刻统一。
- 桌面顶栏/侧栏玻璃、导航新拟态胶囊、海报卡浅色渐变+阴影、OSD 玻璃。

## [0.1.0-dev.37] - 2026-09-27

### UI 风格重构（液态玻璃 + 新拟态 · 浅色）
- 新 liquid_neu.dart：玻璃面板 / 新拟态阴影 / NeuButton / 浅色主题。
- 桌面默认 **浅色液态玻璃**；报告 docs/15。

## [0.1.0-dev.36] - 2026-09-27

### 收尾
- 播放失败文案：内核级错误提示「可切换播放引擎」。
- DLNA 控制条：投屏后暂停 / 继续 / +60s / +10min / 停止投屏。
- 三端安装包已重打。

## [0.1.0-dev.35] - 2026-09-27

### 四项补齐（对照 FongMi/TV）
- **默认首页源**：homeSourceKey + 源管理「默认首页源」选择；首页优先该源。
- **flags 线路过滤**：TVBox lags → PlayUrlFilter.globalFlags，resolve 剔除非白名单线路。
- **播放引擎切换**：源管理「播放引擎」libmpv ↔ ExoPlayer（Android v0.2 预留）。
- **DLNA 完整投屏**：Play/Stop/Pause/Resume/Seek + 推送当前真实媒体 URL（非直链不投）。

## [0.1.0-dev.34] - 2026-09-27

### GitHub 同类项目调研落地（FongMi/TV）
- **ads 广告过滤**：TVBox ds 字段 → PlayUrlFilter，播放前剔除广告 URL。
- **flags / home**：配置字段解析入 ParseReport（首页源/线路 flag）。
- **播放错误文案**：playErrorText 对照 ExoErrorMessageProvider（403/404/超时/证书…）。
- 调研笔记：docs/14-GitHub同类项目调研.md

## [0.1.0-dev.32] - 2026-09-27

### jar 蜘蛛源兼容
- 新 SourceKind.spiderJar：csp_* 蜘蛛归入可执行（非 xpath/appys/CMS 形态）。
- **JarSpiderSource**：home/category/search/detail/player 对齐 TVBox Spider JSON。
- **Android/TV 执行桥**：JarSpiderPlugin（DexClassLoader + md5 校验 + 反射调用）。
- 桌面暂无 JVM 桥，spiderJar 在 Windows 标为不可浏览；手机/TV 可加载用户 jar。

## [0.1.0-dev.31] - 2026-09-27

### 源检测体验
- **检测进度列表**：每源完成即写入右侧日志（成功/失败/原因/延迟）。
- **单源重测**：列表行「刷新」图标，即时更新结果。

## [0.1.0-dev.30] - 2026-09-27

### 源管理：有效性检测（模仿阅读 APP）
- **SourceChecker**：并发探活（首页失败再试搜索），记录通过/失败原因/延迟。
- **筛选**：全部 / 启用 / 失效 / 停用（FilterChip 计数）。
- **检测源**：进度显示；失效源列表标红。
- **删除失效源**：确认后一键清理。

## [0.1.0-dev.28] - 2026-09-26

### 源管理引擎升级
- **TtlCache**：CMS JSON 响应内存缓存（3 分钟 TTL）。
- **健康度**：rank / isDegraded / 状态 export-import（KV 落盘重启保留）。
- **聚合搜索**：mergeWorks 按 healthScore 排序多源结果。
- 三端探活后持久化健康度；启动恢复失败不影响应用拉起。
- 测试：sqlite 预加载 + 启动链路保护（防无原生库闪退）。

## [0.1.0-dev.27] - 2026-09-26

### 修复（源导入不可用）
- FeedFetcher 支持：粘贴 JSON 原文、ile:// URI、路径去引号。
- 浏览/分类优先选 **有适配器** 的源（cms_json/xml/drpy），避免首个 xpath 等源导致首页报错。
- 导入向导文案与多行输入；粘贴 JSON 路径测试覆盖。

## [0.1.0-dev.26] - 2026-09-26

### 修复（三端启动闪退）
- **根因**：main() 里 PaintingBinding.instance.imageCache 在 Flutter 绑定初始化前调用，
  checkInstance 抛 null check，进程直接退出。
- 三端先 WidgetsFlutterBinding.ensureInitialized() 再改图片缓存；已重打 Windows / Android / TV 包。

## [0.1.0-dev.25] - 2026-09-26

### 性能优化
- **图片**：海报/封面 cacheWidth 解码上限（400/480/640）+ FilterQuality.medium；
  三端 imageCache.maximumSizeBytes（桌面 48MB / 移动 32MB）。
- **UI 重建**：聚合搜索结果 setState 80ms 合并节流；分类列表去掉无效 cacheExtent。
- **既有**：下载进度节流、Future 缓存、快照 upsert 减写、SearchEngine 单订阅流。

## [0.1.0-dev.24] - 2026-09-26

### 新增（v1.0 发布链路）
- **崩溃日志**：CrashGuard（Zone 异常 + 超 3s 性能标签落盘），三端接入。
- **打包脚本**：	ools/package-windows.ps1 / package-android.ps1。
- **docs/12-发布打包指南.md**：环境、产物路径、version.json 更新清单、合规复查。

## [0.1.0-dev.23] - 2026-09-26

### 新增（v1.0 首批）
- **迷你播放窗**：桌面播放页「小窗」紧凑浮层（播放/展开/关闭）——系统 PiP 壳接入前的替身。
- **DLNA 投屏骨架**：SSDP 发现 MediaRenderer + SetAVTransportURI/Play SOAP（DlnaCastClient）；播放页「投屏」入口。
- **检查更新**：UpdateChecker（version.json 点号比较）+ 源管理「检查更新」。

## [0.1.0-dev.22] - 2026-09-26

### 新增
- **EPG 节目单**：EpgLoader（模板 {name}/{date}）+ EpgPanel；TV 直播播放页节目单按钮，当前节目高亮。
- **外挂字幕自动匹配**：本地视频同目录 .srt/.ass/.ssa/.vtt 自动加载。

## [0.1.0-dev.21] - 2026-09-26

### 修复 / 完善（P2 收尾）
- 备份：settings KV 全量导出/导入（`all`/`putAll`）。
- 下载：`Range` 断点续传；失败保留半截文件；取消清理；进度写库节流。
- LAN：可选共享口令（`X-Star-Token`），请求体上限；`start` 防重入。
- PlayButton（三端）：接线连播 10s 倒计时与下一集。

## [0.1.0-dev.20] - 2026-09-26

### 修复（全库核查）
- **LAN 信标端口**：广播的是发现端口而非 HTTP 端口，对端永远 ping 不通 —— 改为广告 `httpPort`。
- **LAN 生命周期**：discovery 可 stop 后重启；服务绑定失败回滚；HTTP 客户端 finally 关闭；`_json` await close。
- **workKey**：`sourceKey::workId` 拆分用最长前缀匹配；`Favorite._cardFrom` / 库打开不再双拼 workId。
- **快照 upsert**：空字段 `Value.absent()`，不再抹掉已有海报/备注；`save()` 不再清 lineId。
- **备份保真**：导出/导入完整 SourceDef 字段 + 收藏 folderId + 播放记录标题/海报。
- **删除收藏夹**：先清空 folderId 再删，避免 FK 失败。
- **下载**：Store 串行化防丢更新、唯一 ID、失败清理半截文件、`drainQueue`/入队即下。
- **FutureBuilder**：首页/详情缓存 future，避免 rebuild 重复拉取。
- **SearchEngine**：改单订阅 Stream，避免 broadcast 丢事件。
- **连播**：等旧播放页 dispose 后再起下一集。
- **deviceId**：改用主机名，重启后仍可被发现。
- **UI**：ListTile 包 Material（widget 测试）、主题抽离 `theme_notifier.dart`、多处 mounted 守卫。

## [0.1.0-dev.19] - 2026-09-26

### 新增（v0.9 互联）
- **packages/lan**：UDP 信标发现（`LanDiscovery`）+ HTTP 服务/客户端
  （`/ping` `/play` `/backup`）——手机/桌面/TV 同网段互推片、互同步备份，无云。
- **LanBridge**：发现 + 本机服务 + 推片/拉推备份 + 下载一体装配，三端 `AppServices` 注入。
- **下载管理**：`DownloadStore` + `DownloadService`（HttpClient 落盘/进度/失败态），
  「局域网互联 / 下载」页可管理任务。
- 三端互联 UI（`LanPanel` / `DownloadList`）：桌面「我的」与手机「我的」入口。

### 说明
- 投屏 DLNA 协议栈移至 v1.0（当前以局域网推片覆盖手机→TV 场景）。
- 系统级画中画（PiP）依赖各端 shell 能力，v0.9 提供下载与推片主链路。

## [0.1.0-dev.18] - 2026-09-26

### 新增（v0.1/v0.3 产品面补齐）
- **收藏**：`DriftFavoriteStore`（夹/项 + 作品快照）+ 详情收藏开关 + 「我的」收藏列表。
- **观看历史**：`historyDetailed` / 删除 / 清空；三端「收藏与历史」入口。
- **导出导入**：`DriftBackupCodec`（源/记录/收藏 JSON 往返）+ 桌面/手机入口。
- **分类浏览**：三端 CategoryPage（源切换 + 分页）。
- **搜索历史**：KV 落库 + 桌面历史 chip。
- **播放增强**：倍速 0.5–4x、音轨切换、跳过片头/片尾（`PlayerExtrasBar`）。
- **主题**：亮/暗切换（`starThemeData(brightness:)` + 桌面 ThemeNotifier）。
- **源组启停**：源管理按 groupId 批量开关；**清理缓存**入口。

### 修复
- 备份导入：play_record 外键先写 work_snapshot（workKey 拆分正确）。

## [0.1.0-dev.17] - 2026-09-26

### 新增（M3-2 键位 / 连播）
- 连播：三端播放页播完弹 **10s 倒计时**（`NextEpisodeBanner`，可取消/立即播放），
  详情页按选集自动接下一集。
- TV 直播：**数字键换台**（1–4 位频道号缓冲 + 上下键/频道键切台），
  `ChannelNumberOverlay` 浮层显示输入。
- TV 播放：**返回键两级语义**（先收 OSD/倒计时，再退出）；OK 唤起 OSD。

### 新增（M3-6 导入向导）
- `ImportWizardDialog`（三端共用）：输入 → 进度 → **完整导入报告**
  （支持/不支持逐条原因、失效子仓、解析 issues）。
- 桌面源管理 / 手机我的 / TV 设置 接入向导。

## [0.1.0-dev.16] - 2026-09-26

### 新增（M3-3 字幕面板）
- packages/player：`SubtitleStyle`（字号/底板透明度/延迟；TV 默认 32px）、
  外挂字幕 `loadExternalSubtitle`（srt/ass/vtt，本地路径或 URL → file:// 归一）、
  轨道列表合并内封+外挂。
- packages/ui_kit：`StarSubtitleOverlay`（延迟缓冲渲染层）、
  `SubtitlePanel`（轨道选择 + 外挂加载 + 样式滑条）。
- 三端播放页接线：关闭 media_kit 自带字幕层，改用可延迟/可调样式的
  `StarSubtitleOverlay`；桌面对话框 / 手机底部面板 / TV 对话框打开面板。
  TV 默认字幕 ≥32px + 背景板（docs/07 §4.4）。

### 新增（M3-1 TV 焦点引擎）
- apps/tv：`GeometricTvFocusPolicy`（F2 几何最近邻 + 行列锚定，同排优先）、
  `TvFocusMemory`/`TvFocusScope`（F3 按 pageKey 记忆、F4 焦点丢失即恢复）、
  `TvFocusBox`（F5 三重信号）。
- TV 壳/详情页接入 `TvFocusScope`；导航芯片与轨道卡片带 `focusId`。
- 5 测试覆盖评分/记忆/作用域。

## [0.1.0-dev.15] - 2026-09-26

### 新增（QuickJS 三端接线）
- apps/mobile·tv：`FlutterJsRuntime`（flutter_js/QuickJS）与桌面同构接入；
  `sourceFor` 为 drpy 源注入 `jsFactory`，`js:` 内联源三端均可执行。
- drpy 源实例缓存 `_drpyCache`（导入订阅时失效重建），与桌面一致。

## [0.1.0-dev.14] - 2026-09-26

### 修复（drpy 二级/播放深解析收口）
- `DrpyRule.double` 判定写反：字段缺失被当成 double 模式，导致全部模板源
  `detail` 被拒。改为缺省关闭、仅显式 `1/true` 开启。
- `PdfhEngine.pdfh` 整条规则仅为取值后缀（`Text`/`html`/属性名）时误当作
  选择器 —— tabs 线路名因此取空。改为对当前元素自身取值。
- `DrpyTemplateSource`：不再因 `lazy` 等旁路字段的 `js:` 绑死整个源 ——
  仅在真正执行 js: 字段时创建宿主；`resolve` 在未接入 QuickJS 时对直链
  直通（needsParse=false），非直链才要求沙箱。
- `DrpyHost.install` 将 `rule.headers` 合并进请求头基准（与 oheaders 一致）。
- nullable Map 的 `forEach` / 测试未转型等分析错误清零。

### 测试
- packages/plugins：deep_parse / host / template 全量 26 用例通过。
- apps/desktop widget 测试预加载仓库内 sqlite3.dll（flutter test 无 native assets）。

## [0.1.0-dev.11] - 2026-09-26

### 新增（M3-4 模板执行器——零 JS 引擎路径）
- packages/plugins：**PdfhEngine**（drpy pdfh/pdfa 规则求值器：`&&` 层级下钻、
  Text/html/属性取值，基于 package:html 的 CSS 选择器子集）。
- packages/plugins：**DrpyTemplateSource**（纯模板 drpy 源的原生执行器：
  home/category/search 完整实现——host/url 的 fyclass/fypage 占位、一级/搜索
  选择器归一卡片；js: 内联源运行期抛出明确提示，等待 QuickJS）。
- apps/desktop：`sourceFor` 接入 DrpyTemplateSource——纯模板 drpy 源
  （浏览/搜索）即刻可用，无沙箱依赖。

### 说明
- QuickJS 运行时绑定（js: 内联代码源）仍需 Windows 真机 spike，单列后续；
  本路径先行覆盖 drpy 生态中的纯模板源。

## [0.1.0-dev.13] - 2026-09-26

### 新增
- **QuickJS spike 完成**：flutter_js 0.8.7 接入桌面端；冒烟测试（求值 + 跨语言
  JSON 交换）常驻仓库并以 skip 保护——原生库在 flutter test 环境不可加载，
  真机运行时生效。js: 内联 drpy 源的运行时绑定以此为基座随真机验证推进。
- packages/player：**字幕轨能力**——`MediaKitPlayerController` 新增
  `subtitleTracks()/currentSubtitleTrack()/selectSubtitleTrack()`（内封轨道
  枚举与切换，media_kit SubtitleTrack 映射）+ `PlayerSubtitleTrack` 描述类。
- apps/desktop：播放页新增**字幕菜单**（关闭字幕 / 轨道列表 / 选中勾选）。

### 变更
- packages/player：media_kit 的 SubtitleTrack 与 domain 模型同名冲突——
  导入侧 hide 消解。

## [0.1.0-dev.12] - 2026-09-26

### 新增（drpy 三端接线 + 直播页三端一致）
- apps/mobile·tv：`sourceFor` 接入 `DrpyTemplateSource`（drpy 纯模板源三端可浏览/搜索）；
  AppServices 增加 `liveStore`。
- apps/mobile：直播页（分组 ChoiceChip + 频道列表 + 横屏直播播放 + 直播角标）。
- apps/tv：直播页（分组焦点行 + 频道焦点网格 + 全屏直播播放 + 返回）。
- packages/plugins：detail/resolve 闭环测试（直链过滤 + 选集归一 + 相对地址补全）。

### 修复
- `DrpyTemplateSource.detail` 改用 documentElement 直取（pdfa 的 `html` 选择器
  不匹配根元素自身导致播放列表为空）。

## [0.1.0-dev.10] - 2026-09-26

### 新增（M3-4 地基 + M3-5 EPG）
- packages/plugins：**drpy 规则解析器**（`DrpyRuleParser`：JS 对象字面量容错解析——
  裸键/单引号/尾逗号/`//` 注释（字符串内 `https://` 不误伤）/字符串配平花括号；
  `isTemplateOnly` 区分纯模板源与 `js:` 内联代码源）。纯模板源可由原生模板执行器
  直接运行，无需 JS 引擎——M3-4 的第一块地基。5 测试。
- packages/domain：**EPG XMLTV 客户端**（`EpgClient.parse`：programme 解析、
  频道/日期过滤、`+0800` 时区偏移换算、`playingAt` 播出判断）。4 测试。

## [0.1.0-dev.9] - 2026-09-26

### 新增（M3-5 直播链路收尾）
- packages/storage：`DriftLiveChannelStore`（live_channel 表全量替换 + 分组聚合查询，
  外键级联验证）。
- apps/desktop：`AppServices.importFromRef` 订阅中的 `lives[]` 自动拉取 →
  `LiveParser` 解析 → 频道落库（直播源失效不阻断点播导入）；新增**直播页**
  （分组侧栏 + 频道列表 + libmpv 直播播放，红色"直播"角标——全站唯一红色角标场景，
  规范 6.1）。

## [0.1.0-dev.8] - 2026-09-26

### 新增（M2 UI 收尾 + M3-5 数据层）
- packages/domain：**直播解析器 `LiveParser`**（TXT `#genre#`、M3U（tvg 属性 +
  x-tvg-url EPG 捕获）、JSON 直播表三格式；同名多址 `#` 轮换展开；5 测试，
  docs/11 直播样本全部实测通过）。
- apps/mobile：搜索页升级为**聚合搜索**（渐进渲染 + 多源角标 + 失败源提示）。
- apps/tv：新增搜索页（软键盘输入 + 结果焦点网格 + 多源角标），导航接线。
- 三端 `AppServices`：`buildVideoSources` + **周期 L2 探活调度**（每 2 小时，
  测试环境跳过）。

## [0.1.0-dev.7] - 2026-09-26

### 新增（M2 多源聚合核心）
- packages/domain：**聚合搜索引擎**（`SearchEngine`：信号量并发限流、单源超时、
  失败跳过不阻塞、渐进 `Stream<SearchUpdate>`、`mergeWorks` 同片归并去重——
  标题去空白+年份为指纹，多源组置前）。
- packages/domain：**源健康度探活 v1**（`HealthMonitor`：L2 首页探活、近 20 次滑动
  窗口成功率、0.5×成功率+0.3×延迟+0.2×新鲜度评分、批量并发探活）。
- packages/domain：**跨源换源**（`DetailService.findAltSources`：同片指纹匹配，
  年份一致优先、排除原源）。
- packages/domain：`SourceDef.groupId` 源分组 + `Semaphore` 并发原语。
- apps/desktop：聚合搜索页（渐进渲染 + 多源卡角标 + 失败源提示条）、
  源管理一键测活（延迟/等级显示）、详情页换源入口（M2-2）。

### 变更
- 多仓导入自动展开一层（≤8 子仓）并按仓库名归组；`SourceDef.groupId` 落库
  （schema group_id 调整为 TEXT，drift 代码已重新生成）。

## [0.1.0-dev.6] - 2026-09-26

### 新增
- 源兼容性压测闭环：63 个主样本（单仓26/多仓4/直播13/CMS-JSON16/CMS-XML5/JS与其他4，
  见 tools/source_samples.json）+ 存活配置内嵌 CMS 端点抽取 43 个，**共实测 106 条**；
  探测器 `tools/source_probe.dart`（真实引擎全链路：三级回退获取 → 解析 → 分类 →
  多仓递归 → CMS 二段探测 ac=list/detail/play_url 校验，并发池 + 每条 60s 看门狗）。
- docs/11-源样本库与实测报告（清单/状态/打磨记录/兼容性结论）。

### 修复（全部来自压测反馈）
- UTF-16LE/BE 编码配置识别（`ConfigCleaner.decodeBytes`，实测 c120487 wh0 多仓）。
- 三级 JSON 容错新增「字符串内未转义控制字符」修复层（实测 qist·XYQ）。
- 多仓 `{"urls":[…]}` 变体支持（实测 gao·0707 / c00·wh0515）。
- `IoHttpFetch` 新增代理与 `trustSelfSigned`（自签/过期证书）选项；
  HandshakeException 专用提示。
- 解析失败消息带来源 URL 与处置建议（无效源提示上下文化）。
- 响应体读取纳入超时（防慢滴漏服务器挂死）+ 探测器每条 60s 硬看门狗。

### 效果
- 106 条实测：✅ 67→81 / ⚠️ 13→10 / ❌ 26→15；剩余失败均为源自身失效或
  明确标记的不支持形状（原因已向用户提示）。CMS 端点端到端验证 28 条线路。

## [0.1.0-dev.5] - 2026-09-26

### 新增
- **M1-7 三端页面接线完成**：
  - apps/mobile：AppServices（path_provider 数据库）、首页（继续观看真实轨道 + 源推荐流）、
    单源搜索页、我的源管理（导入/启停/删除）、详情吸底主操作、横屏播放页（退出落盘）。
  - apps/tv：AppServices、首页真实轨道（继续观看 + 推荐，焦点三重信号 + 真实海报 + 聚焦展开
    副信息）、详情 35/65（选集焦点二维移动 + 续播主按钮）、OSD 播放页（进度条默认焦点 +
    剩余时间显示）、设置页源管理。
  - packages/storage：`continueWatchingDetailed()`（播放记录 × 作品快照联合查询，
    `ContinueItem` 含「第 N 集 · 剩余 M 分钟」锁死副信息）。
  - 共享焦点组件 `TvFocusChip`/`TvFocusCard`（apps/tv/src/widgets/）。
- docs/10-v0.1-验收走查清单（自动化门禁 + 三端真机走查 + 跨端链路 + 合规红线复核）。

## [0.1.0-dev.4] - 2026-09-26

### 新增
- packages/player：`MediaKitPlayerController` 下沉为三端共享实现（libmpv 内核），
  `asDomain()` 桥接领域契约（依赖方向：player → domain 合法）。
- packages/storage：`DriftPlayRecordStore`（播放记录落库 + 继续观看轨道查询 +
  作品快照 upsert + 导出 JSON）。
- apps/desktop：**M1-7 桌面端真闭环**——`AppServices` 装配（drift 文件库
  `%APPDATA%/StarScreen/star.db`，测试用内存库）、源管理真实化（订阅导入/启停/删除/
  导入报告）、首页真实推荐流（真实海报图 + 兜底回退）、详情选集页、libmpv 播放路由
  （进度条/时间/失败提示，退出自动落盘、重启续播）。
- packages/ui_kit：`StarPoster` 支持真实海报 `imageUrl`（加载失败自动回退缺失图兜底）。

### 变更
- **M1-5 方案调整**：v0.1 三端统一 libmpv 内核（media_kit），ExoPlayer 平台通道移至
  v0.2 —— 回退链架构保留（届时 exo 默认 → libmpv 兜底）。理由：三端一致最快闭环、
  零平台通道；Android 原生库依赖（media_kit_libs_android_video）已接入手机/TV 壳。
- 播放记录外键：落库前先 upsert 作品快照（play_record → work_snapshot 外键要求）。

## [0.1.0-dev.3] - 2026-09-26

### 新增
- packages/domain：**M1-3 cms_xml 适配器**（`CmsXmlSource`：rss 5.1 解析、class 分类树、
  V8/MaxCMS 遗留 `from` 属性与 `|` 分集兼容；复用 $$$ 播放地址解析器）。
- packages/domain：**M1-6 播放会话**（`PlaybackSession` + `DomainPlayerController` 领域契约：
  自动续播（同集未看完 → 上次位置）、5 秒节流落库、<5% 不记录 / ≥90% 标记看完、
  needsParse 拦截、failures 流供 UI 提示换线路/换源）。
- apps/desktop：**M1-4 Windows 播放器实现**（`MediaKitPlayerController`，media_kit 1.2.6 /
  libmpv 内核：load/play/pause/seek/dispose + 位置/缓冲/完成/失败事件桥接）。

### 说明
- 领域层新增 `DomainPlayerController` 以维持依赖方向（domain 不依赖 packages/player），
  宿主组装时做一次性桥接；`CmsXmlSource` 搜索/详情走 `ac=videolist&at=xml` 全量端点。

## [0.1.0-dev.2] - 2026-09-26

### 新增
- packages/domain：**M0-4 源注册表**（`SourceRegistry`/`SourceDefStore`，解析器固化合并策略——
  重复导入不覆盖已注册源、启停状态保留）。
- packages/domain：**M0-5 订阅获取器**（`FeedFetcher`/`IoHttpFetch`：ETag/304 协商、统一 UA、
  本地文件通道、超时与脏字节容错解码）。
- packages/domain：**M1-1/M1-2 cms_json 适配器**（`CmsJsonSource`：home/category/search/detail/
  resolve 全契约实现；AppYsV2 `data.list` 变体；`$$$`/`#`/`$` 播放地址解析；LineNames 线路名
  对照；需解析地址 needsParse 合规过滤标记）。
- packages/storage：**M0-3 drift 接入**（9 表定义与 schema.sql 一一对应、`DriftSourceDefStore`/
  `DriftKeyValueStore`、外键级联、内存库测试；无 sqlite3 原生库环境自动跳过）。

### 变更
- CI 迁移至 ubuntu-latest（drift 运行时测试需要 sqlite3 原生库），并新增 storage 测试步骤。
- 开发指南新增 subst ASCII 盘符方案（build_runner 无法写入中文路径）。

## [0.1.0-dev.1] - 2026-09-26

### 新增
- 工程 monorepo 骨架（pub workspace）：apps/desktop、apps/mobile、apps/tv 三端壳工程与
  packages/domain、ui_kit、player、plugins、storage 五个共享包。
- packages/domain：统一源契约（VideoSource）、领域模型（源/作品/播放/记录/直播/健康度）、
  **M0 订阅配置解析管线**（清洗 → JSON 解析 → 站点分类 → 相对路径解析 → 注册模型），
  含单元测试与脱敏测试样例（fixtures）。
- packages/ui_kit：三层设计令牌（`design-tokens.json` + `tokens.*.css`）与 Dart 侧
  `StarTheme`/`StarTokens`（桌面/手机/TV 三档尺寸），StarPoster 兜底卡组件。
- packages/player：PlayerController 抽象、内核枚举（EXO/IJK/系统/libmpv）与失败回退链定义。
- packages/plugins：JS 沙箱限额常量与 drpy 函数契约接口（实现见里程碑 M3）。
- packages/storage：本地库 schema.sql（订阅/源/作品快照/播放记录/收藏/直播/设置/健康记录）。
- CI 工作流（analyze + test）、架构守护脚本（领域层禁 UI 依赖）。
- 开发文档：docs/08-开发实施指南、docs/09-v0.1-开发任务拆解。
