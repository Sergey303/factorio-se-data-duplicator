"""Package the Factorio addon with the required root directory in the zip."""
from __future__ import annotations

import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod"
info = json.loads((MOD / "info.json").read_text(encoding="utf-8"))
folder = f"{info['name']}_{info['version']}"
output = ROOT / "dist" / f"{folder}.zip"
output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(MOD.rglob("*")):
        if path.is_file():
            archive.write(path, f"{folder}/{path.relative_to(MOD).as_posix()}")
print(output)
