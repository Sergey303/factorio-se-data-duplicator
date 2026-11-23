-- SE Data Duplicator 0.1.5.
-- All changes happen in Factorio's prototype stage; no gameplay events are needed.
-- 0.7.64 baseline is an audited list, NOT a promise to copy arbitrary future "-data" items.
local KNOWN = require("__se-data-duplicator__.known-cards")
local PREFIX = "se-data-duplicator-copy-"
local CATEGORY = "se-data-duplicator-copying-"
local MACHINE_PREFIX = "se-space-supercomputer-"
local EMPTY, JUNK, SIGNIFICANT = "se-empty-data", "se-junk-data", "se-significant-data"
local COLD, HOT = "se-space-coolant-cold", "se-space-coolant-hot"
local BADGE = "__se-data-duplicator__/graphics/icons/copy-badge.png"
local PROBE_TECH = {
  ["se-belt-probe-data"] = {"se-space-catalogue-astronomic-4", 1},
  ["se-star-probe-data"] = {"se-space-catalogue-energy-4", 1},
  ["se-void-probe-data"] = {"se-deep-catalogue-1", 3}
}
local RESERVED = {
  [EMPTY] = true, [JUNK] = true, [SIGNIFICANT] = true,
  ["se-broken-data"] = true
}

local function opt(key)
  return settings.startup["se-data-duplicator-" .. key].value
end

local function assert_proto(kind, name)
  if not (data.raw[kind] and data.raw[kind][name]) then
    error("[SE Data Duplicator] Missing required " .. kind .. ": " .. name, 0)
  end
end

local fail_percent = opt("failure-percent")
local fail = fail_percent / 100
local craft_seconds = opt("craft-seconds")
local coolant = opt("coolant-amount")
local include_probes = opt("include-probes")
local tiered = opt("tiered-supercomputers")
local include_unknown = opt("include-unknown-cards")

assert_proto("item", EMPTY)
assert_proto("item", JUNK)
assert_proto("fluid", COLD)
assert_proto("fluid", HOT)
for i = 1, 4 do
  assert_proto("assembling-machine", MACHINE_PREFIX .. i)
  assert(not (data.raw["recipe-category"] and data.raw["recipe-category"][CATEGORY .. i]),
    "[SE Data Duplicator] Recipe category already exists: " .. CATEGORY .. i)
end

-- Each tier is supported by this supercomputer and all its successors.
local category_prototypes = {}
for tier = 1, 4 do
  category_prototypes[#category_prototypes + 1] =
      {type = "recipe-category", name = CATEGORY .. tier}
end
data:extend(category_prototypes)
for computer = 1, 4 do
  local entity = data.raw["assembling-machine"][MACHINE_PREFIX .. computer]
  entity.crafting_categories = entity.crafting_categories or {}
  for tier = 1, computer do
    local category = CATEGORY .. tier
    local present = false
    for _, original in ipairs(entity.crafting_categories) do
      if original == category then present = true; break end
    end
    if not present then table.insert(entity.crafting_categories, category) end
  end
end

local function is_data_card(name)
  return name:match("^se%-.+%-data$") ~= nil and not RESERVED[name]
end

local function is_probe(name)
  return PROBE_TECH[name] ~= nil
end

-- Product matching is intentionally limited to the card's *own* recipe,
-- not every random recipe which may return that card as a secondary product.
local function is_primary_source(recipe, card)
  if not recipe or recipe.main_product and recipe.main_product ~= card then return false end
  for _, product in ipairs(recipe.results or {}) do
    if product.type == "item" and product.name == card then return true end
  end
  return false
end

local technology_for_recipe = {}
for technology_name, technology in pairs(data.raw.technology or {}) do
  for _, effect in ipairs(technology.effects or {}) do
    if effect.type == "unlock-recipe" and effect.recipe then
      local found = technology_for_recipe[effect.recipe]
      if not found then
        found = {}
        technology_for_recipe[effect.recipe] = found
      end
      found[technology_name] = true
    end
  end
end

local function required_tier(tech_name)
  local family, tier = tech_name:match("^se%-space%-catalogue%-(%a+)%-(%d)$")
  if family and tier then return tonumber(tier) end
  local deep = tech_name:match("^se%-deep%-catalogue%-(%d)$")
  if deep then return math.max(3, tonumber(deep)) end
  return 1
end

local function icon_layers(item)
  local icons = {}
  if item.icons and #item.icons > 0 then
    for _, layer in ipairs(item.icons) do
      local copied = table.deepcopy and table.deepcopy(layer) or {}
      if not table.deepcopy then
        for k, v in pairs(layer) do copied[k] = v end
      end
      if not copied.icon_size then copied.icon_size = item.icon_size or 64 end
      icons[#icons + 1] = copied
    end
  else
    icons[1] = {icon = item.icon, icon_size = item.icon_size or 64}
  end
  icons[#icons + 1] = {icon = BADGE, icon_size = 64}
  return icons
end

local function results_for(card)
  local results = {{type = "fluid", name = HOT, amount = coolant, temperature = 25}}
  if fail < 1 then
    local ok = {type = "item", name = card, amount = 2}
    if fail > 0 then ok.shared_probability = {min = 0, max = 1 - fail} end
    results[#results + 1] = ok
  end
  if fail > 0 then
    local bad = {type = "item", name = JUNK, amount = 2}
    if fail < 1 then bad.shared_probability = {min = 1 - fail, max = 1} end
    results[#results + 1] = bad
  end
  return results
end

-- Read and sort all eligible SE cards. Unknown matches are reported but not
-- silently enabled in 0.7.64; opt-in allows trying future SE content.
local candidates, ignored_unknown, ignored_probes = {}, 0, 0
for name, item in pairs(data.raw.item or {}) do
  if is_data_card(name) then
    if is_probe(name) and not include_probes then
      ignored_probes = ignored_probes + 1
      log("[SE Data Duplicator] SKIP probe (disabled by default): " .. name)
    elseif not KNOWN[name] and not include_unknown then
      ignored_unknown = ignored_unknown + 1
      log("[SE Data Duplicator] SKIP unknown data card (enable opt-in to copy): " .. name)
    elseif not KNOWN[name] and not (item.subgroup and item.subgroup:match("^data%-")) then
      ignored_unknown = ignored_unknown + 1
      log("[SE Data Duplicator] SKIP unknown name with non-data subgroup: " .. name)
    else
      candidates[#candidates + 1] = name
    end
  end
end
table.sort(candidates)
assert(#candidates > 0, "[SE Data Duplicator] No eligible SE data cards found")

local generated, fallback_count, skipped = {}, 0, 0
for _, card in ipairs(candidates) do
  local item = data.raw.item[card]
  local source = (data.raw.recipe or {})[card]
  local techs = {}
  local source_name, mode
  local min_tier = 1

  if is_primary_source(source, card) then
    source_name = card
    for name in pairs(technology_for_recipe[card] or {}) do techs[name] = true end
    if next(techs) then
      mode = "primary-recipe"
    elseif source.enabled ~= false then
      techs["se-space-supercomputer-1"] = true
      mode = "initially-enabled"
      fallback_count = fallback_count + 1
    end
  elseif is_probe(card) then
    local details = PROBE_TECH[card]
    techs[details[1]] = true
    min_tier = details[2]
    source_name = "rocket-launch"
    mode = "probe-launch"
    fallback_count = fallback_count + 1
  end

  if not mode then
    skipped = skipped + 1
    log("[SE Data Duplicator] SKIP " .. card ..
      ": no verified primary source and technology unlock")
  else
    local technology_names, matched_tech = {}, {}
    for tech_name in pairs(techs) do
      if (data.raw.technology or {})[tech_name] then
        matched_tech[tech_name] = true
        technology_names[#technology_names + 1] = tech_name
        min_tier = math.max(min_tier, required_tier(tech_name))
      else
        log("[SE Data Duplicator] WARNING " .. card ..
          ": required technology missing: " .. tech_name)
      end
    end
    table.sort(technology_names)
    if #technology_names == 0 then
      skipped = skipped + 1
      log("[SE Data Duplicator] SKIP " .. card ..
        ": no existing technology to unlock copying")
    elseif not (item.icon or (item.icons and #item.icons > 0)) then
      skipped = skipped + 1
      log("[SE Data Duplicator] SKIP " .. card .. ": no usable item icon")
    else
      local copy_name = PREFIX .. card
      if (data.raw.recipe or {})[copy_name] then
        error("[SE Data Duplicator] Duplicate copy recipe: " .. copy_name, 0)
      end
      local recipe = {
        type = "recipe",
        name = copy_name,
        categories = {CATEGORY .. (tiered and min_tier or 1)},
        enabled = false,
        energy_required = craft_seconds,
        ingredients = {
          {type = "item", name = card, amount = 1},
          {type = "item", name = EMPTY, amount = 1},
          {type = "fluid", name = COLD, amount = coolant, temperature = -100}
        },
        results = results_for(card),
        icons = icon_layers(item),
        localised_name = {"se-data-duplicator.copy-name",
          item.localised_name or {"item-name." .. card}},
        localised_description = {"se-data-duplicator.copy-description",
          tostring(fail_percent)},
        subgroup = item.subgroup,
        order = "z[duplicate]-" .. (item.order or card),
        allow_productivity = false,
        maximum_productivity = 0,
        allow_quality = false,
        can_set_quality = false,
        auto_recycle = false,
        hide_from_player_crafting = true,
        allow_as_intermediate = false,
        always_show_made_in = true
      }
      generated[#generated + 1] = recipe
      for _, tech_name in ipairs(technology_names) do
        local technology = data.raw.technology[tech_name]
        technology.effects = technology.effects or {}
        local found = false
        for _, effect in ipairs(technology.effects) do
          if effect.type == "unlock-recipe" and effect.recipe == copy_name then
            found = true; break
          end
        end
        if not found then
          -- Unlocks the recipe but does not crowd the research results screen.
          technology.effects[#technology.effects + 1] =
              {type = "unlock-recipe", recipe = copy_name, hidden = true}
        end
      end
      log(string.format("[SE Data Duplicator] MAP card=%s source=%s mode=%s technologies=%s min-computer=%d category=%s",
        card, source_name, mode, table.concat(technology_names, ","),
        min_tier, recipe.categories[1]))
    end
  end
end
data:extend(generated)
log(string.format("[SE Data Duplicator] SUMMARY recipes=%d fallback=%d skipped=%d unknown=%d probes-disabled=%d tiered=%s failure=%d%% seconds=%s coolant=%d",
  #generated, fallback_count, skipped, ignored_unknown, ignored_probes,
  tostring(tiered), fail_percent, tostring(craft_seconds), coolant))
