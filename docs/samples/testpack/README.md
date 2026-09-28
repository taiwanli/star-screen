# StarRule 虚构测试源包

> **用途**：规则引擎导入 / 校验 / 测活链路 / 三端 UI 回归的测试资产。  
> **约束**：全部域名使用保留字（`example.com`），**不指向任何真实站点**，不用于观看内容。  
> 生成器：`tools/gen_starrule_testpack.py`

## 文件

| 文件 | 说明 |
|---|---|
| `test.html.4k.demo.star.json` | HTML 模板站：4K 角标、双线路、筛选、分页 |
| `test.json.api.demo.star.json` | JSON API：分页 pageCount、多线路 `$$$`、搜索 |
| `test.cms.quick.demo.star.json` | `sourceType:cms` 快捷协议 |
| `test.alist.personal.demo.star.json` | 个人 Alist 目录树（自建库形态） |
| `testpack.hand4.star.json` | 上述 4 条打包（便于一次导入） |
| `testpack.50.star.json` | 50 站压力包（4 形态循环变体） |

## 导入

```
源管理 → 添加内容源 → 选择/粘贴 testpack.hand4.star.json
```

或深链（文件需可被 HTTP 访问）：

```
starrule://import?url=<url-encoded 链接>
```

## 本地校验

```bash
cd packages/domain
dart run bin/starrule_lint.dart ../../docs/samples/testpack/testpack.50.star.json
```

## 形态覆盖

| 形态 | 验证点 |
|---|---|
| html | 选择器链、`:eq(#line)` 线路、`hasMore:auto`、`{filter_year}` |
| json | `json:` 路径、`pageCount`、`fromField/urlField` CMS 线路 |
| cms | 协议内建四链路、无规则块可导入 |
| alist-json | 目录树 id=path、flat 单线路、`hasMore:none` |

重新生成：

```bash
python tools/gen_starrule_testpack.py --count 50
```
