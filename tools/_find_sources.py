import sqlite3, os

db = os.path.expandvars(r"%APPDATA%\StarScreen\star.db")
conn = sqlite3.connect(db)

rows = conn.execute(
    "SELECT key, name, endpoint, enabled FROM source_defs WHERE kind='cmsJson' AND enabled=1"
).fetchall()
print(f"已启用 cmsJson 源共 {len(rows)} 个：")
for r in rows:
    print(f"  {r}")

print()
rows2 = conn.execute(
    "SELECT key, name, endpoint, source_url, enabled FROM source_defs WHERE kind='drpyJs' AND enabled=1"
).fetchall()
print(f"已启用 drpyJs 源共 {len(rows2)} 个：")
for r in rows2:
    ep = (r[2] or "")[:50]
    src = (r[3] or "")[:60]
    print(f"  {r[0]}: ep={ep}... src={src}...")
