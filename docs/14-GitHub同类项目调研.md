# GitHub 同类项目调研（FongMi/TV · TVBoxOSC · 2026-09-27）

## 样本
| 仓库 | Stars | 语言 | 启示 |
|------|-------|------|------|
| FongMi/TV | 9.5k | Java | TVBox 系旗舰：多内核播放、配置中心、jar 蜘蛛 |
| j4Uq/TVBoxOSC | 17k | Java | 社区分支，配置兼容层 |
| qist/tvbox | 11k | JS 配置 | 测试源仓库 |
| hjdhnx/dr_py | 780 | JS | drpy 蜘蛛生态 |

## FongMi/TV 关键设计
1. **PlayerEngineFactory**：EXO / MPV 双内核，按 DRM/smb/设置自动选型
2. **VodConfig**：解析 sites/parses/rules/ads/flags/doh/hosts/proxy/spider
3. **ads 字段**：播放 URL 命中即过滤（广告片）
4. **flags**：VIP 线路标识
5. **home 站点**：配置指定默认首页源
6. **ExoErrorMessageProvider**：播放错误 → 用户可读文案
7. **DLNA**：投屏服务与 OkHttpStreamClient

## 已落地到星映
- PlayUrlFilter（ads 过滤）+ applyReport 写入 globalAds
- playErrorText 播放错误文案
- ParseReport 增加 adFilters / playFlags / homeSiteKey

## 建议后续
- 默认首页源选择 UI（homeSiteKey）
- flags 白名单过滤 VIP 线路
- 播放引擎切换（v0.2 Exo→libmpv）
