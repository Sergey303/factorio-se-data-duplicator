-- Integration-style prototype mock for all 81 SE 0.7.64 data cards.
-- arg[1]=failure; arg[2]=probes; arg[3]=data-final-fixes.lua
-- arg[4]=known-cards.lua; arg[5]=tiered; arg[6]=unknown
local failure = tonumber(arg[1]) or 10
local probes = arg[2] == "true"
local tiered = arg[5] == "true"
local unknown = arg[6] == "true"
local known = dofile(arg[4])
package.preload["__se-data-duplicator__.known-cards"] = function() return known end

local machine_names = {}
local machines = {}
for index = 1, 4 do
  local name = "se-space-supercomputer-" .. index
  machine_names[#machine_names + 1] = name
  machines[name] = {crafting_categories = {"space-supercomputing-" .. index}}
end
local raw_items = {}
local recipes = {}
local technologies = {}
local function item(name, subgroup)
  raw_items[name] = {icon = "fixture/" .. name .. ".png", icon_size = 64, subgroup = subgroup or "data-energy", order = name}
end
local function tech(name)
  if not technologies[name] then technologies[name] = {effects = {}} end
  return technologies[name]
end
local function unlock(tech_name, recipe_name)
  local t = tech(tech_name)
  t.effects[#t.effects + 1] = {type = "unlock-recipe", recipe = recipe_name}
end

local count, num_probes = 0, 0
for card in pairs(known) do
  count = count + 1
  item(card)
  local is_probe = card:find("probe") ~= nil
  if is_probe then num_probes = num_probes + 1 end
  if not is_probe then
    local t = "se-space-catalogue-material-1"
    if card == "se-atomic-data" then t = "se-space-catalogue-energy-2" end
    if card == "se-singularity-data" or card == "se-hyperlattice-data" or card == "se-timespace-anomaly-data"
        or card == "se-annihilation-data" then
      t = "se-deep-catalogue-2"
    end
    if card == "se-teleportation-data" then t = "se-deep-catalogue-4" end
    local enabled = card == "se-machine-learning-data"
    recipes[card] = {
      enabled = enabled,
      main_product = card,
      results = {{type = "item", name = card, amount = 1}}
    }
    if not enabled then unlock(t, card) end
  end
end
assert(count == 81 and num_probes == 3, "SE 0.7.64 card list is incomplete")
for _, techname in ipairs({
  "se-space-supercomputer-1", "se-space-catalogue-material-1",
  "se-space-catalogue-energy-2", "se-space-catalogue-astronomic-1",
  "se-space-catalogue-astronomic-4", "se-space-catalogue-energy-4",
  "se-deep-catalogue-1", "se-deep-catalogue-2", "se-deep-catalogue-4"
}) do tech(techname) end

-- An intentionally unrelated recipe returns atomic data as a side product
-- and is unlocked BEFORE atomic data is available. It must not grant copying.
recipes["se-unrelated-early-experiment"] = {
  enabled = false,
  main_product = "se-mystery-product",
  results = {
    {type = "item", name = "se-mystery-product", amount = 1},
    {type = "item", name = "se-atomic-data", amount = 1}
  }
}
unlock("se-space-catalogue-astronomic-1", "se-unrelated-early-experiment")

-- Unknown names are opt-in, must be in a data subgroup and have a
-- verified primary production recipe and unlock.
for _, spec in ipairs({
  {"se-foreign-data", "data-custom", true},
  {"se-suspicious-data", "equipment", true},
  {"se-orphan-data", "data-custom", false}
}) do
  local name, subgroup, produced = spec[1], spec[2], spec[3]
  item(name, subgroup)
  if produced then
    recipes[name] = {enabled = false, main_product = name, results = {{type = "item", name = name, amount = 1}}}
    unlock("se-space-catalogue-material-1", name)
  end
end
item("se-empty-data", "data-generic")
item("se-junk-data", "data-generic")
item("se-broken-data", "data-generic")
item("se-significant-data", "data-significant")
recipes["se-significant-data"] = {enabled = false, results = {{type = "item", name = "se-significant-data", amount = 4}}}
unlock("se-space-catalogue-material-1", "se-significant-data")

data = {
  raw = {
    item = raw_items,
    recipe = recipes,
    technology = technologies,
    fluid = {
      ["se-space-coolant-cold"] = {default_temperature = -100},
      ["se-space-coolant-hot"] = {default_temperature = 25}
    },
    ["recipe-category"] = {},
    ["assembling-machine"] = machines
  }
}
function data:extend(entries)
  for _, entry in ipairs(entries) do
    self.raw[entry.type] = self.raw[entry.type] or {}
    assert(not self.raw[entry.type][entry.name], "duplicate prototype: " .. entry.name)
    self.raw[entry.type][entry.name] = entry
  end
end
settings = {startup = {}}
for key, value in pairs({
  ["failure-percent"] = failure,
  ["craft-seconds"] = 5,
  ["coolant-amount"] = 10,
  ["include-probes"] = probes,
  ["tiered-supercomputers"] = tiered,
  ["include-unknown-cards"] = unknown
}) do settings.startup["se-data-duplicator-" .. key] = {value = value} end
local logs = {}
function log(message) logs[#logs + 1] = message end

dofile(arg[3])

local prefix = "se-data-duplicator-copy-"
local generated_count = 0
local expected = 78 + (probes and 3 or 0) + (unknown and 1 or 0)
local expected_fail = failure / 100
for name, recipe in pairs(data.raw.recipe) do
  if name:sub(1, #prefix) == prefix then
    generated_count = generated_count + 1
    local card = name:sub(#prefix + 1)
    assert(known[card] or card == "se-foreign-data")
    assert(#recipe.ingredients == 3)
    assert(recipe.ingredients[1].name == card and recipe.ingredients[1].amount == 1)
    assert(recipe.ingredients[2].name == "se-empty-data" and recipe.ingredients[2].amount == 1)
    assert(recipe.ingredients[3].name == "se-space-coolant-cold" and recipe.ingredients[3].amount == 10)
    assert(recipe.ingredients[3].temperature == -100)
    assert(recipe.results[1].name == "se-space-coolant-hot" and recipe.results[1].temperature == 25)
    assert(recipe.results[1].amount == 10)
    assert(recipe.allow_quality == false and recipe.can_set_quality == false)
    assert(recipe.allow_productivity == false and recipe.maximum_productivity == 0)
    assert(recipe.auto_recycle == false)
    assert(recipe.icons[#recipe.icons].icon == "__se-data-duplicator__/graphics/icons/copy-badge.png")
    assert(recipe.category == nil and #recipe.categories == 1)
    local minimum_tier = 1
    if card == "se-atomic-data" then minimum_tier = 2 end
    if card == "se-singularity-data" then minimum_tier = 3 end
    if card == "se-teleportation-data" then minimum_tier = 4 end
    if card == "se-void-probe-data" then minimum_tier = 3 end
    if tiered then
      if card == "se-atomic-data" or card == "se-singularity-data" or card == "se-teleportation-data"
          or card == "se-void-probe-data" then
        assert(recipe.categories[1] == "se-data-duplicator-copying-" .. minimum_tier)
      end
    else
      assert(recipe.categories[1] == "se-data-duplicator-copying-1")
    end
    local probability_good, probability_junk = 0, 0
    for _, product in ipairs(recipe.results) do
      if product.type == "item" then
        assert(product.amount == 2)
        local chance = product.shared_probability
        local prob = chance and (chance.max - chance.min) or 1
        if product.name == card then probability_good = probability_good + prob
        elseif product.name == "se-junk-data" then probability_junk = probability_junk + prob
        else error("unexpected product " .. product.name) end
      end
    end
    assert(math.abs(probability_good - (1 - expected_fail)) < 1e-9)
    assert(math.abs(probability_junk - expected_fail) < 1e-9)
  end
end
assert(generated_count == expected, "incorrect recipe count " .. generated_count .. " vs " .. expected)
for _, name in ipairs({
  "se-significant-data", "se-empty-data", "se-junk-data", "se-broken-data",
  "se-suspicious-data", "se-orphan-data"
}) do assert(not data.raw.recipe[prefix .. name], "incorrectly duplicated " .. name) end
assert(not data.raw.recipe[prefix .. "se-belt-probe-data"] == (not probes))
assert(data.raw.recipe["se-significant-data"].results[1].amount == 4)

local function tech_effect(tech_name, recipe_name)
  for _, effect in ipairs(technologies[tech_name].effects) do
    if effect.recipe == recipe_name then return effect end
  end
end
local atomic_copy = prefix .. "se-atomic-data"
assert(not tech_effect("se-space-catalogue-astronomic-1", atomic_copy),
    "side-product caused an early unlock")
assert(tech_effect("se-space-catalogue-energy-2", atomic_copy).hidden == true)
assert(tech_effect("se-space-catalogue-energy-2", "se-atomic-data").hidden ~= true)
assert(not tech_effect("se-space-catalogue-material-1", prefix .. "se-significant-data"))
assert(tech_effect("se-space-catalogue-material-1", "se-significant-data"))
for i = 1, 4 do
  local machine = machines[machine_names[i]]
  for level = 1, 4 do
    local found = false
    for _, category in ipairs(machine.crafting_categories) do
      if category == "se-data-duplicator-copying-" .. level then found = true end
    end
    assert(found == (i >= level), "computer categories wrong " .. i .. "," .. level)
  end
end
local map_count, summary = 0, false
for _, line in ipairs(logs) do
  if line:find("] MAP card=", 1, true) then map_count = map_count + 1 end
  if line:find("] SUMMARY", 1, true) then
    summary = true
    assert(line:find("recipes=" .. generated_count, 1, true))
  end
end
assert(summary and map_count == expected)
print("PASS failure=" .. failure .. " probes=" .. tostring(probes) ..
    " tiered=" .. tostring(tiered) .. " unknown=" .. tostring(unknown) ..
    " count=" .. generated_count)
