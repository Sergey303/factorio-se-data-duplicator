#!/usr/bin/env python3
"""Audit SE 0.7.64 data-card coverage against the original installed Space Exploration ZIP.

This is a *source-based* contract, not a substitute for a game-engine data.raw dump.
No game process is started. It never modifies the SE ZIP or Factorio saves.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import re
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "mod" / "known-cards.lua"
REQUIRED_EXCLUSIONS = {"se-empty-data", "se-junk-data", "se-broken-data", "se-significant-data"}
PROBES = {"se-belt-probe-data", "se-star-probe-data", "se-void-probe-data"}
BASE = "space-exploration_0.7.64/"
ITEM_SOURCE = "prototypes/phase-1/item/items.lua"
TECH_SOURCE = "prototypes/phase-1/technology/technology.lua"


def uncomment(source: str) -> str:
    # SE's relevant declarations use simple Lua comments, not dynamically
    # generated item names; the scanner is deliberately source-specific.
    source = re.sub(r"--\[\[.*?\]\]", "", source, flags=re.DOTALL)
    return re.sub(r"--[^\n]*", "", source)


def item_names(source: str) -> set[str]:
    source = uncomment(source)
    found: set[str] = set()
    for match in re.finditer(
        r'make_data_item_sequence\("([^"]+)",\s*\{(.*?)\}\s*[,)]',
        source, flags=re.DOTALL
    ):
        found.update(
            "se-" + suffix + "-data"
            for suffix in re.findall(r'"([a-z][a-z0-9-]*)"', match.group(2))
        )
    found.update(
        "se-" + name for name in re.findall(
            r'name\s*=\s*data_util\.mod_prefix\s*\.\.\s*"([a-z0-9-]+-data)"',
            source
        )
    )
    return found - REQUIRED_EXCLUSIONS


def catalogue_unlocks(source: str) -> dict[str, list[str]]:
    source = uncomment(source)
    mapping: dict[str, set[str]] = {}
    pattern = r'name\s*=\s*data_util\.mod_prefix\s*\.\.\s*"((?:space-catalogue-(?:astronomic|biological|energy|material)|deep-catalogue)-[1-4])"'
    for match in re.finditer(pattern, source):
        technology = "se-" + match.group(1)
        # All catalogue technologies in SE 0.7.64 put effects before icons.
        remainder = source[match.end():]
        boundary = remainder.find("icons =")
        if boundary < 0 or boundary > 1800:
            raise AssertionError(f"Cannot find effects boundary for {technology}")
        region = remainder[:boundary]
        for product in re.findall(
            r'type\s*=\s*"unlock-recipe"\s*,\s*recipe\s*=\s*data_util\.mod_prefix\s*\.\.\s*"([a-z0-9-]+-data)"',
            region
        ):
            mapping.setdefault("se-" + product, set()).add(technology)
    return {name: sorted(techs) for name, techs in sorted(mapping.items())}


def expected_manifest() -> set[str]:
    text = MANIFEST.read_text(encoding="utf-8")
    result = re.findall(r'\["(se-[a-z0-9-]+-data)"\]\s*=\s*true', text)
    assert len(result) == len(set(result)), "Duplicate names in known-cards.lua"
    return set(result)


def run(path: Path, output: Path | None) -> dict:
    with ZipFile(path) as z:
        source = z.read(BASE + ITEM_SOURCE).decode("utf-8")
        tech_source = z.read(BASE + TECH_SOURCE).decode("utf-8")
        discovered = item_names(source)
        manifest = expected_manifest()
        unlocked = catalogue_unlocks(tech_source)
        recipe_sources = [
            name for name in z.namelist()
            if name.endswith(".lua") and "/recipe/" in name
        ]
        recipe_text = "\n".join(z.read(name).decode("utf-8", errors="replace")
                                for name in recipe_sources)

    source_mentions = sorted(
        card for card in discovered - PROBES
        if re.search(r'\bname\s*=\s*data_util\.mod_prefix\s*\.\.\s*"'
                     + re.escape(card.removeprefix("se-")) + r'"', recipe_text)
    )
    result = {
        "se_zip": path.name,
        "item_source": ITEM_SOURCE,
        "technology_source": TECH_SOURCE,
        "verified_cards_count": len(discovered),
        "manifest_cards_count": len(manifest),
        "normal_cards_count": len(discovered - PROBES),
        "probe_cards": sorted(discovered & PROBES),
        "missing_in_manifest": sorted(discovered - manifest),
        "extra_in_manifest": sorted(manifest - discovered),
        "catalogue_research_card_count": len(set(unlocked).intersection(discovered)),
        "catalogue_unlocks": {name: techs for name, techs in unlocked.items()
                              if name in discovered},
        "without_catalogue_unlock": sorted(discovered - set(unlocked)),
        "mentioned_in_recipe_sources": len(source_mentions),
        "without_recipe_source_mentions": sorted(discovered - PROBES - set(source_mentions)),
        "scope": "static Space Exploration 0.7.64 Lua sources; not effective modded data.raw"
    }
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                          encoding="utf-8")
    assert len(discovered) == 81, "SE source 0.7.64 data-card count changed"
    assert len(discovered & PROBES) == 3
    assert not (discovered ^ manifest), "Known-card manifest differs from the SE 0.7.64 ZIP"
    assert not result["without_recipe_source_mentions"], "Potential missing primary recipe sources"
    assert len(set(unlocked).intersection(discovered)) >= 75
    return result


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("se_zip", nargs="?",
                    help="Installed space-exploration_0.7.64.zip (read-only)")
    ap.add_argument("--output", type=Path, help="Save independent JSON audit")
    args = ap.parse_args()
    if args.se_zip:
        path = Path(args.se_zip)
    elif os.name == "nt":
        path = Path(os.environ["APPDATA"]) / "Factorio/mods/space-exploration_0.7.64.zip"
    else:
        ap.error("Please supply path to installed SE 0.7.64 ZIP")
    summary = run(path, args.output)
    print("PASS: SE=0.7.64 cards={verified_cards_count} normal={normal_cards_count} "
          "probes=3 source-tech={catalogue_research_card_count} "
          "primary-name-mentions={mentioned_in_recipe_sources}".format(**summary))
    if args.output:
        print("JSON audit:", args.output)
