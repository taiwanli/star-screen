# -*- coding: utf-8 -*-
from pathlib import Path

OLD_D = "    final engine = SearchEngine(sources: videoSources);"
NEW_D = """    final cooling = {
      for (final s in videoSources)
        if (widget.services.healthMonitor.isCooling(s.def.key)) s.def.key,
    };
    final engine = SearchEngine(sources: videoSources, skipKeys: cooling);"""

OLD_MT = "    _sub = SearchEngine(sources: videoSources).searchAll(keyword).listen((update) {"
NEW_MT = """    final cooling = {
      for (final s in videoSources)
        if (widget.services.healthMonitor.isCooling(s.def.key)) s.def.key,
    };
    _sub = SearchEngine(sources: videoSources, skipKeys: cooling)
        .searchAll(keyword)
        .listen((update) {"""

for name, old, new in [
    ("desktop", OLD_D, NEW_D),
    ("mobile", OLD_MT, NEW_MT),
    ("tv", OLD_MT, NEW_MT),
]:
    p = Path(f"apps/{name}/lib/src/pages/search_page.dart")
    c = p.read_text(encoding="utf-8")
    if "skipKeys" in c:
        print(name, "already")
        continue
    if old not in c:
        raise SystemExit(f"{name} pattern missing")
    c = c.replace(old, new, 1)
    p.write_text(c, encoding="utf-8")
    print(name, "ok")
