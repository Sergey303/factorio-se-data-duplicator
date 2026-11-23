# SE Data Duplicator

Unofficial Space Exploration add-on for **Factorio 2.1 / SE 0.7.64+**.

**Current ZIP: version 0.1.5, unpublished.** The version remains 0.1.5 because it has not been released on the Factorio Mod Portal.

## Recipe

One filled data card + one blank data card + 10 cold thermofluid (−100°C) in an SE supercomputer:

- **90% (default):** 2 copies of the original data card.
- **10% (default):** 2 junk data cards instead.
- **Always:** 10 thermofluid at +25°C.
- **5 seconds**, before machine speed modifiers.
- No productivity, quality upgrades, or automatic recycling.

The mutually exclusive outcomes use Factorio 2.1's `shared_probability`. Original SE recipes remain unchanged. Significant data, empty, junk and broken cards are excluded.

## Final 0.1.5 improvements

1. **81 verified names.** The SE 0.7.64 source contains 78 ordinary data items and 3 probe data items, stored in `mod/known-cards.lua`. New data names are skipped and logged unless explicitly opted in.
2. **Primary-recipe unlocking.** A card's copy is unlocked via its *own* production recipe, not every recipe that returns the card as an unrelated by-product.
3. **Probe data off by default.** The three probe types require an explicit startup opt-in, because rocket launches produce them in bulk.
4. **Optional machine-tier restrictions.** When enabled, a late data card requires a more advanced supercomputer. Disabled by default to preserve the original design and existing factories.
5. **Distinct icon.** Each copying recipe has a small overlay with two overlapping cards; original SE item icons are untouched.
6. **Clean technology screen.** Extra copy-unlock effects use `hidden = true` without hiding original SE unlocks.
7. **Complete diagnostics.** One `MAP card=...` line per generated recipe plus skipped-item warnings and a summary.
8. **Safer compatibility.** Unknown or unmappable nonessential cards are skipped with warnings rather than preventing game startup. Missing SE core fluids, blank cards or machines still trigger clear errors.

### Startup settings

| Option | Default | Range |
|---|---|---|
| Failure chance | 10% | 0–100% |
| Copy duration | 5 s | 1–120 s |
| Coolant per attempt | 10 | 1–1000 |
| Copy probe data | **Off** | On/off |
| Enforce minimum supercomputer tier | **Off** | On/off |
| Try future unknown SE data | **Off** | On/off; needs a verified main recipe and research |

If updating from versions where probe data copying was enabled by default, **review your saved startup settings**, as Factorio may retain the previous value.

On SE 0.7.64, defaults produce **78 recipes**. With probe copying on, **81**. The log shows the real number for a modded setup.

### Supercomputer tiers

With the optional tier mode enabled:

- Research levels 1–4 of the four regular catalogue branches require supercomputers I–IV.
- Deep Space 1–2 require III; Deep Space 3–4 require IV.
- Probe data follows appropriate conservative machine categories.
- Later supercomputers also support recipes requiring earlier tiers.

With tier mode disabled, all SE supercomputers I–IV can copy cards.

### Technology/source selection

- Known normal data cards must have a verified **primary** source recipe with their own name and result.
- Only technologies that unlock that primary recipe can unlock its copy. Initially enabled recipes are gated on Supercomputer I.
- Probe data is launch output, not a crafting recipe. When enabled, the three probes are attached to conservative catalogue technologies.
- Unknown future data names are skipped unless the setting explicitly allows them; even then an item must belong to a data subgroup and have a trusted primary source.
- Missing optional source links are recorded as warnings.

## Installation

Put `se-data-duplicator_0.1.5.zip` in Factorio's `mods` folder without extracting it. Remove older ZIPs of this addon and restart Factorio after changing startup settings.

## Verification

```sh
python3 tests/run_mock_tests.py
python3 tools/package_mod.py
python3 tests/check_package.py
```

The mock suite executes the actual generator with **all 81 card names** in **56 combinations** of failure percentages, probe on/off, tiered mode, and unknown-name policy. It also tests improper by-product unlocks, exclusions, modules, coolant and icon layers. It needs `liblua5.4` installed.

To compare against the *installed* SE 0.7.64 ZIP without touching a save:

```sh
python3 tools/audit_se_source.py /path/to/space-exploration_0.7.64.zip --output audit.json
```

On Windows with default Factorio userdata you may omit the ZIP path. This produces a read-only source-derived inventory and original technology references.

**Important:** mock tests and source scanning are not the same as a game-engine run against all enabled mods. A previous 0.1.5 version's basic copying was tested in-game; the upgraded package still needs a fresh Factorio game-load and save regression test.

## Release

See [PUBLISHING.md](PUBLISHING.md) for portal description and metadata. The ZIP includes `thumbnail.png` and an MIT license.

Source code: https://github.com/Sergey303/factorio-se-data-duplicator
