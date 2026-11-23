"""Static validation of the Factorio 2.1 ZIP and safety invariants."""
from __future__ import annotations
import json
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / "mod"
info = json.loads((MOD / "info.json").read_text(encoding="utf-8"))
assert info["name"] == "se-data-duplicator"
assert info["version"] == "0.1.5", "Unpublished revision must retain version 0.1.5"
assert info["factorio_version"] == "2.1"
assert any(x.startswith("space-exploration >=") for x in info["dependencies"])

source = (MOD / "data-final-fixes.lua").read_text(encoding="utf-8")
known = (MOD / "known-cards.lua").read_text(encoding="utf-8")
settings = (MOD / "settings.lua").read_text(encoding="utf-8")
names = [
    line.split('"')[1] for line in known.splitlines()
    if line.strip().startswith('["se-')
]
assert len(names) == len(set(names)) == 81
for forbidden in ("se-significant-data", "se-broken-data", "se-empty-data", "se-junk-data"):
    assert forbidden not in names
for needle in (
    "is_primary_source(source, card)",
    "source_name = card",
    'hidden = true',
    'recipe = copy_name',
    'temperature = -100',
    'temperature = 25',
    'allow_productivity = false',
    'allow_quality = false',
    'can_set_quality = false',
    'auto_recycle = false',
    'include_probes',
    'tiered',
    'include_unknown',
    'KNOWN',
    "shared_probability",
    'icon_layers(item)',
    'SUMMARY recipes=',
):
    assert needle in source, needle
assert "for recipe_name in pairs(produces" not in source, "Broad by-product unlocking must not return"
for name in ("tiered-supercomputers", "include-unknown-cards", "include-probes"):
    marker = f'name = "se-data-duplicator-{name}"'
    assert marker in settings
    window = settings[settings.index(marker):]
    assert "default_value = false" in window[:125], f"Unsafe default for {name}"

png = (MOD / "graphics/icons/copy-badge.png").read_bytes()
assert png.startswith(bytes.fromhex("89504e470d0a1a0a"))
assert int.from_bytes(png[16:20], "big") == 64
assert int.from_bytes(png[20:24], "big") == 64
assert (MOD / "thumbnail.png").is_file()
assert (MOD / "LICENSE").is_file()
for lang in ("en", "ru"):
    locale = (MOD / "locale" / lang / "locale.cfg").read_text(encoding="utf-8")
    for name in ("include-probes", "tiered-supercomputers", "include-unknown-cards"):
        assert f"se-data-duplicator-{name}=" in locale

folder = f"{info['name']}_{info['version']}"
package = ROOT / "dist" / f"{folder}.zip"
with ZipFile(package) as z:
    for required in (
        "info.json", "settings.lua", "data-final-fixes.lua", "known-cards.lua",
        "graphics/icons/copy-badge.png", "locale/ru/locale.cfg", "locale/en/locale.cfg",
        "thumbnail.png", "LICENSE", "changelog.txt"
    ):
        assert f"{folder}/{required}" in z.namelist(), required
    assert json.loads(z.read(f"{folder}/info.json")) == info
    assert z.testzip() is None
    assert all(m.date_time == (1980, 1, 1, 0, 0, 0) for m in z.infolist()), "Package must be reproducible"
print(f"PASS: {package} ({package.stat().st_size} bytes; 81 audited cards, 10 files)")
