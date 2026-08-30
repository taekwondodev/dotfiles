# Reading a WAL-mode SQLite database from a subprocess

Symptom: a macOS app bridges to a local producer's `state.db` and reports "source
unreadable"/"unavailable" for every read even though `sqlite3 <path> "SELECT ..."`
from a normal shell returns the data.

## Root cause

Producers that run continuously (Hermes, e.g.) keep their SQLite DB in **WAL
journal mode**. Opening it with `sqlite3 -readonly` fails because a read-only
connection cannot open the shared `-shm`/`-wal` index:

```text
Error: in prepare, unable to open database file (14)    # exit 14 / SQLITE_CANTOPEN
```

So `-readonly` + a WAL DB → non-zero exit → the app's reader maps it to an
"unavailable" state. The data exists; the open flag is wrong.

## Fix

Open normally and force query-only — reads WAL (including not-yet-checkpointed
rows) and never mutates data:

```bash
sqlite3 -json "<path>" "PRAGMA query_only=ON; SELECT ...;"
```

In Swift/Process, pass it as one SQL argument:

```swift
process.arguments = ["-json", databaseURL.path, "PRAGMA query_only=ON; " + sql]
```

### Why not the URI form

`file:<path>?mode=ro&immutable=1` also reads, but `immutable` tells SQLite the
file never changes and **skips the WAL** — it can under-report recent
uncheckpointed writes. Prefer `PRAGMA query_only=ON` for an accurate snapshot.

## Verify the bug vs fix

```bash
# broken on a live WAL DB:
/usr/bin/sqlite3 -readonly -json "$DB" "SELECT ...;" ; echo $?   # 14
# works:
/usr/bin/sqlite3 -json "$DB" "PRAGMA query_only=ON; SELECT ...;" ; echo $?   # 0
```

## Test pitfall

A reader integration test that creates a **fresh temp DB** uses the default
rollback-journal mode, where `-readonly` succeeds — so the test passes while the
production WAL read is broken. Add a WAL-mode variant:

```sql
PRAGMA journal_mode=WAL;
CREATE TABLE ...;
INSERT ...;
```

then drive the reader through it. This is the guard that catches the `-readonly`
regression.
