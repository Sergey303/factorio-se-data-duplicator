# SE Data Duplicator

An optional Space Exploration addon for **Factorio 2.1 / SE 0.7.64+**.

**GitHub repository:** https://github.com/Sergey303/factorio-se-data-duplicator  
**Factorio mod ID:** `se-data-duplicator`

**Status:** 0.1.2 fixes the output thermofluid prototype in 0.1.1; Factorio game-level testing remains pending.

## Recipe

Every discovered item whose prototype name matches `se-*-data` (except empty/junk/broken data) gets a copying recipe:

- **Inputs**: 1 data card of the selected type + 1 `se-empty-data` + 10 `se-space-coolant-cold` (-100°C).
- **Outputs**: 90% chance of **2 cards of the same type**, OR 10% chance of **2 `se-junk-data`**. Additionally, **10 `se-space-coolant-hot` (+25°C)** are **always** returned.
- **Default duration**: 5 seconds at speed 1.
- **Machines**: SE Supercomputers 1–4 only.
- **No productivity, quality upgrades or recycling** for copying recipes.

The failure roll uses Factorio 2.1's `shared_probability` on mutually exclusive products: it is **not** two independent random probabilities.

### Startup settings

| Setting | Default | Range |
|---|---:|---:|
| Failure probability | 10% | 0–100% |
| Time per copy | 5 s | 1–120 s |
| Coolant per copy | 10 units | 1–1000 |
| Include probe data | Yes | On/off |

One recipe is added for each matching filled-card **item prototype**, not for each alternative production recipe. `se-significant-data` is treated like any other card. If an original recipe has technology unlocks, those technologies also unlock the copy recipe. Cards with no matching unlock use late fallback technologies (counted in `factorio-current.log`).

### Install

Put `se-data-duplicator_0.1.2.zip` into your Factorio `mods` directory. It contains the required root folder `se-data-duplicator_0.1.2/`. Keep the required Space Exploration dependencies installed. Enable the mod and restart Factorio after changing startup settings.

### Compatibility and test status

- Static and mocked-prototype checks are provided in `tests/`.
- **Actual Factorio + SE game loading and crafting have not yet been performed**. The mod should be treated as a first integration candidate until that test passes.
- Compatibility applies to the named 2.1 / SE 0.7.x family; **SE 0.6 with Factorio 1.1 is not supported**.
- A new SE item ending in `-data` is auto-detected. Items without source recipe unlocks use the latest catalogue as a conservative fallback; this should be checked after every SE update.

### Maintainer test checklist

1. Run with Factorio 2.1 and SE 0.7.64+; inspect `factorio-current.log` for generated recipe count and fallback warnings.
2. Check that `se-significant-data` has exactly one copying recipe, and junk/broken/empty cards do not.
3. Check unlocks in a clean save and a save with researched technologies.
4. Verify each of the 4 supercomputers can select the new recipe and accept/return fluids on the right ports.
5. Run 10,000 crafts at 10% failure, expecting failure count near 1,000 (statistical variation permitted).
6. Check that each attempt returns exactly two cards of one type and exactly 10 units of +25°C thermofluid.
7. Confirm no accidental productivity/quality multipliers and no recycler duplication.

## Sources

- https://mods.factorio.com/mod/space-exploration/downloads
- https://lua-api.factorio.com/latest/types/ProductPrototypeBase.html
- https://lua-api.factorio.com/latest/prototypes/RecipePrototype.html
- https://tbe.gg/factorio-space-exploration/items/se-significant-data
- https://tbe.gg/factorio-space-exploration/items/se-space-coolant-cold

### Developing and packaging

```sh
python3 tests/run_mock_tests.py
python3 tools/package_mod.py
python3 tests/check_package.py
```

The mock tests require `liblua5.4` installed on the host. The packager needs only Python 3.
The CI runs these checks but is **not** a substitute for loading the addon with SE in the actual game.
