"""Mutations confined to a new disposable Linux cache root, never a project."""
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys


def root_path(value, *, existing=True):
    root = Path(value)
    if not re.fullmatch(r"/tmp/ripwire-cache-feasibility\.[0-9a-f]{32}", value):
        raise ValueError("Expected a fresh /tmp/ripwire-cache-feasibility.<uuid-hex> root")
    if root.is_symlink() or root.resolve() != root:
        raise ValueError("Cache root must not resolve through a link")
    if existing:
        info = root.stat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise ValueError("Cache root must be a private directory owned by this user")
    return root


def namespace_path(root, value):
    namespace = Path(value)
    relative = namespace.relative_to(root)
    parts = relative.parts[1:] if relative.parts[0] == "releases" else relative.parts
    if len(parts) != 3 or parts[0] != "v0.5.0" or parts[1] not in {"x64", "arm64"} or not re.fullmatch(r"[0-9a-f]{64}", parts[2]):
        raise ValueError("Unexpected namespace shape")
    if namespace.resolve() != namespace:
        raise ValueError("Namespace must not resolve through a link")
    return namespace


mode, value = sys.argv[1:3]
if mode == "init":
    root = root_path(value, existing=False)
    filesystem = subprocess.check_output(
        ["stat", "-f", "-c", "%T", str(root.parent)], text=True).strip()
    if filesystem not in {"ext2/ext3", "tmpfs", "btrfs", "xfs"}:
        raise ValueError(f"Unsupported native Linux test filesystem: {filesystem}")
    root.mkdir(mode=0o700, exist_ok=False)
    print(root)
elif mode == "namespace":
    root = root_path(value)
    release, architecture, worktree, git_dir, common_dir = sys.argv[3:]
    if release != "v0.5.0" or architecture not in {"x64", "arm64"}:
        raise ValueError("Unexpected pinned release/architecture")
    identity = json.dumps([worktree, git_dir, common_dir], ensure_ascii=True, separators=(",", ":"))
    key = hashlib.sha256(identity.encode("utf-8")).hexdigest()
    namespace = namespace_path(root, str(root / release / architecture / key))
    os.umask(0o077)
    namespace.mkdir(mode=0o700, parents=True, exist_ok=True)
    for name in ("tmp", "xdg"):
        (namespace / name).mkdir(mode=0o700, exist_ok=True)
    print(json.dumps({"key": key, "path": str(namespace)}))
elif mode == "fault":
    root = root_path(value)
    namespace = namespace_path(root, sys.argv[3])
    fault = sys.argv[4]
    family = sys.argv[5]
    if fault not in {"missing", "corrupt"}:
        raise ValueError("Unknown cache fault")
    patterns = {
        "source": r"ripwire-[0-9a-f]{16}-rich\.bin",
        "history": r"ripwire-qchurn-[0-9a-f]+--[0-9a-f]+\.bin",
    }
    if family not in patterns:
        raise ValueError("Unknown cache family")
    matches = [
        path for directory in (namespace / "tmp", namespace / "xdg") for path in directory.rglob("*")
        if re.fullmatch(patterns[family], path.name)
    ]
    if not matches or (family == "source" and len(matches) != 1):
        raise ValueError(f"Unexpected {family} cache count: {len(matches)}")
    for cache in matches:
        if cache.is_symlink() or cache.resolve() != cache or not cache.is_file():
            raise ValueError("Cache fixture refuses non-regular or linked files")
        if fault == "missing":
            cache.unlink()
        else:
            cache.write_bytes(b"deliberately-invalid-cache")
    print(json.dumps({
        "fault": fault, "family": family,
        "relativePaths": [str(cache.relative_to(root)) for cache in matches],
    }))
else:
    raise ValueError(f"Unknown cache fixture mode: {mode}")
