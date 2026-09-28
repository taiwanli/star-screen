# -*- coding: utf-8 -*-
"""生成 StarRule 虚构测试源包（docs/samples/testpack）。

全部域名使用 RFC 2606 / RFC 6761 保留字（example.com / test / invalid），
仅用于规则引擎导入、测活链路、UI 展示的压力与回归测试，不指向任何真实站点。

用法：
  python tools/gen_starrule_testpack.py           # 生成到 docs/samples/testpack/
  python tools/gen_starrule_testpack.py --count 50
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

OUT = Path("docs/samples/testpack")

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

# ---------------------------------------------------------------------------
# 手写代表性样例（覆盖主要形态）
# ---------------------------------------------------------------------------

HTML_4K = {
    "starrule": 1,
    "meta": {
        "id": "test.html.4k.demo",
        "name": "示例4K模板站",
        "version": "1.0.0",
        "author": "星映测试包",
        "description": "虚构 HTML 模板站：多分类 + 4K 角标 + 双线路 + 筛选。域名仅用于引擎测试。",
    },
    "sourceType": "html",
    "site": {
        "host": "https://cinema.example.com",
        "timeout": 12,
        "headers": {"User-Agent": UA, "Referer": "https://cinema.example.com/"},
    },
    "home": {
        "url": "/",
        "recommend": {
            "list": "body&&.vod-card",
            "title": ".title&&Text",
            "id": "a&&href",
            "cover": "img&&data-src",
            "badge": ".note&&Text",
            "year": ".year&&Text",
            "score": ".score&&Text",
        },
        "categories": {
            "mode": "manual",
            "manual": {
                "电影": "movie",
                "剧集": "tv",
                "综艺": "show",
                "4K专区": "4k",
            },
        },
        "filters": {
            "movie": [
                {
                    "key": "year",
                    "name": "年份",
                    "options": [
                        {"label": "全部", "value": ""},
                        {"label": "2026", "value": "2026"},
                        {"label": "2025", "value": "2025"},
                    ],
                }
            ]
        },
    },
    "category": {
        "url": "/type/{cateId}-{catePg}.html{filter_year}",
        "list": "body&&.vod-card",
        "title": ".title&&Text",
        "id": "a&&href",
        "cover": "img&&data-src",
        "badge": ".note&&Text",
        "hasMore": "auto",
    },
    "detail": {
        "url": "/detail/{vid}.html",
        "title": "h1&&Text",
        "cover": ".poster&&img&&src",
        "desc": ".intro&&Text",
        "year": ".meta&&.year&&Text",
        "actor": ".meta&&.actor&&Text",
        "remarks": ".remarks&&Text",
        "lines": {
            "list": ".tabs&&span",
            "name": "Text",
            "episodes": {
                "list": ".playlist:eq(#line)&&a",
                "name": "Text",
                "url": "href",
            },
        },
    },
    "search": {
        "url": "/search/{wd}-{catePg}.html",
        "list": "body&&.vod-card",
        "title": ".title&&Text",
        "id": "a&&href",
        "cover": "img&&data-src",
    },
    "play": {
        "url": "{playUrl}",
        "headers": {"Referer": "https://cinema.example.com/"},
        "parse": "auto",
    },
    "tags": ["测试", "4K", "HTML", "虚构"],
    "enabled": True,
}

JSON_API = {
    "starrule": 1,
    "meta": {
        "id": "test.json.api.demo",
        "name": "示例JSON接口站",
        "version": "1.0.0",
        "author": "星映测试包",
        "description": "虚构 JSON API：分页 + 筛选 + 多线路 + 清晰度角标。",
    },
    "sourceType": "json",
    "site": {
        "host": "https://api.example.com",
        "timeout": 12,
        "headers": {"User-Agent": "okhttp/4.0", "Accept": "application/json"},
    },
    "home": {
        "url": "/v1/home",
        "recommend": {
            "list": "json:data.recommend",
            "title": "json:name",
            "id": "json:id",
            "cover": "json:pic",
            "badge": "json:remarks",
            "score": "json:score",
        },
        "categories": {
            "mode": "json",
            "parse": {
                "list": "json:data.class",
                "name": "json:type_name",
                "id": "json:type_id",
            },
        },
    },
    "category": {
        "url": "/v1/list?type={cateId}&page={catePg}&year={filter_year}",
        "list": "json:data.list",
        "title": "json:name",
        "id": "json:id",
        "cover": "json:pic",
        "badge": "json:remarks",
        "pageCount": "json:data.pagecount",
        "hasMore": "pageCount",
    },
    "detail": {
        "url": "/v1/detail?id={vid}",
        "title": "json:data.name",
        "cover": "json:data.pic",
        "desc": "json:data.desc",
        "year": "json:data.year",
        "actor": "json:data.actor",
        "lines": {
            "fromField": "json:data.play_from",
            "urlField": "json:data.play_url",
        },
    },
    "search": {
        "url": "/v1/search?wd={wd}&page={catePg}",
        "list": "json:data.list",
        "title": "json:name",
        "id": "json:id",
        "cover": "json:pic",
    },
    "play": {"url": "{playUrl}", "parse": "auto"},
    "tags": ["测试", "JSON", "虚构"],
}

CMS_QUICK = {
    "starrule": 1,
    "meta": {
        "id": "test.cms.quick.demo",
        "name": "示例CMS快捷源",
        "version": "1.0.0",
        "author": "星映测试包",
        "description": "sourceType:cms —— 协议内建 home/category/search/detail，规则块可省略。",
    },
    "sourceType": "cms",
    "site": {
        "host": "https://cms.example.com/api.php/provide/vod",
        "timeout": 12,
        "headers": {"User-Agent": UA},
    },
    "tags": ["测试", "CMS", "虚构"],
}

# 个人网盘（Alist 形态）：只描述「自己的挂载」，域名虚构
ALIST_PERSONAL = {
    "starrule": 1,
    "meta": {
        "id": "test.alist.personal.demo",
        "name": "示例个人网盘挂载",
        "version": "1.0.0",
        "author": "星映测试包",
        "description": "虚构 Alist 挂载目录浏览（个人文件库形态）。用于验证 json 目录树规则，不接任何第三方分享站。",
    },
    "sourceType": "json",
    "site": {
        "host": "https://alist.example.com",
        "timeout": 12,
        "headers": {"User-Agent": UA, "Authorization": "Bearer TEST-TOKEN"},
    },
    "home": {
        "url": "/dav/home",
        "recommend": {
            "list": "json:data.content",
            "title": "json:name",
            "id": "json:path",
            "cover": "json:thumb",
            "badge": "json:type",
        },
        "categories": {
            "mode": "manual",
            "manual": {
                "电影": "/媒体/电影",
                "剧集": "/媒体/剧集",
                "学习": "/学习",
            },
        },
    },
    "category": {
        "url": "/api/fs/list",
        "list": "json:data.content",
        "title": "json:name",
        "id": "json:path",
        "cover": "json:thumb",
        "badge": "json:type",
        "hasMore": "none",
    },
    "detail": {
        "url": "/api/fs/get?path={vid}",
        "title": "json:data.name",
        "cover": "json:data.thumb",
        "desc": "json:data.header",
        "lines": {
            "flat": True,
            "episodes": {
                "list": "json:data",
                "name": "json:name",
                "url": "json:raw_url",
            },
        },
    },
    "search": {
        "url": "/api/fs/search?parent=/&keyword={wd}",
        "list": "json:data.content",
        "title": "json:name",
        "id": "json:path",
    },
    "play": {"url": "{playUrl}", "parse": "auto"},
    "tags": ["测试", "Alist", "个人网盘", "虚构"],
}

HAND = {
    "test.html.4k.demo": HTML_4K,
    "test.json.api.demo": JSON_API,
    "test.cms.quick.demo": CMS_QUICK,
    "test.alist.personal.demo": ALIST_PERSONAL,
}


def variant(i: int, family: str) -> dict:
    """生成第 i 个变体（结构与手写样例同构，id/host 错开）。"""
    base = json.loads(json.dumps(HAND[family]))
    suffix = f"{i:02d}"
    base["meta"]["id"] = f"{base['meta']['id'].replace('.demo', '')}.v{suffix}"
    base["meta"]["name"] = f"{base['meta']['name']}·{suffix}"
    base["meta"]["version"] = "1.0.0"
    host = base["site"]["host"]
    # 保留 example.com，换子域
    if "://" in host:
        scheme, rest = host.split("://", 1)
        hostpart = rest
        path = ""
        if "/" in rest:
            hostpart, path = rest.split("/", 1)
            path = "/" + path
        base["site"]["host"] = f"{scheme}://v{suffix}.{hostpart}{path}"
    base["tags"] = [*base.get("tags", []), f"变体{suffix}"]
    return base


def main() -> None:
    count = 50
    if "--count" in sys.argv:
        count = int(sys.argv[sys.argv.index("--count") + 1])
    OUT.mkdir(parents=True, exist_ok=True)

    # 手写 4 条
    for key, rule in HAND.items():
        (OUT / f"{key}.star.json").write_text(
            json.dumps(rule, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    # 变体补齐到 count（循环四种形态）
    families = list(HAND.keys())
    sites = list(HAND.values())
    n = 4
    while n < count:
        fam = families[n % len(families)]
        sites.append(variant(n + 1, fam))
        n += 1

    pack = {
        "starrule": 1,
        "pack": {
            "id": "test.pack.starrule50",
            "name": "StarRule 测试包（虚构 50）",
            "version": "1.0.0",
            "author": "星映测试包",
            "description": (
                "全部域名保留字（example.com），仅供导入/校验/测活链路与 UI 回归，"
                "不指向真实站点。"
            ),
            "generatedAt": "2026-09-28",
        },
        "sites": sites,
    }
    (OUT / "testpack.50.star.json").write_text(
        json.dumps(pack, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # 规则包（仅手写 4 条，便于阅读）
    pack4 = {
        "starrule": 1,
        "pack": {
            "id": "test.pack.hand4",
            "name": "StarRule 测试包·手写4例",
            "version": "1.0.0",
        },
        "sites": list(HAND.values()),
    }
    (OUT / "testpack.hand4.star.json").write_text(
        json.dumps(pack4, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"ok: {OUT}  single={len(HAND)}  pack_sites={len(sites)}")


if __name__ == "__main__":
    main()
