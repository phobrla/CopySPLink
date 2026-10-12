"""Look up the SharePoint UniqueId (GUID) of OneDrive-synced files.

Usage: Get-SharePointLink.py <file_id_low64_decimal> <file_name>
Prints the GUID (no braces) or nothing. Reads copies of OneDrive's
SyncEngineDatabase.db files, where eTag looks like "{GUID},version".
"""
import glob
import os
import re
import shutil
import sqlite3
import sys
import tempfile

item_index = int(sys.argv[1])
file_name = sys.argv[2]
settings = os.path.join(os.environ["LOCALAPPDATA"], "Microsoft", "OneDrive", "settings")
guid_re = re.compile(r"\{([0-9A-Fa-f-]{36})\}")

tmp = tempfile.mkdtemp()
try:
    for i, src in enumerate(glob.glob(os.path.join(settings, "Business*", "SyncEngineDatabase.db"))):
        dst = os.path.join(tmp, "db%d.db" % i)
        try:
            for suffix in ("", "-wal", "-shm"):
                if os.path.exists(src + suffix):
                    shutil.copyfile(src + suffix, dst + suffix)
            con = sqlite3.connect(dst)
            rows = con.execute(
                "select eTag from od_ClientFile_Records where itemIndex=? and fileName=?",
                (item_index, file_name),
            ).fetchall()
            con.close()
        except Exception:
            continue
        for (etag,) in rows:
            m = guid_re.search(etag or "")
            if m:
                print(m.group(1).upper())
                sys.exit(0)
finally:
    shutil.rmtree(tmp, ignore_errors=True)
