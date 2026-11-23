# Technology unlock audit — SE 0.7.64

This audit is based on the locally installed `space-exploration_0.7.64.zip` source, `prototypes/phase-1/technology/technology.lua`, and the active Factorio log (2026-11-23). Counts are from static primary SE technology definitions, not a full reconstruction of all mods' final prototypes.

## Why Deep Catalogue 2 showed extra recipes

The original SE technology `se-deep-catalogue-2` unlocks exactly these four named data recipes:
- `se-singularity-data`
- `se-hyperlattice-data`
- `se-timespace-anomaly-data`
- `se-annihilation-data`

SE Data Duplicator injected an additional copy unlock for each. The result was correct timing but unwanted extra technology-effect icons.

Version 0.1.5 inserts `{type="unlock-recipe", recipe=copy_name, hidden=true}`. Factorio 2.1 documents `hidden` on each unlock modifier. It only hides this **additional effect** from the UI, not the original card recipe or the ability to craft the copy.

## Other main catalogue technologies with the same visual effect

| SE technology | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---:|---:|---:|---:|
| `se-space-catalogue-astronomic` | 5 | 4 | 4 | 3 |
| `se-space-catalogue-biological` | 4 | 4 | 4 | 4 |
| `se-space-catalogue-material` | 5 | 4 | 4 | 4 |
| `se-space-catalogue-energy` | 4 | 4 | 4 | 3 |
| `se-deep-catalogue` | 3 | 4 | 4 | 4 |

Each count is the number of data-recipe unlock entries in that original technology. All 20 catalogue technologies may show extra duplication icons in 0.1.4. The 0.1.5 hidden-effect change covers them all without changing unlock timing.

## Runtime data

The installed game log contains:
`[SE Data Duplicator] Generated 81 copying recipes (3 fallback unlocks), 10% failure, 5s, 10 coolant`.

The mock suite contains 14 scenarios with various failure probabilities and probes included/excluded.

## Remaining risks (not yet verified as concrete failures)

1. **Over-broad origin association.** The generator considers *any* recipe that returns a data card, including possible secondary products and alternate sources; multiple technologies may therefore unlock the same copy recipe or unlock it prematurely. Restrict to authoritative primary production recipes after auditing the actual combined prototypes.
2. **Three fallback unlocks.** The game log does not list their names, so verify them individually against special probe/event-based acquisition. Fallbacks could make a recipe available too early or too late.
3. **Discovery gaps.** Cards of other item prototype types or names not matching `^se%-.+%-data$` are skipped.
4. **Upgrade compatibility.** Prototype names and categories can change in SE, and old saves should be checked after update.

## Recommended in-game acceptance

1. In an existing save, inspect `se-deep-catalogue-2`: it should show the 4 original data recipes and no addon copy icons.
2. Verify that the 4 copy recipes still appear in a suitable SE supercomputer after research.
3. Confirm `se-significant-data` cannot be copied.
4. Repeat with another catalogue in Astronomic/Material/Biological/Energy families.
5. Note any copy that unlocks earlier than its primary original recipe.

Official API: https://lua-api.factorio.com/latest/types/UnlockRecipeModifier.html
