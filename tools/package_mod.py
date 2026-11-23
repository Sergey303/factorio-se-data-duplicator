"""Package the Factorio addon with the required root directory in the zip."""
from __future__ import annotations

import json
from pathlib import Path
from zipfile import ZIP_STORED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod"
info = json.loads((MOD / "info.json").read_text(encoding="utf-8"))
folder = f"{info['name']}_{info['version']}"
output = ROOT / "dist" / f"{folder}.zip"
output.parent.mkdir(parents=True, exist_ok=True)
# Constant ZIP timestamps, file permissions and sorted names produce exactly the
# same release bytes on Windows and Linux from identical Git sources.
with ZipFile(output, "w", compression=ZIP_STORED) as archive:
    for path in sorted(MOD.rglob("*"), key=lambda p: p.relative_to(MOD).as_posix()):
        if not path.is_file():
            continue
        entry = f"{folder}/{path.relative_to(MOD).as_posix()}"
        info = ZipInfo(entry, date_time=(1980, 1, 1, 0, 0, 0))
        info.compress_type = ZIP_STORED
        info.create_system = 3
        info.external_attr = (0o100644 << 16)
        content = path.read_bytes()
        # Git may check out text as CRLF on Windows and LF on Linux.
        # Normalize only known text-based mod sources, never image bytes.
        if path.name == "LICENSE" or path.suffix.lower() in {".lua", ".json", ".cfg", ".txt"}:
            content = content.replace(b"\r\n", b"\n")
        archive.writestr(info, content, compress_type=ZIP_STORED)
print(output)
