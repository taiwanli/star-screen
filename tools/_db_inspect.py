import sqlite3, os
db = os.path.expandvars(r"%APPDATA%\StarScreen\star.db")
conn = sqlite3.connect(db)
tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
print("Tables:", tables)
for (t,) in tables:
    cols = conn.execute(f"PRAGMA table_info({t})").fetchall()
    print(f"\n{t}: {[c[1] for c in cols]}")
    rows = conn.execute(f"SELECT * FROM {t} LIMIT 5").fetchall()
    for r in rows:
        print(" ", r)
