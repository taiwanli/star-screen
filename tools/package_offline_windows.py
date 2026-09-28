# -*- coding: utf-8 -*-
"""生成「开箱即用」Windows 离线包：exe + 依赖 + 捆绑 JRE + Jar 桥。

用法:
  python tools/package_offline_windows.py

产物:
  dist/星映-Windows-开箱即用-<ver>.zip
    StarScreen/
      star_desktop.exe + *.dll + data/
      jre-min/          # jlink 迷你 JRE（jar 蜘蛛用）
      bridge/star-spider-bridge.jar
      README.txt
"""
from __future__ import annotations

import shutil
import zipfile
from pathlib import Path

BUILD = Path(r"C:\XingYingBuild")
SRC = Path(r"C:\Users\Administrator\Desktop\星映 - 副本")
OUT = SRC / "dist"
VER = "0.1.0-dev.45"
STAGE = OUT / "StarScreen-offline"
ZIP = OUT / f"星映-Windows-开箱即用-{VER}.zip"

REL = BUILD / "apps/desktop/build/windows/x64/runner/Release"
JRE = BUILD / "tools/jre-min"
BRIDGE = BUILD / "tools/java-bridge/star-spider-bridge.jar"

assert REL.joinpath("star_desktop.exe").exists(), REL
assert JRE.exists(), JRE
assert BRIDGE.exists(), BRIDGE

if STAGE.exists():
    shutil.rmtree(STAGE)
shutil.copytree(REL, STAGE)
shutil.copytree(JRE, STAGE / "jre-min")
(STAGE / "bridge").mkdir()
shutil.copy2(BRIDGE, STAGE / "bridge" / "star-spider-bridge.jar")

(STAGE / "README.txt").write_text(
    f"""星映 StarScreen · Windows 开箱即用包 {VER}

【安装】
解压到任意目录（勿放需管理员权限的路径），双击 star_desktop.exe

【已内置 · 无需另装】
- 播放内核 libmpv / Exo / 外部播放器
- QuickJS（drpy / StarRule script）
- SQLite
- 迷你 JRE（jre-min）+ Jar 蜘蛛桥（bridge/）

【功能】
- 导入 TVBox / StarRule / 本地文件 / 文件夹
- 点播、搜索、详情、播放、直播
- jar 蜘蛛（依赖本机已捆绑 JRE，无需装 JDK）

【常见问题】
1. 杀软误报：将目录加入信任
2. 无法播放：源管理 → 播放引擎，切换 Exo / 外部播放器
3. jar 源失败：该 jar 或依赖安卓组件，可换 StarRule 或手机端
4. 没有内容源：请自行导入订阅（应用不内置源）

【卸载】
直接删除该文件夹；数据在 %APPDATA%\\StarScreen
""",
    encoding="utf-8",
)

if ZIP.exists():
    ZIP.unlink()
with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for f in STAGE.rglob("*"):
        if f.is_file():
            z.write(f, f.relative_to(STAGE.parent).as_posix())

size = ZIP.stat().st_size / 1e6
print("zip:", ZIP.name, f"{size:.1f} MB")
print("folder:", STAGE)
