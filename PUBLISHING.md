# Factorio Mod Portal: SE Data Duplicator

## Metadata

- **Internal name:** `se-data-duplicator` (must not be changed)
- **Display title:** SE Data Duplicator
- **Category:** Tweaks (`tweaks`)
- **Tags:** Manufacturing (`manufacturing`), Fluids (`fluids`)
- **License:** MIT (`default_mit`)
- **Source URL:** https://github.com/Sergey303/factorio-se-data-duplicator
- **Homepage:** https://github.com/Sergey303/factorio-se-data-duplicator
- **Factorio:** 2.1
- **Dependency:** Space Exploration 0.7.64+
- **Thumbnail:** `mod/thumbnail.png` (generated pixel-art illustration, not gameplay footage).

## Short summary (English)

Duplicate Space Exploration data cards in supercomputers with a chance of failure. Uses cold thermofluid, produces two matching cards or two junk cards. Significant data is deliberately excluded.

## Description (English, Markdown)

# SE Data Duplicator

Tired of repeatedly producing the same research data? **SE Data Duplicator** adds copying recipes for Space Exploration data cards, without making the process completely risk-free.

## How it works

In an SE supercomputer, combine:
- **1 filled data card** of the type you want to copy
- **1 blank data card**
- **10 units of cold thermofluid (−100 °C)**

After **5 seconds** (before machine speed modifiers), the machine produces **either**:
- **90% chance:** 2 cards containing the same type of data
- **10% chance:** 2 junk data cards, with both input cards consumed

**Always returned:** 10 units of thermofluid at **+25 °C**, even if copying fails.

## Balance and compatibility

- **Significant data cannot be duplicated.** Neither can blank, junk or broken data cards.
- Works in SE supercomputers I–IV, not in ordinary assembling machines.
- Copying recipes follow existing SE research unlocks; special probe data can optionally be included.
- Productivity, item quality upgrades and automatic recycling are disabled for these recipes.
- Does not change the original Space Exploration recipes.
- Startup settings control failure chance (0–100%), copying duration (1–120 s), coolant amount (1–1000), and probe card support.
- Requires **Factorio 2.1** and **Space Exploration 0.7.64+**.

This is an unofficial community addon for Space Exploration. The pixel-art thumbnail is illustrative, not a screenshot.

**Source code / issues:** https://github.com/Sergey303/factorio-se-data-duplicator

## Known limitations

The addon finds data cards from SE item prototypes. An SE update or other mods that rename machine, fluid, data card, or technology prototypes may require an addon update. One ordinary copying recipe and the exclusion of Significant data have been tested in-game; automated mock tests cover 14 scenarios, but not every card and supercomputer combination.

## Short summary (Russian)

Копирование карт данных Space Exploration в суперкомпьютерах с риском получить две мусорные карты. Требуется термофлюид −100 °C, возвращается +25 °C. «Важные данные» не копируются.

## Описание (русский)

**SE Data Duplicator** добавляет рецепты копирования карт данных Space Exploration в суперкомпьютеры SE I–IV.

**1 заполненная карта + 1 чистая карта + 10 термофлюида −100 °C →**
- **90%:** 2 карты того же типа;
- **10%:** 2 мусорные карты.

10 единиц термофлюида +25 °C возвращаются в любом случае. Копирование занимает 5 секунд до модификаторов скорости машины.

**«Важные данные» исключены**, как и пустые, сломанные и мусорные карты. Продуктивность, улучшение качества и автоматическая переработка рецептов отключены. Рецепты следуют технологиям SE; данные зондов можно включать или отключать. В настройках доступны вероятность брака, время, расход охлаждения.

Требуются Factorio 2.1 и Space Exploration 0.7.64+. Мод неофициальный, исходники: https://github.com/Sergey303/factorio-se-data-duplicator

## Publish checklist

1. Keep the actual ZIP filename `se-data-duplicator_0.1.4.zip` and its single root folder `se-data-duplicator_0.1.4/`.
2. Check for `info.json`, `thumbnail.png`, `LICENSE`, `settings.lua`, `data-final-fixes.lua` inside that folder.
3. Select Category **Tweaks**, tags **Manufacturing** and **Fluids**, license **MIT**.
4. Set the source and homepage URL to the GitHub repository.
5. Paste the English summary and Markdown description from this file.
6. Upload the release ZIP. Do not describe the illustrative thumbnail as a screenshot.
7. Confirm a clean Factorio load and check the recipes against the in-game installed SE version before marking the release as fully verified.

## Potential error symptoms

- **Missing SE item / thermofluid / supercomputer**: a prototype was renamed or removed, a dependency version differs, or another mod replaces it.
- **Could not unlock copy of ...; missing technology**: generated card has no source unlock and the fallback research prototype is absent.
- **Recipe category already exists / duplicate recipe**: another mod registers the same internal name.
- **Recipe exists but does not run**: unmet technology, incorrect machine, coolant fluidbox direction or connection, missing −100 °C input, or blocked +25 °C output.
- **An expected card has no copy recipe**: it does not match the SE data-card item naming convention or belongs to a different prototype type.
