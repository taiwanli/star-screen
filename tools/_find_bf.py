import sqlite3, os

db = os.path.expandvars(r"%APPDATA%\StarScreen\star.db")
conn = sqlite3.connect(db)

# 找 bfzyapi 源的 key
r = conn.execute(
    "SELECT key, name FROM source_defs WHERE endpoint LIKE '%bfzyapi%'"
).fetchall()
print("bfzyapi:", r)

# 找所有 enabled cmsJson（hex 编码避免乱码）
rows = conn.execute(
    "SELECT key, name, endpoint FROM source_defs WHERE kind='cmsJson' AND enabled=1"
).fetchall()
print(f"\nEnabled cmsJson ({len(rows)}):")
for key, name, ep in rows:
    print(f"  key={key!r}  name={name!r}  ep={ep}")
