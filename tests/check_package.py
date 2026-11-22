"""Check the packaged Factorio mod layout and metadata."""
from __future__ import annotations

import json
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod"
info = json.loads((MOD / "info.json").read_text(encoding="utf-8"))
assert info["name"] == "se-data-duplicator"
assert info["factorio_version"] == "2.1"
assert any(dep.startswith("space-exploration >=") for dep in info["dependencies"])
source = (MOD / "data-final-fixes.lua").read_text(encoding="utf-8")
assert "shared_probability" in source
assert "categories = {CATEGORY}" in source
assert 'local SIGNIFICANT = "se-significant-data"' in source
assert 'and item_name ~= SIGNIFICANT' in source
assert "category = CATEGORY" not in source
for fluid in ("se-space-coolant-cold", "se-space-coolant-hot"):
    assert fluid in source
assert "local HOT = \"se-space-coolant\"" not in source
for lang in ("en", "ru"):
    text = (MOD / "locale" / lang / "locale.cfg").read_text(encoding="utf-8")
    assert "[mod-name]" in text
    assert "copy-name=" in text
    assert "copy-description=" in text

folder = f"{info['name']}_{info['version']}"
package = ROOT / "dist" / f"{folder}.zip"
with ZipFile(package) as z:
    names = z.namelist()
    for required in ("info.json", "settings.lua", "data-final-fixes.lua",
                     "locale/ru/locale.cfg", "locale/en/locale.cfg"):
        assert f"{folder}/{required}" in names
    assert json.loads(z.read(f"{folder}/info.json")) == info
print(f"OK: {package} ({package.stat().st_size} bytes; {len(names)} files)")
