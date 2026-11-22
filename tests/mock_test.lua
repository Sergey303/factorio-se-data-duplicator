-- Executes the real prototype generator under a minimal simulated Factorio data stage.
-- Values passed as args: failure%, include_probes (true/false).
local failure = tonumber(arg[1]) or 10
local probes = arg[2] ~= "false"
local function machine()
  return {crafting_categories = {"space-supercomputing"}}
end

local machines = {
  ["se-space-supercomputer-1"] = machine(),
  ["se-space-supercomputer-2"] = machine(),
  ["se-space-supercomputer-3"] = machine(),
  ["se-space-supercomputer-4"] = machine()
}

data = {
  raw = {
    item = {
      ["se-empty-data"] = {icon = "a", icon_size = 64},
      ["se-junk-data"] = {icon = "b", icon_size = 64},
      ["se-broken-data"] = {icon = "c", icon_size = 64},
      ["se-significant-data"] = {icon = "d", icon_size = 64, subgroup = "data"},
      ["se-atomic-data"] = {icons = {{icon="e", icon_size=64}}, subgroup="data"},
      ["se-star-probe-data"] = {icon = "f", icon_size=64, subgroup="data"},
      ["se-rhga-data"] = {icon = "g", icon_size=64, subgroup="data"},
      ["se-data-storage-substrate"] = {icon = "h"}
    },
    fluid = {
      ["se-space-coolant-cold"] = {default_temperature = -100},
      ["se-space-coolant-hot"] = {default_temperature = 25}
    },
    ["recipe-category"] = {},
    ["assembling-machine"] = machines,
    recipe = {
      ["se-atomic-data"] = {results={{type="item",name="se-atomic-data",amount=1}},enabled=false},
      ["se-significant-data"] = {results={{type="item",name="se-significant-data",amount=4}},enabled=false},
      ["se-rhga-data"] = {results={{type="item",name="se-rhga-data",amount=1}},enabled=true}
    },
    technology = {
      ["se-space-supercomputer-1"] = {effects={}},
      ["se-space-catalogue-material-1"] = {effects={{type="unlock-recipe",recipe="se-significant-data"}}},
      ["se-space-catalogue-energy-2"] = {effects={{type="unlock-recipe",recipe="se-atomic-data"}}},
      ["se-space-catalogue-energy-3"] = {effects={{type="unlock-recipe",recipe="se-atomic-data"}}},
      ["se-space-catalogue-energy-4"] = {effects={}},
      ["se-space-catalogue-astronomic-4"] = {effects={}},
      ["se-deep-catalogue-1"] = {effects={}},
      ["se-deep-catalogue-4"] = {effects={}}
    }
  }
}
function data:extend(entries)
  for _, entry in ipairs(entries) do
    self.raw[entry.type] = self.raw[entry.type] or {}
    assert(not self.raw[entry.type][entry.name], "duplicate " .. entry.name)
    self.raw[entry.type][entry.name] = entry
  end
end
settings = {startup={}}
for key, value in pairs({
  ["se-data-duplicator-failure-percent"] = failure,
  ["se-data-duplicator-craft-seconds"] = 5,
  ["se-data-duplicator-coolant-amount"] = 10,
  ["se-data-duplicator-include-probes"] = probes
}) do
  settings.startup[key] = {value=value}
end
local last_log
function log(message) last_log = message end

dofile(arg[3])

local prefix = "se-data-duplicator-copy-"
local generated = 0
for name, recipe in pairs(data.raw.recipe) do
  if name:sub(1,#prefix) == prefix then
    generated=generated+1
    assert(#recipe.categories == 1 and recipe.categories[1] == "se-data-duplicator-copying")
    assert(recipe.category == nil, "Factorio 2.1 requires categories, not category")
    assert(#recipe.ingredients == 3)
    assert(recipe.ingredients[1].amount == 1)
    assert(recipe.ingredients[2].name == "se-empty-data")
    assert(recipe.ingredients[3].name == "se-space-coolant-cold")
    assert(recipe.ingredients[3].temperature == -100)
    assert(recipe.results[1].name == "se-space-coolant-hot" and recipe.results[1].temperature == 25)
    assert(recipe.results[1].amount == 10)
    assert(recipe.allow_productivity == false and recipe.allow_quality == false)
    assert(recipe.auto_recycle == false)
    local total_good, total_bad = 0, 0
    for _, result in ipairs(recipe.results) do
      if result.type == "item" then
        local share = result.shared_probability
        local chance = share and (share.max - share.min) or 1
        if result.name == "se-junk-data" then
          total_bad = total_bad + chance
          assert(result.amount == 2)
        else
          assert(result.name == name:sub(#prefix+1))
          assert(result.amount == 2)
          total_good = total_good + chance
        end
      end
    end
    assert(math.abs(total_good + total_bad - 1) < 1e-9)
    assert(math.abs(total_bad - failure/100) < 1e-9)
  end
end
assert(generated == (probes and 3 or 2))
-- Significant data remains an original SE research item but is never copied.
assert(not data.raw.recipe[prefix .. "se-significant-data"])
assert(data.raw.recipe["se-significant-data"])
assert(data.raw.recipe["se-significant-data"].results[1].amount == 4)
assert(not data.raw.recipe[prefix .. "se-empty-data"])
assert(not data.raw.recipe[prefix .. "se-broken-data"])
assert(not data.raw.recipe[prefix .. "se-junk-data"])
assert(not data.raw.recipe[prefix .. "se-data-storage-substrate"])
assert(data.raw.recipe[prefix .. "se-atomic-data"].icons[1].icon == "e")
assert(data.raw.recipe[prefix .. "se-rhga-data"])
assert(data.raw.recipe[prefix .. "se-star-probe-data"] ~= nil == probes)

local function tech_contains(tech, recipe)
  for _, effect in ipairs(data.raw.technology[tech].effects or {}) do
    if effect.recipe == recipe then return true end
  end
  return false
end
assert(not tech_contains("se-space-catalogue-material-1", prefix .. "se-significant-data"))
assert(tech_contains("se-space-catalogue-material-1", "se-significant-data"))
assert(tech_contains("se-space-catalogue-energy-2", prefix .. "se-atomic-data"))
assert(tech_contains("se-space-catalogue-energy-3", prefix .. "se-atomic-data"))
assert(tech_contains("se-space-supercomputer-1", prefix .. "se-rhga-data"))
if probes then
  assert(tech_contains("se-space-catalogue-energy-4", prefix .. "se-star-probe-data"))
end
for _, machine in pairs(machines) do
  local count=0
  for _, category in ipairs(machine.crafting_categories) do
    if category=="se-data-duplicator-copying" then count=count+1 end
  end
  assert(count==1)
end
assert(last_log:find("Generated " .. generated .. " copying recipes"))
print("OK: failure=" .. failure .. "%, probes=" .. tostring(probes) .. ", recipes=" .. generated)
