"""Test-only Linux endpoint for independent argv, environment, and byte oracles."""
import json
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import time


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


mode = sys.argv[1]
if mode == "bootstrap-context":
    print(json.dumps({"environment": {
        name: os.environ[name]
        for name in ("GIT_WORK_TREE", "GIT_CONFIG_KEY_0", "GIT_CONFIG_VALUE_0",
                     "GIT_CONFIG_KEY_1", "GIT_CONFIG_VALUE_1", "TMPDIR", "XDG_CACHE_HOME")
    }}))
elif mode == "context":
    count = int(os.environ["GIT_CONFIG_COUNT"])
    print(json.dumps({
        "argv": sys.argv[2:],
        "cwd": os.getcwd(),
        "root": git("rev-parse", "--show-toplevel"),
        "gitDir": git("rev-parse", "--absolute-git-dir"),
        "commonDir": git("rev-parse", "--git-common-dir"),
        "head": git("rev-parse", "HEAD"),
        "overrides": [
            [os.environ[f"GIT_CONFIG_KEY_{i}"], os.environ[f"GIT_CONFIG_VALUE_{i}"]]
            for i in range(count)
        ],
        "fsmonitor": git("config", "--get", "core.fsmonitor"),
    }, ensure_ascii=True))
elif mode == "bytes":
    # Each stream exceeds pipe capacity before the other is written.
    sys.stdout.buffer.write(bytes(range(256)) * 4096 + b"\r\nutf8:\xc3\xa9")
    sys.stdout.buffer.flush()
    sys.stderr.buffer.write(bytes(reversed(range(256))) * 4096 + b"\r\npartial")
    sys.stderr.buffer.flush()
    sys.exit(23)
elif mode == "empty":
    sys.exit(0)
elif mode == "sleep":
    time.sleep(10)
elif mode == "snapshot":
    snapshot = {}
    roots = [Path(value) for value in sys.argv[2:]]
    roots.extend(Path.home() / value for value in (
        ".gitconfig", ".config/git/config", ".ripwire", ".cache/ripwire"))
    for root in roots:
        if not root.exists() and not root.is_symlink():
            snapshot[str(root)] = {"kind": "missing"}
            continue
        paths = [root] + sorted(root.rglob("*")) if root.is_dir() else [root]
        for path in paths:
            if path.is_symlink():
                entry = {"kind": "link", "target": os.readlink(path)}
            elif path.is_dir():
                entry = {"kind": "directory"}
            elif path.is_file():
                digest = hashlib.sha256()
                with path.open("rb") as file:
                    for chunk in iter(lambda: file.read(1024 * 1024), b""):
                        digest.update(chunk)
                entry = {"kind": "file", "sha256": digest.hexdigest()}
            else:
                raise ValueError(f"Unsupported snapshot file type: {path}")
            entry["mode"] = path.lstat().st_mode
            snapshot[str(path)] = entry
    print(json.dumps(snapshot, sort_keys=True))
else:
    raise ValueError(f"Unknown probe mode: {mode}")
