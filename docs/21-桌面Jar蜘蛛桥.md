# 桌面端 Jar 蜘蛛桥说明

> 目标：在 Windows/macOS/Linux 桌面跑 TVBox `csp_*` jar 蜘蛛  
> 状态：已实现 JVM 子进程桥（`DesktopJvmJarHost` + `StarJarBridge.java`）

---

## 1. 为什么不能像手机一样跑

| 点 | 手机 | 桌面 |
|---|---|---|
| 加载 | `DexClassLoader` | 无 Dex，需 **JVM `URLClassLoader`** |
| `init(Context, …)` | 安卓 Context | 需 **动态代理桩** |
| 依赖 | OkHttp/安卓工具类 | 多数纯 Java 可用；依赖 Dex/安卓组件的会失败 |

**结论**：约 70–80% 的纯 Java 蜘蛛可在桌面跑；深度绑安卓的仍不行。

---

## 2. 架构

```
Flutter (JarSpiderSource)
    │  JSON Lines (stdin/stdout)
    ▼
java -cp star-spider-bridge.jar:your.jar \
     StarJarBridge com.github.catvod.spider.Xxx
    │  反射调用 homeContent / searchContent / …
    ▼
你的 spider.jar
```

桥类：`tools/java-bridge/StarJarBridge.java` → `star-spider-bridge.jar`

---

## 3. 使用步骤

1. **本机安装 JDK 17+**（已在常见路径自动探测）
2. 将 `star-spider-bridge.jar` 放在：
   - 应用目录旁 `bridge/`，或
   - 工程 `tools/java-bridge/`
3. 订阅里声明 jar 蜘蛛（TVBox type=3 + `csp_Xxx` + `jar`）
4. 导入后源会标「jar 蜘蛛」；**桌面可尝试浏览**（若 jar 依赖安卓 API 会报错并提示）

### 手动测试桥

```bash
cd tools/java-bridge
javac -encoding UTF-8 StarJarBridge.java
jar cf star-spider-bridge.jar StarJarBridge.class

java -cp "star-spider-bridge.jar;path\to\spider.jar" \
     StarJarBridge com.github.catvod.spider.Douban
# 交互输入：
# {"cmd":"init","extend":""}
# {"cmd":"homeVod"}
```

---

## 4. 协议（JSON Lines）

| cmd | 参数 | 方法 |
|---|---|---|
| `init` | `extend` | `init(Context,String)` |
| `home` | `filter` | `homeContent(boolean)` |
| `homeVod` | | `homeVideoContent()` |
| `category` | `tid,pg,filter,extend` | `categoryContent(...)` |
| `search` | `key,quick,pg` | `searchContent(...)` |
| `detail` | `ids[]` | `detailContent(List)` |
| `play` | `flag,id,vipFlags[]` | `playerContent(...)` |
| `ping` / `exit` | | 健康检查 / 退出 |

响应：`{"ok":true,"data":…}` / `{"ok":false,"error":"…"}`

---

## 5. 限制

| 限制 | 说明 |
|---|---|
| 依赖 `android.*` 实现逻辑 | 可能 `ClassNotFound` |
| 需要用户本机 JDK | 无 JRE 则 `available=false` |
| 安全 | 仅加载**用户导入**的 jar；不自动下未知包 |
| 合规 | 与项目基线一致：不扩展嗅探；源由用户自备 |

---

## 6. 失败时的替代路径

1. **StarRule 重写**该站（推荐，三端一致）
2. 手机/TV 上跑该 jar，桌面用**局域网串流/同步**
3. 自建 **drpy / 服务器桥**（docs/05 §2）

---

## 7. 代码入口

| 文件 | 说明 |
|---|---|
| `tools/java-bridge/StarJarBridge.java` | JVM 桥源码 |
| `tools/java-bridge/star-spider-bridge.jar` | 已编译产物 |
| `apps/desktop/lib/src/jar_host.dart` | `DesktopJvmJarHost` |
| `packages/domain/lib/src/adapters/jar_spider_source.dart` | 适配器（三端共用） |
