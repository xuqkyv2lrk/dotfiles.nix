"""Translate DuckStation save states between the RP6 and this PC.

The Android build files every state of a multi-disc game under the first disc's
serial, quick-saves to slot 0 and records the disc as a SAF content:// URI. The
desktop build files states under the serial of the disc in the drive, has no
slot 0 and needs a local path. The synced folder keeps the Android layout; the
desktop gets its own folder, and this script maps one quick slot between them:
synced <first serial>_0.sav <-> local <every disc serial>_1.sav.
"""

import argparse
import hashlib
import json
import os
import re
import struct
import sys
import urllib.parse
from pathlib import Path

ANDROID_SLOT = 0
DESKTOP_SLOT = 1
# SAVE_STATE_HEADER: media path length/offset, then screenshot and data offsets
# that sit behind the path and move with it
OFF_PATH_LEN = 0xA8
OFF_PATH_OFFSET = 0xAC
OFF_SCREENSHOT_OFFSET = 0xC4
OFF_DATA_OFFSET = 0xD4
MAGIC = b"DUCC"
# Java's Uri.encode leaves these unescaped; anything else must match byte for byte
ANDROID_SAFE = "!'()*"


def load_disc_sets(path: Path) -> dict[str, list[str]]:
    """Map every serial of a multi-disc game to the game's ordered serial list."""
    sets: dict[str, list[str]] = {}
    current: list[str] | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("- name:"):
            current = None
        elif line.strip() == "serials:":
            current = []
        elif current is not None and (m := re.match(r"^\s+- (\S+)$", line)):
            current.append(m.group(1))
            for serial in current:
                sets[serial] = current
    return sets


def state_version(data: bytes) -> int:
    return struct.unpack_from("<I", data, 4)[0]


def read_media_path(data: bytes) -> str:
    length, offset = struct.unpack_from("<II", data, OFF_PATH_LEN)
    return data[offset:offset + length].decode("utf-8")


def with_media_path(data: bytes, path: str) -> bytes:
    """Return the state with its media path replaced and later offsets shifted."""
    length, offset = struct.unpack_from("<II", data, OFF_PATH_LEN)
    new = path.encode("utf-8")
    delta = len(new) - length
    out = bytearray(data[:offset] + new + data[offset + length:])
    struct.pack_into("<I", out, OFF_PATH_LEN, len(new))
    for field in (OFF_SCREENSHOT_OFFSET, OFF_DATA_OFFSET):
        (value,) = struct.unpack_from("<I", out, field)
        if value > offset:
            struct.pack_into("<I", out, field, value + delta)
    return bytes(out)


class Mapper:
    def __init__(self, uri_prefix: str, rom_dir: Path) -> None:
        self.uri_prefix = uri_prefix
        self.rom_dir = rom_dir

    def to_local(self, media: str) -> str | None:
        if not media.startswith(self.uri_prefix):
            return media if media.startswith("/") else None
        rel = urllib.parse.unquote(media[len(self.uri_prefix):])
        return str(self.rom_dir / rel)

    def to_android(self, media: str) -> str | None:
        if media.startswith("content://"):
            return media
        try:
            rel = Path(media).relative_to(self.rom_dir)
        except ValueError:
            return None
        return self.uri_prefix + urllib.parse.quote(str(rel), safe=ANDROID_SAFE)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_atomic(path: Path, data: bytes) -> None:
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_bytes(data)
    os.chmod(tmp, 0o660)
    os.replace(tmp, path)


def state_file(folder: Path, serial: str, slot: int) -> Path:
    return folder / f"{serial}_{slot}.sav"


def sync(args: argparse.Namespace) -> None:
    sets = load_disc_sets(args.disc_sets)
    mapper = Mapper(args.uri_prefix, args.rom_dir)
    db_path: Path = args.db
    db: dict[str, dict[str, str]] = json.loads(db_path.read_text()) if db_path.exists() else {}
    only = set(args.only)

    def family(serial: str) -> list[str]:
        return sets.get(serial, [serial])

    # The RP6 cannot load a state newer than its own build writes; learn that version
    # from states it made (Android media path), ignoring ones this script wrote
    written = {seen.get("synced") for seen in db.values()}
    android_version = 0
    for f in args.synced.glob("*.sav"):
        data = f.read_bytes()
        if (data[:4] == MAGIC and digest(data) not in written
                and read_media_path(data).startswith("content://")):
            android_version = max(android_version, state_version(data))
    db["_meta"] = {"android_version": str(android_version)}

    keys: set[str] = set()
    for f in args.synced.glob(f"*_{ANDROID_SLOT}.sav"):
        keys.add(f.name.rsplit("_", 1)[0])
    for f in args.local.glob(f"*_{DESKTOP_SLOT}.sav"):
        keys.add(family(f.name.rsplit("_", 1)[0])[0])

    for key in sorted(keys - {"_meta"}):
        serials = family(key)
        if only and not only.intersection(serials):
            continue
        seen = db.setdefault(key, {})
        candidates: list[tuple[float, str, Path]] = []
        synced = state_file(args.synced, key, ANDROID_SLOT)
        if synced.exists() and digest(synced.read_bytes()) != seen.get("synced"):
            candidates.append((synced.stat().st_mtime, "synced", synced))
        for serial in serials:
            local = state_file(args.local, serial, DESKTOP_SLOT)
            if local.exists() and digest(local.read_bytes()) != seen.get(serial):
                candidates.append((local.stat().st_mtime, serial, local))
        if not candidates:
            continue

        _, origin, source = max(candidates)
        data = source.read_bytes()
        if data[:4] != MAGIC:
            print(f"{source}: not a DuckStation state, skipped", file=sys.stderr)
            continue
        media = read_media_path(data)
        local_media = mapper.to_local(media)
        android_media = mapper.to_android(media)
        if local_media is None or android_media is None:
            print(f"{source}: media path outside the ROM folder: {media}", file=sys.stderr)
            continue

        local_data = with_media_path(data, local_media)
        android_data = with_media_path(data, android_media)
        for serial in serials:
            target = state_file(args.local, serial, DESKTOP_SLOT)
            if serial != origin or local_data != data:
                write_atomic(target, local_data)
            seen[serial] = digest(local_data)
        if origin != "synced" and state_version(data) > android_version:
            print(f"{key}: {source.name} is state version {state_version(data)}, the RP6 "
                  f"reads up to {android_version}; kept local only", file=sys.stderr)
            continue
        if origin != "synced" or android_data != data:
            write_atomic(synced, android_data)
        seen["synced"] = digest(android_data)
        print(f"{key}: {source.name} -> slot {ANDROID_SLOT} and {len(serials)} local copies")

    tmp = db_path.with_name(f".{db_path.name}.tmp")
    tmp.write_text(json.dumps(db, indent=1, sort_keys=True))
    os.replace(tmp, db_path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--synced", type=Path, required=True, help="Syncthing state folder")
    parser.add_argument("--local", type=Path, required=True, help="desktop state folder")
    parser.add_argument("--rom-dir", type=Path, required=True, help="local PSX ROM folder")
    parser.add_argument("--uri-prefix", required=True, help="Android URI of the ROM folder")
    parser.add_argument("--disc-sets", type=Path, required=True, help="DuckStation discsets.yaml")
    parser.add_argument("--db", type=Path, required=True, help="hashes of written states")
    parser.add_argument("--only", nargs="*", default=[], help="limit to these serials")
    sync(parser.parse_args())


if __name__ == "__main__":
    main()
