# 安全政策 · Security Policy

## 支持版本

| 版本 | 安全更新 |
|---|---|
| `0.1.x`（master） | ✅ |
| 更早提交 | 尽力而为 |

## 上报漏洞

**请勿在公开 Issue 中报告安全漏洞。**

请通过以下任一方式私下联系维护者：

1. **GitHub Security Advisories**（推荐）  
   仓库页 → Security → Report a vulnerability  
   （`https://github.com/taiwanli/star-screen/security/advisories/new`）
2. 在 GitHub 向维护者 **私信 / 私有讨论**
3. 若上述不可用：在公开 Issue 中仅留言「有安全问题需私下沟通」，维护者会联系你

请尽量包含：

- 受影响组件（如播放内核 / 导入器 / 局域网 / 备份）
- 复现步骤与环境（OS、版本）
- 影响评估（如任意文件读取、远程代码执行等）
- 建议修复（如有）

我们力争 **72 小时内** 回复确认，修复后会公开致谢（可选匿名）。

## 威胁模型（摘要）

| 关注点 | 说明 |
|---|---|
| 订阅 / 规则导入 | 视为不可信输入；解析容错，不执行任意代码（脚本仅 QuickJS 沙箱） |
| jar 蜘蛛 | 仅加载用户显式导入的 jar；桌面走 JVM 子进程，不自动下载未知包 |
| 局域网 / 备份 | 需 token；默认拒绝敏感路径 |
| 播放地址 | `needsParse` 默认过滤，不做网页嗅探 |

## 非安全问题

普通 Bug、功能建议请用 [Issue 模板](./.github/ISSUE_TEMPLATE/)。
