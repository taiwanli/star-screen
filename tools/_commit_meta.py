# -*- coding: utf-8 -*-
from pathlib import Path

p = Path(".gitignore")
c = p.read_text(encoding="utf-8")
c = c.replace("*.star.json\n", "# docs/samples 虚构测试样例可入库\n")
p.write_text(c, encoding="utf-8")
print("gitignore ok")

import subprocess
r = subprocess.run(["git", "add", "-A"], capture_output=True, text=True)
print(r.stderr[-200:] if r.stderr else "add ok")
r = subprocess.run(
    [
        "git",
        "commit",
        "-m",
        "docs: 补齐开源元数据（贡献指南/行为准则/安全/Issue·PR 模板）\n\n- README 重写：安装、运行前提、快速使用、文档索引、CI badge\n- CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / AUTHORS\n- GitHub Issue 与 PR 模板\n- CI 监听 master；补充 CODEOWNERS\n- 恢复 docs/samples 测试样例入库（仅虚构域名）\n\nCo-Authored-By: MiMo <noreply@xiaomi.com>",
    ],
    capture_output=True,
    text=True,
)
print(r.stdout[-500:] if r.stdout else "")
print(r.stderr[-300:] if r.stderr else "")
print("commit rc", r.returncode)
